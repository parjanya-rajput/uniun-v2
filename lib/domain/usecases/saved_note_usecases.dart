import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/domain/repositories/saved_note_repository.dart';

// ── ToggleSaveInput ───────────────────────────────────────────────────────────

class ToggleSaveInput {
  const ToggleSaveInput({
    required this.eventId,
    required this.contentPreview,
    required this.isSaved,
  });
  final String eventId;
  final String contentPreview;

  /// Pass the current saved state — use case will flip it.
  final bool isSaved;
}

// ── ToggleSaveUseCase ─────────────────────────────────────────────────────────

@lazySingleton
class ToggleSaveUseCase
    extends UseCase<Either<Failure, bool>, ToggleSaveInput> {
  final SavedNoteRepository _repository;
  const ToggleSaveUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(
    ToggleSaveInput input, {
    bool cached = false,
  }) async {
    if (input.isSaved) {
      final result = await _repository.unsaveNote(input.eventId);
      return result.fold(Left.new, (_) => const Right(false));
    } else {
      final result =
          await _repository.saveNote(input.eventId, input.contentPreview);
      return result.fold(Left.new, (_) => const Right(true));
    }
  }
}

// ── IsSavedNoteUseCase ────────────────────────────────────────────────────────

@lazySingleton
class IsSavedNoteUseCase extends UseCase<Either<Failure, bool>, String> {
  final SavedNoteRepository _repository;
  const IsSavedNoteUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(String eventId, {bool cached = false}) {
    return _repository.isSaved(eventId);
  }
}

// ── GetAllSavedNotesUseCase ───────────────────────────────────────────────────

@lazySingleton
class GetAllSavedNotesUseCase
    extends NoParamsUseCase<Either<Failure, List<SavedNoteEntity>>> {
  final SavedNoteRepository _repository;
  const GetAllSavedNotesUseCase(this._repository);

  @override
  Future<Either<Failure, List<SavedNoteEntity>>> call() {
    return _repository.getAll();
  }
}
