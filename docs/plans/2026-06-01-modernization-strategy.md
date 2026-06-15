# 2026-06-01 — Modernization: Approach & Findings

Decision record and key findings for the Rails 5.1→8 / Ruby 2.7→3.2 modernization.
Companion docs: [`2026-06-01-orientation.md`](2026-06-01-orientation.md) (survey),
[`2026-06-01-behavioral-spec.md`](2026-06-01-behavioral-spec.md) (behavior),
[`2026-06-01-pathc-upgrade-plan.md`](2026-06-01-pathc-upgrade-plan.md) (execution).

## Goal

A modern, **turnkey-dockerizable** license server: upgrade the end-of-life
framework, run on **puma** (the app already depended on puma but deployed via
Passenger), and make it start with a single command.

## Complexity assessment

The **app is small**: ~493 non-comment lines of app+lib Ruby; 4 controllers, 2
models, 1 logic helper; 25 views; the original `test/` was empty scaffolding (no
real tests); 151 gems locked. The difficulty is not the app logic — it's in four
places:

1. **EOL framework = the security exposure.** Rails 5.1.7 (5.2 security-EOL
   mid-2022) on Ruby 2.7.8 (EOL 2023-03-31). The dangerous leaf gems were already
   bumped in `Gemfile.lock` (nokogiri, rack, loofah, rails-html-sanitizer,
   mysql2), so residual CVE risk concentrated in framework + Ruby.
2. **API-client coupling = the gating unknown.** The pinned `ontologies_api_client`
   v2.0.0 can't be modernized without moving Rails forward (the modern client
   wants activesupport 8). Issue #35 already showed the live API drifting
   (pagination) and breaking the pin.
3. **License-key crypto is an external contract (#34).** Deployed appliances
   validate keys against the exact RSA/AES format in `lib/util/encryption_util.rb`.
   Upgrade Rails *without touching it*; don't change the format. A crypto rework is
   a separate, optional project.
4. **No tests.** Any upgrade is validated by hand — but the app is small enough
   that a tiny characterization harness covers nearly all behavior cheaply, and
   that becomes the regression net.

## Approach: full, in-place upgrade (vs. alternatives)

Three options were weighed:
- **Containerize as-is** — fastest, but bakes EOL Ruby/Rails (unpatched CVEs) into
  the image and just containerizes the brittleness.
- **Minimal updates** — the only Rails reachable without forcing the client jump is
  ~5.2 (also EOL); a genuinely supported framework needs Ruby 3.x + Rails 7/8,
  which drags the client coupling — i.e. it collapses into a full upgrade.
- **Full modernization (chosen)** — Ruby 3.2 / Rails 8, modern client, puma,
  dockerized. App-code churn is small (mostly Gemfile / config / Rails-defaults),
  it's actually supported, future API drift stops breaking it, and it aligns with
  `bioportal_web_ui`'s stack.

Done **in place** (not a fresh skeleton) so the change set stays a reviewable diff
against the original — validated behind the characterization harness, after a
de-risking spike.

## Spike results — both API calls green under the modern stack

Ran the app's two BP API calls against a live (staging) server with the modern
stack (Ruby 3.2, `ontologies_api_client` tag **v2.9.0**, activesupport 8.0.3,
faraday 2.14):
- `User.get(.../users/{user})` parses cleanly — the #35-class pagination breakage
  is gone on v2.9.0.
- `User.authenticate(user, pass)` returns a `User` with an apikey.

Carry into the build:
- **Use client tag `v2.9.0`** — NOT the numerically-higher v5.x tags (a stale
  lineage, gemspec 0.0.6, that mis-resolves under Faraday 2). v2.9.0 pins
  activesupport 8.0.3.
- The client's multipart path references `Tempfile` and
  `ActionDispatch::Http::UploadedFile`; a real Rails app provides both (only bare
  scripts need to require/stub them).
- **#20** (blank first/last name → 500 on `new`) is real and easily reproduced.

## Crypto cross-version interop — verified

A key minted under Ruby 2.7.8 / OpenSSL 1.1.1n decrypts under Ruby 3.2.3 / OpenSSL
3.0.13 **and vice-versa** (`test/characterization/encryption_util_test.rb`). So
the upgraded server mints keys that field appliances still accept, and
`private_encrypt` / `public_decrypt` still work under OpenSSL 3. (#34's signature
rework remains separate and optional.)

## Invariants

- Don't change the license-key format (external contract; cross-version verified).
- Preserve the approval lifecycle, the admin/owner access model, the email matrix,
  and appliance-ID validation (see the behavioral spec).
