import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/draft/draft_entity.dart';

part 'draft_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('Draft')
class DraftModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String draftId; // UUID for draft identity

  late String content;

  String? rootEventId; // null = top-level draft
  String? replyToEventId; // null = top-level draft

  late List<String> eTagRefs; // reference graph edges
  late List<String> pTagRefs; // user mentions
  late List<String> tTags; // topics

  late DateTime createdAt;
  late DateTime updatedAt;
}

extension DraftModelExtension on DraftModel {
  DraftEntity toDomain() => DraftEntity(
        draftId: draftId,
        content: content,
        rootEventId: rootEventId,
        replyToEventId: replyToEventId,
        eTagRefs: eTagRefs,
        pTagRefs: pTagRefs,
        tTags: tTags,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
