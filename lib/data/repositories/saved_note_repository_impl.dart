import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/saved_note_model.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/domain/repositories/saved_note_repository.dart';

@Injectable(as: SavedNoteRepository)
class SavedNoteRepositoryImpl extends SavedNoteRepository {
  final Isar isar;
  SavedNoteRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, SavedNoteEntity>> saveNote(
      String eventId, String contentPreview) async {
    try {
      // Idempotent — return existing if already saved
      final existing = await isar.savedNoteModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      if (existing != null) return Right(existing.toDomain());

      final model = SavedNoteModel()
        ..eventId = eventId
        ..savedAt = DateTime.now()
        ..contentPreview = contentPreview;

      await isar.writeTxn(() async {
        await isar.savedNoteModels.put(model);
      });

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> unsaveNote(String eventId) async {
    try {
      await isar.writeTxn(() async {
        final model = await isar.savedNoteModels
            .where()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (model != null) {
          await isar.savedNoteModels.delete(model.id);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isSaved(String eventId) async {
    try {
      final exists = await isar.savedNoteModels
          .where()
          .eventIdEqualTo(eventId)
          .findFirst();
      return Right(exists != null);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SavedNoteEntity>>> getAll() async {
    try {
      final all = await isar.savedNoteModels
          .where()
          .sortBySavedAtDesc()
          .findAll();
      return Right(all.map((m) => m.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
