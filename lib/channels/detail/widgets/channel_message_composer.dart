import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/channels/detail/cubit/channel_detail_cubit.dart';
import 'package:uniun/channels/detail/cubit/channel_detail_state.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/entities/channel_message/channel_message_entity.dart';
import 'package:uniun/l10n/app_localizations.dart';

class ChannelMessageComposer extends StatefulWidget {
  const ChannelMessageComposer({
    super.key,
    required this.channelId,
    this.avatarUrl,
    this.pubkeySeed = '',
    this.replyToEventId,
  });

  final String channelId;
  final String? avatarUrl;
  final String pubkeySeed;

  /// When set, sends a reply to this event instead of a top-level message.
  final String? replyToEventId;

  @override
  State<ChannelMessageComposer> createState() =>
      _ChannelMessageComposerState();
}

class _ChannelMessageComposerState extends State<ChannelMessageComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  final List<ChannelMessageEntity> _mentionRefs = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final refs = _mentionRefs.map((m) => m.id).toList();
    setState(() => _mentionRefs.clear());
    context.read<ChannelDetailCubit>().sendMessage(
          widget.channelId,
          text,
          replyToEventId: widget.replyToEventId,
          mentionRefs: refs,
        );
  }

  void _openLinkPicker(
      BuildContext context, List<ChannelMessageEntity> messages) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChannelReferencePicker(
        messages: messages,
        selected: _mentionRefs,
        onToggle: (msg) {
          setState(() {
            if (_mentionRefs.any((m) => m.id == msg.id)) {
              _mentionRefs.removeWhere((m) => m.id == msg.id);
            } else {
              _mentionRefs.add(msg);
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final state = context.watch<ChannelDetailCubit>().state;
    final isSending = state.isSending;
    final messages = state.messages;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mention ref chips
        if (_mentionRefs.isNotEmpty)
          Container(
            color: AppColors.surfaceContainerLow,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _mentionRefs
                  .map(
                    (msg) => Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(
                        msg.content.length > 30
                            ? '${msg.content.substring(0, 30)}…'
                            : msg.content,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.onSurface),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () =>
                          setState(() => _mentionRefs.removeWhere(
                                (m) => m.id == msg.id,
                              )),
                      backgroundColor: AppColors.surfaceContainerHigh,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ),

        Container(
          color: Colors.white.withValues(alpha: 0.90),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              UserAvatar(
                seed: widget.pubkeySeed,
                photoUrl: widget.avatarUrl,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style:
                      const TextStyle(fontSize: 14, color: AppColors.onSurface),
                  decoration: InputDecoration(
                    hintText: widget.replyToEventId != null
                        ? 'Reply to message…'
                        : l10n.channelMessageHint,
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Link / reference button
              GestureDetector(
                onTap: messages.isEmpty
                    ? null
                    : () => _openLinkPicker(context, messages),
                child: Icon(
                  Icons.link_rounded,
                  size: 22,
                  color: _mentionRefs.isNotEmpty
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedOpacity(
                opacity: (_hasText && !isSending) ? 1.0 : 0.35,
                duration: const Duration(milliseconds: 150),
                child: GestureDetector(
                  onTap:
                      (_hasText && !isSending) ? () => _send(context) : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: isSending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reference picker bottom sheet ─────────────────────────────────────────────

class _ChannelReferencePicker extends StatefulWidget {
  const _ChannelReferencePicker({
    required this.messages,
    required this.selected,
    required this.onToggle,
  });

  final List<ChannelMessageEntity> messages;
  final List<ChannelMessageEntity> selected;
  final void Function(ChannelMessageEntity) onToggle;

  @override
  State<_ChannelReferencePicker> createState() =>
      _ChannelReferencePickerState();
}

class _ChannelReferencePickerState extends State<_ChannelReferencePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.messages
        : widget.messages
            .where((m) =>
                m.content.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.link_rounded,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Reference a message',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: AppColors.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style:
                  const TextStyle(fontSize: 14, color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'Search messages…',
                hintStyle: const TextStyle(
                    color: AppColors.onSurfaceVariant, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 20, color: AppColors.onSurfaceVariant),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final msg = filtered[i];
                final isSelected =
                    widget.selected.any((m) => m.id == msg.id);
                final preview = msg.content.trim();
                final label = preview.length > 80
                    ? '${preview.substring(0, 80)}…'
                    : preview.isEmpty
                        ? '…'
                        : preview;
                return InkWell(
                  onTap: () {
                    widget.onToggle(msg);
                    setState(() {});
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
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
                            isSelected
                                ? Icons.check_rounded
                                : Icons.chat_bubble_outline_rounded,
                            size: 16,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
