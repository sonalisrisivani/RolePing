# What you need to do

I created the **Role Ping** Supabase project in the `inavis` organization (Mumbai), applied the profile migration, and configured the local app with its publishable key. You do not need to create a project, copy keys, or run SQL.

To finish testing email sign-in:

1. In the [Role Ping Auth URL settings](https://supabase.com/dashboard/project/bqsjlmftpxawctenzvja/auth/url-configuration), add `http://127.0.0.1:5173/` to the redirect URL allow list. Check that email sign-in is enabled in Auth providers.
2. Open [the local app](http://127.0.0.1:5173/), enter your own email, and follow the sign-in link. Keep your email link and codes private.
3. Tell me **“Sign-in works”** or send the error text without the link or code.

I can build the next local features while you do this. I can verify the database policies and schema through the connected Supabase plugin; end-to-end email sign-in needs a test inbox. Later notification delivery will require a provider account and consent wording, after the matching flow works.
