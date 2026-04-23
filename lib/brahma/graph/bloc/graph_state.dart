part of 'graph_bloc.dart';

enum GraphStatus { initial, loading, loaded, error }

class GraphState {
  const GraphState({
    this.status = GraphStatus.initial,
    this.nodes = const [],
    this.adjacency = const {},
    this.selectedNodeId,
    this.errorMessage,
  });

  final GraphStatus status;

  /// All graph nodes (saved notes, own notes, drafts).
  final List<GraphNodeData> nodes;

  /// Bidirectional adjacency: nodeId → set of connected nodeIds.
  final Map<String, Set<String>> adjacency;

  /// The currently selected node id, null = nothing selected.
  final String? selectedNodeId;

  final String? errorMessage;

  GraphState copyWith({
    GraphStatus? status,
    List<GraphNodeData>? nodes,
    Map<String, Set<String>>? adjacency,
    String? selectedNodeId,
    bool clearSelection = false,
    String? errorMessage,
  }) {
    return GraphState(
      status: status ?? this.status,
      nodes: nodes ?? this.nodes,
      adjacency: adjacency ?? this.adjacency,
      selectedNodeId:
          clearSelection ? null : (selectedNodeId ?? this.selectedNodeId),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  GraphNodeData? get selectedNode {
    if (selectedNodeId == null) return null;
    try {
      return nodes.firstWhere((n) => n.eventId == selectedNodeId);
    } catch (_) {
      return null;
    }
  }

  bool isConnectedToSelected(String nodeId) {
    if (selectedNodeId == null) return false;
    return adjacency[selectedNodeId]?.contains(nodeId) ?? false;
  }
}
