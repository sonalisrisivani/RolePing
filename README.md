# Role Ping

An early job discovery app for users seeking roles. The current frontend has a simple local preview, Supabase email sign-in, and private profile settings. A Python worker collects the first employer feed into private job storage. Matching and notifications are not built yet.

## Run

```bash
cd app
npm ci
npm run dev
```

Open the URL printed by Vite, usually [http://127.0.0.1:5173/](http://127.0.0.1:5173/). Without Supabase credentials, settings save only in this browser.

## Key files

- [Development plan](SPRINT_PLAN.md)
- [What you need to do](USER_ACTIONS.md)
- [Tech stack](TECH_STACK.md)
- [Product brief](PRODUCT.md)
- [Changeable rules](config/product-rules.json)
- [Development and Git rules](AGENTS.md)

The older planning documents and benchmark evidence remain recoverable from Git history.

## Verify preferences

Run `npm test` and `npm run build` in `app`. Run `supabase/tests/profile_access.sql` as an administrator against the project's database to exercise authenticated ownership rules and preference persistence. The SQL suite raises on failure and rolls back all fixtures on success; it does not send email or create permanent accounts. It verifies database roles, not the browser sign-in flow.

## Collect jobs

The first collector is working against the existing Role Ping project. See [worker instructions](worker/README.md) for its manual run command, safety rules, tests, and source health query. Source selection and limits are configured in [product rules](config/product-rules.json). Collection has no schedule yet.
