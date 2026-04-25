import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nostr_core_dart/nostr.dart';
import 'package:uniun/domain/usecases/create_channel_usecase.dart';
import 'package:uniun/domain/usecases/get_relays_usecase.dart';
import 'package:uniun/domain/usecases/user_usecases.dart';
import 'package:uniun/domain/usecases/save_channel_usecase.dart';
import 'package:uniun/domain/usecases/subscribe_channel_usecase.dart';
import 'package:uniun/domain/entities/channel/channel_entity.dart';

part 'create_channel_event.dart';
part 'create_channel_state.dart';

@injectable
class CreateChannelBloc extends Bloc<CreateChannelEvent, CreateChannelState> {
  final GetRelaysUseCase _getRelaysUseCase;
  final GetActiveUserUseCase _getActiveUserUseCase;
  final CreateChannelUseCase _createChannelUseCase;
  final SaveChannelUseCase _saveChannelUseCase;
  final SubscribeChannelUseCase _subscribeChannelUseCase;

  CreateChannelBloc(
    this._getRelaysUseCase,
    this._getActiveUserUseCase,
    this._createChannelUseCase,
    this._saveChannelUseCase,
    this._subscribeChannelUseCase,
  ) : super(const CreateChannelState()) {
    on<LoadRelaysEvent>(_onLoadRelays);
    on<SubmitChannelEvent>(_onSubmitChannel);
    on<JoinChannelEvent>(_onJoinChannel);
  }

  Future<void> _onLoadRelays(
    LoadRelaysEvent event,
    Emitter<CreateChannelState> emit,
  ) async {
    emit(state.copyWith(isLoadingRelays: true, errorMessage: null));

    final result = await _getRelaysUseCase.call();
    result.fold(
      (failure) {
        emit(
          state.copyWith(
            isLoadingRelays: false,
            errorMessage: 'Failed to load relays.',
          ),
        );
      },
      (relays) {
        emit(
          state.copyWith(
            isLoadingRelays: false,
            availableRelays: relays.map((r) => r.url).toList(),
          ),
        );
      },
    );
  }

  Future<void> _onSubmitChannel(
    SubmitChannelEvent event,
    Emitter<CreateChannelState> emit,
  ) async {
    // Validation
    if (event.name.trim().length < 3) {
      emit(
        state.copyWith(
          errorMessage: 'Channel name must be at least 3 characters.',
        ),
      );
      return;
    }

    if (event.name.trim().length > 30) {
      emit(
        state.copyWith(
          errorMessage: 'Channel name cannot exceed 30 characters.',
        ),
      );
      return;
    }

    if (event.selectedRelays.isEmpty) {
      emit(state.copyWith(errorMessage: 'Please select at least one relay.'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    // Get active user for signing
    final userResult = await _getActiveUserUseCase.call();
    final user = userResult.fold((_) => null, (u) => u);

    if (user == null) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Active user not found or missing private key.',
        ),
      );
      return;
    }

    String hexPriv = user.nsec;
    if (hexPriv.startsWith('nsec1')) {
      try {
        hexPriv = Nip19.decodePrivkey(hexPriv);
      } catch (e) {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: 'Failed to decode private key.',
          ),
        );
        return;
      }
    }

    final input = CreateChannelInput(
      name: event.name.trim(),
      about: event.about.trim(),
      picture: event.picture.trim(),
      relays: event.selectedRelays,
      privateKey: hexPriv,
    );

    final createResult = await _createChannelUseCase.call(input);

    createResult.fold(
      (failure) {
        emit(
          state.copyWith(isSubmitting: false, errorMessage: failure.message),
        );
      },
      (channel) {
        // Success
        emit(state.copyWith(isSubmitting: false, isSuccess: true));
      },
    );
  }

  Future<void> _onJoinChannel(
    JoinChannelEvent event,
    Emitter<CreateChannelState> emit,
  ) async {
    if (event.channelId.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Channel ID cannot be empty.'));
      return;
    }

    if (event.selectedRelays.isEmpty) {
      emit(state.copyWith(errorMessage: 'Please select at least one relay.'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    // Save initial placeholder channel
    final channelInput = ChannelEntity(
      channelId: event.channelId.trim(),
      creatorPubKey: '',
      name: '',
      about: '',
      picture: '',
      relays: event.selectedRelays,
      createdAt: 0,
      updatedAt: 0,
    );

    final saveResult = await _saveChannelUseCase.call(channelInput);
    if (saveResult.isLeft()) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: 'Failed to save channel details locally.',
        ),
      );
      return;
    }

    // Subscribe to channel
    final subInput = SubscribeChannelInput(channelId: event.channelId.trim());
    final subResult = await _subscribeChannelUseCase.call(subInput);

    subResult.fold(
      (failure) {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: 'Failed to subscribe to channel: ${failure.message}',
          ),
        );
      },
      (record) {
        emit(state.copyWith(isSubmitting: false, isSuccess: true));
      },
    );
  }
}
