import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';

enum SavedNotesStatus { initial, loading, loaded, error }

class SavedNotesState {
  const SavedNotesState({
    this.status = SavedNotesStatus.initial,
    this.notes = const [],
    this.errorMessage,
  });

  final SavedNotesStatus status;
  final List<SavedNoteEntity> notes;
  final String? errorMessage;

  SavedNotesState copyWith({
    SavedNotesStatus? status,
    List<SavedNoteEntity>? notes,
    String? errorMessage,
  }) {
    return SavedNotesState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
