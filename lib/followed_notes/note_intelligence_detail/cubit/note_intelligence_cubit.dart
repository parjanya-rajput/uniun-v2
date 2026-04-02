import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/repositories/note_repository.dart';
import 'package:uniun/domain/repositories/profile_repository.dart';
import 'package:uniun/domain/usecases/get_note_by_id_usecase.dart';
import 'package:uniun/domain/usecases/get_replies_usecase.dart';

part 'note_intelligence_state.dart';

class NoteIntelligenceCubit extends Cubit<NoteIntelligenceState> {
  NoteIntelligenceCubit({
    required this.getNoteById,
    required this.getReplies,
    required this.profileRepository,
    required this.noteRepository,
  }) : super(const NoteIntelligenceState());

  final GetNoteByIdUseCase getNoteById;
  final GetRepliesUseCase getReplies;
  final ProfileRepository profileRepository;
  final NoteRepository noteRepository;

  Future<void> load(String noteId) async {
    emit(state.copyWith(status: NoteIntelligenceStatus.loading));

    final noteResult = await getNoteById.call(noteId);
    final note = noteResult.fold((_) => null, (n) => n);
    if (note == null) {
      emit(state.copyWith(
        status: NoteIntelligenceStatus.error,
        errorMessage: 'Note not found',
      ));
      return;
    }

    // Load author profile
    final profileResult =
        await profileRepository.getProfile(note.authorPubkey);
    final profile = profileResult.fold((_) => null, (p) => p);

    // Load direct replies
    final repliesResult = await getReplies.call(noteId);
    final replies =
        repliesResult.fold((_) => <NoteEntity>[], (list) => list);

    // Load reply author profiles
    final replyProfiles = <String, ProfileEntity>{};
    final seenPubkeys = <String>{note.authorPubkey};
    for (final reply in replies) {
      if (!seenPubkeys.contains(reply.authorPubkey)) {
        seenPubkeys.add(reply.authorPubkey);
        final r = await profileRepository.getProfile(reply.authorPubkey);
        r.fold((_) {}, (p) => replyProfiles[p.pubkey] = p);
      }
    }

    // Load referenced notes (eTagRefs) — best-effort, up to 5
    final referencedNotes = <NoteEntity>[];
    for (final refId in note.eTagRefs.take(5)) {
      final r = await noteRepository.getNoteById(refId);
      r.fold((_) {}, (n) => referencedNotes.add(n));
    }

    emit(NoteIntelligenceState(
      status: NoteIntelligenceStatus.loaded,
      note: note,
      profile: profile,
      replies: replies,
      replyProfiles: replyProfiles,
      referencedNotes: referencedNotes,
    ));
  }
}
