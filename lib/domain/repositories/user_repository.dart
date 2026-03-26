import 'package:dartz/dartz.dart';
import 'package:uniun/core/error/failures.dart';
import 'package:uniun/domain/entities/user_key/user_key_entity.dart';

abstract class UserRepository {
  /// Generate a new Nostr keypair and save it locally.
  Future<Either<Failure, UserKeyEntity>> generateKey();

  /// Import an existing keypair from a nsec string.
  Future<Either<Failure, UserKeyEntity>> importKey(String nsec);

  /// Get the currently active user's keypair. Returns notFoundFailure if no user.
  Future<Either<Failure, UserKeyEntity>> getActiveUser();

  /// Clear the stored keypair (logout).
  Future<Either<Failure, Unit>> logout();
}
