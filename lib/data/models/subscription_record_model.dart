import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/subscription_record/subscription_record_entity.dart';

part 'subscription_record_model.g.dart';

/// Persisted subscription definition + checkpoints.
/// Not the live websocket subscription state.
@Collection(ignore: {'copyWith'})
@Name('SubscriptionRecord')
class SubscriptionRecordModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String channelId;

  /// Nostr filter definitions to persist intent.
  late List<int> kinds;
  late List<String> eTags;
  List<String>? authors;
  int? limit;

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
        channelId: channelId,
        kinds: kinds,
        eTags: eTags,
        lastUntilByRelay: lastUntilByRelay,
        authors: authors,
        limit: limit,
        createdAt: createdAt,
        updatedAt: updatedAt,
        enabled: enabled,
      );
}
