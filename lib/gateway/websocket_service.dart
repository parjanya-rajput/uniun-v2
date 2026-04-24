import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:isar_community/isar.dart';
import 'package:uniun/core/enum/note_type.dart';
import 'package:uniun/core/enum/relay_status.dart';
import 'package:uniun/data/models/event_queue_model.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/dm/encrypted_dm_model.dart';
import 'package:uniun/data/models/missing_profile_pubkey_model.dart';
import 'package:uniun/data/models/notes/note_model.dart';
import 'package:uniun/data/models/profile_model.dart';
import 'package:uniun/data/models/relay_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Manages a single WebSocket connection to one Nostr relay.
///
/// Responsibilities:
///  - Maintain a persistent connection with exponential-backoff reconnect.
///  - Maintain an [_lastSentQueueId] cursor into [EventQueueModel]; query the
///    next unsent item, send it, then wait for the relay's ["OK"] response
///    before advancing the cursor.
///  - Receive incoming Nostr events and write them directly to [NoteModel].
///  - Update [RelayModel.status] on every connection state change.
class WebSocketService {
  /// NIP-01 [REQ] subscription id for kind-1 notes from this relay.
  static const _kind1FeedSubscriptionId = 'feed_notes';

  /// NIP-01 [REQ] id for followed-note thread refs (`#e` = followed root ids).
  static const _followedNoteRefsSubscriptionId = 'followed_note_refs';

  static const _dmSubscriptionId = 'dms';
  static const _kind0SubscriptionId = 'profiles';

  final String url;
  final bool read;
  final bool write;
  final Isar _isar;

  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _socketSub;
  StreamSubscription<void>? _missingPubkeysWatcher;

  /// Isar autoincrement id of the last successfully ACK'd queue item.
  /// The service sends items with id > [_lastSentQueueId].
  int _lastSentQueueId;

  int _reconnectAttempt = 0;
  bool _isConnected = false;
  bool _disposed = false;
  Timer? _reconnectTimer;

  /// eventId of the event currently in-flight (sent, waiting for OK).
  String? _pendingEventId;

  /// EventQueueModel.id of the event currently in-flight.
  int? _pendingQueueId;

  /// Dedupes [`FollowedNoteModel`] bumps when the same kind-1 `EVENT` is
  /// delivered twice (e.g. matches both `feed_notes` and `followed_note_refs`).
  final Set<String> _processedFollowReferenceBumps = {};

  final String? activePubkey;

  final void Function(RelayStatus)? onStatusChanged;
  final Future<List<String>?> Function(EventQueueModel)? resolveTargets;

  WebSocketService({
    required this.url,
    required this.read,
    required this.write,
    required Isar isar,
    required int startFromQueueId,
    this.activePubkey,
    this.onStatusChanged,
    this.resolveTargets,
  }) : _isar = isar,
       _lastSentQueueId = startFromQueueId;

  bool get isConnected => _isConnected;

  // ── Connection lifecycle ───────────────────────────────────────────────────

  void connect() {
    if (_disposed) return;
    _updateStatus(RelayStatus.reconnecting);
    try {
      _socket = WebSocketChannel.connect(Uri.parse(url));

      // Wait for TCP/WebSocket readiness before marking connected.
      // This prevents "connection refused" from surfacing as an unhandled error.
      _socket!.ready
          .then((_) {
            if (_disposed) return;
            _socketSub = _socket!.stream.listen(
              _onMessage,
              onError: (_) => _scheduleReconnect(),
              onDone: _scheduleReconnect,
              cancelOnError: true,
            );
            _isConnected = true;
            _reconnectAttempt = 0;
            _updateStatus(RelayStatus.connected);
            _subscribeKind1Feed();
            _subscribeDms();
            _ensureMissingPubkeysWatcher();
            unawaited(_subscribeKind0Profiles());
            unawaited(_subscribeFollowedNoteRefs());
            _processSendQueue();
          })
          .catchError((_) {
            _scheduleReconnect();
          });
    } catch (_) {
      _scheduleReconnect();
    }
  }

  /// Sends [REQ] for kind1 notes (NIP-01). Live matching [EVENT]s follow until [CLOSE].
  void _subscribeKind1Feed() {
    if (!read || _disposed || _socket == null) return;
    _socket!.sink.add(
      jsonEncode([
        'REQ',
        _kind1FeedSubscriptionId,
        {
          'kinds': [1],
        },
      ]),
    );
  }

  void _subscribeDms() {
    if (!read || _disposed || _socket == null || activePubkey == null) return;
    _socket!.sink.add(
      jsonEncode([
        'REQ',
        _dmSubscriptionId,
        {
          'kinds': [1059],
          '#p': [activePubkey],
        },
      ]),
    );
  }

  Future<void> _subscribeKind0Profiles() async {
    if (!read || _disposed || _socket == null) return;
    _socket!.sink.add(jsonEncode(['CLOSE', _kind0SubscriptionId]));
    final missing = await _isar.missingProfilePubkeyModels.where().findAll();
    if (missing.isEmpty) return;

    _socket!.sink.add(
      jsonEncode([
        'REQ',
        _kind0SubscriptionId,
        {
          'kinds': [0],
          'authors': missing.map((m) => m.pubkey).toList(),
        },
      ]),
    );
  }

  void _ensureMissingPubkeysWatcher() {
    if (_missingPubkeysWatcher != null) return;
    _missingPubkeysWatcher = _isar.missingProfilePubkeyModels
        .watchLazy()
        .listen((_) => unawaited(_subscribeKind0Profiles()));
  }

  /// Refreshes the `#e`-filtered [REQ] for all rows in [FollowedNoteModel].
  ///
  /// Called after connect and whenever [CentralRelayManager] observes follow
  /// list changes. Safe to call when not yet connected (no-op).
  Future<void> resyncFollowedNoteSubscriptions() async {
    await _subscribeFollowedNoteRefs();
  }

  Future<void> _subscribeFollowedNoteRefs() async {
    if (!read || _disposed || _socket == null || !_isConnected) return;

    _socket!.sink.add(jsonEncode(['CLOSE', _followedNoteRefsSubscriptionId]));

    final followed = await _isar.followedNoteModels.where().findAll();
    if (followed.isEmpty) return;

    final eRefs = followed.map((f) => f.eventId).toList();
    _socket!.sink.add(
      jsonEncode([
        'REQ',
        _followedNoteRefsSubscriptionId,
        {
          'kinds': [1],
          '#e': eRefs,
        },
      ]),
    );
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _missingPubkeysWatcher?.cancel();
    _missingPubkeysWatcher = null;
    _socketSub?.cancel();
    _socket?.sink.close();
    _isConnected = false;
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _isConnected = false;
    _pendingEventId = null;
    _pendingQueueId = null;
    _updateStatus(RelayStatus.disconnected);
    _socketSub?.cancel();
    _socket?.sink.close();

    final delaySec = min(pow(2, _reconnectAttempt).toInt(), 60);
    _reconnectAttempt++;
    _reconnectTimer = Timer(Duration(seconds: delaySec), connect);
  }

  // ── Outbound — send queue ──────────────────────────────────────────────────

  /// Called by [CentralRelayManager] when a new item is enqueued.
  void onNewQueueItem() => _processSendQueue();

  /// Called by [CentralRelayManager] when [FollowedNoteModel] rows change.
  void onFollowedNotesChanged() => unawaited(_subscribeFollowedNoteRefs());

  Future<void> _processSendQueue() async {
    // Guard: only send if this relay is a write relay, connected, and idle.
    if (!write || !_isConnected || _pendingEventId != null) return;

    final next = await _isar.eventQueueModels
        .where()
        .idGreaterThan(_lastSentQueueId)
        .findFirst();

    if (next == null) return;

    if (resolveTargets != null) {
      final targets = await resolveTargets!(next);
      if (targets != null && !targets.contains(url)) {
        _lastSentQueueId = next.id;
        _processSendQueue();
        return;
      }
    }

    _pendingEventId = next.eventId;
    _pendingQueueId = next.id;
    _socket!.sink.add(next.toSerializedRelayMessage());
  }

  // ── Inbound — relay messages ───────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    List<dynamic> data;
    try {
      data = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return;
    }
    if (data.isEmpty) return;

    final type = data[0] as String;
    switch (type) {
      case 'OK':
        _handleOk(data);
        break;
      case 'EVENT':
        if (read && data.length >= 3) {
          final eventMap = data[2] as Map<String, dynamic>;
          unawaited(_trackMissingProfilePubkey(eventMap));
          final kind = eventMap['kind'] as int?;
          if (kind == 1) {
            unawaited(_handleIncomingKind1Event(eventMap));
          } else if (kind == 0) {
            unawaited(_storeIncomingKind0Profile(eventMap));
          } else if (kind == 1059) {
            unawaited(_storeEncryptedDm(eventMap));
          }
        }
        break;
      case 'EOSE':
        // End of stored events — no action needed in v1.
        break;
      case 'NOTICE':
        // Relay notice — silently ignored in v1.
        break;
    }
  }

  Future<void> _handleOk(List<dynamic> data) async {
    if (data.length < 3) return;
    final eventId = data[1] as String?;
    final accepted = data[2] as bool?;
    if (eventId == null || accepted == null) return;
    if (eventId != _pendingEventId) return;

    if (accepted) {
      // Increment sentCount so CentralRelayManager can dequeue when threshold met.
      await _isar.writeTxn(() async {
        final item = await _isar.eventQueueModels
            .where()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (item != null) {
          item.sentCount++;
          await _isar.eventQueueModels.put(item);
        }
      });
      if (_pendingQueueId != null) {
        _lastSentQueueId = _pendingQueueId!;
      }
    }

    // Whether accepted or rejected, release the pending slot and move on.
    _pendingEventId = null;
    _pendingQueueId = null;
    _processSendQueue();
  }

  Future<void> _handleIncomingKind1Event(Map<String, dynamic> event) async {
    await _storeIncomingEvent(event);
    await _bumpFollowedReferenceCountsIfNeeded(event);
  }

  /// Parses an incoming Nostr event map and persists it to [NoteModel].
  ///
  /// Idempotent — skips if [eventId] already exists.
  /// Only handles Kind 1 (short text notes) in v1.
  Future<void> _storeIncomingEvent(Map<String, dynamic> event) async {
    final kind = event['kind'] as int?;
    if (kind != 1) return; // Kind 0, 42, Blossom → future

    final eventId = event['id'] as String?;
    if (eventId == null) return;

    final model = _parseNoteModel(event);
    try {
      await _isar.writeTxn(() async {
        final existing = await _isar.noteModels
            .where()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (existing != null) return;
        await _isar.noteModels.put(model);
      });
    } catch (_) {
      // Another concurrent relay delivery may have inserted the same eventId.
      return;
    }
    // Isar watcher in Isolate 1 fires automatically — Flutter UI updates.
  }

  Future<void> _storeEncryptedDm(Map<String, dynamic> event) async {
    final eventId = event['id'] as String?;
    if (eventId == null) return;

    final rawTags = (event['tags'] as List<dynamic>? ?? []);
    String? pTagRef;
    for (final tag in rawTags) {
      if (tag is List && tag.length >= 2 && tag[0] == 'p') {
        pTagRef = tag[1] as String;
        break;
      }
    }

    if (pTagRef == null) return;

    final model = EncryptedDmModel(
      eventId: eventId,
      sig: event['sig'] as String? ?? '',
      authorPubkey: event['pubkey'] as String? ?? '',
      pTagRef: pTagRef,
      content: event['content'] as String? ?? '',
      kind: event['kind'] as int? ?? 1059,
      created: DateTime.fromMillisecondsSinceEpoch((event['created_at'] as int? ?? 0) * 1000),
    );

    try {
      await _isar.writeTxn(() async {
        final existing = await _isar.encryptedDmModels
            .where()
            .eventIdEqualTo(eventId)
            .findFirst();
        if (existing != null) return;
        await _isar.encryptedDmModels.put(model);
      });
    } catch (_) {
      // Duplicate write race from concurrent relay deliveries.
      return;
    }
  }

  Future<void> _storeIncomingKind0Profile(Map<String, dynamic> event) async {
    final pubkey = event['pubkey'] as String?;
    final createdAtSec = event['created_at'] as int?;
    if (pubkey == null || pubkey.isEmpty || createdAtSec == null) return;

    Map<String, dynamic> metadata;
    try {
      metadata = jsonDecode(event['content'] as String? ?? '') as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final incomingUpdatedAt = DateTime.fromMillisecondsSinceEpoch(createdAtSec * 1000);
    try {
      await _isar.writeTxn(() async {
        final existing = await _isar.profileModels
            .where()
            .pubkeyEqualTo(pubkey)
            .findFirst();
        if (existing != null && incomingUpdatedAt.isBefore(existing.updatedAt)) {
          return;
        }

        final model = existing ?? ProfileModel();
        model.pubkey = pubkey;
        model.name =
            metadata['display_name'] as String? ?? metadata['name'] as String?;
        model.username = metadata['name'] as String?;
        model.about = metadata['about'] as String?;
        model.avatarUrl = metadata['picture'] as String?;
        model.nip05 = metadata['nip05'] as String?;
        model.updatedAt = incomingUpdatedAt;
        model.lastSeenAt = existing?.lastSeenAt;

        await _isar.profileModels.put(model);

        final missing = await _isar.missingProfilePubkeyModels
            .where()
            .pubkeyEqualTo(pubkey)
            .findFirst();
        if (missing != null) {
          await _isar.missingProfilePubkeyModels.delete(missing.id);
        }
      });
    } catch (_) {
      // Duplicate upsert race from concurrent kind-0 deliveries.
      return;
    }
  }

  Future<void> _trackMissingProfilePubkey(Map<String, dynamic> event) async {
    final pubkey = event['pubkey'] as String?;
    if (pubkey == null || pubkey.isEmpty) return;

    final existingProfile = await _isar.profileModels
        .where()
        .pubkeyEqualTo(pubkey)
        .findFirst();
    if (existingProfile != null) return;
    try {
      await _isar.writeTxn(() async {
        // Keep check+insert in one write transaction to avoid races when
        // duplicate relay deliveries arrive concurrently.
        final existingMissing = await _isar.missingProfilePubkeyModels
            .where()
            .pubkeyEqualTo(pubkey)
            .findFirst();
        if (existingMissing != null) return;

        final row = MissingProfilePubkeyModel()
          ..pubkey = pubkey
          ..firstSeenAt = DateTime.now();
        await _isar.missingProfilePubkeyModels.put(row);
      });
    } catch (_) {
      // Best-effort tracking only. If another concurrent writer inserted the
      // same pubkey first (unique index), we can safely ignore.
    }
  }

  Future<void> _bumpFollowedReferenceCountsIfNeeded(
    Map<String, dynamic> event,
  ) async {
    final kind = event['kind'] as int?;
    if (kind != 1) return;

    final incomingId = event['id'] as String?;
    if (incomingId == null || incomingId.isEmpty) return;

    final eRefs = _extractEtagIdsFromEventMap(event);
    if (eRefs.isEmpty) return;

    final followed = await _isar.followedNoteModels.where().findAll();
    if (followed.isEmpty) return;

    final followedRoots = followed.map((f) => f.eventId).toSet();
    final refsToIncrement = <String>{};

    for (final ref in eRefs) {
      if (!followedRoots.contains(ref)) continue;
      if (ref == incomingId) continue;
      final dedupeKey = '$ref|$incomingId';
      if (_processedFollowReferenceBumps.contains(dedupeKey)) continue;
      _processedFollowReferenceBumps.add(dedupeKey);
      refsToIncrement.add(ref);
    }
    if (refsToIncrement.isEmpty) return;

    await _isar.writeTxn(() async {
      for (final ref in refsToIncrement) {
        final fresh = await _isar.followedNoteModels
            .where()
            .eventIdEqualTo(ref)
            .findFirst();
        if (fresh == null) continue;
        fresh.newReferenceCount = fresh.newReferenceCount + 1;
        await _isar.followedNoteModels.put(fresh);
      }
    });
  }

  List<String> _extractEtagIdsFromEventMap(Map<String, dynamic> event) {
    final rawTags = (event['tags'] as List<dynamic>? ?? []);
    final out = <String>[];
    for (final rawTag in rawTags) {
      if (rawTag is! List || rawTag.isEmpty) continue;
      final tagName = rawTag[0] as String?;
      if (tagName != 'e' || rawTag.length < 2) continue;
      final id = rawTag[1] as String?;
      if (id == null || id.isEmpty) continue;
      out.add(id);
    }
    return out;
  }

  NoteModel _parseNoteModel(Map<String, dynamic> event) {
    final rawTags = (event['tags'] as List<dynamic>? ?? []);

    String? rootEventId;
    String? replyToEventId;
    final eTagRefs = <String>[];
    final pTagRefs = <String>[];
    final tTags = <String>[];

    for (final rawTag in rawTags) {
      if (rawTag is! List || rawTag.isEmpty) continue;
      final tagName = rawTag[0] as String?;
      if (tagName == null || rawTag.length < 2) continue;

      switch (tagName) {
        case 'e':
          final tagId = rawTag[1] as String;
          eTagRefs.add(tagId);
          if (rawTag.length > 3) {
            final marker = rawTag[3] as String?;
            if (marker == 'root') rootEventId = tagId;
            if (marker == 'reply') replyToEventId = tagId;
          }
        case 'p':
          pTagRefs.add(rawTag[1] as String);
        case 't':
          tTags.add(rawTag[1] as String);
      }
    }

    final content = event['content'] as String? ?? '';
    final createdAtSec = event['created_at'] as int? ?? 0;

    return NoteModel(
      eventId: event['id'] as String,
      sig: event['sig'] as String? ?? '',
      authorPubkey: event['pubkey'] as String? ?? '',
      content: content,
      type: NoteType.text,
      eTagRefs: eTagRefs,
      rootEventId: rootEventId,
      replyToEventId: replyToEventId,
      pTagRefs: pTagRefs,
      tTags: tTags,
      created: DateTime.fromMillisecondsSinceEpoch(createdAtSec * 1000),
      isSeen: false,
    );
  }

  // ── Status tracking ────────────────────────────────────────────────────────

  void _updateStatus(RelayStatus status) {
    onStatusChanged?.call(status);
  }
}
