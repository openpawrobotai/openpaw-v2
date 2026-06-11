# 🐾 openpaw-website

Next.js site + APIs for **OpenPaw** — the public landing/vision site and backend API routes. MIT licensed.

> Part of [OpenPaw](https://github.com/ayvalabs) by Ayva Labs. Maintainer: **@aeropriest**.

## Stack
- Next.js (App Router) — site + API routes in one project.
- API routes under `app/api/*`.

## Layout
```
app/
├── (marketing)/      landing, vision, build-in-public log
├── api/
│   └── health/route.ts   example API route
├── layout.tsx
└── page.tsx
components/  · lib/  · public/
```

## Develop
```bash
npm install
npm run dev   # http://localhost:3000
```

## Notes
- Secrets via env (`.env.local`, gitignored) — never commit keys.
- Deploy target: Vercel.

## License
MIT © 2026 aeropriest
