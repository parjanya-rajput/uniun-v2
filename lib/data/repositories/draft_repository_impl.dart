import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/draft_model.dart';
import 'package:uniun/domain/entities/draft/draft_entity.dart';
import 'package:uniun/domain/repositories/draft_repository.dart';

@Injectable(as: DraftRepository)
class DraftRepositoryImpl extends DraftRepository {
  final Isar isar;

  DraftRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, DraftEntity>> saveDraft(DraftEntity draft) async {
    try {
      final existing = await isar.draftModels.filter().draftIdEqualTo(draft.draftId).findFirst();

      final model = DraftModel()
        ..draftId = draft.draftId
        ..content = draft.content
        ..rootEventId = draft.rootEventId
        ..replyToEventId = draft.replyToEventId
        ..eTagRefs = draft.eTagRefs
        ..pTagRefs = draft.pTagRefs
        ..tTags = draft.tTags
        ..createdAt = draft.createdAt
        ..updatedAt = draft.updatedAt;

      await isar.writeTxn(() async {
        if (existing != null) {
          model.id = existing.id;
        }
        await isar.draftModels.put(model);
      });

      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DraftEntity>>> getDrafts() async {
    try {
      final drafts = await isar.draftModels.where().sortByUpdatedAtDesc().findAll();
      return Right(drafts.map((d) => d.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DraftEntity>> getDraftById(String draftId) async {
    try {
      final draft = await isar.draftModels.filter().draftIdEqualTo(draftId).findFirst();
      if (draft == null) {
        return const Left(Failure.notFoundFailure('Draft not found'));
      }
      return Right(draft.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteDraft(String draftId) async {
    try {
      await isar.writeTxn(() async {
        await isar.draftModels.filter().draftIdEqualTo(draftId).deleteAll();
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
