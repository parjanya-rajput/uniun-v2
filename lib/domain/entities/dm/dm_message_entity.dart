import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/core/enum/note_type.dart';

part 'dm_message_entity.freezed.dart';

@freezed
abstract class DmMessageEntity with _$DmMessageEntity {
  const factory DmMessageEntity({
    required String eventId,
    required int conversationId,
    required String receiverPubkey,
    String? replyToEventId,
    required String content,
    String? subject,
    required int kind,
    required NoteType type,
    required DateTime created,
    required bool isSeen,
  }) = _DmMessageEntity;
}
