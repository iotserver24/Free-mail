# Free-mail Frontend (Nuxt 4)

Nuxt 4 + Vue 3 SPA that talks to the Free-mail backend via cookie-authenticated requests. The UI ships with:

- Sidebar-driven mailbox navigation, inbox and domain management
- Thread view with HTML/plain previews, attachments UI, and toast notifications
- Composer drawer that uploads attachments directly to Catbox
- Pinia stores for auth/session refresh (`stores/auth.ts`) and cached mail data (`stores/mail.ts`)

## Prerequisites

- Node.js 18+
- Backend API running locally (default `http://localhost:4000`)
- Filled `frontend/.env` file

```env
NUXT_PUBLIC_API_BASE=http://localhost:4000
NUXT_PUBLIC_CATBOX_USERHASH=
```

`NUXT_PUBLIC_CATBOX_USERHASH` is optional—set it if you use a Catbox account/userhash for uploads.

## Install Dependencies

```bash
cd frontend
npm install
```

## Run the Dev Server

```bash
npm run dev
```

- Nuxt serves the SPA on `http://localhost:3000`
- The runtime config (`useRuntimeConfig().public.apiBase`) must point at a backend origin that accepts cookies from `http://localhost:3000`

## Type Checking

```bash
npx nuxi typecheck
```

## Build for Production

For static hosting (Netlify, Vercel static, Cloudflare Pages):

```bash
npm run generate
# Output: .output/public
```

For a self-hosted Nitro server (Node adapter):

```bash
npm run build
npx nuxi preview   # optional sanity check
```

Deploy the resulting `.output` directory to your platform of choice. Make sure the production environment replicates the two `NUXT_PUBLIC_*` variables.
