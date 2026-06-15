# 2026-06-01 — Behavioral Characterization & Test Sketch

Purpose: a precise, line-derived description of **what this app does today**, so
we can (a) preserve behavior across the dockerization + Rails/Ruby upgrade,
(b) design a characterization test harness against it, and (c) give reviewers a
precise reference to confirm before changes. Derived from a full static
read of the code + git history at HEAD `452926f`. Nothing here has been executed
yet — the harness/spike will validate it.

> Companion docs: [`2026-06-01-modernization-strategy.md`](2026-06-01-modernization-strategy.md)
> (paths & decision), [`2026-06-01-orientation.md`](2026-06-01-orientation.md)
> (survey), and architecture in [`../../CLAUDE.md`](../../CLAUDE.md).

## TL;DR for the upgrade

- **External API surface = 2 calls only** (`User.authenticate`, `User.get`). The
  whole client/Rails coupling risk reduces to validating these two. **This is the
  spike.**
- **License-key format is an external contract** (deployed appliances verify it
  with the committed public key). Must be byte-compatible. Don't change it.
- **Security debt to fix during cleanup (changes behavior intentionally):** CSRF
  is disabled app-wide; `params.permit!` mass-assignment; raw SQL interpolation;
  session stores the BP apikey and it's echoed into page JS.

## Authorship / intent (from git history)

- **Michael Dorf (`mdorf`, NCBO/Stanford)** built ~all of it in a focused
  Jan–Apr 2020 sprint (workflow, admin actions, notifications, datatables UI,
  cron, crypto).
- **Alex Skrenchuk (NCBO)** added the ops layer (Capistrano, staging env, whenever
  cron deploy, mem_cache_store, the 2023 modernization nudge + 2025 deploy
  workflow).
- **Jennifer Vendetti (`jvendetti`, NCBO)** — 2026 user-lookup fix (#35).
- Intent clues: commits repeatedly harden against **flaky BP API client
  responses** (`766ccaf`: auth returns truthy-but-no-apikey → check `&.apikey`;
  `87e968e`/#1-#8: BP users can disappear → handle nil `mail_user`) and against
  **editing a live license** (`62a0a41`: lock Appliance ID once a key exists).

## Roles & access model

- **Anonymous** → only the landing page + login. `check_access` redirects any
  `licenses` action to login (preserving `redirect` back-URL).
- **Logged-in non-admin (owner)** → sees/creates only their own licenses (scoped
  by `bp_username == session user`); may edit a license **only while `pending`**;
  may renew their latest approved license. Cannot see ID/username/admin columns.
- **Admin** (`session[:user].admin?` from BP) → sees all licenses; can create on
  behalf of others, edit any, approve/disapprove (when not expired), delete, and
  `login_as` another user. Sees extra fields (License ID, BP username, name,
  Identification, Comments, Approval Status).

## External dependencies / integration points (the upgrade-sensitive list)

| Dependency | Where | Notes for upgrade/docker |
|---|---|---|
| **BP REST API — `User.authenticate(user,pass)`** | `LoginController#create` | Returns a client User (apikey, admin?, firstName, lastName, email, username) **or** a truthy object w/ `errors`/`error` and no `apikey`. Login guard: `logged_in_user&.apikey && !errors && !error`. |
| **BP REST API — `User.get("$BP_REST_URL/users/{username}")`** | `ApplicationHelper#find_user_by_bp_username` | Direct GET (NOT the paginated `/users` list — that's the #35 fix). Returns user, or nil/`.errors` → treated as "no user". |
| `ontologies_api_client` config | `config/initializers/ontologies_api_client.rb` | rest_url, apikey ($API_KEY), purl_prefix, caching flag. |
| **MySQL** | `licenses`, `license_purposes` | 2 tables; see schema. |
| **Memcached** | session + cache (`:mem_cache_store`, ns `LicenseServer`) | sessions live here in prod/staging. |
| **SMTP** | `ActionMailer` smtp_settings in per-env config | 5 mail types. |
| **RSA keypair** | `config/keys/*.pem` ($PRIVATE/$PUBLIC_KEY_FILE) | private = signing; public committed for reference. |
| **whenever/cron** | `config/schedule.rb` → `batch:send_licence_to_expire_notifications` | per-host minute jitter via xxHash. |
| **Browser CDN assets** | `_header`/`_footer` | DataTables CSS/JS + Google Fonts from CDNs; jQuery/Cookies via sprockets `vendor.js`. Runtime browser network deps. |

Session stores the **entire** BP user object (incl. `apikey`); `_header.html.erb`
emits `$(document).data({user: session[:user].to_json})` — apikey reaches page JS.

## Route → action surface

```
GET  /                         license_server#index   landing (or redirect to /licenses if logged in)
*    /login (resources)        login#index/create     index=form, create=authenticate
GET  /logout                   login#destroy          clear session
GET  /login_as/:login_as       login#login_as         admin impersonation
resources :licenses            index show new edit create update destroy
  POST  /licenses/:id/approve     approve
  POST  /licenses/:id/disapprove  disapprove
  POST  /licenses/:id/renew       renew   (also GET :renew)
resources :license_server      (only #index used)
```
`LicensesController` before_actions: `check_access` (auth + owner scoping),
`check_license_exists` (admin 404 if id missing), `check_for_cancel` (Cancel
button on create/update → back to index), `init_license_purposes` (all),
`init_max_ids` (index/show).

## Per-action behavior

### `LoginController`
- **index**: if logged in → `/licenses`. Else capture `redirect` (from param or
  referer) into session for post-login bounce.
- **create**: validate username/password present → `User.authenticate`. Success
  (`&.apikey` etc.) → store user in session (`session[:user][:admin]=admin?`),
  redirect to saved `redirect` or `/licenses`. Failure → re-render with the
  client's error message (or "Invalid username/password combination").
- **login_as** (admin only): look up target via `find_user_by_bp_username`; stash
  current user in `session[:admin_user]`, swap `session[:user]` to target, **keep
  the admin's apikey**. Redirect back.
- **destroy**: `session[:user]=nil`, flash "Logged out", → root.

### `LicensesController`
- **index**: list licenses (admin=all, else own), ordered `approval_status DESC,
  id DESC`; compute per-appliance row color + `latest` flag; group rows by
  appliance_id. View toggles All/Latest via cookie (`licensesLatestOnly`),
  DataTables with `stateSave`.
- **new**: blank License. For non-admins, pre-fill first/last name from the
  session BP user. ⚠️ **#20 bug:** `session[:user].firstName.strip` raises if
  the BP account has nil first/last name.
- **edit**: admin → edit; non-admin → edit only if `pending`, else falls through
  to **show** (read-only). Appliance ID field becomes read-only (hidden field)
  once `license_key` exists (`62a0a41`).
- **show**: detail view; shows license key + copy button when present; expiry
  status; admin-only Identification/Comments.
- **create**: `save_license_from_params` (see invariants). Emails: `submitted`
  to the user **unless** status already `approved`; `submitted_admin` to
  `$ADMIN_EMAIL` **unless** the creator is an admin. If admin set status to
  `approved`, immediately `approve_license` (generates key + emails `approved`).
- **update**: same save path; re-render edit on error, else flash + redirect.
- **approve** / **approve_license(id)**: set `approved`; **only if `valid_date`
  or `license_key` is nil** set `valid_date = today + $LICENSE_VALIDITY_MONTHS`
  and generate `license_key` (so re-approve never regenerates). Email `approved`
  with the key; if BP user gone → flash error, no email.
- **disapprove**: set `disapproved`, **clear `valid_date` and `license_key`**;
  email `disapproved`; nil-user → flash error.
- **renew**: clone the license with `id=nil` and render `new` (a fresh pending
  request for the same appliance_id; the prior row is retained as history).
- **destroy** (admin): hard `destroy!` + flash.

## Domain rules & invariants (must hold after upgrade)

1. **approval_status** ∈ {`pending` (default), `approved`, `disapproved`}, stored
   as string enum.
2. **Appliance ID valid** iff UUID **or** matches `^$LEGACY_APPLIANCE_ID-[0-9a-z]+$`.
3. **bp_username must resolve** to a real BP user (`find_user_by_bp_username`) at
   create/update validation time.
4. **Key + valid_date are generated once**, on first approval; never regenerated
   on subsequent approves. Disapprove clears both, so a later re-approve mints a
   *new* key and a fresh `valid_date`.
5. **"latest" = MAX(id) per appliance_id.** Renew adds a new row; the appliance's
   history is the id-ordered chain. Renew button only on latest **and** approved.
6. **Approve/Disapprove** allowed only for admin **and** non-expired licenses.
7. **Edit** allowed for admin always; for owner only while `pending`.
8. **Expiry**: `expired?` = `valid_date < today`; `about_to_expire?` = within
   `today .. today + $LICENCE_TO_EXPIRE_NUM_DAYS_ADVANCE`.
9. **Row color**: deterministic from `appliance_id[0..5]` (chroma hash), except
   the legacy-prefix appliances (no color).

### Email matrix
| Trigger | To user | To admin |
|---|---|---|
| User self-creates (pending) | `submitted` | `submitted_admin` |
| Admin creates for user, not approved | `submitted` | — |
| Admin creates for user, approved | — | — then `approved` (with key) |
| Approve | `approved` (key) | — |
| Disapprove | `disapproved` | — |
| Cron, license about to expire | `license_to_expire` | — |

Staging reroutes **all** mail to `$EMAIL_OVERRIDE` + subject tag
(`sandbox_email_interceptor.rb`).

## License-key crypto contract (DO NOT change format)

`lib/util/encryption_util.rb`, payload `"appliance_id;organization;valid_date"`:
1. AES-256-CBC encrypt payload with a random key (implicit IV — the #34 concern).
2. RSA `private_encrypt` the AES key.
3. Emit `base64(rsa_blob) + "|" + base64(aes_ciphertext)`.
Appliance verifies via RSA `public_decrypt` of part 1 → AES key → decrypt part 2.
**Acceptance test:** a key minted by the app must round-trip through
`EncryptionUtil.decrypt(public_key, key)` back to the exact payload.

## Background job

`batch:send_licence_to_expire_notifications` (nightly): select latest, approved,
not-yet-reminded licenses with `valid_date` in `[today, today+N]`; email each
user `license_to_expire`; set `expiration_reminder_sent=true`. Note: the flag is
set **even if** the BP user is gone (no email sent in that case).

## Known fragilities / security debt (observed, not yet changed)

- **CSRF disabled**: every controller `skip_before_action :verify_authenticity_token`.
- **Mass assignment**: `params[:license].permit!` in `save_license_from_params`.
- **SQL string interpolation**: `init_max_ids` and `License.latest_licenses`
  interpolate `session username` / status / filters into SQL.
- **Apikey exposure**: full BP user (incl. apikey) in session + emitted to page JS.
- **Deprecated client-side `document.execCommand("copy")`** for the copy button.
- **API client pin brittleness**: #35 class of breakage as the live API evolves.

## How to test it (characterization harness sketch)

Three layers, cheap because the app is tiny:

1. **Pure unit (no DB/API):**
   - Crypto round-trip (mint → `decrypt` with public key → payload matches);
     stability of format string.
   - `License#expired?`, `#about_to_expire?`, `latest_licenses` SQL, appliance-ID
     validation regex (UUID + legacy pattern, and rejections).
   - `CronParser` minute jitter determinism.
2. **Request/integration with the BP API stubbed** (WebMock/VCR around the 2
   calls): login success/failure; owner-scoping & access control (anon→login,
   non-admin can't see others, edit-only-when-pending); create→submitted emails
   matrix; approve generates key once + email; disapprove clears key; renew clones;
   appliance-ID lock after key; the #20 nil-name path; admin-only delete.
   - Assert `ActionMailer::Base.deliveries` for the email matrix.
3. **Live smoke (NCBO's acceptance bar):** boot the app, log in with real BP
   creds against the API, create→approve a license, confirm the emailed key
   verifies with the public key. Compare screens/fields against the
   look-but-don't-touch production server.

Fixtures already present: `test/fixtures/licenses.yml`, `license_purposes.yml`.
Seed defines the 9 purposes. The current `test/*` files are empty scaffolding —
this harness is net-new and is the regression net for the upgrade.

## Open questions (can't infer from code)

- Exact appliance-side verification code/version — to guarantee key-format compat.
- Is `login_as` (impersonation) still used / wanted?
- Real value/shape of `$LEGACY_APPLIANCE_ID` (affects the validation regex + the
  one-time CSV import).
- Any consumers of the current email copy/subjects we must preserve verbatim.

## Next steps

1. Obtain BP **test credentials** → run the **2-call compatibility spike**
   (modern `ontologies_api_client` + Rails) — the gating unknown for the upgrade.
2. Scaffold the **layer-1 + layer-2** harness above (no live API) as the
   regression net.
3. Then proceed into path C (Ruby 3.2+/Rails 7–8, puma, dockerize) behind it.
