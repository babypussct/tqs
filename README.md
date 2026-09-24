<div align="center">
<img width="1200" height="475" alt="GHBanner" src="https://github.com/user-attachments/assets/0aa67016-6eaf-458a-adb2-6e31a0763ed6" />
</div>

# TQSShop — cửa hàng boardgame Tam Quốc Sát

Repository này chứa storefront TQSShop, order service server-authoritative và
các API quản trị/notification. Kiến trúc sau refactor được mô tả tại
[`docs/architecture/SHOP_REFACTOR.md`](./docs/architecture/SHOP_REFACTOR.md).

The repository currently tracks `dist/`; regenerate it with `npm run build`
before a deployment that consumes the checked-in static output.

## Firebase environments

TQSShop production uses one canonical Firebase project and one named Firestore
database:

- Firebase project alias `production` → `gen-lang-client-0845413094` (`TQS SHOP`)
- Firestore database → `ai-studio-ae9f678c-29b1-4f19-b872-e5b15e1cee0b`

The alias is defined in [`.firebaserc`](./.firebaserc). Always pass the alias
explicitly for production deploys so unrelated Firebase projects in the same
Google account are not selected accidentally. A staging alias will be added
only after the staging project access and ownership are verified.

## Run Locally

**Prerequisites:** Node.js 20+

1. Install dependencies:
   ```bash
   npm ci
   ```
2. Setup environment variables (optional for basic local dev):
   ```bash
   cp .env.example .env.local
   ```
3. Run the development server:
   ```bash
   npm run dev
   ```
4. Check types & build:
   ```bash
   npm run lint
   npm run build
   ```
5. Run Firestore Rules contract tests in the local emulator:
   ```bash
   npm run test:rules
   ```

The canonical Rules source is [`firestore.rules`](./firestore.rules). Deploy it only
from a reviewed commit, after the emulator suite and the frontend/API smoke tests pass:

```bash
firebase deploy --project production --only firestore:rules,firestore:indexes
```

## Gate 4 security configuration

Telegram is treated as a private admin channel. Configure `TELEGRAM_WEBHOOK_SECRET`
and `TELEGRAM_CHAT_ID` in the server environment; optionally set
`TELEGRAM_ALLOWED_USER_IDS` to a comma-separated list of numeric Telegram user IDs.
Webhook registration is locked behind `TELEGRAM_SETUP_SECRET` (or the webhook secret
as a fallback) and must be invoked only during an intentional setup operation:

```text
GET /api/telegram-webhook?setup=true&secret=<TELEGRAM_SETUP_SECRET>
```

`/api/notify` is private and accepts only an authenticated Firebase ID token with a
`NEW_REVIEW` payload containing `reviewId`; the server reloads the review and checks
that the caller owns it. Do not put Telegram secrets in Vite/client variables.

## Phase 5 media uploads

Admin media uploads use [`POST /api/media/upload-url`](./api/media/upload-url.ts)
and Cloudflare R2 presigned `PUT` URLs. The endpoint requires a Firebase ID token,
checks the category-specific admin permission, accepts only JPEG/PNG/WebP up to
5 MiB, and returns an immutable public URL. Configure the server-only R2 variables
and explicit browser origins described in [`docs/media/R2_SETUP.md`](./docs/media/R2_SETUP.md).

The browser upload flow is shared by `ImageUploader` and `RichTextEditor`; no R2
credential or Cloudinary upload preset is exposed to Vite. Existing Cloudinary
URLs remain readable for backward compatibility while catalog data is migrated.
