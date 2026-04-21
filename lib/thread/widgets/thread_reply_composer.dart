import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:uniun/l10n/app_localizations.dart';
import 'package:uniun/common/widgets/user_avatar.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/thread/bloc/thread_bloc.dart';

class ThreadReplyComposer extends StatelessWidget {
  const ThreadReplyComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    this.avatarUrl,
    this.pubkeySeed = '',
    // --- ThreadBloc path (thread page) ---
    this.state,
    // --- Callback path (channel thread page) ---
    this.replyingToName,
    this.isSending = false,
    this.canPost = false,
    this.onSend,
    this.onClearReply,
    this.onTextChanged,
    this.onLinkTap,
    this.hasLinks = false,
  }) : assert(state != null || onSend != null,
            'Provide either state (ThreadBloc) or onSend callback');

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? avatarUrl;
  final String pubkeySeed;

  // ThreadBloc path
  final ThreadState? state;

  // Callback path overrides
  final String? replyingToName;
  final bool isSending;
  final bool canPost;
  final VoidCallback? onSend;
  final VoidCallback? onClearReply;
  final void Function(String)? onTextChanged;
  final VoidCallback? onLinkTap;
  final bool hasLinks;

  bool get _useCallbacks => onSend != null;

  String? get _replyingToName =>
      _useCallbacks ? replyingToName : state?.replyingToName;

  bool get _canPost => _useCallbacks ? canPost : (state?.canPost ?? false);

  bool get _isPosting =>
      _useCallbacks ? isSending : state?.postStatus == ThreadPostStatus.posting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return KeyboardDismissOnTap(
      child: Container(
        color: Colors.white.withValues(alpha: 0.90),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Replying to @name" pill
            if (_replyingToName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.threadReplyingTo(_replyingToName!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          if (_useCallbacks) {
                            onClearReply?.call();
                          } else {
                            context
                                .read<ThreadBloc>()
                                .add(const SetReplyTargetEvent());
                          }
                        },
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),

            // Composer row
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    seed: pubkeySeed,
                    photoUrl: avatarUrl,
                    size: 32,
                    borderRadius: 16,
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: _replyingToName != null
                            ? l10n.threadReplyTo(_replyingToName!)
                            : l10n.threadReplyToThis,
                        hintStyle: const TextStyle(
                            color: AppColors.onSurfaceVariant, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (v) {
                        if (_useCallbacks) {
                          onTextChanged?.call(v);
                        } else {
                          context
                              .read<ThreadBloc>()
                              .add(UpdateReplyTextEvent(v));
                        }
                      },
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),

                  if (onLinkTap != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onLinkTap,
                      child: Icon(Icons.link_rounded,
                          size: 22,
                          color: hasLinks
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(width: 6),
                  ] else
                    const SizedBox(width: 10),

                  // Post button
                  GestureDetector(
                    onTap: _canPost
                        ? () {
                            if (_useCallbacks) {
                              onSend!();
                            } else {
                              context
                                  .read<ThreadBloc>()
                                  .add(const PostReplyEvent());
                            }
                          }
                        : null,
                    child: AnimatedOpacity(
                      opacity: _canPost ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 150),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: _isPosting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                l10n.threadPost,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
