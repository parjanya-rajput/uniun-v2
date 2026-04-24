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
        // Increment direct parent + mention-refs (not the channel root ID which
        // is always message.rootEventId/channelId — that's a Kind 40 event, not
        // a channel message, so it will never be found and is safe to skip).
        final toIncrement = <String>{};
        if (message.replyToEventId != null) {
          toIncrement.add(message.replyToEventId!);
        }
        for (final ref in message.eTagRefs) {
          if (ref != message.rootEventId && ref != message.replyToEventId) {
            toIncrement.add(ref);
          }
        }
        for (final refId in toIncrement) {
          final parent = await isar.channelMessageModels
              .where()
              .eventIdEqualTo(refId)
              .findFirst();
          if (parent != null) {
            parent.cachedReplyCount++;
            await isar.channelMessageModels.put(parent);
          }
        }
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

      await _backfillReplyCountsIfNeeded(rows);
      return Right(rows.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  Future<void> _backfillReplyCountsIfNeeded(
      List<ChannelMessageModel> models) async {
    final toUpdate = <ChannelMessageModel>[];
    for (final m in models) {
      // Count all messages that reference m — both direct replies
      // (replyToEventId == m.eventId) and mention-refs (m.eventId in eTagRefs
      // but not as rootEventId). For channel messages rootEventId is always
      // the Kind-40 channel ID, never another channel message, so
      // eTagRefsElementEqualTo gives the correct union of both cases.
      final count = await isar.channelMessageModels
          .filter()
          .eTagRefsElementEqualTo(m.eventId)
          .count();
      if (count != m.cachedReplyCount) {
        m.cachedReplyCount = count;
        toUpdate.add(m);
      }
    }
    if (toUpdate.isEmpty) return;
    await isar.writeTxn(() async {
      for (final m in toUpdate) {
        await isar.channelMessageModels.put(m);
      }
    });
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
      // Query by eTagRefs containing messageId — matches both direct replies
      // (replyToEventId) and mention references, mirroring Vishnu note behaviour.
      final rows = await isar.channelMessageModels
          .filter()
          .eTagRefsElementEqualTo(messageId)
          .sortByCreated()
          .findAll();
      return Right(rows.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getChannelMessageReplyCount(
    String messageId,
  ) async {
    try {
      final count = await isar.channelMessageModels
          .filter()
          .eTagRefsElementEqualTo(messageId)
          .count();
      return Right(count);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
