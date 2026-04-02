import 'package:freezed_annotation/freezed_annotation.dart';

part 'saved_note_entity.freezed.dart';

@freezed
abstract class SavedNoteEntity with _$SavedNoteEntity {
  const factory SavedNoteEntity({
    required String eventId,
    required DateTime savedAt,
    required String contentPreview,
  }) = _SavedNoteEntity;
}
