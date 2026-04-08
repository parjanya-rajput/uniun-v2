import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/dm/dm_message_entity.dart';

abstract class DmMessageRepository {
  Future<Either<Failure, DmMessageEntity>> saveMessage(DmMessageEntity entity);

  Future<Either<Failure, List<DmMessageEntity>>> getMessages(
    String otherPubkey, {
    DateTime? before,
    int limit = 30,
  });

  Future<Either<Failure, DmMessageEntity>> getMessageById(String eventId);
}
