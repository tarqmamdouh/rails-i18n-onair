RailsI18nOnair.configure do |config|
  # Storage mode for translations
  # Options:
  #   :file     - Use local YAML files (default, no database required)
  #   :database - Use database storage (requires migrations)
  config.storage_mode = :database
end
