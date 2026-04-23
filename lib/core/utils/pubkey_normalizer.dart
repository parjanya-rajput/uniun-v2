import 'package:nostr_core_dart/nostr.dart';

/// Converts a Nostr public key input into canonical storage format.
///
/// Canonical format is a lowercase 64-char hex pubkey.
String normalizeNostrPubkey(String input) {
  var value = input.trim();
  if (value.startsWith('npub1')) {
    value = Nip19.decodePubkey(value);
  }

  final hex = value.toLowerCase();
  final hexRegex = RegExp(r'^[0-9a-f]{64}$');
  if (!hexRegex.hasMatch(hex)) {
    throw FormatException('Invalid public key format');
  }

  return hex;
}
