import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/channels/detail/cubit/channel_detail_cubit.dart';
import 'package:uniun/channels/detail/widgets/channel_message_composer.dart';
import 'package:uniun/channels/thread/cubit/channel_thread_cubit.dart';
import 'package:uniun/channels/thread/cubit/channel_thread_state.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/channel_message/channel_message_entity.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/followed_notes/cubit/followed_notes_cubit.dart';
import 'package:uniun/vishnu/widgets/note_card.dart';

class ChannelThreadPage extends StatelessWidget {
  const ChannelThreadPage({
    super.key,
    required this.channelId,
    required this.messageId,
    required this.channelName,
    required this.parentCubit,
  });

  final String channelId;
  final String messageId;
  final String channelName;
  final ChannelDetailCubit parentCubit;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ChannelThreadCubit()..load(messageId),
        ),
        BlocProvider(
          create: (_) => getIt<FollowedNotesCubit>()..load(),
        ),
        BlocProvider.value(value: parentCubit),
      ],
      child: _ChannelThreadView(
        channelId: channelId,
        messageId: messageId,
        channelName: channelName,
      ),
    );
  }
}

class _ChannelThreadView extends StatefulWidget {
  const _ChannelThreadView({
    required this.channelId,
    required this.messageId,
    required this.channelName,
  });

  final String channelId;
  final String messageId;
  final String channelName;

  @override
  State<_ChannelThreadView> createState() => _ChannelThreadViewState();
}

class _ChannelThreadViewState extends State<_ChannelThreadView> {
  String? _userAvatarUrl;
  String? _userPubkey;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final r = await getIt<GetActiveUserProfileUseCase>().call();
    if (!mounted) return;
    setState(() {
      _userPubkey = r.fold((_) => null, (p) => p.pubkeyHex);
      _userAvatarUrl = r.fold((_) => null, (p) => p.avatarUrl);
    });
  }

  Future<void> _toggleFollow(
    BuildContext ctx,
    String noteId,
    String contentPreview,
    bool isCurrentlyFollowed,
  ) async {
    final cubit = ctx.read<FollowedNotesCubit>();
    if (isCurrentlyFollowed) {
      await cubit.unfollowNote(noteId);
    } else {
      await cubit.followNote(noteId, contentPreview);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '#${widget.channelName}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: BlocBuilder<ChannelThreadCubit, ChannelThreadState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final root = state.root;
          if (root == null) {
            return const Center(
              child: Text('Message not found.',
                  style: TextStyle(color: AppColors.onSurfaceVariant)),
            );
          }

          return Column(
            children: [
              Expanded(
                child: BlocBuilder<FollowedNotesCubit, FollowedNotesState>(
                  builder: (ctx, followedState) {
                    final followedIds = followedState.notes
                        .map((n) => n.eventId)
                        .toSet();
                    final threadCubit = ctx.read<ChannelThreadCubit>();
                    final parentCubit = ctx.read<ChannelDetailCubit>();

                    Widget card(ChannelMessageEntity msg) {
                      final isSaved = state.savedIds.contains(msg.id);
                      final isFollowed = followedIds.contains(msg.id);
                      return NoteCard(
                        note: msg.toNoteEntity(),
                        profile: state.profiles[msg.authorPubkey],
                        isSaved: isSaved,
                        isFollowed: isFollowed,
                        onTap: () {},
                        onSaveTap: () {
                          if (isSaved) {
                            threadCubit.unsaveMessage(msg.id, parentCubit);
                          } else {
                            threadCubit.saveMessage(msg, parentCubit);
                          }
                        },
                        onFollowTap: () => _toggleFollow(
                          ctx,
                          msg.id,
                          msg.content.length > 80
                              ? msg.content.substring(0, 80)
                              : msg.content,
                          isFollowed,
                        ),
                      );
                    }

                    return ListView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 8,
                      ),
                      children: [
                        card(root),
                        if (state.replies.isNotEmpty)
                          const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF1F5F9)),
                        ...state.replies.map(card),
                      ],
                    );
                  },
                ),
              ),
              ChannelMessageComposer(
                channelId: widget.channelId,
                avatarUrl: _userAvatarUrl,
                pubkeySeed: _userPubkey ?? '',
                replyToEventId: widget.messageId,
              ),
            ],
          );
        },
      ),
    );
  }
}
