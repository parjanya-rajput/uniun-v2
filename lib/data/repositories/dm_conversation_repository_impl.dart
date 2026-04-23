import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/core/utils/pubkey_normalizer.dart';
import 'package:uniun/data/models/dm/dm_conversation_model.dart';
import 'package:uniun/domain/entities/dm/dm_conversation_entity.dart';
import 'package:uniun/domain/repositories/dm_conversation_repository.dart';

@Injectable(as: DmConversationRepository)
class DmConversationRepositoryImpl extends DmConversationRepository {
  final Isar isar;
  DmConversationRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, List<DmConversationEntity>>> getConversations() async {
    try {
      final rows = await isar.dmConversationModels.where().findAll();
      rows.sort((a, b) => a.otherPubkey.compareTo(b.otherPubkey));
      return Right(rows.map((c) => c.toDomain()).toList());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DmConversationEntity>> getConversationByOtherPubkey(
    String otherPubkey,
  ) async {
    try {
      final normalizedPubkey = normalizeNostrPubkey(otherPubkey);
      final row = await isar.dmConversationModels
          .where()
          .otherPubkeyEqualTo(normalizedPubkey)
          .findFirst();
      if (row == null) {
        return Left(
          Failure.notFoundFailure(
            'DM conversation not found for otherPubkey: $normalizedPubkey',
          ),
        );
      }
      return Right(row.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DmConversationEntity>> saveConversation(
    DmConversationEntity entity,
  ) async {
    try {
      final normalizedPubkey = normalizeNostrPubkey(entity.otherPubkey);
      final existing = await isar.dmConversationModels
          .where()
          .otherPubkeyEqualTo(normalizedPubkey)
          .findFirst();
      if (existing != null) {
        return Right(existing.toDomain());
      }

      final model = DmConversationModel()
        ..otherPubkey = normalizedPubkey
        ..relays = entity.relays;
      await isar.writeTxn(() async {
        await isar.dmConversationModels.put(model);
      });
      return Right(model.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteConversation(String otherPubkey) async {
    try {
      final normalizedPubkey = normalizeNostrPubkey(otherPubkey);
      await isar.writeTxn(() async {
        final existing = await isar.dmConversationModels
            .where()
            .otherPubkeyEqualTo(normalizedPubkey)
            .findFirst();
        if (existing != null) {
          await isar.dmConversationModels.delete(existing.id);
        }
      });
      return const Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
