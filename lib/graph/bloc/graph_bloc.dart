import 'package:bloc/bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';

part 'graph_event.dart';
part 'graph_state.dart';

class GraphBloc extends Bloc<GraphEvent, GraphState> {
  GraphBloc() : super(const GraphState()) {
    on<LoadGraphEvent>(_onLoad);
    on<SelectGraphNodeEvent>(_onSelect);
    on<DeselectGraphNodeEvent>(_onDeselect);
  }

  Future<void> _onLoad(LoadGraphEvent event, Emitter<GraphState> emit) async {
    emit(state.copyWith(status: GraphStatus.loading));
    final result = await getIt<GetAllSavedNotesUseCase>().call();
    result.fold(
      (f) => emit(state.copyWith(
        status: GraphStatus.error,
        errorMessage: f.toMessage(),
      )),
      (notes) => emit(state.copyWith(
        status: GraphStatus.loaded,
        notes: notes,
        adjacency: _buildAdjacency(notes),
      )),
    );
  }

  void _onSelect(SelectGraphNodeEvent event, Emitter<GraphState> emit) {
    // Toggle: tapping the already-selected node deselects it
    if (state.selectedNoteId == event.noteEventId) {
      emit(state.copyWith(clearSelection: true));
    } else {
      emit(state.copyWith(selectedNoteId: event.noteEventId));
    }
  }

  void _onDeselect(DeselectGraphNodeEvent event, Emitter<GraphState> emit) {
    emit(state.copyWith(clearSelection: true));
  }

  /// Builds a bidirectional adjacency map from saved-note eTagRefs.
  /// An edge A↔B is created only when BOTH A and B are saved.
  static Map<String, Set<String>> _buildAdjacency(List<SavedNoteEntity> notes) {
    final savedIds = {for (final n in notes) n.eventId};
    final adj = <String, Set<String>>{
      for (final n in notes) n.eventId: <String>{},
    };
    for (final note in notes) {
      for (final ref in note.eTagRefs) {
        if (ref != note.eventId && savedIds.contains(ref)) {
          adj[note.eventId]!.add(ref);
          adj[ref]!.add(note.eventId); // bidirectional
        }
      }
    }
    return adj;
  }
}
