import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/subscription_record/subscription_record_entity.dart';
import 'package:uniun/domain/repositories/subscription_record_repository.dart';

@lazySingleton
class SaveSubscriptionRecordUseCase extends UseCase<
    Either<Failure, SubscriptionRecordEntity>, SubscriptionRecordEntity> {
  final SubscriptionRecordRepository repository;
  const SaveSubscriptionRecordUseCase(this.repository);

  @override
  Future<Either<Failure, SubscriptionRecordEntity>> call(
    SubscriptionRecordEntity input, {
    bool cached = false,
  }) {
    return repository.saveRecord(input);
  }
}
