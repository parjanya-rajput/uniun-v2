import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/channel_message_model.dart';
import 'package:uniun/domain/entities/channel_message/channel_message_entity.dart';
import 'package:uniun/domain/repositories/channel_message_repository.dart';

@Injectable(as: ChannelMessageRepository)
class ChannelMessageRepositoryImpl extends ChannelMessageRepository {
  final Isar isar;

  ChannelMessageRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, ChannelMessageEntity>> saveMessage(
    ChannelMessageEntity message,
  ) async {
    try {
      final existing = await isar.channelMessageModels
          .where()
          .eventIdEqualTo(message.id)
          .findFirst();
      if (existing != null) {
        return Right(existing.toDomain());
      }

      final model = ChannelMessageModel()
        ..eventId = message.id
        ..channelId = message.channelId
        ..sig = message.sig
        ..authorPubkey = message.authorPubkey
        ..content = message.content
        ..eTagRefs = List<String>.from(message.eTagRefs)
        ..pTagRefs = List<String>.from(message.pTagRefs)
        ..rootEventId = message.rootEventId
        ..replyToEventId = message.replyToEventId
        ..created = message.created;

      await isar.writeTxn(() async {
        await isar.channelMessageModels.put(model);
      });

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChannelMessageEntity>>> getMessagesForChannel({
    required String channelId,
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      final List<ChannelMessageModel> rows;
      if (before != null) {
        rows = await isar.channelMessageModels
            .filter()
            .channelIdEqualTo(channelId)
            .createdLessThan(before)
            .sortByCreatedDesc()
            .limit(limit)
            .findAll();
      } else {
        rows = await isar.channelMessageModels
            .filter()
            .channelIdEqualTo(channelId)
            .sortByCreatedDesc()
            .limit(limit)
            .findAll();
      }

      return Right(rows.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChannelMessageEntity?>> getMessageByEventId(
    String eventId,
  ) async {
    try {
      final row = await isar.channelMessageModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      return Right(row?.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChannelMessageEntity>>> getChannelMessageReplies(
    String messageId,
  ) async {
    try {
      final rows = await isar.channelMessageModels
          .filter()
          .replyToEventIdEqualTo(messageId)
          .sortByCreated()
          .findAll();
      return Right(rows.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
