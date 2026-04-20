import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/relay/relay_entity.dart';
import 'package:uniun/domain/repositories/relay_repository.dart';

@lazySingleton
class GetRelaysUseCase extends NoParamsUseCase<Either<Failure, List<RelayEntity>>> {
  final RelayRepository repository;

  const GetRelaysUseCase(this.repository);

  @override
  Future<Either<Failure, List<RelayEntity>>> call() {
    return repository.getAll();
  }
}
