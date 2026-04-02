part of 'note_intelligence_cubit.dart';

enum NoteIntelligenceStatus { initial, loading, loaded, error }

class NoteIntelligenceState {
  const NoteIntelligenceState({
    this.status = NoteIntelligenceStatus.initial,
    this.note,
    this.profile,
    this.replies = const [],
    this.replyProfiles = const {},
    this.referencedNotes = const [],
    this.errorMessage,
  });

  final NoteIntelligenceStatus status;
  final NoteEntity? note;
  final ProfileEntity? profile;
  final List<NoteEntity> replies;
  final Map<String, ProfileEntity> replyProfiles;
  final List<NoteEntity> referencedNotes;
  final String? errorMessage;

  NoteIntelligenceState copyWith({
    NoteIntelligenceStatus? status,
    NoteEntity? note,
    ProfileEntity? profile,
    List<NoteEntity>? replies,
    Map<String, ProfileEntity>? replyProfiles,
    List<NoteEntity>? referencedNotes,
    String? errorMessage,
  }) {
    return NoteIntelligenceState(
      status: status ?? this.status,
      note: note ?? this.note,
      profile: profile ?? this.profile,
      replies: replies ?? this.replies,
      replyProfiles: replyProfiles ?? this.replyProfiles,
      referencedNotes: referencedNotes ?? this.referencedNotes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
