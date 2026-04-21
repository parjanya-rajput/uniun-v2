import 'package:uniun/domain/entities/channel_message/channel_message_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';

class ChannelThreadState {
  const ChannelThreadState({
    this.root,
    this.replies = const [],
    this.profiles = const {},
    this.savedIds = const {},
    this.isLoading = false,
    this.isSending = false,
  });

  final ChannelMessageEntity? root;
  final List<ChannelMessageEntity> replies;
  final Map<String, ProfileEntity> profiles;
  final Set<String> savedIds;
  final bool isLoading;
  final bool isSending;

  ChannelThreadState copyWith({
    ChannelMessageEntity? root,
    List<ChannelMessageEntity>? replies,
    Map<String, ProfileEntity>? profiles,
    Set<String>? savedIds,
    bool? isLoading,
    bool? isSending,
  }) {
    return ChannelThreadState(
      root: root ?? this.root,
      replies: replies ?? this.replies,
      profiles: profiles ?? this.profiles,
      savedIds: savedIds ?? this.savedIds,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
    );
  }
}
