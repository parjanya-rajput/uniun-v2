import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/brahma/graph/models/graph_node_type.dart';
import 'package:uniun/brahma/graph/painters/dot_pattern_painter.dart';
import 'package:uniun/brahma/graph/painters/edge_painter.dart';
import 'package:uniun/brahma/graph/widgets/graph_header.dart';

// ── Graph canvas ───────────────────────────────────────────────────────────────

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({
    super.key,
    required this.nodes,
    required this.adjacency,
    required this.selectedNodeId,
    required this.onNodeTap,
    required this.onCanvasTap,
  });

  final List<GraphNodeData> nodes;
  final Map<String, Set<String>> adjacency;
  final String? selectedNodeId;
  final void Function(String nodeId) onNodeTap;
  final VoidCallback onCanvasTap;

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  late Graph _graph;
  late FruchtermanReingoldAlgorithm _algorithm;
  Timer? _timer;
  bool _initialized = false;

  double _graphW = 400;
  double _graphH = 800;

  bool _isDragging = false;
  static const _settleSteps = 180;

  Node? _pinnedNode;
  Offset? _pinnedPosition;

  @override
  void initState() {
    super.initState();
    _prepareGraph(widget.nodes);
  }

  void _prepareGraph(List<GraphNodeData> nodes) {
    _initialized = false;
    _isDragging = false;
    _timer?.cancel();
    _timer = null;
    _graph = _buildGraph(nodes);
    _algorithm = FruchtermanReingoldAlgorithm(
      FruchtermanReingoldConfiguration(
        iterations: 100,
        repulsionRate: 0.5,
        repulsionPercentage: 0.5,
        attractionRate: 0.15,
        attractionPercentage: 0.45,
        lerpFactor: 0.05,
        movementThreshold: 0.3,
      ),
    );
  }

  Graph _buildGraph(List<GraphNodeData> nodes) {
    final g = Graph()..isTree = false;
    final nodeMap = <String, Node>{};
    final allIds = {for (final n in nodes) n.eventId};

    for (final n in nodes) {
      final connections = widget.adjacency[n.eventId]?.length ?? 0;
      final sz = (46.0 + connections * 3.0).clamp(46.0, 70.0);
      final node = Node.Id(n.eventId);
      node.size = Size(sz, sz);
      nodeMap[n.eventId] = node;
      g.addNode(node);
    }

    final added = <String>{};
    for (final n in nodes) {
      for (final ref in n.eTagRefs) {
        if (allIds.contains(ref) && ref != n.eventId) {
          final key = ([n.eventId, ref]..sort()).join('|');
          if (added.add(key)) {
            g.addEdge(nodeMap[n.eventId]!, nodeMap[ref]!);
          }
        }
      }
    }
    return g;
  }

  void _initPhysics(double w, double h) {
    _graphW = w;
    _graphH = h;
    _algorithm.setDimensions(w, h);
    for (final node in _graph.nodes) {
      final nodeId = node.key!.value as String;
      final connections = widget.adjacency[nodeId]?.length ?? 0;
      final sz = (46.0 + connections * 3.0).clamp(46.0, 70.0);
      node.size = Size(sz, sz);
    }
    _algorithm.init(_graph);
    _initialized = true;
  }

  void _runSettle({Node? pinned, Offset? pinnedAt}) {
    _pinnedNode = pinned;
    _pinnedPosition = pinnedAt;
    _timer?.cancel();
    int steps = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (_isDragging) return;
      _algorithm.step(_graph);
      if (_pinnedNode != null && _pinnedPosition != null) {
        _pinnedNode!.position = _pinnedPosition!;
      }
      steps++;
      if (steps >= _settleSteps) {
        t.cancel();
        _pinnedNode = null;
        _pinnedPosition = null;
        return;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(GraphCanvas old) {
    super.didUpdateWidget(old);
    if (old.nodes != widget.nodes) {
      _prepareGraph(widget.nodes);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return const Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: DotPatternPainter())),
          Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Save notes to build your knowledge graph.\n\nEdges appear when one note references another.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: DotPatternPainter())),

        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onCanvasTap,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : 400.0;
              final h = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : 800.0;

              if (!_initialized) {
                _initPhysics(w, h);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _runSettle();
                });
              }

              return InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 6.0,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: Size(_graphW, _graphH),
                      painter: EdgePainter(
                        graph: _graph,
                        selectedNodeId: widget.selectedNodeId,
                      ),
                    ),

                    ..._graph.nodes.map((node) {
                      final nodeId = node.key!.value as String;
                      final nodeData = widget.nodes
                          .where((n) => n.eventId == nodeId)
                          .firstOrNull;
                      final color = nodeData != null
                          ? graphNodeTypeColors[nodeData.type]!
                          : AppColors.primary;
                      final connections =
                          widget.adjacency[nodeId]?.length ?? 0;
                      final nodeSize =
                          (46.0 + connections * 3.0).clamp(46.0, 70.0);
                      final isSelected = widget.selectedNodeId == nodeId;
                      final isConnected =
                          widget.selectedNodeId != null &&
                          (widget.adjacency[widget.selectedNodeId]
                                  ?.contains(nodeId) ??
                              false);
                      final hasSelection = widget.selectedNodeId != null;
                      final opacity =
                          hasSelection && !isSelected && !isConnected
                          ? 0.25
                          : 1.0;

                      return Positioned(
                        left: node.x,
                        top: node.y,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onNodeTap(nodeId),
                          onPanStart: (_) => _isDragging = true,
                          onPanUpdate: (details) {
                            node.position = node.position + details.delta;
                            if (mounted) setState(() {});
                          },
                          onPanEnd: (_) {
                            _isDragging = false;
                            _runSettle(
                              pinned: node,
                              pinnedAt: Offset(node.x, node.y),
                            );
                          },
                          onPanCancel: () {
                            _isDragging = false;
                            _runSettle(
                              pinned: node,
                              pinnedAt: Offset(node.x, node.y),
                            );
                          },
                          child: Opacity(
                            opacity: opacity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: nodeSize,
                                  height: nodeSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected || isConnected
                                        ? color
                                        : color.withValues(alpha: 0.85),
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                            width: 2.5,
                                          )
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  color.withValues(alpha: 0.55),
                                              blurRadius: 18,
                                              spreadRadius: 4,
                                            ),
                                          ]
                                        : isConnected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  color.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: 88,
                                  child: Text(
                                    _labelFor(nodeId),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isSelected
                                          ? color
                                          : AppColors.onSurfaceVariant,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      height: 1.3,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _labelFor(String nodeId) {
    try {
      final node = widget.nodes.firstWhere((n) => n.eventId == nodeId);
      final text = node.content.trim().replaceAll('\n', ' ');
      return text.length > 30 ? '${text.substring(0, 30)}…' : text;
    } catch (_) {
      return '…';
    }
  }
}
