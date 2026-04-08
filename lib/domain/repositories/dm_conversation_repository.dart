import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/dm/dm_conversation_entity.dart';

abstract class DmConversationRepository {
  Future<Either<Failure, List<DmConversationEntity>>> getConversations();

  Future<Either<Failure, DmConversationEntity>> getConversationByOtherPubkey(
    String otherPubkey,
  );

  /// Idempotent: if conversation already exists, no change is applied.
  Future<Either<Failure, DmConversationEntity>> saveConversation(
    DmConversationEntity entity,
  );

  Future<Either<Failure, Unit>> deleteConversation(String otherPubkey);
}
