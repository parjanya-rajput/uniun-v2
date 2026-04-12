import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_record_entity.freezed.dart';

@freezed
abstract class SubscriptionRecordEntity with _$SubscriptionRecordEntity {
  const factory SubscriptionRecordEntity({
    required String channelId,
    required List<int> kinds,
    required List<String> eTags,
    List<String>? authors,
    int? limit,
    required Map<String, int> lastUntilByRelay,
    required int createdAt,
    required int updatedAt,
    @Default(true) bool enabled,
  }) = _SubscriptionRecordEntity;
}
