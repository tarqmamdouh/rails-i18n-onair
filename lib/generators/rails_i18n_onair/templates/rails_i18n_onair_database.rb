RailsI18nOnair.configure do |config|
  # Storage mode for translations
  # Options:
  #   :file     - Use local YAML files (default, no database required)
  #   :database - Use database storage (requires migrations)
  config.storage_mode = :database

  # Enable the backend to intercept t() calls in views and controllers
  # config.enable_backend = false

  # Enable caching of translations (recommended for production)
  # config.cache_translations = true

  # Lazy load locales on-demand instead of loading all at startup
  # config.lazy_load_locales = true
end
