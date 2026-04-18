import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';

abstract class AIModelRepository {
  /// Returns the catalog of models, with [isRecommended] set based on device RAM.
  Future<List<AIModelEntity>> getAvailableModels();

  /// Returns the model the user has downloaded and activated, or null if none.
  Future<Either<Failure, AIModelEntity?>> getActiveModel();

  /// Downloads the model identified by [modelId] and marks it as active.
  /// Emits [AIModelDownloadEvent]s until complete or failed.
  Stream<AIModelDownloadEvent> downloadAndActivateModel(AIModelId modelId);

  /// Removes the active model selection (does not delete the file).
  Future<Either<Failure, Unit>> clearActiveModel();

  /// Returns IDs of all models whose files are present on disk.
  Future<Set<AIModelId>> getDownloadedModelIds();

  /// Returns total bytes used by all downloaded model files (from catalog sizeBytes).
  Future<int> getDownloadedModelsSizeBytes();

  /// Deletes the model file from disk and removes it from Isar.
  /// If it was the active model, clears the active selection too.
  Future<Either<Failure, Unit>> deleteModel(AIModelId modelId);

}
