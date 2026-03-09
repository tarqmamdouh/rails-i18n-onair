RailsI18nOnair.configure do |config|
  # Storage mode for translations
  # Options:
  #   :file     - Use local YAML files (default, no database required)
  #   :database - Use database storage (requires migrations)
  config.storage_mode = :file

  # Path to locale files when using file mode
  # Default: "config/locales"
  config.locale_files_path = "config/locales"

  # Enable Live UI to allow signed-in translators to edit translations
  # directly from the application's pages (BETA)
  # config.live_ui = false
end
