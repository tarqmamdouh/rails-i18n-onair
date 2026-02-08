# RailsI18nOnair

A comprehensive i18n management solution for Rails monolith applications.

## Requirements

- Ruby 2.7.5+
- Rails 6.0+
- PostgreSQL (for JSONB support)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rails_i18n_onair"
```

And then execute:

```bash
$ bundle install
```

Run the install generator:

```bash
$ rails generate rails_i18n_onair:install
```

This will:
- Create an initializer at `config/initializers/rails_i18n_onair.rb`
- Copy migrations (if using database mode)

**If using database mode**, run the migrations:

```bash
$ rails db:migrate
```

## Configuration

Configure the gem in `config/initializers/rails_i18n_onair.rb`:

```ruby
RailsI18nOnair.configure do |config|
  # Storage mode for translations
  # Options:
  #   :file     - Use local YAML files (default, no database required)
  #   :database - Use database storage (requires migrations)
  config.storage_mode = :file

  # Path to locale files when using file mode
  # Default: "config/locales"
  config.locale_files_path = "config/locales"
end
```

### Storage Modes

#### File Mode (Default)
Uses your existing YAML locale files in `config/locales/`. Perfect for:
- Small to medium applications
- Apps with simple translation needs
- When you want to keep translations in version control

```ruby
config.storage_mode = :file
config.locale_files_path = "config/locales"
```

#### Database Mode
Stores translations in PostgreSQL with JSONB. Perfect for:
- Large applications with many translations
- Dynamic translation management
- When you need a web UI to manage translations
- Multi-tenant applications

```ruby
config.storage_mode = :database
```

**Note:** Database mode requires PostgreSQL for JSONB support.

## Usage

### Importing Locale Files to Database

If you're using database mode, you can import your existing YAML locale files into the database:

#### Import All Locale Files

```bash
$ rake rails_i18n_onair:import:all
```

This will:
- Scan the configured `locale_files_path` directory
- Find all files matching the pattern `[language].yml` (e.g., `en.yml`, `fr.yml`, `es.yml`)
- Import each file into the `translations` table
- Skip files that don't match the naming convention

**Supported file naming patterns:**
- `en.yml` - English
- `fr.yml` - French
- `es.yml` - Spanish
- `es-MX.yml` - Spanish (Mexico)
- `pt-BR.yml` - Portuguese (Brazil)

**Example output:**
```
Importing locale files from: config/locales
================================================================================

Import Summary:
  Imported: 3 file(s)
  Skipped:  1 file(s)

Errors:
  - Skipped invalid_file.txt: Invalid file name format

================================================================================
Import completed!
```

#### Import a Specific Language

```bash
$ rake rails_i18n_onair:import:language[en]
$ rake rails_i18n_onair:import:language[fr]
```

### Models

#### Translator
The `Translator` model handles authentication for the translation dashboard:

```ruby
# Create a translator
translator = RailsI18nOnair::Translator.create(
  username: "admin",
  password: "secure_password"
)

# Authenticate
translator.authenticate("secure_password")
```

#### Translation
The `Translation` model stores translations in JSONB format:

```ruby
# Import from YAML file
RailsI18nOnair::Translation.import_from_yaml("en", "config/locales/en.yml")

# Find translation by language
translation = RailsI18nOnair::Translation.find_by(language: "en")

# Get a specific translation value
translation.get_translation("user.name")  # => "Name"

# Set a translation value
translation.set_translation("user.name", "Full Name")

# Merge new translations
translation.merge_translations({ "new_key" => "New Value" })

# Export to YAML
translation.export_to_yaml

# Get all available languages
RailsI18nOnair::Translation.available_languages  # => ["en", "fr", "es"]
```

#### Using the Importer Directly

```ruby
# Import all locale files
importer = RailsI18nOnair::Importer.new
result = importer.import_all

puts "Imported: #{result[:imported]}"
puts "Skipped: #{result[:skipped]}"
puts "Errors: #{result[:errors]}"

# Import a specific language
importer.import_language("en")

# Use custom locale path
custom_importer = RailsI18nOnair::Importer.new("custom/path/to/locales")
custom_importer.import_all
```

### Database Schema

**Translators Table:**
- `username` (string, unique, required)
- `password_digest` (string, required)
- `created_at`, `updated_at`

**Translations Table:**
- `language` (string, unique, required)
- `translation` (jsonb, required, default: {})
- `created_at`, `updated_at`
- Index on `language` (unique)
- GIN index on `translation` for fast JSONB queries

## Development

After checking out the repo, run `bundle install` to install dependencies.

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
