import 'package:isar_community/isar.dart';

part 'encrypted_dm_model.g.dart';

/// Temporarily stores inbound NIP-17 Kind 1059 GiftWraps received from the WebSocket.
/// A background watcher (Nip17EncryptionService) will pop these, decrypt them, 
/// save them as DmMessageModel, and then delete them from this queue.
@Collection(ignore: {'copyWith'})
@Name('EncryptedDm')
class EncryptedDmModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String eventId;

  late String sig;
  late String authorPubkey;

  /// The gift-wrap receiver
  @Index()
  late String pTagRef;

  /// The encrypted gift-wrap payload
  late String content;

  late int kind; // Should generally be 1059

  late DateTime created;

  EncryptedDmModel({
    required this.eventId,
    required this.sig,
    required this.authorPubkey,
    required this.pTagRef,
    required this.content,
    required this.kind,
    required this.created,
  });
}
