# Tech stack

- Frontend: React + Vite, JavaScript, plain CSS.
- Identity and data: Supabase Auth + Postgres with row-level security.
- Job collection and matching: Python worker, later slice.
- Notifications: scheduled worker and delivery provider, later slice.

Keep user-facing operations in the frontend. Privileged collection, matching, delivery, and billing stay server-side. Add infrastructure only when a working feature needs it.
