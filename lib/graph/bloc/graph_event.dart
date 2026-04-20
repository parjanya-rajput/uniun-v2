part of 'graph_bloc.dart';

sealed class GraphEvent {
  const GraphEvent();
}

final class LoadGraphEvent extends GraphEvent {
  const LoadGraphEvent();
}

/// Tap a node — if already selected, deselects it.
final class SelectGraphNodeEvent extends GraphEvent {
  const SelectGraphNodeEvent(this.noteEventId);
  final String noteEventId;
}

final class DeselectGraphNodeEvent extends GraphEvent {
  const DeselectGraphNodeEvent();
}
