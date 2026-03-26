import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/user_key/user_key_entity.dart';

part 'user_key_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('UserKey')
class UserKeyModel {
  Id id = Isar.autoIncrement;

  late String nsec;       // private key hex — used to sign all events
  late String npub;       // public key hex — the user's Nostr identity
  late DateTime createdAt;
}

extension UserKeyModelExtension on UserKeyModel {
  UserKeyEntity toDomain() => UserKeyEntity(
        nsec: nsec,
        npub: npub,
        createdAt: createdAt,
      );
}
