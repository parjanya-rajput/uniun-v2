import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/channel/channel_entity.dart';
import 'package:uniun/domain/repositories/channel_repository.dart';

@lazySingleton
class GetChannelByIdUseCase
    extends UseCase<Either<Failure, ChannelEntity>, String> {
  final ChannelRepository repository;
  const GetChannelByIdUseCase(this.repository);

  @override
  Future<Either<Failure, ChannelEntity>> call(
    String input, {
    bool cached = false,
  }) {
    return repository.getChannelById(input);
  }
}
