# Tech stack

- Frontend: React + Vite, JavaScript, plain CSS.
- Identity and data: Supabase Auth + Postgres with row-level security.
- Job collection: Python worker with a Greenhouse adapter; private Postgres collection tables. Manual runs use the authenticated Supabase CLI; a scoped database-login path is prepared for later scheduling.
- Matching: live invoker-only Postgres function using the signed-in user’s saved preferences. Python extraction, richer ranking, and persisted shortlists remain later slices.
- Notifications: scheduled worker and delivery provider, later slice.

Keep user-facing operations in the frontend. Privileged collection, matching, delivery, and billing stay server-side. Add infrastructure only when a working feature needs it.
