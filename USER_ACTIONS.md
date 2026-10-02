# What you need to do

The **Role Ping** Supabase project is connected, its migrations are applied, and you confirmed email sign-in works. No immediate setup is required from you.

Supabase's built-in email sender is limited to two messages per hour for the whole project. If you see “email rate limit exceeded,” use an existing sign-in link or signed-in browser tab and wait before requesting another. Repeated clicks will not speed up the reset. Before inviting other users, we will need a dedicated email provider for authentication messages.

Database preference save/reload and two-identity isolation checks now pass automatically with rolled-back test fixtures. No second account setup is needed from you for those checks. Signed-in browser save/refresh remains unverified because this Mac denied computer-control permission. The agent can retry once computer control is available; no manual form-testing task is assigned to you.

Notification delivery will eventually need a provider account and consent wording, after matching works.

The first job collector is built and verified with 21 live Razorpay postings. It can run through the already-authenticated Supabase CLI, so no database password is needed from you for manual development runs. Scheduling and a dedicated worker credential remain later work.
