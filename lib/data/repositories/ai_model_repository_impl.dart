import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:system_info_plus/system_info_plus.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/ai_model_selection_model.dart';
import 'package:uniun/data/models/app_settings_model.dart';
import 'package:uniun/domain/entities/ai_model/ai_model_entity.dart';
import 'package:uniun/domain/repositories/ai_model_repository.dart';
import 'package:path/path.dart' as p;

@Injectable(as: AIModelRepository)
class AIModelRepositoryImpl implements AIModelRepository {
  final Isar _isar;

  AIModelRepositoryImpl(this._isar);

  // ── Model catalog ────────────────────────────────────────────────────────────
  // All URLs are real HuggingFace releases compatible with flutter_gemma 0.13.x
  // on Android and iOS (no auth token required).
  //
  // Mobile file format rules:
  //  .task      → MediaPipe LiteRT engine (Android + iOS)
  //  .litertlm  → LiteRT-LM engine       (Android + iOS + Desktop)
  //
  // Gemma 4 E2B/E4B use .litertlm (LiteRT-LM). All others use .task.

  // Base catalog — isRecommended is set dynamically in getAvailableModels()
  // based on device RAM so users always see the right suggestion.
  static const List<AIModelEntity> _catalog = [
    AIModelEntity(
      modelId: AIModelId.qwen25_05b,
      sizeLabel: '586 MB',
      sizeBytes: 614572032,
      tier: AIModelTier.lite,
      isRecommended: false,
      optimization: AIModelOptimization.cpu,
      downloadUrl:
          'https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task',
    ),
    AIModelEntity(
      modelId: AIModelId.deepseekR1,
      sizeLabel: '1.7 GB',
      sizeBytes: 1825964032,
      tier: AIModelTier.balanced,
      isRecommended: false,
      optimization: AIModelOptimization.cpu,
      downloadUrl:
          'https://huggingface.co/litert-community/DeepSeek-R1-Distill-Qwen-1.5B/resolve/main/deepseek_q8_ekv1280.task',
    ),
    AIModelEntity(
      modelId: AIModelId.gemma4E2b,
      sizeLabel: '2.4 GB',
      sizeBytes: 2576980377,
      tier: AIModelTier.performance,
      isRecommended: false,
      optimization: AIModelOptimization.gpuCpu,
      downloadUrl:
          'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    ),
    AIModelEntity(
      modelId: AIModelId.gemma4E4b,
      sizeLabel: '4.3 GB',
      sizeBytes: 4617089638,
      tier: AIModelTier.flagship,
      isRecommended: false,
      optimization: AIModelOptimization.gpu,
      downloadUrl:
          'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm',
    ),
  ];

  /// flutter_gemma engine params — separate from the public entity fields.
  static const Map<AIModelId, ({ModelType modelType, ModelFileType fileType})>
      _gemmaParams = {
    AIModelId.qwen25_05b: (
      modelType: ModelType.qwen,
      fileType: ModelFileType.task
    ),
    AIModelId.deepseekR1: (
      modelType: ModelType.deepSeek,
      fileType: ModelFileType.task
    ),
    AIModelId.gemma4E2b: (
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm
    ),
    AIModelId.gemma4E4b: (
      modelType: ModelType.gemmaIt,
      fileType: ModelFileType.litertlm
    ),
  };

  @override
  Future<List<AIModelEntity>> getAvailableModels() async {
    final recommended = await _recommendedModelId();
    return _catalog
        .map((m) => m.copyWith(isRecommended: m.modelId == recommended))
        .toList();
  }

  /// Reads total physical RAM and returns the best-fit model ID.
  /// Thresholds (conservative — model size + OS overhead):
  ///   < 3 GB  → Qwen3 0.6B
  ///   3–5 GB  → DeepSeek R1
  ///   5–7 GB  → Gemma 4 E2B
  ///   ≥ 7 GB  → Gemma 4 E4B
  static Future<AIModelId> _recommendedModelId() async {
    try {
      // physicalMemory returns MB, or null on unsupported platforms.
      final totalMb = await SystemInfoPlus.physicalMemory;
      if (totalMb == null || totalMb <= 0) return AIModelId.deepseekR1;
      if (totalMb < 3000) return AIModelId.qwen25_05b;
      if (totalMb < 5000) return AIModelId.deepseekR1;
      if (totalMb < 7000) return AIModelId.gemma4E2b;
      return AIModelId.gemma4E4b;
    } catch (_) {
      return AIModelId.deepseekR1;
    }
  }

  // ── Active model ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AIModelEntity?>> getActiveModel() async {
    try {
      final settings = await _isar.appSettingsModels.get(1);
      final activeId = settings?.activeModelId;
      if (activeId == null) return const Right(null);

      final entry = _catalog.where((m) => m.modelId == activeId).firstOrNull;
      if (entry == null) return const Right(null);

      final params = _gemmaParams[activeId]!;
      final filename = p.basename(Uri.parse(entry.downloadUrl).path);
      final isInstalled = await FlutterGemma.isModelInstalled(filename);

      if (!isInstalled) {
        // Files cleared (app reinstall / storage wipe) — reset active model.
        await clearActiveModel();
        return const Right(null);
      }

      // Restore flutter_gemma's in-memory active model state.
      if (!FlutterGemma.hasActiveModel()) {
        await FlutterGemma.installModel(
          modelType: params.modelType,
          fileType: params.fileType,
        ).fromNetwork(entry.downloadUrl).install();
      }

      return Right(entry.copyWith(isDownloaded: true));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearActiveModel() async {
    try {
      await _isar.writeTxn(() async {
        final settings =
            await _isar.appSettingsModels.get(1) ?? AppSettingsModel();
        settings.activeModelId = null;
        await _isar.appSettingsModels.put(settings);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  // ── Download ─────────────────────────────────────────────────────────────────

  @override
  Stream<AIModelDownloadEvent> downloadAndActivateModel(
      AIModelId modelId) async* {
    final entry = _catalog.where((m) => m.modelId == modelId).firstOrNull;
    if (entry == null) {
      yield AIModelDownloadEvent.failed('Unknown model: ${modelId.name}');
      return;
    }

    final params = _gemmaParams[modelId]!;
    final progressController = StreamController<int>();

    FlutterGemma.installModel(
      modelType: params.modelType,
      fileType: params.fileType,
    )
        .fromNetwork(entry.downloadUrl)
        .withProgress((percent) {
          if (!progressController.isClosed) progressController.add(percent);
        })
        .install()
        .then((_) {
          if (!progressController.isClosed) progressController.close();
        })
        .catchError((Object e) {
          if (!progressController.isClosed) {
            progressController.addError(e);
            progressController.close();
          }
        });

    try {
      await for (final percent in progressController.stream) {
        yield AIModelDownloadEvent.progress(percent / 100.0);
      }
    } catch (e) {
      yield AIModelDownloadEvent.failed(e.toString());
      return;
    }

    // install() completed — persist selection to Isar.
    try {
      await _isar.writeTxn(() async {
        // Record that this model is downloaded.
        final prev = await _isar.aIModelSelectionModels
            .filter()
            .modelIdEqualTo(modelId)
            .findFirst();
        final model = prev ?? AIModelSelectionModel();
        model.modelId = modelId;
        model.modelName = modelId.name;
        model.modelPath = modelId.name;
        model.downloadedAt = DateTime.now();
        await _isar.aIModelSelectionModels.put(model);

        // Set as active model in settings singleton.
        final settings =
            await _isar.appSettingsModels.get(1) ?? AppSettingsModel();
        settings.activeModelId = modelId;
        await _isar.appSettingsModels.put(settings);
      });

      yield AIModelDownloadEvent.complete(modelId);
    } catch (e) {
      yield AIModelDownloadEvent.failed(e.toString());
    }
  }
}
