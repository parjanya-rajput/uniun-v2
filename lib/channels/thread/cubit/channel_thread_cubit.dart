import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniun/channels/detail/cubit/channel_detail_cubit.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/domain/entities/channel_message/channel_message_entity.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';
import 'package:uniun/domain/usecases/get_channel_messages_usecase.dart';
import 'package:uniun/domain/usecases/profile_usecases.dart';
import 'package:uniun/domain/usecases/saved_note_usecases.dart';
import 'channel_thread_state.dart';

class ChannelThreadCubit extends Cubit<ChannelThreadState> {
  ChannelThreadCubit() : super(const ChannelThreadState());

  Future<void> load(String messageId) async {
    emit(state.copyWith(isLoading: true));

    final rootResult =
        await getIt<GetChannelMessageByIdUseCase>().call(messageId);
    if (isClosed) return;

    final root = rootResult.fold((_) => null, (m) => m);
    if (root == null) {
      emit(state.copyWith(isLoading: false));
      return;
    }

    final repliesResult =
        await getIt<GetChannelMessageRepliesUseCase>().call(messageId);
    if (isClosed) return;

    final replies =
        repliesResult.fold((_) => <ChannelMessageEntity>[], (r) => r);

    final all = [root, ...replies];
    final profiles = await _loadProfiles(all);
    if (isClosed) return;
    final savedIds = await _loadSavedIds(all);
    if (isClosed) return;

    emit(state.copyWith(
      isLoading: false,
      root: root,
      replies: replies,
      profiles: profiles,
      savedIds: savedIds,
    ));
  }

  Future<Map<String, ProfileEntity>> _loadProfiles(
      List<ChannelMessageEntity> messages) async {
    final pubkeys = messages.map((m) => m.authorPubkey).toSet();
    final profiles = <String, ProfileEntity>{};
    for (final pk in pubkeys) {
      final r = await getIt<GetProfileUseCase>().call(pk);
      r.fold((_) => null, (p) => profiles[pk] = p);
    }
    return profiles;
  }

  Future<Set<String>> _loadSavedIds(
      List<ChannelMessageEntity> messages) async {
    final saved = <String>{};
    for (final msg in messages) {
      final r = await getIt<IsSavedNoteUseCase>().call(msg.id);
      r.fold((_) => null, (isSaved) {
        if (isSaved) saved.add(msg.id);
      });
    }
    return saved;
  }

  void saveMessage(ChannelMessageEntity msg, ChannelDetailCubit parent) {
    parent.saveMessage(msg);
    emit(state.copyWith(savedIds: {...state.savedIds, msg.id}));
  }

  void unsaveMessage(String id, ChannelDetailCubit parent) {
    parent.unsaveMessage(id);
    emit(state.copyWith(savedIds: state.savedIds.difference({id})));
  }
}
