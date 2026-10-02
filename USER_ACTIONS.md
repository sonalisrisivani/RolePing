# What you need to do

The app runs locally in preview mode now. For real sign-in and saved settings:

1. Create a Supabase project in your account.
2. Enable email sign-in and add `http://127.0.0.1:5173/` to Auth redirect URLs.
3. Copy `app/.env.example` to `app/.env.local` and fill in `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` from the Supabase project dashboard. Keep `.env.local` on your computer; it is ignored by Git. Do not put a service-role key, secret key, database password, or personal access token there.
4. Run `supabase/migrations/20261002100152_create_profiles.sql` in the Supabase SQL Editor, then tell me "Supabase setup done." You can enter your own test email in the app; no password needs to be shared.

I can then verify the connected frontend and account isolation, and continue with the next functional slice. If you already have a connected Supabase CLI or MCP integration, tell me and I can handle the migration instead.

Later, real notifications will need a delivery channel, provider account, consent wording, and decisions for open values in `config/product-rules.json`. Those do not block current frontend work.
