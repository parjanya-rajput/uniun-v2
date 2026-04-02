part of 'vishnu_feed_bloc.dart';

sealed class VishnuFeedEvent {
  const VishnuFeedEvent();
}

final class LoadFeedEvent extends VishnuFeedEvent {
  const LoadFeedEvent();
}

final class RefreshFeedEvent extends VishnuFeedEvent {
  const RefreshFeedEvent();
}

final class LoadMoreFeedEvent extends VishnuFeedEvent {
  const LoadMoreFeedEvent();
}

final class ToggleSaveFeedEvent extends VishnuFeedEvent {
  const ToggleSaveFeedEvent(this.noteId, this.contentPreview);
  final String noteId;
  final String contentPreview;
}
