import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/brahma/bloc/brahma_create_bloc.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';

/// Bottom sheet for searching and selecting notes to mention.
/// Shows a search field + results list. Selected notes are added
/// as e-tags with "mention" marker when the note is published.
class MentionSearchSheet extends StatefulWidget {
  const MentionSearchSheet({super.key});

  @override
  State<MentionSearchSheet> createState() => _MentionSearchSheetState();
}

class _MentionSearchSheetState extends State<MentionSearchSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query, BuildContext ctx) {
    if (query.trim().isEmpty) {
      ctx.read<BrahmaCreateBloc>().add(const ClearMentionSearchEvent());
    } else {
      ctx.read<BrahmaCreateBloc>().add(SearchMentionsEvent(query.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<BrahmaCreateBloc, BrahmaCreateState>(
      builder: (ctx, state) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded,
                        size: 18,
                        color: AppColors.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text(
                      l10n.brahmaMentionSheetTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (q) => _onQueryChanged(q, ctx),
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: l10n.brahmaMentionSearchHint,
                    hintStyle: const TextStyle(
                        color: AppColors.onSurfaceVariant, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: AppColors.onSurfaceVariant),
                    suffixIcon: state.isMentionSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Results
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: _searchController.text.trim().isEmpty
                    ? _SelectedList(selected: state.selectedMentions)
                    : state.mentionResults.isEmpty && !state.isMentionSearching
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.brahmaMentionEmpty,
                              style: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: state.mentionResults.length,
                            itemBuilder: (_, i) {
                              final note = state.mentionResults[i];
                              final isSelected = state.selectedMentions
                                  .any((m) => m.id == note.id);
                              return _NoteResultTile(
                                note: note,
                                isSelected: isSelected,
                                selectedLabel: l10n.brahmaMentionSelected,
                                onTap: () {
                                  if (isSelected) {
                                    ctx.read<BrahmaCreateBloc>().add(
                                        RemoveMentionEvent(note.id));
                                  } else {
                                    ctx.read<BrahmaCreateBloc>().add(
                                        AddMentionEvent(note));
                                  }
                                },
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ── Already-selected list (shown when search field is empty) ─────────────────

class _SelectedList extends StatelessWidget {
  const _SelectedList({required this.selected});
  final List<NoteEntity> selected;

  @override
  Widget build(BuildContext context) {
    if (selected.isEmpty) return const SizedBox(height: 8);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: selected.length,
      itemBuilder: (ctx, i) {
        final note = selected[i];
        return _NoteResultTile(
          note: note,
          isSelected: true,
          selectedLabel: AppLocalizations.of(context)!.brahmaMentionSelected,
          onTap: () =>
              ctx.read<BrahmaCreateBloc>().add(RemoveMentionEvent(note.id)),
        );
      },
    );
  }
}

// ── Single result tile ───────────────────────────────────────────────────────

class _NoteResultTile extends StatelessWidget {
  const _NoteResultTile({
    required this.note,
    required this.isSelected,
    required this.selectedLabel,
    required this.onTap,
  });

  final NoteEntity note;
  final bool isSelected;
  final String selectedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = note.content.trim();
    final displayText = preview.length > 120
        ? '${preview.substring(0, 120)}…'
        : preview.isEmpty
            ? '…'
            : preview;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.article_outlined,
                size: 16,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 2),
                    Text(
                      selectedLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary.withValues(alpha: 0.8),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
