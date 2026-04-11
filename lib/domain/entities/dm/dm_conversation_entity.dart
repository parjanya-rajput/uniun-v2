import 'package:freezed_annotation/freezed_annotation.dart';

part 'dm_conversation_entity.freezed.dart';

@freezed
abstract class DmConversationEntity with _$DmConversationEntity {
  const factory DmConversationEntity({
    int? id,
    required String otherPubkey,
    String? relayUrl,
  }) = _DmConversationEntity;
}
