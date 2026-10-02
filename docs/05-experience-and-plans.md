# Role Ping — User experience, delivery, and plans

## Proposed screens

| Screen | Primary purpose | Required states |
|---|---|---|
| Landing | Explain saved search effort, coverage, and how delivery works | Clear limits; no job guarantee |
| Signup | Establish identity and private account | Verification, retry, existing account |
| Profile | Collect education, experience, skills, and availability | Incomplete, validation errors, confirmed |
| Preferences | Define roles, locations, salary, and strictness | Conflicting settings, unknown-field choices |
| Delivery setup | Choose available channel, timezone, and frequency | Unverified destination, paused, confirmed |
| My jobs | Ranked shortlist with fit reasons | Loading, no matches, degraded sources, stale evidence |
| Job detail | Explain suitability and uncertainty; open application | Closed, conflict/quarantine, already applied |
| Saved/applied | Track user-reported progress | Empty list, undo action |
| Settings | Edit preferences, pause, export/delete request | Pending change, pending deletion |
| Operator console | Health and exception review | Broken source, suspect job, failed delivery |

Keep technical collection logs out of student flows. A useful student-facing message is “Some sources are temporarily unavailable; last checked at …”, not a stack trace. Do not expose a numerical confidence score without explaining what it measures.

## Example card

Illustrative content, not a real opening:

> Junior Backend Developer · Example Company\
> Bengaluru · Full-time · Salary undisclosed\
> Why it fits: Python and SQL; preferred location; accepts recent graduates.\
> Check before applying: graduation year not specified; Django is requested.\
> First found 25 minutes ago; last checked 10 minutes ago.\
> Apply · Save · Not relevant

Application links open the original job/employer page. Public sharing removes personalised reasons, account identifiers, and private preferences.

## Daily digest semantics

Proposed default: 07:00 in the chosen timezone; suggest Asia/Kolkata for the initial India pilot but ask the user to confirm. Store an IANA timezone and recompute scheduled UTC times so future non-India users handle daylight-saving changes correctly.

At send time, select up to five qualifying, unnotified jobs. Rerank the current candidate pool; remove closed, stale, applied, dismissed, conflicting, or newly ineligible jobs. Do not implement a blind FIFO backlog. Suppressed jobs may remain visible in saved history with status labels, but should not be marketed as fresh matches.

A timezone or preference change invalidates relevant queued eligibility snapshots. Proposed behavior for a missed digest: send only if still within a configurable grace window; otherwise wait for the next scheduled slot. Avoid a burst of backlogged digests after an outage. Final grace window is an operational setting to choose during the pilot.

## Channel abstraction

First provider/channel is not selected. Recommended pilot order is email, then a limited official WhatsApp integration; Telegram, push, or additional channels are later options. The user should see only channels that actually work.

Each adapter accepts recipient reference, consent reference, batch ID, message payload, and idempotency key; returns provider message ID and accepted/rejected/error state. Delivery/read receipts are separate events when supported. “Provider accepted” is not “user read.”

WhatsApp integration must use current official platform requirements, template approval where required, and appropriate opt-in/unsubscribe behavior. Provider pricing and classification must be checked during integration; no rate or free-message assumption is locked into this PRD. Background messages remain subject to the user's channel choice and limits.

## Delivery reliability

Outbox lifecycle: pending → leased → submitted → delivered/failed/unknown. Recheck consent and current eligibility before submission. Record attempts; retry bounded transient failures. If a provider times out after possibly accepting a send, reconcile using provider IDs/idempotency when available rather than blindly duplicating it. Absolute exactly-once delivery across providers is not assumed.

Pause/unsubscribe cancels unsent work immediately. Switching channels should not resend all prior jobs. Proposed default is deduplication across channels for the same user; multi-channel repeat delivery would require explicit preference. Quiet hours and caps apply to paid alerts too.

## Proposed plan boundaries

| Capability | Free hypothesis | Paid hypothesis |
|---|---|---|
| Matching correctness | Same eligibility/quality rules | Same eligibility/quality rules |
| Delivery | Daily scheduled digest | Faster after detection, with limits |
| Digest size | Up to five qualifying new jobs | Higher configurable cap |
| Searches | One preference set | Multiple saved searches |
| Channels | One supported channel | Additional supported channel options |
| Actions | Save, applied, dismiss, feedback | Same plus later reminders/history features |
| Watchlists | Deferred | Company watchlists |

These are proposals; price, cap, and channel allocation require cost and willingness-to-pay testing. The free product should be useful without fabricated scarcity or deliberately poor matches. Faster alerts mean shorter delay after discovery, not guaranteed immediate publication detection or hiring advantage.

## Payment and entitlements

Defer public billing until the quality gates are met. A test entitlement can support a controlled pilot, assigned only by an authorised operator. Real billing requires verified webhooks, replay protection, explicit cancellation behavior, grace-period decisions, and handling upgrades/downgrades without duplicate alerts. Plan enforcement happens server-side, including delivery frequency and cap; hiding a button is not enforcement.

## Unit economics worksheet

Monthly contribution per paying user = net subscription receipts minus attributable collection, compute, storage, extraction/model, messaging, payment-processing, and support costs.

Track shared source costs separately from marginal per-user costs. Allocation assumption: shared collection cost divided by the active users benefiting from that source. Model low/base/high cases using measured matches and messages per active seeker. Paid instant alerts may send many more messages than one digest, so cost them separately before setting prices.
