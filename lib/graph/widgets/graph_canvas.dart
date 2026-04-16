import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';

// ── Multi-color palette ────────────────────────────────────────────────────────
const _palette = [
  Color(0xFF319BED),
  Color(0xFF7C3AED),
  Color(0xFF059669),
  Color(0xFFD97706),
  Color(0xFF0891B2),
  Color(0xFFDB2777),
  Color(0xFF65A30D),
  Color(0xFF9333EA),
];

// ── Dot grid background — matches Shiv tree view ──────────────────────────────
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.4)
      ..strokeCap = StrokeCap.round;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter old) => false;
}

// ── Edge painter ───────────────────────────────────────────────────────────────
class _EdgePainter extends CustomPainter {
  final Graph graph;
  final String? selectedNodeId;

  _EdgePainter({required this.graph, required this.selectedNodeId});

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in graph.edges) {
      final srcId = edge.source.key!.value as String;
      final destId = edge.destination.key!.value as String;

      final srcCenter = Offset(
        edge.source.x + edge.source.width / 2,
        edge.source.y + edge.source.height / 2,
      );
      final destCenter = Offset(
        edge.destination.x + edge.destination.width / 2,
        edge.destination.y + edge.destination.height / 2,
      );

      final isHighlighted =
          selectedNodeId != null &&
          (srcId == selectedNodeId || destId == selectedNodeId);
      final hasSelection = selectedNodeId != null;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlighted ? 2.5 : 1.2
        ..color = isHighlighted
            ? AppColors.primary.withValues(alpha: 0.9)
            : hasSelection
            ? AppColors.outline.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.3);

      canvas.drawLine(srcCenter, destCenter, paint);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) => true;
}

// ── Graph canvas ───────────────────────────────────────────────────────────────

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({
    super.key,
    required this.notes,
    required this.adjacency,
    required this.selectedNoteId,
    required this.onNodeTap,
    required this.onCanvasTap,
  });

  final List<SavedNoteEntity> notes;
  final Map<String, Set<String>> adjacency;
  final String? selectedNoteId;
  final void Function(String eventId) onNodeTap;
  final VoidCallback onCanvasTap;

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  late Graph _graph;
  late FruchtermanReingoldAlgorithm _algorithm;
  final Map<String, Color> _nodeColorMap = {};
  Timer? _timer;
  bool _initialized = false;

  // Graph canvas dimensions — set once from screen size
  double _graphW = 400;
  double _graphH = 800;

  bool _isDragging = false;
  static const _settleSteps = 180; // ~3 s of spring animation at 60 fps

  // Pinned node: stays at the dropped position during re-settle so attraction
  // force cannot pull it back toward its neighbours (Obsidian-style behaviour).
  Node? _pinnedNode;
  Offset? _pinnedPosition;

  @override
  void initState() {
    super.initState();
    _prepareGraph(widget.notes);
  }

  void _prepareGraph(List<SavedNoteEntity> notes) {
    _initialized = false;
    _isDragging = false;
    _timer?.cancel();
    _timer = null;
    _graph = _buildGraph(notes);
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
    _nodeColorMap.clear();
    for (int i = 0; i < notes.length; i++) {
      _nodeColorMap[notes[i].eventId] = _palette[i % _palette.length];
    }
  }

  Graph _buildGraph(List<SavedNoteEntity> notes) {
    final g = Graph()..isTree = false;
    final nodeMap = <String, Node>{};
    final savedIds = {for (final n in notes) n.eventId};

    for (final note in notes) {
      final connections = widget.adjacency[note.eventId]?.length ?? 0;
      final sz = (46.0 + connections * 3.0).clamp(46.0, 70.0);
      final node = Node.Id(note.eventId);
      node.size = Size(sz, sz);
      nodeMap[note.eventId] = node;
      g.addNode(node);
    }

    final added = <String>{};
    for (final note in notes) {
      for (final ref in note.eTagRefs) {
        if (savedIds.contains(ref) && ref != note.eventId) {
          final key = ([note.eventId, ref]..sort()).join('|');
          if (added.add(key)) {
            g.addEdge(nodeMap[note.eventId]!, nodeMap[ref]!);
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
      final eventId = node.key!.value as String;
      final connections = widget.adjacency[eventId]?.length ?? 0;
      final sz = (46.0 + connections * 3.0).clamp(46.0, 70.0);
      node.size = Size(sz, sz);
    }
    _algorithm.init(_graph);
    _initialized = true;
  }

  // Runs spring physics for [_settleSteps] frames then stops.
  // If [pinned] is set, that node is locked at [pinnedAt] every frame so
  // attraction force cannot drag it back toward its neighbours.
  void _runSettle({Node? pinned, Offset? pinnedAt}) {
    _pinnedNode = pinned;
    _pinnedPosition = pinnedAt;
    _timer?.cancel();
    int steps = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      if (_isDragging) return;
      _algorithm.step(_graph);
      // Re-lock the pinned node every frame — overrides whatever the algorithm moved it to.
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
    if (old.notes != widget.notes) {
      _prepareGraph(widget.notes);
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
    if (widget.notes.isEmpty) {
      return Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Save notes to build your knowledge graph.\n\nEdges appear when one saved note references another.',
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
        // ── Fixed dot background ─────────────────────────────────────────
        Positioned.fill(child: CustomPaint(painter: _DotPatternPainter())),

        // ── Graph (unconstrained — full zoom + pan freedom) ──────────────
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
                // No constraints, no boundary — full freedom to zoom + pan
                constrained: false,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 6.0,
                child: Stack(
                  // Clip.none: nodes can be dragged anywhere — never clipped
                  clipBehavior: Clip.none,
                  children: [
                    // Edges — CustomPaint sized to match initial graph area
                    CustomPaint(
                      size: Size(_graphW, _graphH),
                      painter: _EdgePainter(
                        graph: _graph,
                        selectedNodeId: widget.selectedNoteId,
                      ),
                    ),

                    // Nodes — Positioned at live algorithm positions
                    ..._graph.nodes.map((node) {
                      final eventId = node.key!.value as String;
                      final color = _nodeColorMap[eventId] ?? AppColors.primary;
                      final connections =
                          widget.adjacency[eventId]?.length ?? 0;
                      final nodeSize = (46.0 + connections * 3.0).clamp(
                        46.0,
                        70.0,
                      );
                      final isSelected = widget.selectedNoteId == eventId;
                      final isConnected =
                          widget.selectedNoteId != null &&
                          (widget.adjacency[widget.selectedNoteId]?.contains(
                                eventId,
                              ) ??
                              false);
                      final hasSelection = widget.selectedNoteId != null;
                      final opacity =
                          hasSelection && !isSelected && !isConnected
                          ? 0.25
                          : 1.0;

                      return Positioned(
                        left: node.x,
                        top: node.y,
                        child: GestureDetector(
                          onTap: () => widget.onNodeTap(eventId),

                          // Drag: physics pauses on start, resumes on end
                          // No clamping — full freedom, nodes cross each other
                          onPanStart: (_) {
                            _isDragging = true;
                          },
                          onPanUpdate: (details) {
                            // Direct position update — zero physics interference
                            node.position = node.position + details.delta;
                            if (mounted) setState(() {});
                          },
                          onPanEnd: (_) {
                            _isDragging = false;
                            // Re-settle surrounding nodes around the dropped
                            // position. Pin this node so attraction cannot
                            // pull it back toward its neighbours.
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
                                    color: isSelected
                                        ? color
                                        : isConnected
                                        ? color
                                        : color.withValues(alpha: 0.85),
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                            width: 2.5,
                                          )
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withValues(
                                                alpha: 0.55,
                                              ),
                                              blurRadius: 18,
                                              spreadRadius: 4,
                                            ),
                                          ]
                                        : isConnected
                                        ? [
                                            BoxShadow(
                                              color: color.withValues(
                                                alpha: 0.3,
                                              ),
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
                                    _labelFor(eventId),
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

  String _labelFor(String eventId) {
    try {
      final note = widget.notes.firstWhere((n) => n.eventId == eventId);
      final text = note.content.trim().replaceAll('\n', ' ');
      return text.length > 30 ? '${text.substring(0, 30)}…' : text;
    } catch (_) {
      return '…';
    }
  }
}
