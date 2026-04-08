import 'package:freezed_annotation/freezed_annotation.dart';

part 'dm_message_entity.freezed.dart';

@freezed
abstract class DmMessageEntity with _$DmMessageEntity {
  const factory DmMessageEntity({
    required String eventId,
    required String otherPubkey,
    required String senderPubkey,
    required List<String> receiverPubkeys,
    required String content,
    String? subject,
    String? replyToEventId,
    required DateTime createdAt,
    required bool isSentByMe,
  }) = _DmMessageEntity;
}
