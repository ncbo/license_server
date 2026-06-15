# Characterization tests

Behavior-locking tests written *before* the Rails 5.1→8 / Ruby 2.7→3.2
modernization (path C), so we can prove the upgrade preserves behavior even
though the original app shipped with no real tests. See
[`../../docs/plans/2026-06-01-behavioral-spec.md`](../../docs/plans/2026-06-01-behavioral-spec.md)
for the full behavioral spec these are derived from.

These are deliberately **standalone** (they do not `require` the Rails
environment), so they run on any Ruby version — that's what makes them valid as a
before/after baseline across the upgrade.

## What's here

- `encryption_util_test.rb` — the license-key crypto contract (round-trip, wire
  format, per-call randomness). The format is an external contract (appliances
  verify it), so this must keep passing byte-for-byte.

Run one file standalone:

```bash
ruby test/characterization/encryption_util_test.rb
```

## Coming next (per the test sketch in the behavioral spec)

- Pure model rules: `License#expired?`, `#about_to_expire?`, appliance-ID
  validation regex, `CronParser` minute-jitter determinism.
- Request/integration specs (login, access control, the email matrix,
  approve→key-once, disapprove-clears, renew-clones, the #20 nil-name path) — to
  be added against the Rails 8 stack as it comes up during the upgrade, with the
  two BioPortal API calls stubbed (WebMock).
