# Ditto Admin

React + Vite + TypeScript admin dashboard. Talks to the NestJS backend's
`/admin/*` endpoints (`backend/src/modules/admin/`), guarded by
`Role.ADMIN` + Firebase Auth — same "ditto-713d5" Firebase project as
`mobile/customer_app`/`mobile/tailor_app`, since Auth is project-wide.

## Running locally

```bash
npm install
npm run dev
```

Defaults to `http://localhost:3000` for the API (see `.env.example` —
copy to `.env.local` to override). The backend must be running with a
`Role.ADMIN` user already provisioned — see
`backend/prisma/promote-admin.js`.

## Views

- **Overview** — stats (pending applications, active tailors, total users,
  orders this month) plus a preview of applications needing review
- **Applications** — approve/reject pending `BusinessApplication` rows
- **Users** — every `User` row, searchable client-side
- **Tailors** — every `TailorProfile`, with completed-order counts and
  ratings, searchable client-side

Design tokens and layout ported from `docs/admin-prototype.html`.
