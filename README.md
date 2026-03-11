# Rails I18n OnAir

![Rails I18n OnAir](app/assets/images/rails_i18n_onair/banner.svg)

A comprehensive i18n management solution for Rails monolith applications. Browse, edit, sync, and live-edit translations from a web dashboard or directly on the page.

## Requirements

- Ruby 2.7.2+
- Rails 6.0+
- PostgreSQL (for JSONB support in database mode)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rails_i18n_onair"
```

Then run:

```bash
$ bundle install
```

### Quick Install (Recommended)

Run the install generator, which will guide you through the setup:

```bash
$ rails generate rails_i18n_onair:install
```

This interactive installer will:

1. Create an initializer at `config/initializers/rails_i18n_onair.rb`
2. Ask you to choose a storage mode (file or database)
3. Install the translator migration (always required for authentication)
4. Install the translation migration (only if database mode is selected)
5. Mount the engine at `/i18n` in your routes
6. Prompt to run migrations
7. Create an initial translator account so you can log in immediately

**Specify storage mode directly:**

```bash
$ rails generate rails_i18n_onair:install --storage-mode=database
$ rails generate rails_i18n_onair:install --storage-mode=file
```

**Skip translator account creation:**

```bash
$ rails generate rails_i18n_onair:install --skip-translator
```

### Manual Migration Installation

If you need to install migrations separately:

```bash
# Install translator migration (always required)
$ rails rails_i18n_onair:install:migrations:translator

# Install translation migration (database mode only)
$ rails rails_i18n_onair:install:migrations:translation

# Or install both
$ rails rails_i18n_onair:install:migrations:all
```

Then run:

```bash
$ rails db:migrate
```

### Mounting the Engine

The install generator automatically mounts the engine, but if you need to do it manually:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount RailsI18nOnair::Engine, at: "/i18n"
end
```

Access the dashboard at `http://localhost:3000/i18n`

## Configuration

Configure the gem in `config/initializers/rails_i18n_onair.rb`:

```ruby
RailsI18nOnair.configure do |config|
  # Storage mode for translations
  # :file     — Use local YAML files (default, no database table required)
  # :database — Use database storage with JSONB (requires PostgreSQL + migrations)
  config.storage_mode = :file

  # Path to locale files (used by file mode and import tasks)
  # Default: "config/locales"
  config.locale_files_path = "config/locales"

  # Enable Live UI inline editing (requires translator sign-in)
  # Default: false
  config.live_ui = false

  # Enable caching of translations (recommended for production)
  # Default: true
  config.cache_translations = true

  # Lazy load locales on-demand instead of loading all at startup
  # Default: true
  config.lazy_load_locales = true
end
```

### Storage Modes

#### File Mode (Default)

Uses your existing YAML locale files in `config/locales/`. Best for:
- Small to medium applications
- Keeping translations in version control
- Apps with simple translation needs

```ruby
config.storage_mode = :file
config.locale_files_path = "config/locales"
```

#### Database Mode

Stores translations in PostgreSQL with JSONB. Best for:
- Large applications with many translations
- Dynamic translation management via the dashboard
- Multi-tenant applications

```ruby
config.storage_mode = :database
```

In database mode, I18n uses a chained backend: database lookup first, falling back to YAML files for any missing keys. Translations are cached at multiple levels (Rails cache, request-level, and in-memory) for performance.

## Dashboard

The web dashboard at `/i18n` provides:

- **Browse translations** — View all translations by language (database mode) or by file (file mode)
- **Edit translations** — Edit key-value pairs in a table UI with add/delete key support
- **Sync locales** — Compare two locales and copy missing keys from one to the other
- **Download all** — Download all translations as a ZIP archive

## Live UI

Live UI allows translators to edit translations directly on the page. When enabled and a translator is signed in, translatable text is highlighted and clickable. A floating toolbar lets translators toggle edit mode, click any translation, and save changes instantly.

### Enabling Live UI

```ruby
# config/initializers/rails_i18n_onair.rb
RailsI18nOnair.configure do |config|
  config.live_ui = true
end
```

Then sign in as a translator at `/i18n/login`. Once signed in, a floating toolbar appears on every page with an edit mode toggle.

### How It Works

Live UI operates through three layers that cover different translation contexts:

#### View translations (`t()` in templates)

The `TranslationHelper` is prepended to `ActionView::Helpers::TranslationHelper`. Every `t()` / `translate()` call in views and partials wraps its output in an editable `<span>` with data attributes:

```html
<span data-i18n-onair="true"
      data-i18n-key="welcome.title"
      data-i18n-locale="en"
      style="display:contents">Welcome!</span>
```

The `display:contents` style ensures the `<span>` does not affect layout.

For translations with interpolation variables (`%{name}`), the raw template and variable values are stored in additional data attributes so the editor can display the template for editing while the page shows the interpolated result.

#### Form submit buttons (`f.submit`)

The `FormHelper` is prepended to `ActionView::Helpers::FormBuilder`. When Live UI is active, `f.submit` renders a `<button>` instead of an `<input>`, allowing the translated label to be wrapped in an editable `<span>`:

```html
<!-- Without Live UI: -->
<input type="submit" value="Create User">

<!-- With Live UI: -->
<button type="submit">
  <span data-i18n-onair="true" data-i18n-key="helpers.submit.user.create" ...>
    Create User
  </span>
</button>
```

When Live UI is off, `f.submit` falls through to the original Rails helper — zero overhead.

#### Flash messages and controller translations

The `ControllerHelper` is prepended to `AbstractController::Translation`. Controller-level `t()` calls (commonly used for flash messages) embed invisible Unicode markers around the translated text:

```ruby
flash[:notice] = t("user.created_successfully")
# Internally stores: "⟦i18n:user.created_successfully:en⟧User created!⟦/i18n⟧"
```

These markers:
- Survive flash session serialization (they are just string bytes)
- Survive ERB HTML-escaping (Unicode mathematical brackets are not HTML-special characters)

The middleware replaces these markers with editable `<span>` wrappers before the response reaches the browser. The user never sees the raw markers.

### Edit Mode Persistence

Edit mode state is persisted in `localStorage`. When a translator toggles edit mode on, it stays active across page navigations and reloads until explicitly toggled off.

### Opting Out

For cases where wrapping breaks the layout (e.g., translations used as HTML attribute values), opt out per-key:

```ruby
t("some.key", i18n_onair: false)
```

### Locale Handling

If your application uses region-qualified locales in the URL (e.g., `en_FRA`, `pt-BR`), Live UI automatically strips the region and uses only the language code (`en`, `pt`) for file lookup and YAML key navigation. This matches the common convention of naming locale files `en.yml`, `fr.yml`, etc.

## Importing Locale Files

If you are using database mode, you can import your existing YAML locale files:

### Import All

```bash
$ rake rails_i18n_onair:import:all
```

This scans `config/locales/` for files matching `[language].yml` (e.g., `en.yml`, `fr.yml`, `en-US.yml`) and imports each into the database.

### Import a Specific Language

```bash
$ rake rails_i18n_onair:import:language[en]
$ rake rails_i18n_onair:import:language[fr]
```

## Models

### Translator

Handles authentication for the dashboard and Live UI:

```ruby
# Create a translator
RailsI18nOnair::Translator.create(
  username: "admin",
  password: "secure_password"
)

# Authenticate
translator.authenticate("secure_password")
```

Password minimum length: 6 characters.

### Translation (database mode)

Stores translations in JSONB format:

```ruby
# Find by language
translation = RailsI18nOnair::Translation.find_by(language: "en")

# Lookup a specific key
translation.get_translation("user.name") # => "Name"

# Set a specific key
translation.set_translation("user.name", "Full Name")

# Merge new translations
translation.merge_translations({ "new_key" => "New Value" })

# Import from YAML file
RailsI18nOnair::Translation.import_from_yaml("en", "config/locales/en.yml")

# Export to YAML
translation.export_to_yaml

# Available languages
RailsI18nOnair::Translation.available_languages # => ["en", "fr", "es"]
```

## Database Schema

**Translators Table:**
- `username` (string, unique, required)
- `password_digest` (string, required)
- `created_at`, `updated_at`

**Translations Table (database mode only):**
- `language` (string, unique, required)
- `translation` (jsonb, required, default: `{}`)
- `created_at`, `updated_at`
- Unique index on `language`
- GIN index on `translation` for fast JSONB queries

## Development

After checking out the repo, run `bundle install` to install dependencies.

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
