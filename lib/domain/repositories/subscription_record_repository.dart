import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/subscription_record/subscription_record_entity.dart';

abstract class SubscriptionRecordRepository {
  Future<Either<Failure, SubscriptionRecordEntity>> saveRecord(
    SubscriptionRecordEntity record,
  );

  Future<Either<Failure, SubscriptionRecordEntity>> getRecordByChannelId(String channelId);

  Future<Either<Failure, List<SubscriptionRecordEntity>>> getEnabledRecords();

  Future<Either<Failure, Unit>> updateCheckpoint(
    String channelId,
    Map<String, int> lastUntilByRelay,
  );

  Future<Either<Failure, Unit>> toggleEnabled(String channelId, bool enabled);
} 
