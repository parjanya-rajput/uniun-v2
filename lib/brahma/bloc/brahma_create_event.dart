part of 'brahma_create_bloc.dart';

sealed class BrahmaCreateEvent {
  const BrahmaCreateEvent();
}

final class UpdateContentEvent extends BrahmaCreateEvent {
  const UpdateContentEvent(this.content);
  final String content;
}

final class SubmitNoteEvent extends BrahmaCreateEvent {
  const SubmitNoteEvent({this.rootEventId, this.replyToEventId});
  final String? rootEventId;
  final String? replyToEventId;
}

final class ResetBrahmaEvent extends BrahmaCreateEvent {
  const ResetBrahmaEvent();
}
