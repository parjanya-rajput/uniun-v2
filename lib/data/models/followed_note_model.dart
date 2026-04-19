import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/followed_note/followed_note_entity.dart';

part 'followed_note_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('FollowedNote')
class FollowedNoteModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String eventId;

  late String contentPreview;
  late DateTime followedAt;

  /// Incremented in the gateway isolate when a kind **1** `EVENT` references
  /// this [eventId] via an **e** tag (deduped across duplicate relay deliveries).
  late int newReferenceCount;
}

extension FollowedNoteModelExtension on FollowedNoteModel {
  FollowedNoteEntity toDomain() => FollowedNoteEntity(
        eventId: eventId,
        contentPreview: contentPreview,
        followedAt: followedAt,
        newReferenceCount: newReferenceCount,
      );
}
