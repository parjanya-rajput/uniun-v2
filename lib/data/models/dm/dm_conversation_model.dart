import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/dm/dm_conversation_entity.dart';

part 'dm_conversation_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('DmConversation')
class DmConversationModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String otherPubkey;

  List<String> relays = [];
}

extension DmConversationModelExtension on DmConversationModel {
  DmConversationEntity toDomain() => DmConversationEntity(
    id: id,
    otherPubkey: otherPubkey,
    relays: relays,
  );
}
