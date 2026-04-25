part of 'create_channel_bloc.dart';

@immutable
sealed class CreateChannelEvent {}

final class LoadRelaysEvent extends CreateChannelEvent {}

final class SubmitChannelEvent extends CreateChannelEvent {
  final String name;
  final String about;
  final String picture;
  final List<String> selectedRelays;

  SubmitChannelEvent({
    required this.name,
    required this.about,
    required this.picture,
    required this.selectedRelays,
  });
}

final class JoinChannelEvent extends CreateChannelEvent {
  final String channelId;
  final List<String> selectedRelays;

  JoinChannelEvent({required this.channelId, required this.selectedRelays});
}
