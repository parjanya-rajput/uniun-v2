import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/saved_note/saved_note_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/saved_notes/cubit/saved_notes_cubit.dart';
import 'package:uniun/saved_notes/cubit/saved_notes_state.dart';
import 'package:uniun/thread/pages/thread_page.dart';

class SavedNotesPage extends StatelessWidget {
  const SavedNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SavedNotesCubit()..load(),
      child: const _SavedNotesView(),
    );
  }
}

// ── View ───────────────────────────────────────────────────────────────────────

class _SavedNotesView extends StatefulWidget {
  const _SavedNotesView();

  @override
  State<_SavedNotesView> createState() => _SavedNotesViewState();
}

class _SavedNotesViewState extends State<_SavedNotesView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SavedNoteEntity> _filter(List<SavedNoteEntity> notes) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return notes;
    return notes.where((n) {
      return n.content.toLowerCase().contains(q) ||
          n.tTags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          l10n.savedNotesTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        elevation: 0,
      ),
      body: BlocBuilder<SavedNotesCubit, SavedNotesState>(
        builder: (context, state) {
          if (state.status == SavedNotesStatus.initial ||
              state.status == SavedNotesStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            );
          }
          if (state.status == SavedNotesStatus.error) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Failed to load saved notes',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          final filtered = _filter(state.notes);

          return Column(
            children: [
              // ── Search bar ──────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.savedNotesSearch,
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.onSurfaceVariant,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.onSurfaceVariant,
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // ── List ────────────────────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => context.read<SavedNotesCubit>().load(),
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: state.notes.isEmpty
                                  ? const _EmptyState()
                                  : const _NoResultsState(),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final cubit = context.read<SavedNotesCubit>();
                            return _SavedNoteCard(
                              note: filtered[i],
                              onTap: () => Navigator.push(
                                ctx,
                                MaterialPageRoute(
                                  builder: (_) => ThreadPage(
                                    noteId: filtered[i].eventId,
                                    savedOnly: true,
                                  ),
                                ),
                              ).then((_) => cubit.load()),
                            );
                          },
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

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_border_rounded,
              size: 56,
              color: AppColors.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.savedNotesEmpty,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.savedNotesEmptySub,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No notes match your search.',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Saved note card ────────────────────────────────────────────────────────────

class _SavedNoteCard extends StatelessWidget {
  const _SavedNoteCard({required this.note, required this.onTap});

  final SavedNoteEntity note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shortKey = note.authorPubkey.length >= 8
        ? note.authorPubkey.substring(0, 8)
        : note.authorPubkey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author + saved time
            Row(
              children: [
                Text(
                  shortKey,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.bookmark_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(note.savedAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Full content — no truncation
            Text(
              note.content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurface,
                height: 1.5,
              ),
            ),
            if (note.tTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: note.tTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
