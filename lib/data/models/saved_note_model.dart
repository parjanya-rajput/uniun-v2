import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';

part 'saved_note_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('SavedNote')
class SavedNoteModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String eventId;

  late DateTime savedAt;

  // Content snapshot so the note is readable even after CleanupManager evicts
  // the source NoteModel (saved notes are kept forever).
  late String contentPreview;
}

extension SavedNoteModelExtension on SavedNoteModel {
  SavedNoteEntity toDomain() => SavedNoteEntity(
        eventId: eventId,
        savedAt: savedAt,
        contentPreview: contentPreview,
      );
}
