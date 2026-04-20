import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/subscription_record/subscription_record_entity.dart';
import 'package:uniun/domain/repositories/subscription_record_repository.dart';

class SubscribeChannelInput {
  final String channelId;

  const SubscribeChannelInput({
    required this.channelId,
  });
}

@lazySingleton
class SubscribeChannelUseCase extends UseCase<Either<Failure, SubscriptionRecordEntity>, SubscribeChannelInput> {
  final SubscriptionRecordRepository _repository;

  const SubscribeChannelUseCase(this._repository);

  @override
  Future<Either<Failure, SubscriptionRecordEntity>> call(SubscribeChannelInput input, {bool cached = false}) async {
    try {
      final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final subRecord = SubscriptionRecordEntity(
        channelId: input.channelId,
        kinds: const [41, 42, 43, 44],
        eTags: [input.channelId],
        authors: null,
        limit: null,
        lastUntilByRelay: const {},
        createdAt: nowUnix,
        updatedAt: nowUnix,
        enabled: true,
      );
      return _repository.saveRecord(subRecord);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
