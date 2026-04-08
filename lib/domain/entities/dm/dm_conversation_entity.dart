import 'package:freezed_annotation/freezed_annotation.dart';

part 'dm_conversation_entity.freezed.dart';

@freezed
abstract class DmConversationEntity with _$DmConversationEntity {
  const factory DmConversationEntity({required String otherPubkey}) =
      _DmConversationEntity;
}
