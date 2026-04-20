import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:nostr/nostr.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/usecases/usecase.dart';
import 'package:uniun/domain/entities/channel/channel_entity.dart';
import 'package:uniun/domain/entities/subscription_record/subscription_record_entity.dart';
import 'package:uniun/domain/repositories/channel_repository.dart';
import 'package:uniun/domain/repositories/event_queue_repository.dart';
import 'package:uniun/domain/repositories/subscription_record_repository.dart';

class CreateChannelInput {
  final String name;
  final String about;
  final String picture;
  final List<String> relays;
  final String privateKey;

  const CreateChannelInput({
    required this.name,
    required this.about,
    required this.picture,
    required this.relays,
    required this.privateKey,
  });
}

/// Creates a NIP-28 channel locally, enqueues kind **40** for relay publish,
/// and persists an active [SubscriptionRecordEntity] for that channel id.
@lazySingleton
class CreateChannelUseCase
    extends UseCase<Either<Failure, ChannelEntity>, CreateChannelInput> {
  final ChannelRepository _channelRepository;
  final EventQueueRepository _eventQueueRepository;
  final SubscriptionRecordRepository _subscriptionRecordRepository;

  const CreateChannelUseCase(
    this._channelRepository,
    this._eventQueueRepository,
    this._subscriptionRecordRepository,
  );

  @override
  Future<Either<Failure, ChannelEntity>> call(
    CreateChannelInput input, {
    bool cached = false,
  }) async {
    try {
      final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final metadata = {
        'name': input.name,
        'about': input.about,
        'picture': input.picture,
      };

      final kind40 = Event.from(
        privkey: input.privateKey,
        kind: 40,
        content: jsonEncode(metadata),
        tags: const [],
        createdAt: nowUnix,
      );

      // NIP-28: the channel's unique id is the hex event id of this kind-40 event.
      final channelId = kind40.id;

      final channel = ChannelEntity(
        channelId: channelId,
        creatorPubKey: kind40.pubkey,
        name: input.name,
        about: input.about,
        picture: input.picture,
        relays: input.relays,
        createdAt: nowUnix,
        updatedAt: nowUnix,
      );

      final saveResult = await _channelRepository.saveChannel(channel);
      if (saveResult.isLeft()) return saveResult;

      final created = DateTime.fromMillisecondsSinceEpoch(
        kind40.createdAt * 1000,
      );
      final enqueueResult = await _eventQueueRepository.enqueueSignedEvent(
        eventId: channelId,
        authorPubkey: kind40.pubkey,
        sig: kind40.sig,
        kind: 40,
        eTagRefs: const [],
        pTagRefs: const [],
        tTags: const [],
        content: kind40.content,
        created: created,
      );
      if (enqueueResult.isLeft()) {
        return Left(
          enqueueResult.fold(
            (f) => f,
            (_) => const Failure.errorFailure('enqueue failed'),
          ),
        );
      }

      final subRecord = SubscriptionRecordEntity(
        channelId: channelId,
        kinds: const [41, 42, 43, 44],
        eTags: [channelId],
        authors: null,
        limit: null,
        lastUntilByRelay: const {},
        createdAt: nowUnix,
        updatedAt: nowUnix,
        enabled: true,
      );
      final subResult = await _subscriptionRecordRepository.saveRecord(
        subRecord,
      );
      if (subResult.isLeft()) {
        return Left(
          subResult.fold(
            (f) => f,
            (_) => const Failure.errorFailure('subscription save failed'),
          ),
        );
      }

      return saveResult;
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
