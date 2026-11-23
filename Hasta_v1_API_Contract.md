# Hasta v1.0.0 — API & Realtime Contract

Companion to `Hasta_v1_Master_PRD.md`. All paths are prefixed `/v1`. All request/response bodies are JSON. All timestamps are ISO-8601 UTC (`2026-11-23T09:30:00Z`). All ids are UUIDv7 strings. Enum literals are `snake_case` and identical in DB, API, and Dart.

## 0. Conventions

| Item | Rule |
| --- | --- |
| Auth | `Authorization: Bearer <access_token>` (JWT, 15 min). Refresh via `POST /v1/auth/refresh`. |
| Idempotency | Every state-changing POST/PATCH/DELETE accepts `Idempotency-Key: <uuidv7>`. Replay returns the stored body + `Idempotent-Replayed: true`. Keys retained 7 days. |
| Correlation | `X-Request-Id` echoed in every response and present in all logs. |
| Pagination | Cursor-based: `?cursor=<opaque>&limit=20` → response contains `next_cursor` (null when exhausted). |
| Rate limits | `429` + `Retry-After: <seconds>` + body `{code:"rate_limited"}`. |
| Errors | Uniform envelope (below). Never leak stack traces or internal ids. |
| Localisation | `Accept-Language: my | en` (default `my`). All server-provided user-facing copy is a key resolved client-side; only error codes come from the API. |

**Error envelope**

```json
{
  "error": {
    "code": "opener_limit",
    "message_key": "dating.openerLimit",
    "status": 429,
    "request_id": "018f6c2a-7b41-7a2e-9c31-2f6c1d5b9a11",
    "details": { "remaining": 0, "cleared_when": "counterparty_replies" },
    "retry_after_seconds": null
  }
}
```

Standard codes: `unauthenticated` · `forbidden` · `not_found` · `validation_failed` · `rate_limited` · `idempotency_conflict` · `device_cooldown` · `guest_exists_on_target` · `token_expired` · `token_used` · `identity_in_use` · `google_email_unverified` · `identity_required` · `opener_limit` · `chat_closed` · `chat_dormant` · `under_18` · `upload_too_large` · `nsfw_blocked` · `store_receipt_invalid` · `subscription_other_account` · `offline_only_online_action`.

---

## 1. Auth & Identity

### 1.1 `POST /v1/auth/device/register` — public
Registers the device and returns the hash. The raw id crosses the wire once, over TLS, and is **never persisted**.

Request
```json
{ "raw_device_id": "android-id-or-idfv", "platform": "android", "app_version": "1.0.0", "os_version": "14" }
```
Response `200`
```json
{ "device_hash": "9f2c…", "device_token": "dt_…", "platform": "android", "registered_at": "2026-11-23T09:30:00Z" }
```

### 1.2 `POST /v1/auth/guest` — public, rate limited (3 / device / hour)
Creates or resumes the guest account for this device.

Request
```json
{ "device_token": "dt_…", "locale": "my" }
```
Response `200`
```json
{
  "access_token": "eyJ…", "refresh_token": "rt_…", "expires_in": 900,
  "account": { "id": "018f…", "status": "active", "is_guest": true, "display_name": null, "username": null, "created_at": "2026-11-23T09:30:00Z" },
  "device_binding": { "id": "018f…", "role": "primary", "device_hash": "9f2c…", "bound_at": "2026-11-23T09:30:00Z" },
  "is_new_account": true
}
```
Errors: `429 device_cooldown` (`details.retry_after_days`), `403 validation_failed`, `429 rate_limited`.

### 1.3 `POST /v1/auth/refresh` — public
Request `{ "refresh_token": "rt_…", "device_token": "dt_…" }` → `200` new pair (old refresh invalidated). Reuse of a rotated token ⇒ `401 unauthenticated` and the whole token family is revoked.

### 1.4 `POST /v1/auth/logout` — auth
`{ "device_token": "dt_…", "everywhere": false }` → `204`.

### 1.5 `GET /v1/me` — auth
```json
{
  "account": { "id": "018f…", "status": "active", "is_guest": true, "created_at": "…" },
  "profile": { "display_name": "…", "username": "…", "bio": "…", "avatar_url": "…", "birth_date": "1998-04-02" },
  "identities": [ { "provider": "google", "email_masked": "h***@gmail.com", "linked_at": "…" } ],
  "entitlements": [ { "store": "google", "product_id": "hasta.premium.monthly", "status": "active", "expires_at": "…" } ],
  "flags": { "dating_enabled": false, "dating_paused": false, "premium": false, "test_mode_panel": false }
}
```

### 1.6 Gmail linking

`POST /v1/auth/identities/google/link:start` — auth
→ `200 { "state": "…", "nonce": "…", "scopes": ["openid","email","profile"], "auth_url": "https://accounts.google.com/o/oauth2/v2/auth?…", "expires_in": 300 }`

`POST /v1/auth/identities/google/link:complete` — auth
Request `{ "state": "…", "code": "…" }` — the server exchanges `code` (PKCE) and verifies the id_token itself. A client `id_token` (or any unknown field) → `400 validation_failed`. Device binding comes from the device-bound session (T46). The state is single-use, expires after 300 s, and is bound to the account and device that started it.
→ `200 { "identity": { "provider": "google", "email_masked": "h***@gmail.com", "linked_at": "…" }, "account": { "id": "018f…", "is_guest": false }, "unlocked": ["premium_purchase","restore_purchases","device_recovery"] }`
Errors: `409 identity_in_use`, `422 google_email_unverified`, `401 token_expired` (state), `403 store_receipt_invalid`→n/a, `400 validation_failed`.

`GET /v1/auth/identities/google/link:callback` — public; the HTTPS `redirect_uri` registered with Google (web client, SPEC §19).
→ `302 Location: hasta://link/google?code=…&state=…` (or `?error=…&state=…` on cancel). It forwards only `code`, `error` and `state`.

`DELETE /v1/auth/identities/google` — auth
→ `204`, or `409 {code:"recovery_required"}` when it is the only recovery method. Unlinking sets `is_guest=true` only when no Google/Apple identity remains, which `recovery_required` currently makes unreachable; existing paid entitlement survives to expiry (no refund).

> **Not implemented in v1:** `POST /v1/auth/google/signin`, `POST /v1/auth/apple/signin`, any `id_token`-only login, any OTP/SMS route. CI gate T37 fails the build if any appears.

### 1.7 Recovery (old device lost)

`POST /v1/auth/recover:start` — public → `{ "state":"…","nonce":"…","auth_url":"…" }` (Google only in v1)
`POST /v1/auth/recover:complete` — public → same shape as guest response, plus `"revoked_other_sessions": 3`. If no account matches the identity ⇒ `404 not_found` with copy guiding to guest creation.

### 1.8 QR device transfer

| Endpoint | Auth | Body | Result |
| --- | --- | --- | --- |
| `POST /v1/auth/transfer/start` | auth (old device) | `{}` | `200 { "transfer_id":"…", "qr_payload":"{\"v\":1,\"token\":\"tt_…\"}", "expires_at":"…(+120s)" }` — rate limit 2 / 3 min |
| `POST /v1/auth/transfer/redeem` | auth (new device) | `{ "token":"tt_…", "device_token":"dt_…" }` | `200 { "status":"awaiting_confirmation", "expires_at":"…" }` |
| `POST /v1/auth/transfer/confirm` | auth (old device) | `{ "transfer_id":"…", "biometric_verified": true }` | `200 { "status":"confirmed", "new_device_bound_at":"…", "revoked_sessions": 4 }` |
| `POST /v1/auth/transfer/reject` | auth (old device) | `{ "transfer_id":"…" }` | `200 { "status":"rejected" }` |
| `GET /v1/auth/transfer/:id` | auth | — | `200 { "status":"pending|awaiting_confirmation|confirmed|rejected|expired" }` |

Errors: `410 token_expired`, `409 token_used`, `409 guest_exists_on_target`, `403 biometric_required`.

### 1.9 Sessions & devices
`GET /v1/auth/sessions` → list `{id, device_hash_short, platform, created_at, last_seen_at, current}`.
`DELETE /v1/auth/sessions/:id` · `DELETE /v1/auth/sessions?others=true` → `204`.

### 1.10 Account lifecycle
`POST /v1/account/deactivate` — auth, online only → `200 { "status":"paused", "reactivate_by":"…" }`
`DELETE /v1/account` — auth, online only, requires `Confirm-Deletion: <typed phrase hash>` → `202 { "status":"deleted", "purge_at":"…(+30d)", "cooldown_until":"…(+30d)", "store_subscription_notice_key":"billing.cancelInStore", "drive_backup_action":"deleted|user_action_required" }`

---

## 2. Social

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| GET/PATCH | `/v1/profile` | self | read/update own profile (field-level HLC merge) |
| GET | `/v1/users/:id/profile` | any | public view — **never contains dating fields** |
| POST | `/v1/friends/requests` | auth | `{ "to_user_id":"…" }` → `201` |
| PATCH | `/v1/friends/requests/:id` | auth | `{ "action":"accept|decline" }` |
| GET | `/v1/friends?cursor=&limit=` | auth | list |
| DELETE | `/v1/friends/:userId` | auth | unfriend |
| POST | `/v1/posts` | auth | create (idempotent) |
| GET | `/v1/feed?cursor=&filter=all|friends|groups|pages` | auth | ranked feed, page size 20 |
| GET | `/v1/posts/:id` | auth | detail (audience-checked) |
| PATCH/DELETE | `/v1/posts/:id` | author | edit within 15 min / delete (`scope=me|everyone`) |
| PUT/DELETE | `/v1/posts/:id/reactions` | auth | `{ "kind":"like|love|care|haha|wow|sad" }` |
| GET/POST | `/v1/posts/:id/comments` | auth | depth ≤ 2 |
| GET/POST | `/v1/groups`, `/v1/groups/:id/members` | auth | groups |
| GET/POST | `/v1/pages`, `/v1/pages/:id/posts` | auth | pages |
| GET | `/v1/search?q=&type=users|posts|groups|pages&cursor=` | auth | Meilisearch-backed; offline falls back to a bundled index |
| GET/PATCH | `/v1/notifications`, `/v1/notifications/read` | auth | **social actions only** |
| POST/DELETE | `/v1/blocks` | auth | `{ "user_id":"…", "scope":"all|social|dating" }` |
| POST | `/v1/reports` | auth | see §6 |

**`POST /v1/posts` request**
```json
{
  "audience": "friends",
  "container_id": null,
  "body": "မင်္ဂလာပါ",
  "media": [ { "key": "media/018f….webp", "kind": "photo", "width": 1080, "height": 1350, "blurhash": "LKO2?l%2…" } ]
}
```
**Feed item response (abridged)**
```json
{
  "id": "018f…", "author": { "id":"018f…", "display_name":"မိုး", "avatar_url":"…", "is_page": false },
  "audience": "friends", "body": "…", "media": [ { "url":"…", "thumb_url":"…", "aspect":"4:5", "blurhash":"…" } ],
  "counts": { "reactions": 12, "comments": 3, "shares": 1 },
  "my_reaction": "like", "created_at": "…", "edited_at": null,
  "ranking_debug": null
}
```
`ranking_debug` is populated **only** in `dev`/`test` builds.

---

## 3. Chat engine

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/v1/chats?folder=all|private|group|channel|dating|unread|pinned|archived&cursor=` | auth | chat list; dating folder only when dating is on |
| POST | `/v1/chats` | auth | `{ "type":"private|group|channel", "member_ids":[…] }` (dating chats are created **only** by the match flow) |
| GET | `/v1/chats/:id/messages?before_seq=&limit=50` | member | history |
| POST | `/v1/chats/:id/messages` | member | send (idempotent) |
| PATCH | `/v1/chats/:id/messages/:msgId` | author | edit ≤ 15 min |
| DELETE | `/v1/chats/:id/messages/:msgId?scope=me|everyone` | author | delete; dating chat accepts `everyone` only |
| POST | `/v1/chats/:id/read` | member | `{ "up_to_seq": 128 }` → emits read receipts if enabled |
| PATCH | `/v1/chats/:id/settings` | member | mute, pin, folder, read-receipt toggle |
| POST | `/v1/media/uploads:init` | auth | `{ "kind":"photo|video|voice|file", "size":1234, "mime":"image/webp", "checksum_sha256":"…" }` → `{ "upload_id":"…", "parts":[{ "index":1, "url":"…" }], "max_size":20971520 }` |
| POST | `/v1/media/uploads/:id/complete` | auth | `{ "etags":[…] }` → `{ "key":"…", "thumb_url":"…", "blurhash":"…", "nsfw": { "score":0.02, "action":"pass" } }` |

**Send message request**
```json
{ "client_msg_id": "018f…", "kind": "text", "body": "မင်္ဂလာပါ", "reply_to": null }
```
**Send message response**
```json
{ "id":"018f…", "chat_id":"018f…", "seq":129, "status":"sent", "created_at":"…" }
```
Dating-chat failures: `429 opener_limit` (`details.remaining`), `403 chat_closed` (unmatched), `423 chat_dormant` (reopen required), `403 forbidden` (not matched).

---

## 4. Sync

`GET /v1/sync/changes?cursor=<opaque>&entities=messages,chats,profiles,posts,notifications,dating&limit=500`

```json
{
  "cursor": "eyJzZXEiOjEyOX0",
  "has_more": false,
  "server_time": "2026-11-23T09:30:00Z",
  "changes": {
    "messages": [ { "op":"upsert", "data": { "id":"…", "chat_id":"…", "seq":129, "kind":"text", "body":"…", "status":"delivered" } } ],
    "chats":    [ { "op":"patch",  "id":"018f…", "fields": { "last_seq":129, "unread":2 } } ],
    "profiles": [ { "op":"patch",  "id":"018f…", "fields": { "bio":"…" }, "hlc": 1732353000123 } ],
    "dating":   [ { "op":"upsert", "data": { "match_id":"…", "state":"matched" } } ],
    "deletions":[ { "entity":"messages", "id":"018f…", "scope":"everyone" } ]
  }
}
```
Rules: field-level patches only; `hlc` present on every mergeable entity; clients must apply changes inside a Drift transaction and persist `cursor` atomically with the data.

`POST /v1/sync/push` (outbox drain) — accepts a batch (≤ 50 ops) of `{ entity, op, idempotency_key, payload, hlc }`, returns per-op results `{ key, status:"applied|duplicate|rejected", server_hlc }`.

---

## 5. Dating

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| GET/PUT | `/v1/dating/profile` | self | separate entity; PUT is field-level HLC merge |
| POST | `/v1/dating/enable` | self | requires age ≥ 18 → else `403 under_18` |
| POST | `/v1/dating/pause` | self | `{ "paused": true }`; propagates ≤ 60 s |
| POST | `/v1/dating/verification` | self | selfie upload → `verification: pending|verified|rejected`; images stored on the restricted path |
| GET | `/v1/dating/cards?limit=10` | self | candidate stack (filters + scoring applied server-side) |
| POST | `/v1/dating/swipes` | self | `{ "to_user_id":"…", "kind":"like|pass|super_like|undo" }` (idempotent) |
| GET | `/v1/dating/likes/incoming?cursor=` | self | Likes You |
| GET | `/v1/dating/matches?cursor=` | self | Matches |
| POST | `/v1/dating/matches/:id/unmatch` | self | closes chat both sides, sets `retain_until = now()+30d` |
| POST | `/v1/dating/matches/:id/reopen` | self | reopen a dormant chat |
| GET | `/v1/dating/radar?radius_km=5` | self | **banded distance only** |
| PATCH | `/v1/dating/settings` | self | filters, radar visibility, show distance, read receipts, notifications |
| POST | `/v1/dating/profile/reset` | self | destructive, confirm required |

**`GET /v1/dating/cards` response**
```json
{
  "cards": [
    {
      "user_id": "018f…", "display_name": "…", "age": 26,
      "photos": [ { "url":"…", "aspect":"4:5", "blurhash":"…" } ],
      "bio": "…", "interests": ["ခရီးသွား", "ကော်ဖီ"], "occupation": null,
      "verified": true, "distance_band": "within_1km", "prompt": { "q":"အကြိုက်ဆုံး ခရီးစဉ်", "a":"…" }
    }
  ],
  "quota": { "super_like_remaining": 1, "undo_remaining": 5 },
  "next_cursor": null
}
```
`distance_band ∈ { "within_1km", "~3km", "~5km", "~10km", "hidden" }`. **No `lat`, `lon`, or metre-precision distance may appear in any response** (test T12).

**`POST /v1/dating/swipes` response**
```json
{ "result":"like_recorded", "matched": true, "match": { "id":"018f…", "chat_id":"018f…", "matched_at":"…" } }
```
On match the server also emits `match.created` (WS) and a privacy-safe push.

**`GET /v1/dating/radar` response**
```json
{ "updated_at":"…", "radius_km":5, "people":[ { "token":"p_…", "distance_band":"~3km", "avatar_blurred_url":"…", "verified":true } ], "cached": false }
```
Offline: `200` with the last cached payload and `"cached": true, "cached_at": "…"`.

---

## 6. Safety & moderation

`POST /v1/reports`
```json
{ "target_type":"message", "target_id":"018f…", "reason":"money_request", "detail":"…", "context": { "chat_id":"018f…" } }
```
→ `201 { "report_id":"…", "severity":"high", "status":"open", "sla_due_at":"…" }`

`reason ∈ { harassment, spam, scam, money_request, nudity, child_safety, violence, extortion, fake_profile, other }`. `child_safety | violence | extortion` ⇒ `severity=critical`, human moderator within 24 h. Evidence snapshot is written to the vault automatically.

Moderator/legal endpoints (`/v1/admin/**`) require role `moderator` or `legal`; every vault read writes an access-log entry; non-authorized access ⇒ `403` (T34).

---

## 7. Billing

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/v1/billing/products` | auth | catalogue with localised prices |
| POST | `/v1/billing/purchase:intent` | auth | `{ "product_id":"…", "store":"google|apple" }` → `{ "client_account_token":"<account uuid>" }` (use as `obfuscatedAccountId` / `appAccountToken`). Guests ⇒ `403 identity_required` (T21). Online only. |
| POST | `/v1/billing/purchase:verify` | auth | `{ "store":"…", "receipt":"…|purchase_token":"…", "product_id":"…" }` → server verifies with the store API → `{ "entitlement": { "status":"active", "expires_at":"…" } }` |
| POST | `/v1/billing/restore` | auth | online only → `{ "restored": 1, "entitlements":[…], "rejected":[{ "reason":"subscription_other_account" }] }` |
| POST | `/v1/billing/webhooks/apple` · `/google` | signed | notifications → update `status`, `last_verified_at`; refunds ⇒ `revoked` (T24) |

State machine: `pending → active → (grace → active|expired) | revoked`. Direct `pending → revoked` transitions are forbidden except on a verified refund/fraud signal.

---

## 8. WebSocket (Socket.IO) contract

Namespace `/rt`. Auth: `auth: { token: "<access_token>", device_token: "dt_…" }`. Rooms: `user:{accountId}`, `chat:{chatId}`, `device:{deviceHash}`. Reconnect: exponential backoff with jitter (1 s → 60 s cap) + immediate retry on connectivity change; after reconnect the client **must** run `GET /v1/sync/changes` before trusting local state. Heartbeat 25 s ping / 60 s pong timeout.

| Event (server → client) | Payload | Notes |
| --- | --- | --- |
| `message.new` | `{ chat_id, id, seq, sender_id, kind, body?, media?, created_at, chat_type }` | `chat_type` drives badge channel |
| `message.status` | `{ chat_id, id, status: "sent|delivered|read" }` | `read` only if the recipient's read receipts are on |
| `message.deleted` | `{ chat_id, id, scope: "me|everyone" }` | |
| `message.edited` | `{ chat_id, id, body, edited_at }` | |
| `chat.typing` | `{ chat_id, user_id, typing: true|false }` | 4 s TTL |
| `chat.updated` | `{ chat_id, fields: {…} }` | |
| `chat.closed` | `{ chat_id, reason: "unmatched|blocked" }` | client must drop the subscription **and** purge local cache |
| `chat.dormant` | `{ chat_id, dormant: true, reopen_allowed: true }` | |
| `match.created` | `{ match_id, chat_id, peer: { display_name_first_initial:"M", verified:true }, prompt? }` | **no full name, no photo** |
| `dating.profile_paused` | `{ paused: true }` | |
| `notification.new` | `{ id, kind, payload }` | social kinds only; dating kinds go to `dating.notification.new` |
| `dating.notification.new` | `{ id, kind: "match|likes_you|message", chat_id? }` | separate channel, separate badge |
| `session.revoked` | `{ reason: "transfer|password_change|admin|reuse_detected" }` | client must sign out immediately |
| `transfer.confirm_required` | `{ transfer_id, target_device_label, expires_at }` | old device |
| `sync.cursor_invalid` | `{}` | client must full-resync that entity class |
| `moderation.action` | `{ target_type, target_id, action }` | content removed by moderators |

Client → server: `chat.join {chat_id}` · `chat.leave {chat_id}` · `message.ack {chat_id, up_to_seq}` · `typing {chat_id, typing}` · `presence {state}`.

**Presence:** `online` written to Redis with 60 s TTL; last-seen is bucketed (`just_now | minutes | hours | day | days | week_plus`) before being exposed, per privacy settings.

Push (FCM/APNs) payload is privacy-safe: `{ "title": "Hasta", "body_key": "push.match.generic", "data": { "type": "match", "chat_id": "…" } }` — no name, no photo, no message text. Dating push uses a separate notification channel with its own sound/vibration settings.

---

## 9. OpenAPI

`docs/api/openapi.yaml` must be generated from the NestJS decorators and validated in CI (`spectral lint` + breaking-change detection against the previous tag). Any breaking change to `/v1` fails the build; ship `/v2` instead with ≥ 3-month deprecation.
