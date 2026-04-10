import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/dm_message_model.dart';
import 'package:uniun/domain/entities/dm/dm_message_entity.dart';
import 'package:uniun/domain/repositories/dm_message_repository.dart';

@Injectable(as: DmMessageRepository)
class DmMessageRepositoryImpl extends DmMessageRepository {
  final Isar isar;
  DmMessageRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, DmMessageEntity>> saveMessage(
    DmMessageEntity entity,
  ) async {
    try {
      final existing = await isar.dmMessageModels
          .where()
          .eventIdEqualTo(entity.eventId)
          .findFirst();
      if (existing != null) {
        return Right(existing.toDomain());
      }

      final model = DmMessageModel()
        ..eventId = entity.eventId
        ..conversationId = entity.conversationId
        ..content = entity.content
        ..subject = entity.subject
        ..replyToEventId = entity.replyToEventId
        ..createdAt = entity.createdAt
        ..isSentByMe = entity.isSentByMe;

      await isar.writeTxn(() async {
        await isar.dmMessageModels.put(model);
      });

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DmMessageEntity>>> getMessages(
    int conversationId, {
    DateTime? before,
    int limit = 30,
  }) async {
    try {
      final rows = await isar.dmMessageModels
          .where()
          .conversationIdEqualTo(conversationId)
          .findAll();

      rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final filtered = before == null
          ? rows
          : rows.where((m) => m.createdAt.isBefore(before)).toList();

      return Right(filtered.take(limit).map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DmMessageEntity>> getMessageById(
    String eventId,
  ) async {
    try {
      final row = await isar.dmMessageModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (row == null) {
        return Left(
          Failure.notFoundFailure('DM message not found for eventId: $eventId'),
        );
      }
      return Right(row.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
