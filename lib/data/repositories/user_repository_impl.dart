import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:isar_community/isar.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/data/models/user_key_model.dart';
import 'package:uniun/domain/entities/user_key/user_key_entity.dart';
import 'package:uniun/domain/repositories/user_repository.dart';

@Injectable(as: UserRepository)
class UserRepositoryImpl extends UserRepository {
  final Isar isar;
  UserRepositoryImpl({required this.isar});

  @override
  Future<Either<Failure, UserKeyEntity>> generateKey() async {
    try {
      // Key generation requires a crypto library (to be integrated with EmbeddedServer).
      // Placeholder: caller provides nsec/npub derived from secp256k1.
      return Left(Failure.errorFailure('generateKey: not yet implemented'));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserKeyEntity>> importKey(String nsec) async {
    try {
      // Derive npub from nsec — requires secp256k1 (to be wired with EmbeddedServer).
      // For now we store whatever npub is derived externally and passed in alongside nsec.
      return Left(Failure.errorFailure('importKey: not yet implemented'));
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserKeyEntity>> getActiveUser() async {
    try {
      final key = await isar.userKeyModels.where().findFirst();
      if (key == null) {
        return Left(Failure.notFoundFailure('No active user found'));
      }
      return Right(key.toDomain());
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await isar.writeTxn(() async {
        await isar.userKeyModels.clear();
      });
      return Right(unit);
    } catch (e) {
      return Left(Failure.errorFailure(e.toString()));
    }
  }
}
