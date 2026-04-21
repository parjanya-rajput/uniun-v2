import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/channel_message/channel_message_entity.dart';

abstract class ChannelMessageRepository {
  /// Idempotent insert by [ChannelMessageEntity.id] (event id).
  Future<Either<Failure, ChannelMessageEntity>> saveMessage(
    ChannelMessageEntity message,
  );

  /// Channel thread messages, newest first.
  Future<Either<Failure, List<ChannelMessageEntity>>> getMessagesForChannel({
    required String channelId,
    int limit,
    DateTime? before,
  });

  Future<Either<Failure, ChannelMessageEntity?>> getMessageByEventId(
    String eventId,
  );

  /// Direct replies to a single channel message, oldest first.
  Future<Either<Failure, List<ChannelMessageEntity>>> getChannelMessageReplies(
    String messageId,
  );
}
