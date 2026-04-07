import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/subscription_record/subscription_record_entity.dart';

part 'subscription_record_model.g.dart';

/// Persisted subscription definition + checkpoints.
/// Not the live websocket subscription state.
@Collection(ignore: {'copyWith'})
@Name('SubscriptionRecord')
class SubscriptionRecordModel {
  Id id = Isar.autoIncrement;

  /// Stable logical key (not runtime random REQ id).
  // @Index(unique: true) // up for discussion
  // late String key;

  /// Nostr filter definitions to persist intent.
  late List<int> kinds;
  late List<String> eTags;
  List<String>? authors;
  int? limit;

  /// Which relays this subscription should run on.
  late List<String> relays;

  /// JSON-encoded Map<String, int> checkpoint by relay.
  late String lastUntilByRelayJson;

  late int createdAt;
  late int updatedAt;

  @Index()
  late bool enabled;
}

extension SubscriptionRecordModelExtension on SubscriptionRecordModel {
  SubscriptionRecordEntity toDomain(Map<String, int> lastUntilByRelay) =>
      SubscriptionRecordEntity(
        key: key,
        kinds: kinds,
        eTags: eTags,
        relays: relays,
        lastUntilByRelay: lastUntilByRelay,
        authors: authors,
        limit: limit,
        createdAt: createdAt,
        updatedAt: updatedAt,
        enabled: enabled,
      );
}
