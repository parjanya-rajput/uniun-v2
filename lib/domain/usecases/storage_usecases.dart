import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/storage/storage_stats.dart';
import 'package:uniun/domain/repositories/storage_repository.dart';


// ── GetStorageStatsUseCase ────────────────────────────────────────────────────

@lazySingleton
class GetStorageStatsUseCase
    extends UseCase<Either<Failure, StorageStats>, String> {
  final StorageRepository _repository;
  const GetStorageStatsUseCase(this._repository);

  @override
  Future<Either<Failure, StorageStats>> call(
    String ownPubkey, {
    bool cached = false,
  }) {
    return _repository.getStats(ownPubkey);
  }
}

// ── DeleteFeedNotesUseCase ────────────────────────────────────────────────────

@lazySingleton
class DeleteFeedNotesUseCase extends UseCase<Either<Failure, int>, String> {
  final StorageRepository _repository;
  const DeleteFeedNotesUseCase(this._repository);

  @override
  Future<Either<Failure, int>> call(
    String ownPubkey, {
    bool cached = false,
  }) {
    return _repository.deleteFeedNotes(ownPubkey);
  }
}

// ── DeleteAllChatHistoryUseCase ───────────────────────────────────────────────

@lazySingleton
class DeleteAllChatHistoryUseCase
    extends NoParamsUseCase<Either<Failure, Unit>> {
  final StorageRepository _repository;
  const DeleteAllChatHistoryUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call() {
    return _repository.deleteAllChatHistory();
  }
}
