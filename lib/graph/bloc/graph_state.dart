part of 'graph_bloc.dart';

enum GraphStatus { initial, loading, loaded, error }

class GraphState {
  const GraphState({
    this.status = GraphStatus.initial,
    this.notes = const [],
    this.adjacency = const {},
    this.selectedNoteId,
    this.errorMessage,
  });

  final GraphStatus status;

  /// All saved notes — nodes in the graph.
  final List<SavedNoteEntity> notes;

  /// Bidirectional adjacency: noteEventId → set of connected noteEventIds.
  /// An edge exists only when BOTH notes are saved.
  final Map<String, Set<String>> adjacency;

  /// The currently selected node, null = nothing selected.
  final String? selectedNoteId;

  final String? errorMessage;

  GraphState copyWith({
    GraphStatus? status,
    List<SavedNoteEntity>? notes,
    Map<String, Set<String>>? adjacency,
    String? selectedNoteId,
    bool clearSelection = false,
    String? errorMessage,
  }) {
    return GraphState(
      status: status ?? this.status,
      notes: notes ?? this.notes,
      adjacency: adjacency ?? this.adjacency,
      selectedNoteId: clearSelection ? null : (selectedNoteId ?? this.selectedNoteId),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  SavedNoteEntity? get selectedNote {
    if (selectedNoteId == null) return null;
    try {
      return notes.firstWhere((n) => n.eventId == selectedNoteId);
    } catch (_) {
      return null;
    }
  }

  bool isConnectedToSelected(String noteEventId) {
    if (selectedNoteId == null) return false;
    return adjacency[selectedNoteId]?.contains(noteEventId) ?? false;
  }
}
