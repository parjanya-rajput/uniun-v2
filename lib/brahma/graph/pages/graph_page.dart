import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/brahma/bloc/brahma_create_bloc.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/brahma/graph/bloc/graph_bloc.dart';
import 'package:uniun/brahma/graph/widgets/graph_canvas.dart';
import 'package:uniun/brahma/graph/widgets/graph_fab.dart';
import 'package:uniun/brahma/graph/widgets/graph_header.dart';
import 'package:uniun/brahma/graph/widgets/graph_node_panel.dart';

class GraphPage extends StatelessWidget {
  const GraphPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BrahmaCreateBloc, BrahmaCreateState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == BrahmaCreateStatus.success) {
          Navigator.popUntil(context, ModalRoute.withName(AppRoutes.home));
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<GraphBloc, GraphState>(
        builder: (context, state) {
          // ── Loading ──────────────────────────────────────────────────────
          if (state.status == GraphStatus.initial ||
              state.status == GraphStatus.loading) {
            return const Column(
              children: [
                GraphHeader(),
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
              ],
            );
          }

          // ── Error ────────────────────────────────────────────────────────
          if (state.status == GraphStatus.error) {
            return Column(
              children: [
                const GraphHeader(),
                Expanded(
                  child: Center(
                    child: Text(
                      state.errorMessage ?? 'Failed to load graph',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            );
          }

          // ── Loaded ───────────────────────────────────────────────────────
          return Stack(
            children: [
              // Canvas fills the whole screen
              Positioned.fill(
                child: GraphCanvas(
                  nodes: state.nodes,
                  adjacency: state.adjacency,
                  selectedNodeId: state.selectedNodeId,
                  onNodeTap: (id) =>
                      context.read<GraphBloc>().add(SelectGraphNodeEvent(id)),
                  onCanvasTap: () =>
                      context.read<GraphBloc>().add(const DeselectGraphNodeEvent()),
                ),
              ),

              // Header overlays the top
              const Positioned(
                top: 0, left: 0, right: 0,
                child: GraphHeader(),
              ),

              // Node detail panel slides up from the bottom
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: _NodePanelSlider(state: state),
              ),

              // FAB — hidden while a panel is open
              if (state.selectedNode == null)
                const Positioned(
                  right: 20, bottom: 24,
                  child: GraphFab(),
                ),
            ],
          );
        },
      ),
      ),
    );
  }
}

// ── Animated panel wrapper ─────────────────────────────────────────────────────
class _NodePanelSlider extends StatelessWidget {
  const _NodePanelSlider({required this.state});
  final GraphState state;

  @override
  Widget build(BuildContext context) {
    final node = state.selectedNode;
    return AnimatedSlide(
      offset: node != null ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: node != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: node != null
            ? GraphNodePanel(
                node: node,
                onClose: () => context
                    .read<GraphBloc>()
                    .add(const DeselectGraphNodeEvent()),
                onEditTap: (draftId) async {
                  final bloc = context.read<GraphBloc>();
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.brahmaCreate,
                    arguments: {'draftId': draftId, 'autoPublish': false},
                  );
                  bloc.add(const LoadGraphEvent());
                  bloc.add(SelectGraphNodeEvent(draftId));
                },
                onPublishTap: (draftId) {
                  // Publish directly — no navigation needed.
                  // BlocListener<BrahmaCreateBloc> in GraphPage handles
                  // popping to home on success.
                  context.read<BrahmaCreateBloc>().add(
                        PublishDraftEvent(
                          draftId: draftId,
                          content: node.content,
                        ),
                      );
                },
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
