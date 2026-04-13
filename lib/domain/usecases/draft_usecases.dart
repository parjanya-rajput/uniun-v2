import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/draft/draft_entity.dart';
import 'package:uniun/domain/repositories/draft_repository.dart';
import 'package:uniun/domain/repositories/note_repository.dart';

/// Save a draft (create or update).
@lazySingleton
class SaveDraftUseCase extends UseCase<Either<Failure, DraftEntity>, DraftEntity> {
  final DraftRepository repository;

  SaveDraftUseCase(this.repository);

  @override
  Future<Either<Failure, DraftEntity>> call(DraftEntity input, {bool cached = false}) {
    return repository.saveDraft(input);
  }
}

/// Get all drafts, ordered by most recent first.
@lazySingleton
class GetDraftsUseCase extends NoParamsUseCase<Either<Failure, List<DraftEntity>>> {
  final DraftRepository repository;

  GetDraftsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DraftEntity>>> call() {
    return repository.getDrafts();
  }
}

/// Get a single draft by ID.
@lazySingleton
class GetDraftByIdUseCase extends UseCase<Either<Failure, DraftEntity>, String> {
  final DraftRepository repository;

  GetDraftByIdUseCase(this.repository);

  @override
  Future<Either<Failure, DraftEntity>> call(String draftId, {bool cached = false}) {
    return repository.getDraftById(draftId);
  }
}

/// Delete a draft.
@lazySingleton
class DeleteDraftUseCase extends UseCase<Either<Failure, Unit>, String> {
  final DraftRepository repository;

  DeleteDraftUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String draftId, {bool cached = false}) {
    return repository.deleteDraft(draftId);
  }
}

/// Publish a draft as a note (convert draft to note and publish).
@lazySingleton
class PublishDraftUseCase extends UseCase<Either<Failure, Unit>, DraftEntity> {
  final NoteRepository noteRepository;
  final DraftRepository draftRepository;

  PublishDraftUseCase(this.noteRepository, this.draftRepository);

  @override
  Future<Either<Failure, Unit>> call(DraftEntity input, {bool cached = false}) async {
    // Note: The draft is converted to a note in the BLoC, not here.
    // This use case primarily handles the cleanup after publishing.
    // Delete the draft after successful publish is handled by the BLoC.
    return const Right(unit);
  }
}
