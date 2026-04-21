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
import 'channel_detail_state.dart';

class ChannelDetailCubit extends Cubit<ChannelDetailState> {
  ChannelDetailCubit() : super(const ChannelDetailState());

  Future<void> load(String channelId) async {
    emit(state.copyWith(status: ChannelDetailStatus.loading, isLoading: true));

    final channelResult = await getIt<GetChannelByIdUseCase>().call(channelId);
    if (isClosed) return;

    final channel = channelResult.fold((_) => null, (c) => c);
    if (channel == null) {
      emit(state.copyWith(
        status: ChannelDetailStatus.error,
        isLoading: false,
        errorMessage: 'Channel not found.',
      ));
      return;
    }

    final messagesResult = await getIt<GetChannelMessagesUseCase>()
        .call(GetChannelMessagesInput(channelId: channelId, limit: 50));
    if (isClosed) return;

    final rawMessages =
        messagesResult.fold((_) => <ChannelMessageEntity>[], (m) => m);

    // Isar returns newest-first; reverse for oldest-at-top chat display.
    final messages = rawMessages.reversed.toList();

    final profiles = await _loadProfiles(messages);
    if (isClosed) return;

    final savedIds = await _loadSavedIds(messages);
    if (isClosed) return;

    final replyCounts = await _loadReplyCounts(messages);
    if (isClosed) return;

    emit(state.copyWith(
      status: ChannelDetailStatus.loaded,
      channel: channel,
      messages: messages,
      profiles: profiles,
      savedIds: savedIds,
      replyCounts: replyCounts,
      isLoading: false,
    ));
  }

  Future<void> sendMessage(
    String channelId,
    String content, {
    String? replyToEventId,
    List<String> mentionRefs = const [],
  }) async {
    if (content.trim().isEmpty) return;
    emit(state.copyWith(isSending: true, errorMessage: null));

    final keysResult = await getIt<GetActiveUserKeysUseCase>().call();
    if (isClosed) return;

    final keys = keysResult.fold((_) => null, (k) => k);
    if (keys == null) {
      emit(state.copyWith(isSending: false, errorMessage: 'Not logged in.'));
      return;
    }

    final result = await getIt<CreateChannelMessageUseCase>().call(
      CreateChannelMessageInput(
        channelId: channelId,
        content: content.trim(),
        privateKey: keys.privkeyHex,
        replyToEventId: replyToEventId,
        mentionRefs: mentionRefs,
      ),
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isSending: false,
        errorMessage: failure.toMessage(),
      )),
      (message) {
        final updated = [...state.messages, message];
        // Increment reply count for parent message immediately
        final updatedCounts = Map<String, int>.from(state.replyCounts);
        if (replyToEventId != null) {
          updatedCounts[replyToEventId] =
              (updatedCounts[replyToEventId] ?? 0) + 1;
        }
        emit(state.copyWith(
          isSending: false,
          messages: updated,
          replyCounts: updatedCounts,
        ));
      },
    );
  }

  Future<void> saveMessage(ChannelMessageEntity message) async {
    final note = message.toNoteEntity();
    final result = await getIt<SaveNoteUseCase>().call(note);
    if (isClosed) return;
    result.fold(
      (_) => null,
      (_) => emit(state.copyWith(
        savedIds: {...state.savedIds, message.id},
      )),
    );
  }

  Future<void> unsaveMessage(String messageId) async {
    final result = await getIt<UnsaveNoteUseCase>().call(messageId);
    if (isClosed) return;
    result.fold(
      (_) => null,
      (_) => emit(state.copyWith(
        savedIds: state.savedIds.difference({messageId}),
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
