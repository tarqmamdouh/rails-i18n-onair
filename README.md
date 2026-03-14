# Rails I18n OnAir 🌍

![Rails I18n OnAir](app/assets/images/rails_i18n_onair/banner.svg)

**Live translation management for Rails monolith applications.** A mountable engine that gives your team a full-featured dashboard to manage i18n translations — with an optional Live UI mode that lets translators click directly on any text in your running app and edit it on the spot.

No more "hey can you update this string?" Slack messages. 🎉

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Storage Modes](#storage-modes)
- [Live UI](#live-ui)
- [Dashboard](#dashboard)
- [Models & API](#models--api)
- [Rake Tasks](#rake-tasks)
- [Authentication](#authentication)
- [Custom I18n Backend](#custom-i18n-backend)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- 🖥️ **Web Dashboard** — Browse, search, and edit all your translations from a clean UI
- 🗄️ **Dual Storage Modes** — Keep translations in YAML files _or_ store them in PostgreSQL with JSONB
- ✏️ **Live UI** — In-app inline editor: click any text, edit it, save it — without leaving the page
- 🔐 **Built-in Auth** — Separate translator accounts (no coupling to your `User` model)
- 📦 **Import / Export** — Round-trip between YAML files and the database in one command
- ⚡ **Smart Caching** — Request-level, Rails cache, and memory cache layers keep things fast
- 🔗 **Backend Chain** — Database-first lookup with automatic fallback to your YAML files
- 🛠️ **Install Generator** — Interactive setup wizard, migrations included

---

## Requirements

| Requirement | Version |
| --- | --- |
| Ruby | >= 2.7.5 |
| Rails | >= 6.0 |
| PostgreSQL | Required for **database mode** only |
| SQLite | Works for **file mode** and development |

---

## Installation

### 1. Add to your Gemfile

```ruby
gem "rails_i18n_onair"
```

```bash
bundle install
```

### 2. Run the install generator

The interactive installer handles everything — storage choice, migrations, routes, and an initial account:

```bash
rails generate rails_i18n_onair:install
```

It will:

1. Create `config/initializers/rails_i18n_onair.rb`
2. Ask which storage mode you want (`file` or `database`)
3. Copy the translator migration (always needed for auth)
4. Copy the translation migration (only if database mode)
5. Mount the engine at `/i18n` in your `routes.rb`
6. Offer to run `rails db:migrate` right away
7. Create your first translator account so you can log in immediately

### 3. Advanced install options

```bash
# Pre-select storage mode (skip the prompt)
rails generate rails_i18n_onair:install --storage-mode=database
rails generate rails_i18n_onair:install --storage-mode=file

# Skip creating the initial translator account
rails generate rails_i18n_onair:install --skip-translator
```

### 4. Manual migration installation

Need to install migrations separately (e.g., in a CI pipeline)?

```bash
rails rails_i18n_onair:install:migrations:translator   # auth table only
rails rails_i18n_onair:install:migrations:translation  # translations table (database mode)
rails rails_i18n_onair:install:migrations:all          # both at once

rails db:migrate
```

### 5. Mount the engine manually

The generator does this automatically, but if you need to do it yourself:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount RailsI18nOnair::Engine, at: "/i18n"
  # ... your routes
end
```

Visit `http://localhost:3000/i18n` to access the dashboard.

---

## Configuration

Configure the gem in `config/initializers/rails_i18n_onair.rb`:

```ruby
RailsI18nOnair.configure do |config|
  # :file (default) — reads/writes YAML files
  # :database        — reads/writes PostgreSQL JSONB
  config.storage_mode = :file

  # Where to find your locale YAML files (file mode only)
  # Default: "config/locales"
  config.locale_files_path = "config/locales"

  # Cache translations in memory + Rails cache
  # Strongly recommended for production
  # Default: true
  config.cache_translations = true

  # Load each locale lazily (on first use) instead of all at startup
  # Default: true
  config.lazy_load_locales = true

  # Enable the Live UI inline editing feature
  # When true, a toolbar appears for signed-in translators
  # Default: false
  config.live_ui = false
end
```

### Resetting configuration (useful in tests)

```ruby
RailsI18nOnair.reset_configuration!
```

---

## Storage Modes

### File Mode (default)

Works with your existing `config/locales/*.yml` files. No database table required for translations — just the translator auth table.

Best for:

- Keeping translations in version control
- Small to medium projects
- Teams that prefer YAML as the source of truth

```ruby
config.storage_mode = :file
config.locale_files_path = "config/locales"
```

The dashboard lets you view, edit, and reload YAML files. You can also sync files to the database at any time if you want to migrate later.

### Database Mode

Stores translations in a PostgreSQL JSONB column. Supports full CRUD from the dashboard UI with no file system access needed.

Best for:

- Large applications with many languages
- Non-technical translators who need a UI
- Dynamic, runtime-editable translations
- Multi-tenant setups

```ruby
config.storage_mode = :database
config.cache_translations = true
```

> **Note:** Database mode requires PostgreSQL for its JSONB column (`translation jsonb`). SQLite works for tests and development (the gem uses a plain `json` column in that context).

#### Migrating from file to database

```bash
# Import all YAML files in config/locales into the database
rake rails_i18n_onair:import:all
```

---

## Live UI

Live UI is the gem's headline feature. When enabled, a floating toolbar appears in the bottom-right corner of your app for any signed-in translator. They can toggle **Edit Mode**, click on any translated string, and edit it inline — all without leaving the page.

### How it works

1. **Middleware** (`RailsI18nOnair::LiveUi::Middleware`) intercepts outgoing HTML responses and injects a self-contained `<script>` tag before `</body>`
2. **Translation helper override** (`RailsI18nOnair::LiveUi::TranslationHelper`) is prepended to `ActionView::Helpers::TranslationHelper` — every `t()` call wraps its output in a `<span>` with data attributes when the Live UI is active
3. **JavaScript** renders the toolbar, popover editor, and handles `PATCH` requests to the Live Translations API
4. Everything is cleaned up automatically — no DOM pollution when Live UI is off

### Enabling Live UI

```ruby
# config/initializers/rails_i18n_onair.rb
RailsI18nOnair.configure do |config|
  config.live_ui = true
end
```

Or toggle it at runtime from the dashboard under **Settings → Live UI**.

### Data attributes on spans

When Live UI is active, every `t()` call produces:

```html
<span
  data-i18n-onair="true"
  data-i18n-key="en.user.greeting"
  data-i18n-locale="en"
  style="display:contents"
>
  Hello, Alice!
</span>
```

`display:contents` makes the span invisible to layout — your existing CSS is unaffected. ✨

### Opting out per call

If a specific translation should never be wrapped (e.g., inside a JSON response or a meta tag):

```erb
<%= t("page.title", i18n_onair: false) %>
```

### Live UI toolbar

The injected toolbar provides:

- **FAB button** (bottom-right, always visible) — opens the panel
- **Edit Mode toggle** — highlights all editable spans on the page with a dashed outline
- **Click to edit** — clicking any highlighted span opens a popover with a textarea
- **Save / Cancel** — Save POSTes the new value to the API; the page updates instantly
- **Toast notifications** — Success/error feedback after each save

### Keyboard shortcut

Press **`Alt + Shift + E`** to toggle Edit Mode without reaching for the toolbar.

---

## Dashboard

Access the dashboard at the mount path (default `/i18n`).

### Navigation

| Section | URL | Description |
| --- | --- | --- |
| Dashboard | `/i18n` | Overview — translation counts, languages, recent activity |
| Translations | `/i18n/translations` | Full CRUD for translations (database mode) |
| Locale Files | `/i18n/locale_files` | View and edit YAML files (file mode) |
| Settings | `/i18n/settings` | Toggle Live UI and view current configuration |
| Login | `/i18n/login` | Translator sign-in |

### Dashboard (database mode)

Shows total translation records, list of languages, and entry counts per locale.

### Dashboard (file mode)

Shows all YAML files in the configured locale path with file sizes and modification times.

### Translations editor

- Edit raw translation data per language
- Nested key/value tree view
- Import from YAML, export to YAML
- Reload I18n backend after changes

---

## Models & API

### `RailsI18nOnair::Translator`

Handles authentication. Uses `has_secure_password` (bcrypt).

```ruby
# Create
translator = RailsI18nOnair::Translator.create!(username: "alice", password: "secret123")

# Authenticate
translator.authenticate("secret123")   # => translator
translator.authenticate("wrong")       # => false
```

**Validations:**

- `username` — required, unique
- `password` — required on create, minimum 6 characters

### `RailsI18nOnair::Translation`

Stores one record per language. The `translation` column holds the full nested JSONB hash.

```ruby
# Import from a YAML file
record = RailsI18nOnair::Translation.import_from_yaml("en", "config/locales/en.yml")

# Find
record = RailsI18nOnair::Translation.load_locale("en")

# Read a nested key
record.get_translation("en.user.name")   # => "Name"

# Write a nested key (persists immediately)
record.set_translation("en.user.name", "Full Name")

# Deep merge a hash into existing translations
record.merge_translations("en" => { "new_key" => "New Value" })

# Export to YAML string
yaml_string = record.export_to_yaml

# Class-level helpers
RailsI18nOnair::Translation.available_languages       # => ["en", "fr", "es"]
RailsI18nOnair::Translation.locale_exists?("en")      # => true
RailsI18nOnair::Translation.lookup_key("en", "en.user.name")  # => "Name"
RailsI18nOnair::Translation.load_locales(["en", "fr"])        # => { "en" => {...}, "fr" => {...} }
```

### Live Translations API

Used internally by the Live UI JavaScript. Available to any HTTP client too.

```http
PATCH /i18n/api/live_translations/:locale
```

**Request body (JSON):**

```json
{
  "key": "user.greeting",
  "value": "Hello, friend!"
}
```

**Response:**

```json
{ "status": "ok" }
```

**Errors:**

| Status | Condition |
| --- | --- |
| `403 Forbidden` | Live UI is disabled in configuration |
| `422 Unprocessable Entity` | Blank key, or locale not found in storage |
| `302 Redirect` | Not authenticated |

---

## Rake Tasks

### Import

```bash
# Import all locale YAML files into the database
rake rails_i18n_onair:import:all

# Import a single language
rake rails_i18n_onair:import:language[en]
rake rails_i18n_onair:import:language[pt-BR]
```

**Supported filename patterns:** `en.yml`, `fr.yml`, `es-MX.yml`, `pt-BR.yml`

Files that don't match the `[language].yml` convention are skipped with a note.

**Example output:**

```text
Importing locale files from: config/locales
================================================================================

Import Summary:
  Imported: 3 file(s)
  Skipped:  1 file(s)

Errors:
  - Skipped application.en.yml: Invalid file name format

================================================================================
Import completed!
```

### Migrations

```bash
rake rails_i18n_onair:install:migrations:translator   # translator auth table
rake rails_i18n_onair:install:migrations:translation  # translations JSONB table
rake rails_i18n_onair:install:migrations:all          # both
```

---

## Authentication

The gem ships its own authentication system — completely separate from your app's `User` model. There's no Devise, no Warden, just a session cookie and bcrypt.

### Creating translators

Via the install generator (prompted automatically), or manually:

```ruby
RailsI18nOnair::Translator.create!(username: "alice", password: "secret123")
```

### Session flow

1. `GET /i18n/login` — login form
2. `POST /i18n/login` — sets `session[:translator_id]`
3. `DELETE /i18n/logout` — clears the session
4. All dashboard routes run `before_action :authenticate_translator!` and redirect to the login page if not signed in

### The Live UI auth check

The middleware checks `session[:translator_id]` in the Rack env cookie directly — it doesn't hit the database on every request. The flag is stored in `RailsI18nOnair::Current.live_ui_active` (a `CurrentAttributes` attribute) and is reset automatically at the end of each request.

---

## Custom I18n Backend

When `storage_mode: :database` is configured and the translations table exists, the gem installs a custom `I18n::Backend::Chain`:

```text
RailsI18nOnair::DatabaseBackend → file backend (your YAML files)
```

This means:

- Translations found in the database are returned first
- Keys missing from the database fall back to your YAML files transparently
- Removing a translation from the database automatically falls back to the file

### Caching layers

The backend uses three cache layers (fast → slow):

1. **Request cache** — `RailsI18nOnair::Current.translation_cache` (a plain hash, reset each request)
2. **Memory cache** — `@memory_cache` on the backend instance
3. **Rails cache** — `Rails.cache.fetch("i18n_onair:locale:#{locale}", expires_in: 1.hour)`

All layers are cleared when you save a translation from the dashboard or the Live UI.

### Reloading the backend

```ruby
I18n.backend.reload!             # Clear all locales
I18n.backend.reload_locale(:en)  # Clear just one locale
```

Or use the dashboard: **Locale Files → Reload Backend**.

---

## Testing

The gem has a full RSpec test suite that runs without a dummy Rails app — components are loaded directly for speed.

```bash
bundle exec rspec
```

### Test structure

```text
spec/
├── spec_helper.rb              # Minimal RSpec config
├── rails_helper.rb             # DB setup, model loading, transaction rollback
├── unit/
│   ├── configuration_spec.rb
│   ├── current_spec.rb
│   ├── file_manager_spec.rb
│   ├── importer_spec.rb
│   └── live_ui/
│       ├── middleware_spec.rb
│       ├── script_spec.rb
│       └── translation_helper_spec.rb
├── models/
│   ├── translation_spec.rb
│   └── translator_spec.rb
└── controllers/
    ├── settings_controller_spec.rb
    └── api/
        └── live_translations_controller_spec.rb
```

Tests use SQLite in-memory with `ActiveRecord::Rollback` for isolation — no database cleanup gems needed.

---

## Database Schema

### `rails_i18n_onair_translators`

| Column | Type | Notes |
| --- | --- | --- |
| `id` | bigint | primary key |
| `username` | string | NOT NULL, unique |
| `password_digest` | string | NOT NULL |
| `created_at` | datetime | |
| `updated_at` | datetime | |

### `rails_i18n_onair_translations`

| Column | Type | Notes |
| --- | --- | --- |
| `id` | bigint | primary key |
| `language` | string | NOT NULL, unique (e.g. `"en"`, `"pt-BR"`) |
| `translation` | jsonb | NOT NULL, default `{}` |
| `created_at` | datetime | |
| `updated_at` | datetime | |

Indexes: unique on `language`, GIN on `translation` (fast JSONB key lookup).

---

## Development

```bash
git clone https://github.com/tarqmamdouh/rails-i18n-onair
cd rails-i18n-onair
bundle install
bundle exec rspec
```

The test suite uses SQLite in-memory — no PostgreSQL needed locally. For a production-parity test of the JSONB features, set `DATABASE_URL` to a Postgres instance before running specs.

---

## Contributing

Bug reports and pull requests are welcome on GitHub at [github.com/tarqmamdouh/rails-i18n-onair](https://github.com/tarqmamdouh/rails-i18n-onair)

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Add tests for your changes (the suite already has 176 examples — let's keep that green 🟢)
4. Open a pull request

---

## License

Released under the [MIT License](https://opensource.org/licenses/MIT).
