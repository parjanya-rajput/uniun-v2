import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/graph/bloc/graph_bloc.dart';
import 'package:uniun/graph/widgets/graph_canvas.dart';
import 'package:uniun/graph/widgets/graph_node_panel.dart';

class GraphPage extends StatelessWidget {
  const GraphPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GraphBloc()..add(const LoadGraphEvent()),
      child: const _GraphView(),
    );
  }
}

class _GraphView extends StatelessWidget {
  const _GraphView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Knowledge Graph',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: BlocBuilder<GraphBloc, GraphState>(
        builder: (context, state) {
          if (state.status == GraphStatus.initial ||
              state.status == GraphStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            );
          }
          if (state.status == GraphStatus.error) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Failed to load graph',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          return Stack(
            children: [
              // ── Full-area graph canvas ───────────────────────────────
              Positioned.fill(
                child: GraphCanvas(
                  notes: state.notes,
                  adjacency: state.adjacency,
                  selectedNoteId: state.selectedNoteId,
                  onNodeTap: (id) =>
                      context.read<GraphBloc>().add(SelectGraphNodeEvent(id)),
                  onCanvasTap: () => context
                      .read<GraphBloc>()
                      .add(const DeselectGraphNodeEvent()),
                ),
              ),

              // ── Note detail panel (slides up on node tap) ────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedSlide(
                  offset: state.selectedNote != null
                      ? Offset.zero
                      : const Offset(0, 1),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: state.selectedNote != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: state.selectedNote != null
                        ? GraphNodePanel(
                            note: state.selectedNote!,
                            onClose: () => context
                                .read<GraphBloc>()
                                .add(const DeselectGraphNodeEvent()),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
