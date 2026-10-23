# TQS game access control

TQS game access now uses the same Firebase project as TQSShop. The browser never creates a FreeKill account from a typed username and password.

## Flow

```text
Google / Firebase Auth
        |
        | Firebase ID token
        v
POST /api/game/session
        |
        | gameAccess/{uid} == approved
        | + short-lived TQS1 HMAC ticket
        v
FreeKill native authentication
        |
        | verifies TQS1|expiry|signature with tqsAuthSecret
        v
Game lobby and rooms
```

The first session request creates `gameAccess/{uid}` with `status: pending`. A user cannot write this document or change the status from the browser. An admin with `manageGameAccess` moves it to `approved` or `suspended` from the TQSShop admin screen.

`nativeName` is a new deterministic FreeKill identity in the `tqs_` namespace. For Firebase UIDs already matching the bounded native alphabet, the readable `tqs_<firebase-id>` form is retained, except for the reserved `h_` + 62 lowercase-hex pattern used by the hash namespace. UIDs containing other characters, exceeding the bound, or matching that reserved shape use a SHA-256-derived `tqs_h_...` form rather than being stripped or truncated; this prevents two Firebase identities from sharing one native `userinfo.id` and therefore one account temp-ban. It is not the display name and it is not a password. The admin UI cannot enter an old native name, and the API ignores any legacy mapping already present in `gameAccess`; approved users always receive the new identity and the native account is created only after a valid signed ticket is presented. Existing native database rows are not silently deleted by this source change. A production cutover that must remove them needs a separately approved, backed-up database reset.

## Server configuration

Set the same unpredictable value, at least 32 characters, in both server environments:

- TQSShop/Vercel: `TQS_GAME_TICKET_SECRET`
- FreeKill source deployment: `TQS_GAME_TICKET_SECRET` in the native service environment

Keep `tqsAuthRequired: true` for the source build. The checked-in native template leaves `tqsAuthSecret` empty intentionally; `run-server.sh` requires the external environment secret and the patched C++ config loader reads `TQS_GAME_TICKET_SECRET`. On systemd, create `/etc/tqs-game-auth.env` with mode `0600` and a single `TQS_GAME_TICKET_SECRET=...` entry; the service unit already loads that file. Never commit that file or put the value in a public JSON config. An empty or short secret fails closed.

The source deployment applies [`tqs-game-access.patch`](../deploy/freekill-native/patches/freekill-asio/tqs-game-access.patch) after the existing reconnect patch; the current static amd64 FreeKill artifact cannot receive this C++ patch and must be replaced by a source-built release before enabling SSO in production.

The game Pages project needs the server origin for its same-origin bridge:

- `TQS_GAME_AUTH_ORIGIN=https://<the-tqsshop-origin>` as a Pages environment variable
- `GAME_ALLOWED_ORIGINS=https://tqsvn.pages.dev` in the TQSShop API environment
- Add the Pages hostname to Firebase Authentication's authorized domains and keep the Google provider enabled.

For local Vite development, set `VITE_GAME_SESSION_URL` to the TQSShop API endpoint if `/api/game/session` is not proxied locally. Firebase web configuration remains public and can use the checked-in TQSShop config or the existing `VITE_FIREBASE_*` overrides.

## Deployment checkpoint — 18/10/2026

The bounded production deployment is live:

- TQSShop/Vercel: deployment `dpl_GxWyXxNPcpqpMcP5tdQiz1LzCiqy`, ready at `https://tqsshop.vercel.app`.
- Game/Cloudflare Pages: deployment `c928f1ff-48e1-4d85-9b84-df9eb9e91a52` at `https://tqsvn.pages.dev`, with the same-origin `/gateway` bridge.
- Firebase rules and indexes: released to project `gen-lang-client-0845413094`.
- Native: source-built `freekill-asio-source-0.1.17` from commit `b8a2ad48305aea7b55ccca325fcbeb100cb8a01a`; the 14 pinned packages and server-only QA package passed VM verification, and `freekill-native.service` is listening on port `9527`.

Observed public probes are `401` for both direct and Pages-bridged session requests without a Bearer token, `204` for the Pages CORS preflight, `200 ok` for `/gateway/healthz`, and `200` for the TQSShop storefront. A valid-ticket login requires a Firebase identity whose `gameAccess/{uid}` document has been approved by an administrator; that authenticated smoke path was not run in this deployment checkpoint.

The cutover does not map or migrate old native accounts. The current source release `server/users.db` was checked after deployment and all account-related tables (`userinfo`, `uuidinfo`, `friendinfo`, ban/mute and whitelist tables) contain zero rows. The backup remains available for rollback; no old account is accepted by the new ticket-only login path.

## Pool policy

`gamePoolPolicies/new_heg_mode` stores a monotonically increasing revision, the opening general count, and separate `disabledPacks.generals` and `disabledPacks.cards` arrays. `generalNum` is an integer from 5 through 10: the administrator can choose 5, 7, 10, or any supported value in that range in the same panel as the pack locks. Missing or invalid values from older policies fall back to 5. The admin screen lists only the 14 general and 4 card packages in the installed `new_heg_mode` inventory, using Vietnamese labels without exposing internal package IDs or custom-ID entry. When it loads a legacy policy, the form drops unknown, duplicated, or wrong-category entries and asks the administrator to save once to persist the cleaned policy. The game-session API applies the same whitelist and count normalization before returning a policy snapshot so old saved entries cannot break room creation even before that save. A new room receives the current sanitized policy; the browser adapter checks that the available general pool has at least `capacity * generalNum` distinct generals and sends the selected value as native `_game.generalNum`. The native Hegemony mode then deals that many choices to each player. Existing rooms keep their native room snapshot.

The native template also accepts `tqsLockedPacks`. This is the server-side forced list used by the Lua worker. Keep it synchronized with the policy when deploying a policy that must survive a modified or hostile client; reload the native server after changing it. Individual card IDs are intentionally not part of this first version because FreeKill does not have one native `disabled_cards` guard across draw pile, virtual cards, and use validation.

## Admin permissions

- `manageGameAccess`: approve, suspend, and manage new game identities.
- `manageGamePool`: change the pack policy and revision.

These permissions are independent from shop products, orders, and role management. Super Admin receives both automatically.
