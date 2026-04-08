import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/dm/dm_message_entity.dart';

part 'dm_message_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('DmMessage')
class DmMessageModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String eventId;

  @Index()
  late String otherPubkey;

  late String senderPubkey;
  late List<String> receiverPubkeys;
  late String content;
  String? subject;
  String? replyToEventId;
  late DateTime createdAt;
  late bool isSentByMe;
}

extension DmMessageModelExtension on DmMessageModel {
  DmMessageEntity toDomain() => DmMessageEntity(
    eventId: eventId,
    otherPubkey: otherPubkey,
    senderPubkey: senderPubkey,
    receiverPubkeys: receiverPubkeys,
    content: content,
    subject: subject,
    replyToEventId: replyToEventId,
    createdAt: createdAt,
    isSentByMe: isSentByMe,
  );
}
