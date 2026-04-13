import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/draft/draft_entity.dart';

abstract class DraftRepository {
  Future<Either<Failure, DraftEntity>> saveDraft(DraftEntity draft);
  Future<Either<Failure, List<DraftEntity>>> getDrafts();
  Future<Either<Failure, DraftEntity>> getDraftById(String draftId);
  Future<Either<Failure, Unit>> deleteDraft(String draftId);
}
