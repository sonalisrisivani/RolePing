# Your one-time setup

Do these steps once so I can continue the connected build without repeated setup questions:

1. Create a Supabase project in your account.
2. In Supabase Auth, enable email sign-in and allow `http://127.0.0.1:5173/` as a redirect URL.
3. Copy `app/.env.example` to `app/.env.local`. Fill in `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` from the project dashboard. This file is ignored by Git. Never put a service-role key, secret key, database password, or personal access token in it.
4. Run `supabase/migrations/20261002100152_create_profiles.sql` in the Supabase SQL Editor. Use your own email to test sign-in; no password needs to be shared.
5. Tell me **“Supabase setup done”**. If any step fails, send the error text without credentials.

After that I can verify the connected profile flow and build the next slices in [SPRINT_PLAN.md](SPRINT_PLAN.md). I will ask for a decision only when a later external dependency actually needs one, such as a notification provider or consent wording. Those choices do not block current development.
