# CLAUDE.md — OntoPortal License Server

Context for AI assistants and developers working in this repository.

## Project Overview

The OntoPortal Appliance License Server is a Ruby on Rails application that issues
and manages licenses for downloadable OntoPortal/BioPortal **virtual appliances**.
A site operator requests a license (tied to an *Appliance ID*); an admin reviews
and approves it; the app generates a cryptographically signed **license key** and
emails it to the requester. It also sends expiration reminders.

There is **no local user table** — the app authenticates and looks users up via
the **BioPortal REST API** (the `ontologies_api_client` gem), the same API the
`bioportal_web_ui` frontend uses.

## Tech Stack

- **Framework**: Rails 8.0.3
- **Ruby**: 3.2.9 (see `.ruby-version`)
- **Database**: MySQL (`mysql2`)
- **Cache / sessions**: Memcached via `:mem_cache_store` (`dalli`); sessions use
  `ActionDispatch::Session::CacheStore`
- **App server**: Puma
- **Views**: Haml (+ ERB mailer templates), Bootstrap 4, SCSS through Sprockets
  (`sprockets-rails` + `sassc-rails`), jQuery
- **BioPortal API client**: `ncbo/ontologies_api_ruby_client`, GitHub tag **`v2.9.0`**
- **Scheduling**: `whenever` (crontab); `fugit` for cron parsing
- **Container**: `Dockerfile` + `docker-compose.yml` (app + MySQL + memcached)

## How It Works

### License request → key lifecycle
- A logged-in user submits a `License` (appliance_id, organization, purpose,
  project info, reason) → status **`pending`**. Emails go to the user ("received")
  and the admin ("submitted"). See `LicensesController#create`.
- An admin **approves** (`LicensesController#approve` → `approve_license`): status
  becomes **`approved`**, `valid_date = today + $LICENSE_VALIDITY_MONTHS` (default
  12), and — only the first time — a signed `license_key` is generated and emailed.
- An admin **disapproves**: status **`disapproved`**, key/date cleared; the user
  gets a "needs additional info" email.
- **Renew** clones an existing license into a fresh `new` form.
- Access control (`#check_access`): non-admins may only see/edit their own licenses
  and only while `pending`; admins see all.

### License-key cryptography (`lib/util/encryption_util.rb`)
Hybrid RSA + AES. The payload `"appliance_id;organization;valid_date"` is
AES-256-CBC encrypted with a random key; that key is RSA `private_encrypt`ed; the
output is `base64(rsa_blob)|base64(cipher)`. The appliance verifies it with the
**public** key (`config/keys/public.pem`) via `public_decrypt`. The RSA private
key (`config/keys/private.pem`) is gitignored and supplied per environment.

> This format is an **external contract** — appliances in the field validate
> against it, and it is byte-stable across OpenSSL 1.1→3 (a Ruby/OpenSSL upgrade
> does not break it). Issue #34 proposes a standard signed-payload scheme for new
> licenses while keeping this format for back-compat; treat changes here with care.

### Authentication & user lookup
- Login calls `LinkedData::Client::Models::User.authenticate` against the BioPortal
  REST API; the returned user (apikey, `admin?`) is stored in `session[:user]`.
  Admins can `login_as` another user.
- User lookups use `ApplicationHelper#find_user_by_bp_username`, which GETs
  `/users/{username}` **directly** (not the paginated `/users` list — the fix for
  issue #35). Don't reintroduce a list-and-filter approach.

### Data model (`db/schema.rb`)
- `licenses`: `bp_username`, first/last name, organization, `appliance_id`,
  `license_key`, `valid_date`, `approval_status` (enum approved/disapproved/pending),
  `expiration_reminder_sent`, FK → `license_purpose`.
- `license_purposes`: nine seeded categories (`db/seeds.rb`).
- An Appliance ID validates as a UUID or a `$LEGACY_APPLIANCE_ID-…` pattern.

### Notifications & scheduling
- `NotifierMailer`: request submitted (user + admin), approved, disapproved,
  to-expire. SMTP is set per environment.
- `config/initializers/sandbox_email_interceptor.rb` reroutes *all* mail to
  `$EMAIL_OVERRIDE` in `staging` — preserve this behavior when changing mail.
- A nightly rake task `batch:send_licence_to_expire_notifications`
  (`lib/tasks/batch.rake`) emails users `$LICENCE_TO_EXPIRE_NUM_DAYS_ADVANCE` days
  before expiry; `config/schedule.rb` builds the crontab with a deterministic
  per-host minute jitter (`lib/util/cron_parser.rb`).

## Key Directories

```
app/          controllers, models (license, license_purpose), helpers, mailers, views
config/       environments, initializers, keys/, license_server_config.rb.sample, schedule.rb
lib/tasks/    batch.rake;   lib/util/  encryption_util.rb, cron_parser.rb
db/           migrations, schema.rb, seeds.rb
docker/       entrypoint.sh + ENV-driven config templates
test/         Minitest (characterization, models, integration)
docs/plans/   design notes & decision logs
```

## Configuration

Real configuration is **not committed**. Each environment loads
`config/license_server_config_<env>.rb` (see `config/environments/*.rb`), copied
from `config/license_server_config.rb.sample`. Key globals: `$BP_REST_URL`,
`$API_KEY`, `$PRIVATE_KEY_FILE`/`$PUBLIC_KEY_FILE`, `$LICENSE_VALIDITY_MONTHS`,
`$LEGACY_APPLIANCE_ID`, the expiry-notification settings, and the `$*_EMAIL` + SMTP
settings. Gitignored: `config/license_server_config*.rb`, `config/database.yml`,
`config/secrets.yml`, `config/keys/private.pem`, `data/`.

In the container, configuration is supplied via **environment variables** —
`docker/license_server_config.rb` reads `ENV` and the entrypoint renders it at
startup, so no secrets are baked into the image.

## Running & Testing

Turnkey (Docker):

```bash
BP_REST_URL=<api> API_KEY=<key> docker compose up --build   # → http://localhost:3000
```

Brings up app + MySQL + memcached, migrates/seeds, and serves Puma. For production,
provide `SECRET_KEY_BASE` and a real RSA private key (mount it + set
`PRIVATE_KEY_FILE`); otherwise the entrypoint generates ephemeral dev values (with
warnings).

Tests (Minitest):

```bash
docker compose run --rm test          # full suite in a test-flavored image
```

CI runs the same suite on push/PR (`.github/workflows/test.yml`). The suite stubs
the two BioPortal API calls, so it needs no live API.

## Code Style / Tooling

- Ruby: RuboCop (`bundle exec rubocop`)
- Security: Brakeman (`bundle exec brakeman`)

## Gotchas (carry into future changes)

- **`ontologies_api_client` version:** use the GitHub tag **`v2.9.0`** (gemspec
  2.9.0, requires `activesupport 8.0.3`) — NOT the numerically-higher `v5.x` tags,
  which are a stale lineage (gemspec 0.0.6, loose deps that mis-resolve under
  Faraday 2). The gem is GitHub-sourced; the `ontologies_api_client 0.0.6` on
  rubygems.org is unrelated — never use it.
- **Rails 8 + Minitest:** pin **`minitest ~> 5.25`** (minitest 6 breaks the Rails 8
  test runner); `require 'minitest/mock'` for `Object#stub`.
- **Security posture:** CSRF is enabled (no blanket
  `skip_before_action :verify_authenticity_token`); use **strong params**, not
  `params.permit!` (mass-assignment once let a non-admin self-set
  `approval_status=approved` and self-issue a key); keep user input out of SQL
  string interpolation.
- **The license-key format is an external contract** — don't change it (see above).

## Design Notes & History

`docs/plans/` holds dated design notes and the record of the Rails 8 / Ruby 3.2
modernization (orientation, a behavioral characterization of the app, and the
upgrade plan) — useful "how we got here / what's next" context.

## Useful Links

- API client: https://github.com/ncbo/ontologies_api_ruby_client
- Sibling frontend application: https://github.com/ncbo/bioportal_web_ui
