import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/note_model.dart';
import 'package:uniun/domain/entities/note/note_entity.dart';

part 'event_queue_model.g.dart';

/// Durable outbound event queue. Each row represents one signed Nostr event
/// that needs to be published to one or more relays.
///
/// [id] is the Isar autoincrement integer — used as the ordered cursor by
/// every [WebSocketService] so each connection tracks its own send position
/// independently via [WebSocketService._lastSentQueueId].
///
/// An entry is eligible for dequeue when:
///   sentCount >= number of currently connected write relays
///   AND enqueuedAt < now - 30 minutes
@Collection(ignore: {'copyWith'})
@Name('EventQueue')
class EventQueueModel {
  Id id = Isar.autoIncrement;

  /// Nostr event ID (SHA256 hex) — unique per event.
  @Index(unique: true)
  late String eventId;

  /// Signed event payload stored in structured form.
  /// WebSocketService serializes this to the relay wire format at send time.
  late String authorPubkey;
  late String sig;
  late String content;
  late int kind;
  late List<String> eTagRefs;
  String? rootEventId;
  String? replyToEventId;
  late List<String> pTagRefs;
  late List<String> tTags;
  late DateTime created;

  /// Number of write-relay connections that have received ["OK", id, true].
  /// Incremented atomically by each WebSocketService on successful ACK.
  late int sentCount = 0;

  /// When this event was enqueued. Used for the 30-minute dequeue gate.
  late DateTime enqueuedAt;
}

/// Tag reconstruction order (must match [PublishNoteUseCase._buildTags]):
///   1. root e-tag (NIP-10)
///   2. reply e-tag (NIP-10)
///   3. mention e-tags (remaining eTagRefs)
///   4. p-tags
///   5. t-tags
extension EventQueueModelExtension on EventQueueModel {
  /// Populates this queue row from a data-layer [NoteModel].
  EventQueueModel populateFromNoteModel(NoteModel note) {
    eventId = note.eventId;
    authorPubkey = note.authorPubkey;
    sig = note.sig;
    content = note.content;
    kind = 1;
    eTagRefs = List<String>.from(note.eTagRefs);
    rootEventId = note.rootEventId;
    replyToEventId = note.replyToEventId;
    pTagRefs = List<String>.from(note.pTagRefs);
    tTags = List<String>.from(note.tTags);
    created = note.created;
    sentCount = 0;
    enqueuedAt = DateTime.now();
    return this;
  }

  /// Populates this queue row from a domain-layer [NoteEntity].
  ///
  /// NoteEntity does not carry root/reply threading markers, so those remain
  /// null and all eTagRefs are emitted as mention tags.
  EventQueueModel populateFromNoteEntity(NoteEntity note) {
    eventId = note.id;
    authorPubkey = note.authorPubkey;
    sig = note.sig;
    content = note.content;
    kind = 1;
    eTagRefs = List<String>.from(note.eTagRefs);
    rootEventId = null;
    replyToEventId = null;
    pTagRefs = List<String>.from(note.pTagRefs);
    tTags = List<String>.from(note.tTags);
    created = note.created;
    sentCount = 0;
    enqueuedAt = DateTime.now();
    return this;
  }

  /// Relay wire message: ["EVENT", {signed-event-json}]
  String toSerializedRelayMessage() {
    final tags = <List<String>>[
      if (rootEventId != null) ['e', rootEventId!, '', 'root'],
      if (replyToEventId != null) ['e', replyToEventId!, '', 'reply'],
      for (final ref in eTagRefs)
        if (ref != rootEventId && ref != replyToEventId)
          ['e', ref, '', 'mention'],
      for (final p in pTagRefs) ['p', p],
      for (final t in tTags) ['t', t],
    ];

    return jsonEncode([
      'EVENT',
      <String, dynamic>{
        'id': eventId,
        'pubkey': authorPubkey,
        'created_at': created.millisecondsSinceEpoch ~/ 1000,
        'kind': kind,
        'tags': tags,
        'content': content,
        'sig': sig,
      },
    ]);
  }
}
