import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/domain/usecases/publish_note_usecase.dart';

part 'brahma_create_event.dart';
part 'brahma_create_state.dart';

@injectable
class BrahmaCreateBloc extends Bloc<BrahmaCreateEvent, BrahmaCreateState> {
  final UserRepository _userRepository;
  final PublishNoteUseCase _publishUseCase;

  BrahmaCreateBloc(this._userRepository, this._publishUseCase)
      : super(const BrahmaCreateState()) {
    on<UpdateContentEvent>(_onUpdateContent);
    on<SubmitNoteEvent>(_onSubmitNote, transformer: droppable());
    on<ResetBrahmaEvent>(_onReset);
  }

  void _onUpdateContent(
    UpdateContentEvent event,
    Emitter<BrahmaCreateState> emit,
  ) {
    final tags = _extractHashtags(event.content);
    emit(state.copyWith(content: event.content, extractedTags: tags));
  }

  Future<void> _onSubmitNote(
    SubmitNoteEvent event,
    Emitter<BrahmaCreateState> emit,
  ) async {
    if (!state.canSubmit) return;
    emit(state.copyWith(status: BrahmaCreateStatus.submitting));

    // 1. Get signing key
    final userResult = await _userRepository.getActiveUser();
    String privkeyHex = '';
    String pubkeyHex = '';

    final userError = userResult.fold<Failure?>(
      (f) => f,
      (user) {
        privkeyHex = Nip19.decodePrivkey(user.nsec);
        pubkeyHex = user.pubkeyHex;
        return null;
      },
    );
    if (userError != null) {
      emit(state.copyWith(
        status: BrahmaCreateStatus.error,
        errorMessage: _msg(userError),
      ));
      return;
    }

    // 2. Build NIP-10 tags + hashtags
    final tags = <List<String>>[];
    if (event.rootEventId != null) {
      tags.add(['e', event.rootEventId!, '', 'root']);
    }
    if (event.replyToEventId != null) {
      tags.add(['e', event.replyToEventId!, '', 'reply']);
    }
    for (final h in state.extractedTags) {
      tags.add(['t', h]);
    }

    // 3. Sign with nostr_core_dart
    late final Event signedEvent;
    try {
      signedEvent = Event.from(
        kind: 1, // Kind 1 = Short Text Note (NIP-01)
        tags: tags,
        content: state.content.trim(),
        privkey: privkeyHex,
      );
    } catch (e) {
      emit(state.copyWith(
        status: BrahmaCreateStatus.error,
        errorMessage: 'Signing failed: $e',
      ));
      return;
    }

    // 4. Build NoteEntity
    final eTagRefs = [
      if (event.rootEventId != null) event.rootEventId!,
      if (event.replyToEventId != null) event.replyToEventId!,
    ];

    final note = NoteEntity(
      id: signedEvent.id,
      sig: signedEvent.sig,
      authorPubkey: pubkeyHex,
      content: signedEvent.content,
      type: NoteType.text,
      eTagRefs: eTagRefs,
      pTagRefs: const [],
      tTags: state.extractedTags,
      created: DateTime.fromMillisecondsSinceEpoch(signedEvent.createdAt * 1000),
      isSeen: true,
      rootEventId: event.rootEventId,
      replyToEventId: event.replyToEventId,
    );

    // 5. Publish: save locally + enqueue for relay
    final result = await _publishUseCase.call(note);
    result.fold(
      (f) => emit(state.copyWith(
        status: BrahmaCreateStatus.error,
        errorMessage: _msg(f),
      )),
      (published) => emit(state.copyWith(
        status: BrahmaCreateStatus.success,
        publishedNoteId: published.id,
      )),
    );
  }

  void _onReset(ResetBrahmaEvent event, Emitter<BrahmaCreateState> emit) {
    emit(const BrahmaCreateState());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<String> _extractHashtags(String content) {
    final matches = RegExp(r'#(\w+)').allMatches(content);
    return matches
        .map((m) => m.group(1)!)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }

  String _msg(Failure f) => f.when(
        failure: (m) => m,
        notFoundFailure: (m) => m,
        errorFailure: (m) => m,
      );
}
