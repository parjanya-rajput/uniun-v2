import 'dart:async';

import 'package:isar_community/isar.dart';
import 'package:uniun/data/models/event_queue_model.dart';
import 'package:uniun/data/models/followed_note_model.dart';
import 'package:uniun/data/models/relay_model.dart';
import 'package:uniun/gateway/websocket_service.dart';

/// Orchestrates all relay connections inside the Gateway isolate.
///
/// Responsibilities:
///  1. **Isar watcher on [EventQueueModel]** — when a new queue row appears,
///     notify all [WebSocketService]s so they can send immediately.
///  2. **Isar watcher on [RelayModel]** — when Isolate 1 adds or removes a
///     relay at runtime, sync the [_services] map accordingly.
///  3. **Isar watcher on [FollowedNoteModel]** — refresh `#e` [REQ] filters on
///     all [WebSocketService]s when the user follows/unfollows notes.
///  4. **Dequeue timer** — every 5 minutes, delete queue entries that have
///     been sent by every active write relay AND are older than 30 minutes.
///
/// The Gateway isolate stays alive as long as [CentralRelayManager] holds
/// active timers and stream subscriptions.
class CentralRelayManager {
  final Isar _isar;

  /// One [WebSocketService] per relay URL.
  final Map<String, WebSocketService> _services = {};

  Timer? _dequeueTimer;
  StreamSubscription<void>? _queueWatcher;
  StreamSubscription<void>? _relayWatcher;
  StreamSubscription<void>? _followedNotesWatcher;

  CentralRelayManager({required Isar isar}) : _isar = isar;

  // ── Startup ────────────────────────────────────────────────────────────────

  Future<void> start() async {
    // 1. Spin up one WebSocketService per persisted relay.
    final relays = await _isar.relayModels.where().findAll();
    for (final relay in relays) {
      _addService(relay.url, read: relay.read, write: relay.write, fromTail: false);
    }

    // 2. Watch EventQueueModel so services send new items immediately.
    _queueWatcher = _isar.eventQueueModels.watchLazy().listen((_) {
      for (final svc in _services.values) {
        svc.onNewQueueItem();
      }
    });

    // 3. Watch RelayModel for runtime add/remove from Isolate 1.
    _relayWatcher = _isar.relayModels.watchLazy().listen((_) {
      _syncRelayServices();
    });

    _followedNotesWatcher = _isar.followedNoteModels.watchLazy().listen((_) {
      for (final svc in _services.values) {
        svc.onFollowedNotesChanged();
      }
    });

    // 4. Start dequeue cleanup timer.
    _dequeueTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _runDequeuePass();
    });
  }

  // ── Dequeue (timer callback) ───────────────────────────────────────────────

  Future<void> _runDequeuePass() async {
    final activeWriteCount =
        _services.values.where((s) => s.isConnected && s.write).length;
    if (activeWriteCount == 0) return;

    final threshold = DateTime.now().subtract(const Duration(minutes: 30));

    // Dequeue if: sentCount >= every active write relay AND older than 30 min.
    final expired = await _isar.eventQueueModels
        .filter()
        .sentCountGreaterThan(activeWriteCount - 1)
        .enqueuedAtLessThan(threshold)
        .findAll();

    if (expired.isEmpty) return;

    await _isar.writeTxn(() async {
      await _isar.eventQueueModels
          .deleteAll(expired.map((e) => e.id).toList());
    });
  }

  // ── Relay service management ───────────────────────────────────────────────

  /// Syncs [_services] with current [RelayModel] rows after a watcher fire.
  Future<void> _syncRelayServices() async {
    final current = await _isar.relayModels.where().findAll();
    final currentUrls = current.map((r) => r.url).toSet();
    final serviceUrls = Set<String>.from(_services.keys);

    // Add services for newly persisted relays.
    for (final relay in current) {
      if (!serviceUrls.contains(relay.url)) {
        // New relay starts from the current queue tail (only new events).
        _addService(relay.url, read: relay.read, write: relay.write, fromTail: true);
      }
    }

    // Remove services for deleted relays.
    for (final url in serviceUrls) {
      if (!currentUrls.contains(url)) {
        _services[url]?.disconnect();
        _services.remove(url);
      }
    }
  }

  Future<void> _addService(
    String url, {
    required bool read,
    required bool write,
    required bool fromTail,
  }) async {
    int startId = 0;
    if (fromTail) {
      // New relay added at runtime — start from the current queue tail so it
      // only picks up events published after it was added.
      // anyId() returns items in ascending id order; the last item has the max id.
      final all = await _isar.eventQueueModels.where().anyId().findAll();
      startId = all.isEmpty ? 0 : all.last.id;
    }

    final svc = WebSocketService(
      url: url,
      read: read,
      write: write,
      isar: _isar,
      startFromQueueId: startId,
    );
    _services[url] = svc;
    svc.connect();
  }

  // ── Shutdown ───────────────────────────────────────────────────────────────

  void stop() {
    _queueWatcher?.cancel();
    _relayWatcher?.cancel();
    _followedNotesWatcher?.cancel();
    _dequeueTimer?.cancel();
    for (final svc in _services.values) {
      svc.disconnect();
    }
    _services.clear();
  }
}
