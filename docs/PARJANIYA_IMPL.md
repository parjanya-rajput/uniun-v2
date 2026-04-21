# What Parjaniya Built — Gateway + Channels

Simple explanation of what exists, how it connects, and what still needs to be built.

---

## Part 1 — The Gateway (Relay Sync Engine)

### The Big Idea

The app has **two Dart isolates** running at the same time:

```
Isolate 1 — Flutter UI
  reads and writes Isar normally

Isolate 2 — Gateway (Parjaniya's code)
  also has Isar open on the same file
  manages all WebSocket connections to relays
```

They never talk to each other directly. **Isar is the shared inbox/outbox between them.**

When the UI wants to send a note → it writes a row to `EventQueueModel` in Isar.  
The Gateway is watching Isar → it sees the new row → it sends it to the relay.  
When the relay sends a note back → Gateway writes it to `NoteModel` in Isar.  
Isar fires a watcher in the UI isolate → the feed updates automatically.

No `SendPort`. No `ReceivePort`. No polling. Just Isar watchers.

---

### Files

```
lib/gateway/
  gateway.dart                — app startup, spawns the isolate
  gateway_init_message.dart   — carries the Isar folder path into the isolate
  central_relay_manager.dart  — the orchestrator (one per app lifetime)
  websocket_service.dart      — one WebSocket connection per relay
```

---

### gateway.dart — How It Starts

```dart
// Called once at app launch (main.dart)
GatewayBootstrap.start()
  → Isolate.spawn(gatewayEntryPoint, GatewayInitMessage(isarDirectory: dir.path))
```

Inside the isolate:
1. Opens Isar at the same path as the UI isolate
2. Creates `CentralRelayManager(isar: isar)`
3. Calls `manager.start()`
4. The isolate stays alive forever (it holds active timers and stream subscriptions)

---

### central_relay_manager.dart — The Orchestrator

Think of this as the "boss" that manages all relay connections.

**On startup it does 4 things:**

1. **Reads all relays from `RelayModel`** (Isar). Creates one `WebSocketService` per relay. If no relays exist, it saves the default relay first.

2. **Watches `EventQueueModel`** — when the UI writes a new event to send, the watcher fires and tells all `WebSocketService`s to check the queue immediately (don't wait for next timer).

3. **Watches `RelayModel`** — when the UI adds or removes a relay at runtime, this watcher fires and syncs the services map (adds a new `WebSocketService` or removes the old one).

4. **Watches `FollowedNoteModel`** — when the user follows or unfollows a note, this watcher fires and tells each service to refresh its `#e` subscription filter.

**Every 5 minutes (cleanup timer):** deletes `EventQueueModel` rows that are older than 30 minutes (they've been sent already).

**Channel-specific relays (temporary services):**  
When a channel event (Kind 40–44) is queued, the manager checks `ChannelModel.relays` to see if this event needs to go to a specific relay URL beyond the main relays. If yes, it creates a temporary `WebSocketService` for that URL with a 5-minute auto-destroy timer.

---

### websocket_service.dart — One Connection Per Relay

Each `WebSocketService` manages one WebSocket URL. It handles both sending and receiving.

**Connection:**
- Connects on creation. If it fails or drops, reconnects with exponential backoff (1s, 2s, 4s, 8s... up to 60s max).

**On connect it immediately sends two subscriptions:**

```
REQ feed_notes      → {"kinds": [1]}
                       "give me all Kind 1 notes"

REQ followed_note_refs → {"kinds": [1], "#e": ["noteId1", "noteId2", ...]}
                          "give me notes that e-tag any of my followed notes"
```

**Sending (outbound queue):**
- Reads `EventQueueModel` rows where `id > _lastSentQueueId` (cursor-based).
- Sends one event at a time. Waits for `["OK", eventId, true]` from the relay before sending the next one.
- If the relay says OK → increments `sentCount` on the row, advances the cursor.
- If the relay rejects → still advances (don't retry forever).
- Channel events check `resolveTargets` — if this relay isn't the right one for this event, skips it.

**Receiving (inbound):**
- Handles `["EVENT", subId, {...}]` messages.
- Parses the Nostr event → builds a `NoteModel` → writes to Isar (idempotent — skips if eventId already exists).
- After storing, checks if any `e` tags in this event match followed notes → if yes, increments `FollowedNoteModel.newReferenceCount`.
- The Isar write automatically fires the feed watcher in the UI isolate → UI updates.

**NIP-10 parsing (done inside WebSocketService):**
```
["e", id, relay, "root"]   → NoteModel.rootEventId = id
["e", id, relay, "reply"]  → NoteModel.replyToEventId = id
["e", id, relay, "mention"] → NoteModel.eTagRefs += id
["p", pubkey, ...]          → NoteModel.pTagRefs += pubkey
["t", hashtag]              → NoteModel.tTags += hashtag
```

---

### What the Gateway Does NOT Do Yet

- Does **not** subscribe to channel messages (Kind 41/42). `SubscriptionRecordModel` exists in Isar but the Gateway doesn't read it yet to open live `REQ` filters for channels.
- Does **not** handle incoming Kind 0 (profiles), Kind 42 (channel messages), Kind 14 (DMs). The `_storeIncomingEvent` only handles Kind 1 right now.
- Does **not** subscribe to DMs (`{"kinds": [1059], "#p": [myPubkey]}`).

---

## Part 2 — Channels (NIP-28)

### What Was Built

The full data + domain + create UI layer for channels. **No channel list page or message feed page yet.**

---

### Data Models (Isar)

**`ChannelModel`** — stores one channel per row:
```
channelId         — the Kind 40 event id (this IS the channel forever)
creatorPubKey     — who made it
name, about, picture — channel info (can be updated by Kind 41)
relays            — list of relay URLs this channel lives on
createdAt         — when Kind 40 was created
updatedAt         — timestamp of last accepted Kind 41 (metadata update)
lastMetaEvent     — event id of last accepted Kind 41
lastReadEventId   — unread tracking checkpoint (same pattern as Vishnu feed)
lastReadAt        — unix timestamp of last read
```

**`ChannelMessageModel`** — stores one Kind 42 message per row:
```
eventId        — the message's Nostr event id
channelId      — which channel it belongs to (Kind 40 event id)
authorPubkey   — who sent it
content        — the message text
eTagRefs       — e-tag references
rootEventId    — the channelId (Kind 40 id is the "root" for Kind 42)
replyToEventId — if this message replies to another message in the channel
created        — timestamp
```

**`SubscriptionRecordModel`** — stores what channels the user is subscribed to:
```
channelId       — which channel
kinds           — [41, 42, 43, 44]  (channel meta + messages)
eTags           — [channelId]        (the #e filter)
lastUntilByRelay — Map<relayUrl, unixTimestamp>  (pagination cursor per relay)
enabled         — true/false
```
This is the "intent" record. The Gateway reads this (in future) to know which REQ filters to open.

---

### Domain Layer

**Entities (freezed, immutable):**
- `ChannelEntity` — mirrors `ChannelModel` fields
- `ChannelMessageEntity` — mirrors `ChannelMessageModel` fields
- `SubscriptionRecordEntity` — mirrors `SubscriptionRecordModel` fields

**Repository interfaces:**
- `ChannelRepository` — `saveChannel`, `updateChannelMetadata`, `getChannels`, `getChannelById`, `updateLastRead`
- `ChannelMessageRepository` — `saveMessage`, `getMessagesForChannel`, `getMessageByEventId`

**Repository implementations (both done):**
- `ChannelRepositoryImpl` — full Isar CRUD. Metadata update guards against out-of-order Kind 41s (only accepts newer timestamps).
- `ChannelMessageRepositoryImpl` — full Isar CRUD with pagination.

---

### Use Cases (all done)

| Use Case | What It Does |
|----------|-------------|
| `CreateChannelUseCase` | Builds + signs Kind 40 event → saves to `ChannelModel` → enqueues in `EventQueueModel` → saves `SubscriptionRecordEntity` |
| `CreateChannelMessageUseCase` | Builds + signs Kind 42 event → saves to `ChannelMessageModel` → enqueues in `EventQueueModel` |
| `SubscribeChannelUseCase` | Saves a `SubscriptionRecordEntity` for an existing channel (for channels you join, not create) |
| `GetChannelsUseCase` | Returns all channels from Isar |
| `GetChannelByIdUseCase` | Returns one channel by channelId |

---

### Create Channel Flow (Done — UI exists)

**Page:** `lib/channels/create/pages/create_channel_page.dart`

What the user sees:
1. Text field for Channel Name (3–30 chars)
2. Text field for About (theme/rules)
3. Text field for Picture URL (optional)
4. Relay picker — shows a checkbox dialog of available relays from `RelayModel` (fetched via `GetRelaysUseCase`)
5. "Create Channel" button

What happens on submit:
```
User taps "Create Channel"
  ↓
CreateChannelBloc.add(SubmitChannelEvent(...))
  ↓
Validates name length (3–30) and relay selection
  ↓
Gets active user (needs nsec for signing)
  ↓
CreateChannelUseCase.call(CreateChannelInput)
  ↓
  1. Signs Kind 40 event with user's private key
  2. channelId = kind40.id  (the event's id IS the channel id forever)
  3. Saves ChannelEntity to ChannelRepository → Isar
  4. Enqueues Kind 40 in EventQueueRepository → Isar
  5. Saves SubscriptionRecordEntity → Isar
  ↓
  Gateway sees new row in EventQueueModel → sends Kind 40 to relay
  ↓
Success → Navigator.pop(context)
```

The `BlocListener` shows a green snackbar on success, red snackbar on error.

---

## Part 3 — What Is NOT Built Yet

This is the clear picture of what needs to happen next:

### Gateway gaps

| What's missing | What needs to happen |
|---------------|---------------------|
| Channel message receiving | Gateway needs to read `SubscriptionRecordModel` rows and open `REQ {"kinds":[41,42],"#e":[channelId]}` for each enabled subscription |
| Profile / Kind 0 receiving | `_storeIncomingEvent` only handles Kind 1. Need Kind 0 handler to write `ProfileModel`. |
| DM receiving | Need `REQ {"kinds":[1059],"#p":[myPubkey]}` subscription + handler to decrypt and store |

### Channel UI gaps

| What's missing | Description |
|---------------|-------------|
| Channel list page | A page showing all channels the user has created or subscribed to |
| Channel detail / message feed | Scrollable list of Kind 42 messages for a channel, with reply support |
| Send message UI | Text input in channel detail page → calls `CreateChannelMessageUseCase` |
| Subscribe to existing channel | UI to discover and subscribe to a channel by ID or from a list |
| Unread badge | Channel shows unread count using `lastReadEventId` (the model field exists, just needs UI) |
| Drawer integration | Channel list in the app drawer (DrawerBloc currently has placeholder) |
| Kind 41 metadata update | UI for channel creator to update name/about/picture |

### DM gaps

Everything — no DM UI, no DM bloc, no DM receive handler in Gateway.

---

## Summary: What Parjaniya Built

```
✅  Gateway isolate bootstrap (gateway.dart)
✅  CentralRelayManager — Isar watcher orchestration
✅  WebSocketService — connect, send queue (cursor), receive Kind 1, NIP-10 parse
✅  Followed note reference count bump on incoming events
✅  ChannelModel + ChannelMessageModel + SubscriptionRecordModel (Isar)
✅  ChannelEntity + ChannelMessageEntity + SubscriptionRecordEntity (domain)
✅  ChannelRepository + ChannelMessageRepository (interface + impl)
✅  CreateChannelUseCase (signs Kind 40, enqueues, saves subscription)
✅  CreateChannelMessageUseCase (signs Kind 42, enqueues, saves locally)
✅  SubscribeChannelUseCase + GetChannelsUseCase + GetChannelByIdUseCase
✅  CreateChannelBloc + CreateChannelPage (full create UI)

🔲  Gateway: read SubscriptionRecordModel and open channel REQ filters
🔲  Gateway: handle incoming Kind 42 → ChannelMessageModel
🔲  Gateway: handle incoming Kind 0 → ProfileModel
🔲  Channel list page
🔲  Channel detail / message feed page
🔲  Drawer integration for channels
🔲  DM everything
```
