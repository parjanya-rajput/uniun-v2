import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/repositories/note_repository.dart';
import 'package:uniun/domain/repositories/profile_repository.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/domain/usecases/get_replies_usecase.dart';
import 'package:uniun/domain/usecases/get_note_by_id_usecase.dart';
import 'package:uniun/domain/usecases/publish_note_usecase.dart';

part 'thread_event.dart';
part 'thread_state.dart';

@injectable
class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  final GetNoteByIdUseCase _getNoteById;
  final GetRepliesUseCase _getReplies;
  final PublishNoteUseCase _publishNote;
  final ProfileRepository _profileRepository;
  final NoteRepository _noteRepository;
  final UserRepository _userRepository;

  ThreadBloc(
    this._getNoteById,
    this._getReplies,
    this._publishNote,
    this._profileRepository,
    this._noteRepository,
    this._userRepository,
  ) : super(const ThreadState()) {
    on<LoadThreadEvent>(_onLoad, transformer: droppable());
    on<UpdateReplyTextEvent>(_onUpdateText);
    on<SetReplyTargetEvent>(_onSetTarget);
    on<PostReplyEvent>(_onPost, transformer: droppable());
    on<SwitchTabEvent>(_onSwitchTab);
  }

  // ── Load ────────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    LoadThreadEvent event,
    Emitter<ThreadState> emit,
  ) async {
    emit(state.copyWith(status: ThreadStatus.loading));

    // 1. Fetch root note
    final rootResult = await _getNoteById.call(event.noteId);
    if (rootResult.isLeft()) {
      emit(state.copyWith(
        status: ThreadStatus.error,
        errorMessage: rootResult.fold((f) => _msg(f), (_) => ''),
      ));
      return;
    }
    final rootNote = rootResult.getOrElse(() => throw StateError(''));

    // 2. Fetch root author profile
    final profiles = <String, ProfileEntity>{};
    _profileRepository.getProfile(rootNote.authorPubkey).then(
          (r) => r.fold((_) {}, (p) => profiles[p.pubkey] = p),
        );

    // 3. Fetch direct replies
    final repliesResult = await _getReplies.call(event.noteId);
    final replies = repliesResult.fold((_) => <NoteEntity>[], (r) => r);

    // 4. Fetch profiles + reply counts + nested replies for each reply
    final replyCounts = <String, int>{};
    final nestedReplies = <String, List<NoteEntity>>{};
    final allNotes = [rootNote, ...replies];

    for (final note in allNotes) {
      // Profile
      final pr = await _profileRepository.getProfile(note.authorPubkey);
      pr.fold((_) {}, (p) => profiles[p.pubkey] = p);
    }

    // BFS-expand nested replies (all depths) and fetch reply counts + profiles
    final bfsQueue = [...replies];
    final visited = <String>{rootNote.id, ...replies.map((r) => r.id)};
    int bfsLimit = 60; // safety cap
    while (bfsQueue.isNotEmpty && bfsLimit-- > 0) {
      final current = bfsQueue.removeAt(0);
      // Reply count badge
      final cr = await _noteRepository.getReplyCount(current.id);
      cr.fold((_) {}, (c) => replyCounts[current.id] = c);
      // Nested children
      final nr = await _getReplies.call(current.id);
      nr.fold((_) {}, (list) {
        if (list.isNotEmpty) {
          nestedReplies[current.id] = list;
          for (final n in list) {
            if (!visited.contains(n.id)) {
              visited.add(n.id);
              bfsQueue.add(n);
              _profileRepository
                  .getProfile(n.authorPubkey)
                  .then((r) => r.fold((_) {}, (p) => profiles[p.pubkey] = p));
            }
          }
        }
      });
    }

    emit(state.copyWith(
      rootNote: rootNote,
      profiles: profiles,
      replies: replies,
      replyCounts: replyCounts,
      nestedReplies: nestedReplies,
      status: ThreadStatus.loaded,
    ));
  }

  // ── Reply composer ──────────────────────────────────────────────────────────

  void _onUpdateText(UpdateReplyTextEvent event, Emitter<ThreadState> emit) {
    emit(state.copyWith(replyText: event.text));
  }

  void _onSetTarget(SetReplyTargetEvent event, Emitter<ThreadState> emit) {
    emit(state.copyWith(
      replyingToId: event.replyToId,
      replyingToName: event.replyToName,
    ));
  }

  Future<void> _onPost(
    PostReplyEvent event,
    Emitter<ThreadState> emit,
  ) async {
    if (!state.canPost || state.rootNote == null) return;
    emit(state.copyWith(postStatus: ThreadPostStatus.posting));

    // Get user key
    final userResult = await _userRepository.getActiveUser();
    String privkeyHex = '';
    String pubkeyHex = '';
    final err = userResult.fold<Failure?>(
      (f) => f,
      (u) {
        privkeyHex = Nip19.decodePrivkey(u.nsec);
        pubkeyHex = u.pubkeyHex;
        return null;
      },
    );
    if (err != null) {
      emit(state.copyWith(
        postStatus: ThreadPostStatus.error,
        errorMessage: _msg(err),
      ));
      return;
    }

    final rootId = state.rootNote!.id;
    final replyToId = state.replyingToId ?? rootId;

    // Build NIP-10 tags
    final tags = <List<String>>[
      ['e', rootId, '', 'root'],
      if (replyToId != rootId) ['e', replyToId, '', 'reply'],
    ];

    late final Event signed;
    try {
      signed = Event.from(
        kind: 1,
        tags: tags,
        content: state.replyText.trim(),
        privkey: privkeyHex,
      );
    } catch (e) {
      emit(state.copyWith(
        postStatus: ThreadPostStatus.error,
        errorMessage: 'Signing failed: $e',
      ));
      return;
    }

    final note = NoteEntity(
      id: signed.id,
      sig: signed.sig,
      authorPubkey: pubkeyHex,
      content: signed.content,
      type: NoteType.text,
      eTagRefs: [rootId, if (replyToId != rootId) replyToId],
      pTagRefs: const [],
      tTags: const [],
      created: DateTime.fromMillisecondsSinceEpoch(signed.createdAt * 1000),
      isSeen: true,
      rootEventId: rootId,
      replyToEventId: replyToId,
    );

    final result = await _publishNote.call(note);
    result.fold(
      (f) => emit(state.copyWith(
        postStatus: ThreadPostStatus.error,
        errorMessage: _msg(f),
      )),
      (published) {
        // Optimistically add to the correct list
        final updatedState = state.copyWith(
          replyText: '',
          replyingToId: null,
          replyingToName: null,
          postStatus: ThreadPostStatus.posted,
        );
        // Insert the new reply into the correct list and update counts
        if (replyToId == rootId) {
          emit(updatedState.copyWith(
            replies: [...state.replies, published],
          ));
        } else {
          final updatedNested =
              Map<String, List<NoteEntity>>.from(state.nestedReplies);
          updatedNested[replyToId] = [
            ...(updatedNested[replyToId] ?? []),
            published,
          ];
          // Bump the reply count badge on the parent reply item
          final updatedCounts = Map<String, int>.from(state.replyCounts);
          updatedCounts[replyToId] = (updatedCounts[replyToId] ?? 0) + 1;
          emit(updatedState.copyWith(
            nestedReplies: updatedNested,
            replyCounts: updatedCounts,
          ));
        }
      },
    );
  }

  void _onSwitchTab(SwitchTabEvent event, Emitter<ThreadState> emit) {
    emit(state.copyWith(activeTab: event.index));
  }

  String _msg(Failure f) => f.when(
        failure: (m) => m,
        notFoundFailure: (m) => m,
        errorFailure: (m) => m,
      );
}
