import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/repositories/saved_note_repository.dart';

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
