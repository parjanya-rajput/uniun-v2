import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/graph/pages/graph_page.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Live graph preview shown below the compose card in Brahma.
/// Tap anywhere → opens full [GraphPage].
class GraphPreviewCard extends StatefulWidget {
  const GraphPreviewCard({super.key, this.hashtags = const []});

  final List<String> hashtags;

  @override
  State<GraphPreviewCard> createState() => _GraphPreviewCardState();
}

class _GraphPreviewCardState extends State<GraphPreviewCard> {
  List<SavedNoteEntity> _notes = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<GetAllSavedNotesUseCase>().call();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loaded = true),
      (notes) => setState(() {
        _notes = notes;
        _loaded = true;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ───────────────────────────────────────────────
        Row(
          children: [
            Text(
              l10n.brahmaGraphPreviewLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            const Icon(Icons.hub_rounded, size: 18, color: AppColors.outline),
          ],
        ),
        const SizedBox(height: 12),

        // ── Tappable card ────────────────────────────────────────────────
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GraphPage()),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // ── Live animated mini graph ─────────────────────────
                  Positioned.fill(
                    child: !_loaded
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 1.5,
                            ),
                          )
                        : _notes.isEmpty
                            ? const _EmptyHint()
                            : IgnorePointer(
                                child: _LiveMiniGraph(notes: _notes),
                              ),
                  ),

                  // ── Active hashtag chips ─────────────────────────────
                  if (widget.hashtags.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: widget.hashtags.take(5).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // ── Tap-to-explore chip ──────────────────────────────
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        l10n.brahmaInteractivePreview,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Live mini graph — Stack+Positioned approach for centred nodes ──────────────

class _LiveMiniGraph extends StatefulWidget {
  const _LiveMiniGraph({required this.notes});
  final List<SavedNoteEntity> notes;

  @override
  State<_LiveMiniGraph> createState() => _LiveMiniGraphState();
}

class _LiveMiniGraphState extends State<_LiveMiniGraph> {
  late Graph _graph;
  late FruchtermanReingoldAlgorithm _algorithm;
  Timer? _timer;
  bool _initialized = false;
  bool _timerStarted = false;
  Size _graphSize = const Size(300, 170);

  @override
  void initState() {
    super.initState();
    _graph = _buildGraph(widget.notes);
    _algorithm = FruchtermanReingoldAlgorithm(
      FruchtermanReingoldConfiguration(
        iterations: 100,
        repulsionRate: 0.45,
        repulsionPercentage: 0.45,
        attractionRate: 0.12,
        attractionPercentage: 0.4,
        lerpFactor: 0.1,
        movementThreshold: 0.3,
      ),
    );
  }

  Graph _buildGraph(List<SavedNoteEntity> notes) {
    final g = Graph()..isTree = false;
    final nodeMap = <String, Node>{};
    final savedIds = {for (final n in notes) n.eventId};

    for (final note in notes) {
      final node = Node.Id(note.eventId);
      node.size = const Size(16, 16);
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
    _graphSize = Size(w, h);
    _algorithm.setDimensions(w, h);
    for (final node in _graph.nodes) {
      node.size = const Size(16, 16);
    }
    _algorithm.init(_graph);
    _initialized = true;
  }

  void _startTimer() {
    if (_timerStarted) return;
    _timerStarted = true;
    int steps = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 16), (t) {
      final moved = _algorithm.step(_graph);
      steps++;
      if (steps > 150) {
        t.cancel(); // stop after ~2.5s
        return;
      }
      if (moved && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        final h =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 170.0;

        // Initialize physics once with real card dimensions
        if (!_initialized && w > 0 && h > 0) {
          _initPhysics(w, h);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _startTimer();
          });
        }

        if (!_initialized) return const SizedBox.expand();

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Edges
            CustomPaint(
              size: _graphSize,
              painter: _MiniEdgePainter(graph: _graph),
            ),
            // Nodes — Positioned at live algorithm positions (within card bounds)
            ..._graph.nodes.map((node) {
              final eventId = node.key!.value as String;
              final connections = widget.notes
                  .where((n) => n.eTagRefs.contains(eventId))
                  .length;
              final size = (12.0 + connections * 2.0).clamp(12.0, 20.0);
              return Positioned(
                left: node.x,
                top: node.y,
                child: _MiniNodeDot(size: size),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Mini edge painter ─────────────────────────────────────────────────────────
class _MiniEdgePainter extends CustomPainter {
  final Graph graph;
  _MiniEdgePainter({required this.graph});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.primary.withValues(alpha: 0.35);

    for (final edge in graph.edges) {
      final srcCenter = Offset(
        edge.source.x + edge.source.width / 2,
        edge.source.y + edge.source.height / 2,
      );
      final destCenter = Offset(
        edge.destination.x + edge.destination.width / 2,
        edge.destination.y + edge.destination.height / 2,
      );
      canvas.drawLine(srcCenter, destCenter, paint);
    }
  }

  @override
  bool shouldRepaint(_MiniEdgePainter old) => true;
}

class _MiniNodeDot extends StatelessWidget {
  const _MiniNodeDot({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Solid fill — no transparency
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub_outlined, size: 28, color: AppColors.outlineVariant),
          SizedBox(height: 6),
          Text(
            'Save notes to build\nyour knowledge graph',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
