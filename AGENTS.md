# Development and Git rules

- Build one small working feature at a time. Keep UI simple until core flows work.
- Read `TECH_STACK.md`, `PRODUCT.md`, `SPRINT_PLAN.md`, and `config/product-rules.json` before changing behavior.
- Store changeable product values in `config/product-rules.json`; label proposals and unresolved values.
- Never commit secrets. Browser code gets only the Supabase publishable key. Enforce ownership in database policies.
- Add a new migration for schema changes after a migration has been applied.
- Run the build and relevant tests before committing. Report what could not be verified.
- Make a clean local Git commit after each completed development slice. Stage only files for that slice, verify the staged diff, and use a short imperative subject such as `feat: save user settings`.
- Do not commit generated files or unrelated changes. Do not force-push or rewrite shared history.
