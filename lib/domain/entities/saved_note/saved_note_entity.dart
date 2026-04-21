import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';

part 'saved_note_entity.freezed.dart';

@freezed
abstract class SavedNoteEntity with _$SavedNoteEntity {
  const factory SavedNoteEntity({
    required String eventId,
    required String sig,
    required String authorPubkey,
    required String content,
    required NoteType type,
    required List<String> eTagRefs,
    required List<String> pTagRefs,
    required List<String> tTags,
    required DateTime created,
    required DateTime savedAt,
    /// 384-dim embedding vector. Null until the background EmbeddingService runs.
    List<double>? embedding,
  }) = _SavedNoteEntity;
}

extension SavedNoteToNote on SavedNoteEntity {
  /// [savedEventIds] filters eTagRefs to only those that are also saved,
  /// so the ref count matches what savedOnly ThreadPage will actually show.
  NoteEntity toNoteEntity({Set<String>? savedEventIds}) => NoteEntity(
        id: eventId,
        sig: sig,
        authorPubkey: authorPubkey,
        content: content,
        type: type,
        eTagRefs: savedEventIds != null
            ? eTagRefs.where((id) => savedEventIds.contains(id)).toList()
            : const [],
        pTagRefs: pTagRefs,
        tTags: tTags,
        created: created,
        isSeen: true,
      );
}
