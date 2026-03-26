import 'package:isar_community/isar.dart';
import 'package:uniun/domain/entities/profile/profile_entity.dart';

part 'profile_model.g.dart';

@Collection(ignore: {'copyWith'})
@Name('NostrProfile')
class ProfileModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String pubkey;     // secp256k1 public key — the Nostr identity

  String? name;
  String? username;
  String? about;
  String? avatarUrl;
  String? nip05;          // verified internet identifier (user@domain.com)

  late DateTime updatedAt; // last time this Kind 0 was received/updated
}

extension ProfileModelExtension on ProfileModel {
  ProfileEntity toDomain() => ProfileEntity(
        pubkey: pubkey,
        name: name,
        username: username,
        about: about,
        avatarUrl: avatarUrl,
        nip05: nip05,
        updatedAt: updatedAt,
      );
}
