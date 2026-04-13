import 'package:freezed_annotation/freezed_annotation.dart';

part 'draft_entity.freezed.dart';

@freezed
abstract class DraftEntity with _$DraftEntity {
  const factory DraftEntity({
    required String draftId,
    required String content,
    String? rootEventId,
    String? replyToEventId,
    required List<String> eTagRefs,
    required List<String> pTagRefs,
    required List<String> tTags,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DraftEntity;
}
