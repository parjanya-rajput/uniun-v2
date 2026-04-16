import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart';
import 'package:uniun/thread/bloc/thread_bloc.dart';
import 'package:uniun/thread/widgets/thread_app_bar.dart';
import 'package:uniun/thread/widgets/thread_empty_states.dart';
import 'package:uniun/thread/widgets/thread_parent_context.dart';
import 'package:uniun/thread/widgets/thread_reply_composer.dart';
import 'package:uniun/thread/widgets/thread_reply_item.dart';
import 'package:uniun/thread/widgets/thread_root_note_card.dart';

class ThreadPage extends StatelessWidget {
  const ThreadPage({super.key, required this.noteId, this.savedOnly = false});
  final String noteId;
  final bool savedOnly;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<ThreadBloc>()
            ..add(LoadThreadEvent(noteId, savedOnly: savedOnly)),
        ),
        BlocProvider(
          create: (_) => getIt<FollowedNotesCubit>()..load(),
        ),
      ],
      child: const _ThreadView(),
    );
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class _ThreadView extends StatefulWidget {
  const _ThreadView();

  @override
  State<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<_ThreadView> {
  final _replyController = TextEditingController();
  final _focusNode = FocusNode();
  String? _avatarUrl;
  String _pubkeySeed = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final result = await getIt<GetActiveUserProfileUseCase>().call();
    result.fold((_) {}, (userProfile) {
      if (mounted) {
        setState(() {
          _pubkeySeed = userProfile.pubkeyHex;
          _avatarUrl = userProfile.avatarUrl;
        });
      }
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ThreadBloc, ThreadState>(
      listener: (context, state) {
        if (state.postStatus == ThreadPostStatus.posted) {
          _replyController.clear();
          _focusNode.unfocus();
        }
        if (state.postStatus == ThreadPostStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: const ThreadAppBar(),
            body: switch (state.status) {
              ThreadStatus.loading || ThreadStatus.initial => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                ),
              ThreadStatus.error => ThreadErrorBody(
                  message: state.errorMessage ?? 'Failed to load thread'),
              _ => _ThreadBody(state: state, focusNode: _focusNode),
            },
            bottomNavigationBar: ThreadReplyComposer(
              state: state,
              controller: _replyController,
              focusNode: _focusNode,
              avatarUrl: _avatarUrl,
              pubkeySeed: _pubkeySeed,
            ),
          ),
        );
      },
    );
  }
}

// ── Body — scroll + sliver layout ────────────────────────────────────────────

class _ThreadBody extends StatelessWidget {
  const _ThreadBody({required this.state, required this.focusNode});
  final ThreadState state;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final root = state.rootNote!;

    return CustomScrollView(
      slivers: [
        // ── Parent context (ancestors above the focused note) ─────────────────
        if (state.parentChain.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
            sliver: SliverToBoxAdapter(
              child: ThreadParentContext(
                notes: state.parentChain,
                profiles: state.profiles,
                onNoteTap: (noteId) =>
                    Navigator.pushNamed(context, AppRoutes.thread,
                        arguments: noteId),
              ),
            ),
          ),

        // ── Reference chips (mention e-tags of the root note) ────────────────
        if (state.mentionedNotes.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
            sliver: SliverToBoxAdapter(
              child: _ThreadRefsSection(notes: state.mentionedNotes),
            ),
          ),

        // ── Focused / root note card ───────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.only(
            top: state.parentChain.isEmpty ? 16 : 0,
            left: 20,
            right: 20,
          ),
          sliver: SliverToBoxAdapter(
            child: ThreadRootNoteCard(
              note: root,
              profile: state.profileFor(root.authorPubkey),
            ),
          ),
        ),

        // ── Replies ───────────────────────────────────────────────────────────
        if (state.replies.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: ThreadEmptyReplies(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(
                left: 20, right: 20, top: 12, bottom: 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final reply = state.replies[i];
                  final name = state.profileFor(reply.authorPubkey)?.name ??
                      reply.authorPubkey.substring(0, 8);
                  return ThreadReplyItem(
                    key: ValueKey(reply.id),
                    reply: reply,
                    profile: state.profileFor(reply.authorPubkey),
                    nestedReplies: state.nestedReplies[reply.id] ?? [],
                    nestedProfiles: state.profiles,
                    allNestedReplies: state.nestedReplies,
                    replyCounts: state.replyCounts,
                    replyCount: state.replyCounts[reply.id] ?? 0,
                    showThreadLine: i < state.replies.length - 1,
                    onReplyTap: () {
                      ctx.read<ThreadBloc>().add(
                            SetReplyTargetEvent(
                                replyToId: reply.id, replyToName: name),
                          );
                      focusNode.requestFocus();
                    },
                    // Tapping the content area opens the reply's own thread view
                    onTap: () => Navigator.pushNamed(
                      ctx,
                      AppRoutes.thread,
                      arguments: reply.id,
                    ),
                  );
                },
                childCount: state.replies.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Reference chips shown above the root note in thread detail ────────────────

class _ThreadRefsSection extends StatelessWidget {
  const _ThreadRefsSection({required this.notes});
  final List<NoteEntity> notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.link_rounded, size: 13, color: AppColors.primary),
            SizedBox(width: 5),
            Text(
              'REFERENCES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...notes.map((ref) => _ThreadRefChip(note: ref)),
      ],
    );
  }
}

class _ThreadRefChip extends StatelessWidget {
  const _ThreadRefChip({required this.note});
  final NoteEntity note;

  @override
  Widget build(BuildContext context) {
    final preview = note.content.length > 80
        ? '${note.content.substring(0, 80)}…'
        : note.content;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.thread, arguments: note.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.link_rounded, size: 13, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                preview,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.45,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
