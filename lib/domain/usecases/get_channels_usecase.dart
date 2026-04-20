import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/channel/channel_entity.dart';
import 'package:uniun/domain/repositories/channel_repository.dart';

@lazySingleton
class GetChannelsUseCase
    extends NoParamsUseCase<Either<Failure, List<ChannelEntity>>> {
  final ChannelRepository repository;
  const GetChannelsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChannelEntity>>> call() {
    return repository.getChannels();
  }
}
