import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'saved_notes_state.dart';

class SavedNotesCubit extends Cubit<SavedNotesState> {
  SavedNotesCubit() : super(const SavedNotesState());

  Future<void> load() async {
    emit(state.copyWith(status: SavedNotesStatus.loading));
    final result = await getIt<GetAllSavedNotesUseCase>().call();
    result.fold(
      (f) => emit(state.copyWith(
        status: SavedNotesStatus.error,
        errorMessage: f.toMessage(),
      )),
      (notes) => emit(state.copyWith(
        status: SavedNotesStatus.loaded,
        notes: notes,
      )),
    );
  }
}
