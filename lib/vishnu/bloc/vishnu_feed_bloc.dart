import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/inputs/note_input.dart';
import 'package:uniun/domain/repositories/note_repository.dart';
import 'package:uniun/domain/repositories/profile_repository.dart';
import 'package:uniun/domain/repositories/saved_note_repository.dart';
import 'package:uniun/domain/usecases/get_feed_usecase.dart';
import 'package:uniun/domain/usecases/toggle_save_usecase.dart';

part 'vishnu_feed_event.dart';
part 'vishnu_feed_state.dart';

const _pageSize = 20;

@injectable
class VishnuFeedBloc extends Bloc<VishnuFeedEvent, VishnuFeedState> {
  final GetFeedUseCase _getFeedUseCase;
  final ProfileRepository _profileRepository;
  final NoteRepository _noteRepository;
  final SavedNoteRepository _savedNoteRepository;
  final ToggleSaveUseCase _toggleSave;

  VishnuFeedBloc(
    this._getFeedUseCase,
    this._profileRepository,
    this._noteRepository,
    this._savedNoteRepository,
    this._toggleSave,
  ) : super(const VishnuFeedState()) {
    on<LoadFeedEvent>(_onLoad, transformer: droppable());
    on<RefreshFeedEvent>(_onRefresh, transformer: droppable());
    on<LoadMoreFeedEvent>(_onLoadMore, transformer: droppable());
    on<ToggleSaveFeedEvent>(_onToggleSave, transformer: sequential());
  }

  Future<void> _onLoad(
    LoadFeedEvent event,
    Emitter<VishnuFeedState> emit,
  ) async {
    if (state.status != VishnuFeedStatus.initial) return;
    emit(state.copyWith(status: VishnuFeedStatus.loading));
    await _fetchPage(emit, before: null, append: false);
  }

  Future<void> _onRefresh(
    RefreshFeedEvent event,
    Emitter<VishnuFeedState> emit,
  ) async {
    emit(state.copyWith(status: VishnuFeedStatus.loading));
    await _fetchPage(emit, before: null, append: false);
  }

  Future<void> _onLoadMore(
    LoadMoreFeedEvent event,
    Emitter<VishnuFeedState> emit,
  ) async {
    if (!state.hasMore) return;
    if (state.status == VishnuFeedStatus.loadingMore) return;
    if (state.notes.isEmpty) return;

    emit(state.copyWith(status: VishnuFeedStatus.loadingMore));
    final cursor = state.notes.last.created;
    await _fetchPage(emit, before: cursor, append: true);
  }

  Future<void> _onToggleSave(
    ToggleSaveFeedEvent event,
    Emitter<VishnuFeedState> emit,
  ) async {
    final currentlySaved = state.savedIds.contains(event.noteId);
    // Optimistic update
    final optimistic = Set<String>.from(state.savedIds);
    if (currentlySaved) {
      optimistic.remove(event.noteId);
    } else {
      optimistic.add(event.noteId);
    }
    emit(state.copyWith(savedIds: optimistic));

    // Persist
    final result = await _toggleSave.call(ToggleSaveInput(
      eventId: event.noteId,
      contentPreview: event.contentPreview,
      isSaved: currentlySaved,
    ));

    result.fold(
      // Rollback on failure
      (_) {
        final rollback = Set<String>.from(state.savedIds);
        if (currentlySaved) {
          rollback.add(event.noteId);
        } else {
          rollback.remove(event.noteId);
        }
        emit(state.copyWith(savedIds: rollback));
      },
      (_) {}, // optimistic already correct
    );
  }

  Future<void> _fetchPage(
    Emitter<VishnuFeedState> emit, {
    required DateTime? before,
    required bool append,
  }) async {
    final result = await _getFeedUseCase.call(
      GetFeedInput(limit: _pageSize, before: before),
    );

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: VishnuFeedStatus.error,
        errorMessage: _msg(failure),
      )),
      (newNotes) async {
        final combined = append ? [...state.notes, ...newNotes] : newNotes;

        // Profiles
        final profiles = Map<String, ProfileEntity>.from(state.profiles);
        final newPubkeys = combined
            .map((n) => n.authorPubkey)
            .toSet()
            .where((k) => !profiles.containsKey(k));
        for (final pubkey in newPubkeys) {
          final r = await _profileRepository.getProfile(pubkey);
          r.fold((_) {}, (p) => profiles[pubkey] = p);
        }

        // Reply counts
        final counts = Map<String, int>.from(state.replyCounts);
        for (final note in newNotes) {
          if (!counts.containsKey(note.id)) {
            final r = await _noteRepository.getThreadReplyCount(note.id);
            r.fold((_) {}, (c) => counts[note.id] = c);
          }
        }

        // Saved IDs — refresh the full set from Isar each page load
        final savedResult = await _savedNoteRepository.getAll();
        final savedIds = savedResult.fold(
          (_) => state.savedIds,
          (list) => list.map((e) => e.eventId).toSet(),
        );

        emit(state.copyWith(
          notes: combined,
          profiles: profiles,
          replyCounts: counts,
          savedIds: savedIds,
          status: VishnuFeedStatus.loaded,
          hasMore: newNotes.length >= _pageSize,
        ));
      },
    );
  }

  String _msg(Failure f) => f.when(
        failure: (m) => m,
        notFoundFailure: (m) => m,
        errorFailure: (m) => m,
      );
}
