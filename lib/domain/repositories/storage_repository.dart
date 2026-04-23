import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/storage/storage_stats.dart';

abstract class StorageRepository {
  /// Returns real-time storage stats: DB file size, total note count,
  /// and count of feed notes that can safely be deleted.
  Future<Either<Failure, StorageStats>> getStats(String ownPubkey);

  /// Deletes feed notes (rootEventId == null, not authored by [ownPubkey],
  /// not saved, not followed). Returns number of deleted rows.
  Future<Either<Failure, int>> deleteFeedNotes(String ownPubkey);

  /// Deletes all Shiv conversations and messages.
  Future<Either<Failure, Unit>> deleteAllChatHistory();
}
