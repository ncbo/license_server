# 2026-06-01 — Path C Upgrade Execution Plan (Route 2: in-place)

In-place modernization of `license_server`: **Rails 5.1.7 → 8.0.3, Ruby 2.7.8 →
3.2.9, `ontologies_api_client` v2.0.0 → v2.9.0, Passenger → puma, then Docker.**
Approach **Route 2** (single big in-place bump) — preserves the repo/history so
NCBO sees the work and every change is `git diff`-able against the original.
**Keep `sprockets-rails`** (no esbuild). Gem set cribbed from `bioportal_web_ui`
(the known-good Rails 8 stack). Versions/targets settled in
[`2026-06-01-modernization-strategy.md`](2026-06-01-modernization-strategy.md);
behavior to preserve is in [`2026-06-01-behavioral-spec.md`](2026-06-01-behavioral-spec.md).

## Verification loop (our safety net — no legacy tests existed)

1. `test/characterization/` standalone tests (crypto already GREEN + cross-version
   verified). Add pure model/validation/cron tests.
2. Once booting on Rails 8: request specs with the 2 BP API calls stubbed
   (WebMock) — login, access control, email matrix, approve-key-once,
   disapprove-clears, renew-clones, the #20 nil-name path.
3. Live smoke (NCBO's bar): boot → login with BP creds → create→approve → the
   emailed key verifies against the public key; eyeball vs. look-don't-touch prod.

## Step 1 — Gemfile (this step)

| Old | New | Why |
|-----|-----|-----|
| `rails ~> 5.1.7` | `rails 8.0.3` | target |
| `faraday ~> 1.10` (pin) | *(removed)* | client v2.9.0 brings faraday 2.x |
| `puma ~> 3.7` | `puma ~> 6.0` | modern; run puma directly |
| `sass-rails ~> 5.0` | `sassc-rails` | SCSS for Sprockets on Rails 8 (bootstrap-4 compatible) |
| `uglifier` | `terser` | maintained JS minifier |
| `coffee-rails` | *(removed)* | unused legacy |
| `turbolinks ~> 5` | *(removed)* | dead on Rails 8; app already fought it (`data-turbolinks=false`) |
| `bootstrap ~> 4.1.0` | `bootstrap ~> 4.6` | latest 4.x (keep BS4 look) |
| `haml` (5.x) | `haml ~> 6.1` | Rails 8 compatible |
| `byebug` | `debug` | modern debugger |
| client `tag: v2.0.0` | client `tag: v2.9.0` | spike-proven modern client |
| — | `bootsnap`, `concurrent-ruby = 1.3.4`, `connection_pool < 3`, `net-http`, `net-ftp`, `ffi`, `oj` | Rails 8.0.x pins + Ruby-3 stdlib (mirror web_ui) |
| keep | `jquery-rails`, `jquery-ui-rails`, `dalli`, `mysql2`, `rest-client`, `multi_json`, `chroma`, `uuid`, `fugit`, `ruby-xxHash`, `activerecord-import`, `whenever`, capistrano set | still used |
| `.ruby-version` 2.7.8 | 3.2.9 | target |

Gate: `bundle lock` resolves cleanly → then `bundle install` (in a Ruby-3.2.9 +
libmysqlclient env; the `bioportal-dev` image works) compiles native exts.

## Step 2 — Boot on Rails 8 (next)

- `config/application.rb`: `load_defaults 8.0`; keep `eager_load_paths << lib/util`.
- Add `config/initializers/new_framework_defaults_8_0.rb` review; `bin/` regen if needed.
- **Zeitwerk**: `lib/util/encryption_util.rb`/`cron_parser.rb` are eager-loaded —
  ensure constant names match paths (`EncryptionUtil`, `CronParser`). `batch.rake`
  does `require "#{Rails.root}/app/helpers/application_helper"` + `include` — adapt.
- `config/environments/*`: drop removed 5.1 options; keep the mem_cache_store line
  (needs the `connection_pool < 3` pin); keep the per-env `license_server_config`
  require + `sandbox_email_interceptor`.
- Secrets: app uses `config/secrets.yml`; Rails 8 prefers credentials. Keep
  `secrets.yml` if still supported, else migrate minimally.
- Assets: drop `turbolinks`/coffee from `app/assets/javascripts/application.js`;
  confirm no `.coffee`; `sassc-rails` for SCSS; bootstrap 4 `@import` intact;
  DataTables/jQuery still via the manifest/CDN as today.
- Models: `enum approval_status:` syntax still valid; `belongs_to` already required.

## Step 3 — Security-debt fixes (intentional behavior changes, flagged for NCBO)

Each as its own clearly-labeled commit:
- Re-enable CSRF (remove blanket `skip_before_action :verify_authenticity_token`;
  add real protection / proper form tokens).
- Replace `params[:license].permit!` with explicit strong params.
- Parameterize the raw SQL in `init_max_ids` / `License.latest_licenses`.

## Step 4 — Dockerize (turnkey)

Crib `bioportal_web_ui/developer/`: Dockerfile (Ruby 3.2.9 + node + libmysqlclient
+ mariadb + memcached), `entrypoint.sh` (envsubst config templates, db:setup,
launch puma), env-var config injection. Keep `whenever` cron as a container concern.

## Invariants (do not break)

- **License-key format unchanged** (external contract; cross-version verified).
- The 6-case email matrix, approval lifecycle, admin/owner access model, and
  appliance-ID validation must still hold (see behavioral spec).

## Progress

- [x] Decision: Route 2, keep sprockets-rails.
- [x] Step 1: Gemfile + `.ruby-version` (3.2.9); `bundle lock` clean — 181 gems,
      rails 8.0.3, client v2.9.0 (rev 3c34565), sassc-rails 2.1.2 + bootstrap
      4.6.2.1 + sprockets 4.2.2 all co-resolve. Old lock saved to
      `tmp/Gemfile.lock.rails51.bak`.
- [x] **Step 2 DONE — app runs on Rails 8.0.3 / Ruby 3.2 end-to-end.** Boots,
      `zeitwerk:check` clean (under `load_defaults 8.0`), `db:migrate/seed` ✓,
      `assets:precompile` ✓, Puma serves; verified by HTTP smoke:
      `GET /`=200, `GET /login`=200, **`POST /login` (real BP creds)=302→/licenses
      + session**, `GET /licenses`=200, `GET /licenses/new`=200. Live login
      against the BP API works inside Rails 8 (NCBO's acceptance bar met).
      Complete change set (the whole Rails 5.1→8 / Ruby 2.7→3.2 diff):
      - `Gemfile` (rails 8.0.3, client v2.9.0, sprockets-rails, sassc-rails,
        terser, bootstrap ~>4.6, puma ~>6, Rails-8.0.x pins, Ruby-3 stdlib gems;
        dropped turbolinks/coffee/uglifier/byebug/spring) + `Gemfile.lock`
      - `.ruby-version` → 3.2.9
      - `app/models/license.rb`: `enum :approval_status, {…}` (positional)
      - `config/storage.yml`: added (ActiveStorage default)
      - `app/assets/javascripts/vendor.js`: dropped `//= require turbolinks`
        (rails-ujs + action_cable still ship with Rails 8; js.cookie is vendored)
      - `config/application.rb`: `load_defaults 5.1` → `8.0`
      - `config/environments/{production,staging}.rb`: removed
        `config.read_encrypted_secrets`; `js_compressor :uglifier` → `:terser`
      Note: `/licenses/new` did NOT 500 for the test account used (#20 affects
      only accounts with a genuinely nil first/last name).
- [x] **Harness (first cut) GREEN on Rails 8** — app previously had ZERO working
      tests. `rails test`: 9 runs / 34 assertions / 0 failures; crypto: 3/12.
      Covers: crypto contract; `License#expired?`/`#about_to_expire?`/`latest_licenses`;
      login success+failure; access control (anon→login, owner-sees-own,
      admin-sees-all); **approve→key-once+email**. BP API stubbed at method level
      (`test/test_helper.rb` `BpApiStubs#with_bp` + `FakeBpUser`). Supporting changes:
      `config/environments/test.rb` (`show_exceptions=:none`, load LS config,
      `cache_store=:memory_store`); fixed `test/fixtures/*.yml`;
      `test/{test_helper,models/license_test,integration/auth_and_access_test}.rb`;
      `Gemfile` `minitest ~> 5.25` (+`require 'minitest/mock'`) + `webmock`.
      Run: `tmp/run_tests.sh`. Deferred: disapprove-clears, renew-clones, full
      email matrix, appliance-ID validation, cron jitter.
- [x] **Step 3 DONE — security-debt fixes (verified).** Harness still green
      (10 runs / 38 assertions). CSRF re-enabled (dropped the blanket
      `skip_before_action :verify_authenticity_token` from all 3 controllers) —
      verified on a running server: tokenless POST /login → **422**, token-aware
      → **302**. Strong params (`license_params`) replace `permit!` and now also
      block a real privilege-escalation (a non-admin could self-set
      `approval_status=approved` and self-issue a key) — covered by a new test.
      Raw SQL in `init_max_ids` parameterized via Active Record.
- [x] **Step 4 DONE — turnkey Docker (verified).** `docker compose up --build`
      (mysql:8.0 + memcached + app) → entrypoint renders ENV-driven config,
      generates a dev RSA key + secret if absent, waits for DB, runs `db:prepare`
      (migrate + **seed all 9 purposes**), launches **puma on 0.0.0.0:3000 in
      production**. Verified: GET / =200, GET /login =200, GET /licenses (anon)
      =302→login. Files: `Dockerfile`, `docker-compose.yml`, `.dockerignore`,
      `docker/{entrypoint.sh,license_server_config.rb,database.yml}` (config from
      ENV — no secrets baked in). `db/schema.rb` auto-rewrote to Rails 8 format
      (versioned dump; tables/indexes/FK unchanged).

## Status (2026-06-15)
The upgrade, the test harness, the security fixes, **CI** (`.github/workflows/test.yml`
+ a `docker compose run --rm test` service), and a fix for **#20** (blank first/last
name → 500, with a regression test) are done and verified: `docker compose up` runs
the app and login against a live BioPortal server works. Remaining items below.

## Remaining
- Provide real prod config at deploy: `SECRET_KEY_BASE`, real RSA private key
  (mount + `PRIVATE_KEY_FILE`), real `API_KEY`/`BP_REST_URL`, SMTP.
- Reconcile deploy story: Capistrano (`config/deploy.rb`) vs. the new Docker path;
  decide how the `whenever` expiry cron runs in a container.
- Nice-to-haves: Dalli `protocol: :meta` (deprecation), the deferred harness tests
  (disapprove-clears, renew-clones, full email matrix), the #34 crypto rework.
