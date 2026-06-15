# 2026-06-01 — Repo & Issue-Tracker Survey

A first-pass survey of `license_server` and its open issues, taken at the start of
the Rails 8 / Ruby 3.2 modernization. Architecture is in
[`../../CLAUDE.md`](../../CLAUDE.md); this note is a point-in-time snapshot.

## What this app is

The OntoPortal Appliance License Server — at the time of this survey a Rails 5.1.7
/ MySQL app that issues RSA-signed license keys for OntoPortal/BioPortal virtual
appliances. Users request licenses (tied to an Appliance ID), admins approve, the
app emails a signed key and sends expiry reminders. Authentication and user lookup
go through the BioPortal REST API via `ontologies_api_client` (then pinned
`v2.0.0`).

## Open issues (`ncbo/license_server`, as of 2026-05-22)

| # | State | Summary | Notes |
|---|-------|---------|-------|
| 20 | open | Accounts with blank first/last name → 500 on "Create License" | `LicensesController#new` calls `.strip` on a possibly-nil `firstName`/`lastName`. Small, clean fix. |
| 34 | open | Legacy licensing brittle (AES-CBC implicit IV, RSA-encrypt-as-signature) | Rework to a standard signed-payload scheme; keep legacy for back-compat. Design-heavy; touches `lib/util/encryption_util.rb` + appliance-side validation. |
| 31 | open | Export records to CSV | Self-contained feature. |
| 32 | open | Upgrade Rails to v6+ | Modernization; the `faraday` v1 pin anticipates this. |
| 33 | open | Upgrade to Ruby 3.2+ | Modernization (then on 2.7.8). |
| 9  | open | Registration workflow without an Appliance ID | Workflow/UX change. |

Recently closed (context): **#35** (renewal 500 — `find_user_by_bp_username`,
caused by the now-paginated `/users` response; fixed by GETting `/users/{name}`
directly — commit `452926f`), **#10** (Cognizone license-key troubleshooting).
Older #1–#8, #11 were the 2020–2021 work; ~16 stale Dependabot PRs.

## Starter candidates

- **#20** (blank first/last name → 500) — small, clean.
- **#31** (export to CSV) — self-contained.
- **#32 / #33** (Rails 6+ / Ruby 3.2+) — the modernization, addressed by the
  subsequent upgrade (see `2026-06-01-pathc-upgrade-plan.md`).
