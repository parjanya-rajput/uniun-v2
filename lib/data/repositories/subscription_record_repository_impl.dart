import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/subscription_record_model.dart';
import 'package:uniun/domain/entities/subscription_record/subscription_record_entity.dart';
import 'package:uniun/domain/repositories/subscription_record_repository.dart';

@Injectable(as: SubscriptionRecordRepository)
class SubscriptionRecordRepositoryImpl extends SubscriptionRecordRepository {
  final Isar isar;

  SubscriptionRecordRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, SubscriptionRecordEntity>> saveRecord(
    SubscriptionRecordEntity record,
  ) async {
    try {
      final existing = await isar.subscriptionRecordModels
          .where()
          .keyEqualTo(record.key)
          .findFirst();

      final model = existing ?? SubscriptionRecordModel();
      model.key = record.key;
      model.kinds = List<int>.from(record.kinds);
      model.eTags = List<String>.from(record.eTags);
      model.authors = record.authors == null
          ? null
          : List<String>.from(record.authors!);
      model.limit = record.limit;
      model.relays = List<String>.from(record.relays);
      model.lastUntilByRelayJson = jsonEncode(record.lastUntilByRelay);
      model.createdAt = record.createdAt;
      model.updatedAt = record.updatedAt;
      model.enabled = record.enabled;

      await isar.writeTxn(() async {
        await isar.subscriptionRecordModels.put(model);
      });

      return Right(
        model.toDomain(_decodeLastUntilMap(model.lastUntilByRelayJson)),
      );
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubscriptionRecordEntity>> getRecordByKey(
    String key,
  ) async {
    try {
      final row = await isar.subscriptionRecordModels
          .where()
          .keyEqualTo(key)
          .findFirst();
      if (row == null) {
        return Left(
          Failure.notFoundFailure('Subscription record not found for key: $key'),
        );
      }
      return Right(row.toDomain(_decodeLastUntilMap(row.lastUntilByRelayJson)));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SubscriptionRecordEntity>>>
      getEnabledRecords() async {
    try {
      final rows = await isar.subscriptionRecordModels
          .where()
          .filter()
          .enabledEqualTo(true)
          .findAll();
      return Right(
        rows
            .map((r) => r.toDomain(_decodeLastUntilMap(r.lastUntilByRelayJson)))
            .toList(),
      );
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateCheckpoint(
    String key,
    Map<String, int> lastUntilByRelay,
  ) async {
    try {
      await isar.writeTxn(() async {
        final row = await isar.subscriptionRecordModels
            .where()
            .keyEqualTo(key)
            .findFirst();
        if (row == null) return;
        row.lastUntilByRelayJson = jsonEncode(lastUntilByRelay);
        row.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await isar.subscriptionRecordModels.put(row);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleEnabled(String key, bool enabled) async {
    try {
      await isar.writeTxn(() async {
        final row = await isar.subscriptionRecordModels
            .where()
            .keyEqualTo(key)
            .findFirst();
        if (row == null) return;
        row.enabled = enabled;
        row.updatedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        await isar.subscriptionRecordModels.put(row);
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  Map<String, int> _decodeLastUntilMap(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          value is int ? value : int.tryParse(value.toString()) ?? 0,
        ),
      );
    } catch (_) {
      return <String, int>{};
    }
  }
}
