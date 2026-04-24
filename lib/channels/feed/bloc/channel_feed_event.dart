import 'package:uniun/domain/entities/channel_message/channel_message_entity.dart';

abstract class ChannelFeedEvent {
  const ChannelFeedEvent();
}

class LoadChannelFeedEvent extends ChannelFeedEvent {
  const LoadChannelFeedEvent(this.channelId);
  final String channelId;
}

class SendChannelMessageEvent extends ChannelFeedEvent {
  const SendChannelMessageEvent({
    required this.channelId,
    required this.content,
    this.replyToEventId,
    this.mentionRefs = const [],
  });
  final String channelId;
  final String content;
  final String? replyToEventId;
  final List<String> mentionRefs;
}

class SaveChannelFeedMessageEvent extends ChannelFeedEvent {
  const SaveChannelFeedMessageEvent(this.message);
  final ChannelMessageEntity message;
}

class UnsaveChannelFeedMessageEvent extends ChannelFeedEvent {
  const UnsaveChannelFeedMessageEvent(this.messageId);
  final String messageId;
}
