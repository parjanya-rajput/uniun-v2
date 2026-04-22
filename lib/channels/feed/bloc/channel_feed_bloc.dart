import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/domain/entities/channel_message/channel_message_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/create_channel_message_usecase.dart';
import 'package:uniun/domain/usecases/get_channel_by_id_usecase.dart';
import 'package:uniun/domain/usecases/get_channel_messages_usecase.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'channel_feed_event.dart';
import 'channel_feed_state.dart';

class ChannelFeedBloc extends Bloc<ChannelFeedEvent, ChannelFeedState> {
  ChannelFeedBloc() : super(const ChannelFeedState()) {
    on<LoadChannelFeedEvent>(_onLoad);
    on<SendChannelMessageEvent>(_onSend);
    on<SaveChannelFeedMessageEvent>(_onSave);
    on<UnsaveChannelFeedMessageEvent>(_onUnsave);
  }

  Future<void> _onLoad(
    LoadChannelFeedEvent event,
    Emitter<ChannelFeedState> emit,
  ) async {
    emit(state.copyWith(status: ChannelFeedStatus.loading, isLoading: true));

    final channelResult = await getIt<GetChannelByIdUseCase>().call(event.channelId);
    final channel = channelResult.fold((_) => null, (c) => c);
    if (channel == null) {
      emit(state.copyWith(
        status: ChannelFeedStatus.error,
        isLoading: false,
        errorMessage: 'Channel not found.',
      ));
      return;
    }

    final messagesResult = await getIt<GetChannelMessagesUseCase>()
        .call(GetChannelMessagesInput(channelId: event.channelId, limit: 50));
    final rawMessages = messagesResult.fold((_) => <ChannelMessageEntity>[], (m) => m);
    final messages = rawMessages.reversed.toList();

    final profiles = await _loadProfiles(messages);
    final savedIds = await _loadSavedIds(messages);
    final replyCounts = await _loadReplyCounts(messages);

    emit(state.copyWith(
      status: ChannelFeedStatus.loaded,
      channel: channel,
      messages: messages,
      profiles: profiles,
      savedIds: savedIds,
      replyCounts: replyCounts,
      isLoading: false,
    ));
  }

  Future<void> _onSend(
    SendChannelMessageEvent event,
    Emitter<ChannelFeedState> emit,
  ) async {
    if (event.content.trim().isEmpty) return;
    emit(state.copyWith(isSending: true, errorMessage: null));

    final keysResult = await getIt<GetActiveUserKeysUseCase>().call();
    final keys = keysResult.fold((_) => null, (k) => k);
    if (keys == null) {
      emit(state.copyWith(isSending: false, errorMessage: 'Not logged in.'));
      return;
    }

    final result = await getIt<CreateChannelMessageUseCase>().call(
      CreateChannelMessageInput(
        channelId: event.channelId,
        content: event.content.trim(),
        privateKey: keys.privkeyHex,
        replyToEventId: event.replyToEventId,
        mentionRefs: event.mentionRefs,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSending: false,
        errorMessage: failure.toMessage(),
      )),
      (message) {
        final updated = [...state.messages, message];
        final updatedCounts = Map<String, int>.from(state.replyCounts);
        if (event.replyToEventId != null) {
          updatedCounts[event.replyToEventId!] =
              (updatedCounts[event.replyToEventId!] ?? 0) + 1;
        }
        for (final ref in event.mentionRefs) {
          updatedCounts[ref] = (updatedCounts[ref] ?? 0) + 1;
        }
        emit(state.copyWith(
          isSending: false,
          messages: updated,
          replyCounts: updatedCounts,
        ));
      },
    );
  }

  Future<void> _onSave(
    SaveChannelFeedMessageEvent event,
    Emitter<ChannelFeedState> emit,
  ) async {
    final note = event.message.toNoteEntity();
    final result = await getIt<SaveNoteUseCase>().call(note);
    result.fold(
      (_) => null,
      (_) => emit(state.copyWith(savedIds: {...state.savedIds, event.message.id})),
    );
  }

  Future<void> _onUnsave(
    UnsaveChannelFeedMessageEvent event,
    Emitter<ChannelFeedState> emit,
  ) async {
    final result = await getIt<UnsaveNoteUseCase>().call(event.messageId);
    result.fold(
      (_) => null,
      (_) => emit(state.copyWith(
        savedIds: state.savedIds.difference({event.messageId}),
      )),
    );
  }

  Future<Map<String, ProfileEntity>> _loadProfiles(
      List<ChannelMessageEntity> messages) async {
    final pubkeys = messages.map((m) => m.authorPubkey).toSet();
    final profiles = <String, ProfileEntity>{};
    for (final pk in pubkeys) {
      final result = await getIt<GetProfileUseCase>().call(pk);
      result.fold((_) => null, (p) => profiles[pk] = p);
    }
    return profiles;
  }

  Future<Set<String>> _loadSavedIds(
      List<ChannelMessageEntity> messages) async {
    final saved = <String>{};
    for (final msg in messages) {
      final result = await getIt<IsSavedNoteUseCase>().call(msg.id);
      result.fold((_) => null, (isSaved) {
        if (isSaved) saved.add(msg.id);
      });
    }
    return saved;
  }

  Future<Map<String, int>> _loadReplyCounts(
      List<ChannelMessageEntity> messages) async {
    final counts = <String, int>{};
    for (final msg in messages) {
      final result =
          await getIt<GetChannelMessageReplyCountUseCase>().call(msg.id);
      result.fold((_) => null, (c) => counts[msg.id] = c);
    }
    return counts;
  }
}
