import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';

part 'channel_message_entity.freezed.dart';

/// Local cache of a NIP-28 kind **42** channel message (short text in channel).
@freezed
abstract class ChannelMessageEntity with _$ChannelMessageEntity {
  const factory ChannelMessageEntity({
    /// Nostr event id (hex).
    required String id,
    /// NIP-28 channel id (kind **40** event id).
    required String channelId,
    required String sig,
    required String authorPubkey,
    required String content,
    required List<String> eTagRefs,
    required List<String> pTagRefs,
    String? rootEventId,
    String? replyToEventId,
    required DateTime created,
  }) = _ChannelMessageEntity;
}

extension ChannelMessageToNote on ChannelMessageEntity {
  /// Converts to NoteEntity for display with NoteCard.
  /// eTagRefs are cleared — channel messages are not part of the knowledge graph.
  NoteEntity toNoteEntity() => NoteEntity(
        id: id,
        sig: sig,
        authorPubkey: authorPubkey,
        content: content,
        type: NoteType.text,
        eTagRefs: const [],
        pTagRefs: pTagRefs,
        tTags: const [],
        created: created,
        isSeen: true,
      );
}
