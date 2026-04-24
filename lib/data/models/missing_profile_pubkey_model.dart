import 'package:isar_community/isar.dart';

part 'missing_profile_pubkey_model.g.dart';

/// Tracks pubkeys for which we need to fetch kind-0 metadata.
@Collection(ignore: {'copyWith'})
@Name('MissingProfilePubkey')
class MissingProfilePubkeyModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String pubkey;

  late DateTime firstSeenAt;
}
