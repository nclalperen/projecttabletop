# Multiplayer Plan (EOS + EOSG) — Okey 101 (Godot 4.6)

This is the **implementation-ready multiplayer spec** for a 4‑player, turn‑based **Okey 101 (Yüzbir)** game using:

- **Epic Online Services (EOS)** for identity + lobbies (matchmaking/invites/party state)
- **EOSG** (Godot 4.2+ GDExtension wrapper) for EOS integration, including **Lobbies** and **P2P Multiplayer**

> Decisions locked (from you):
> 1) **Creator is Host**
> 2) **Bot takeover until rejoin**
> 3) Transport clarified below (we’ll use **EOS P2P packets**)
> 4) Matchmaking via **Lobbies** (no queue service in v1)

---

## 0) Glossary (so we don’t talk past each other)

- **Lobby**: a room managed by EOS (roster, attributes, invites, ready state). Persistent connection and real-time attribute updates.
- **P2P transport**: sending packets directly between players (host ↔ clients) via EOS P2P. This is for gameplay messages (turn actions / state updates).
- **Host-authoritative**: the host validates actions and is the single source of truth for the match state.

---

## 1) Topology (v1): Lobby + Host-authoritative “Listen Host”

### Why this fits Okey 101
Okey 101 is low bandwidth and turn-based. A host-authoritative model is simple, robust, and easy to debug:

- Lobby handles: finding players, inviting friends, seat assignment, ready checks
- Host handles: rules validation, turn timer, canonical state, scoring
- Clients handle: UI + sending action requests + rendering confirmed state

---

## 2) EOS / EOSG Services We Use

### Identity / Player IDs
- Use EOS login (via EOSG) to obtain a stable **Product User ID (PUID)**.

### Lobbies (matchmaking + coordination)
Used for:
- Create/join/leave
- Private friend lobbies (invite-only)
- Public lobbies (search by attributes)
- Seat assignment & ready check
- Store “match metadata” (ruleset id/hash, phase, host PUID)

### P2P Multiplayer (gameplay transport)
Used for:
- Host ↔ Client gameplay messaging:
  - ActionRequest → ActionResult
  - Snapshot/Delta sync
  - Ping/Pong (latency/debug)
- Reconnect resync (send snapshot on rejoin)

EOSG explicitly lists and documents **Multiplayer (P2P)** plus lobby/sessions support, and ships demos. (See EOSG docs/repo.)

---

## 3) The thing you didn’t understand (Transport options)

When we said “Transport: EOS P2P vs lobby relay”, this is what it means:

### Option A — EOS P2P packets (recommended, what we’ll implement)
- Pros: designed for sending game messages; scalable; doesn’t abuse lobby updates
- Cons: you implement a small protocol (seq/ack) and reconnection logic

### Option B — “Lobby relay”
- You encode gameplay messages into lobby/member attributes (or lobby notifications).
- Pros: easiest to prototype
- Cons: lobby attributes are not meant for frequent messaging; you’ll hit limits/latency and it becomes messy.

✅ **We will do A** (EOS P2P packets), and we’ll only use lobby attributes for **presence/phase/ready/seat**.

---

## 4) Match Flow (State Machine)

### 4.1 Login
1. Initialize EOS platform (EOSG)
2. Login (dev auth during development; production auth later)
3. Get `local_puid`

### 4.2 Lobby (Public “Quick Match”)
1. Search for lobbies with:
   - `ruleset_id`
   - `version`
   - `phase == FILLING`
   - `open_slots >= 1`
2. If found: join; else: create public lobby
3. When 4 players present:
   - Creator becomes **Host**
   - Deterministic seat assignment (see below)
4. Ready check (each member toggles `ready=true`)
5. When all ready: Host sets `phase=MATCH_STARTING`

### 4.3 Lobby (Private / Friends)
- Creator creates `privacy=INVITE_ONLY`
- Invite friends (EOS overlay / in-game invite code)
- Same seat + ready + start sequence

---

## 5) Seat Assignment & Host

### Host
- **Lobby creator is host** (locked)

### Seats
To keep it deterministic across all clients:
- Sort lobby members by `(join_time, puid)` and assign seats `0..3`.
- Store each member’s `seat` as a member attribute so UI can show it.

---

## 6) Gameplay Transport Protocol (P2P)

### 6.1 Core principle: actions, not replication
We will not stream transforms or per-frame updates.
We only send:
- Action requests
- Action results + state updates

### 6.2 Message types
Use JSON for v1 (easy), switch to binary later if you want.

**Client → Host**
- `HELLO { match_id, puid, client_version }`
- `ACTION_REQUEST { seq, turn_id, action, payload }`
- `PING { t_client_ms }`
- `REJOIN_REQUEST { match_id, last_turn_id_seen }`

**Host → Client(s)**
- `WELCOME { match_id, host_puid, ruleset_id, seats, match_seed }`
- `ACTION_RESULT { seq, ok, error_code?, error_detail? }`
- `STATE_SNAPSHOT { turn_id, state }`
- `STATE_DELTA { turn_id, diff }` (optional; snapshot-only is fine for v1)
- `PONG { t_client_ms, t_host_ms }`
- `REJOIN_SNAPSHOT { turn_id, state }`

### 6.3 Ordering / Idempotency
- Each client uses a monotonically increasing `seq`.
- Host tracks `last_seq_by_puid`; rejects duplicates and out-of-order if needed.
- Host rejects any action not matching `current_turn_seat`.

### 6.4 Reliability
Turn actions must be reliable.
Implementation options:
- If EOSG P2P channel supports reliable delivery, use it.
- If not, implement ACK/RESEND:
  - Host resends last `STATE_*` until it receives `STATE_ACK { turn_id }`.

---

## 7) Reconnects, Dropouts, Bot Takeover (locked)

### 7.1 Reconnect window
- On disconnect: mark player `status=DISCONNECTED` in lobby member attributes.
- Allow rejoin for `REJOIN_WINDOW_SEC` (e.g. 90s / configurable).
- On rejoin: host sends `REJOIN_SNAPSHOT`.

### 7.2 Bot takeover until rejoin
- If a player disconnects, a bot plays their seat.
- If they rejoin within the window:
  - bot stops
  - player resumes next time it becomes their turn (or immediately if desired)

### 7.3 If they never return
Choose one:
- Keep bot for the remainder of the match (recommended for casual)
- Or forfeit seat and compute penalties accordingly

---

## 8) Authoritative Timer
- Host owns the countdown.
- Clients display timer based on host timestamps.
- On timeout:
  - host executes deterministic fallback:
    - bot chooses a legal move, or
    - auto-discard (if legal), or
    - fold/forfeit (not recommended for casual)

---

## 9) Anti-cheat / Trust Model (pragmatic)

Host can theoretically cheat (because host is authoritative).
For casual v1:
- Accept this risk
- Harden against “client cheating” by validating every action on host

If you later want stronger fairness:
- commit–reveal seed protocol for shuffling, or
- dedicated server (Sessions)

---

## 10) Lobby Attributes (what we store in EOS lobby)

### Lobby attributes (public searchable)
- `ruleset_id` (string)
- `version` (string)
- `phase` = `FILLING | READY_CHECK | MATCH_STARTING | IN_MATCH | POST_MATCH`
- `open_slots` (int)

### Lobby attributes (not necessarily searchable)
- `host_puid` (string)
- `match_id` (string)
- `ruleset_hash` (string)

### Member attributes
- `seat` (0..3)
- `ready` (bool)
- `status` = `OK | DISCONNECTED | BOT_ACTIVE`
- `platform` = `pc | android | ios`

---

## 11) Godot Module Layout (recommended)

- `res://net/OnlineServiceEOS.gd`  
  EOS init, login/logout, exposes “online state”.

- `res://net/LobbyServiceEOS.gd`  
  Create/search/join/leave; maintains lobby model; emits signals for UI.

- `res://net/P2PTransportEOS.gd`  
  Send/recv packets; reliability wrapper (ACK/RESEND if needed).

- `res://net/Protocol.gd`  
  Encode/decode messages + schema versioning.

- `res://net/HostMatchController.gd`  
  Host-only: rules engine, action validation, timer, bot takeover, broadcasting state.

- `res://net/ClientMatchController.gd`  
  Client-only: UI hooks, submit actions, apply snapshots/deltas.

---

## 12) Implementation Backlog (in order)

### Milestone A — Online lobby
- [ ] EOS init + login
- [ ] Create lobby / join lobby / leave lobby
- [ ] Show roster & seats
- [ ] Ready toggle + `phase` transitions
- [ ] Creator host election (fixed)

### Milestone B — P2P transport
- [ ] Host opens P2P endpoint
- [ ] Clients connect to host PUID
- [ ] HELLO/WELCOME handshake
- [ ] Ping/Pong debug overlay

### Milestone C — Match start + resync
- [ ] match_id + match_seed assignment
- [ ] initial STATE_SNAPSHOT broadcast
- [ ] rejoin snapshot flow

### Milestone D — Turn actions
- [ ] ACTION_REQUEST validation on host
- [ ] broadcast ACTION_RESULT + snapshot/delta
- [ ] authoritative timer
- [ ] bot takeover on disconnect

### Milestone E — Polish
- [ ] Invite-only lobby UX
- [ ] reconnect UI
- [ ] crash recovery: host rehost lobby (optional)
- [ ] telemetry (disconnect rate, timeouts)

---

## 13) Prompt-ready tasks (copy/paste)

### 13.1 EOS lobby wrapper
“Write `LobbyServiceEOS.gd` for Godot 4.6 using EOSG that can create/search/join/leave lobbies, set lobby attributes (`phase`, `ruleset_id`, `host_puid`), set member attrs (`seat`, `ready`), and emit `lobby_updated(lobby_model)`.”

### 13.2 P2P transport
“Write `P2PTransportEOS.gd` using EOSG P2P APIs that can send/receive JSON messages, with optional ACK/RESEND reliability for snapshots.”

### 13.3 Host authoritative controller
“Write `HostMatchController.gd` that receives `ACTION_REQUEST`, validates via my rules engine, advances turn, and broadcasts `STATE_SNAPSHOT`.”

