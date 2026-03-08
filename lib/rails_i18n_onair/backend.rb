require "i18n"
require "i18n/backend/chain"

module RailsI18nOnair
  # Database-first backend: looks up translations in the DB,
  # falls back to whatever backend was previously configured (e.g. YAML files).
  #
  # Installed automatically by the engine when the translations table exists.
  # Usage: I18n::Backend::Chain.new(DatabaseBackend.new, existing_file_backend)
  class DatabaseBackend < I18n::Backend::Simple
    def initialize
      super
      @initialized = true  # Prevent Simple from loading YAML files — we only use the DB
      @memory_cache = {}
      @loaded_locales = Set.new
      @mutex = Mutex.new

      load_translations_from_database if RailsI18nOnair.configuration.lazy_load_locales == false
    end

    # Override: never load YAML files. This backend is DB-only;
    # the Chain's second backend (file_backend) handles YAML fallback.
    def init_translations
      @initialized = true
    end

    def load_translations(*_filenames)
      # no-op — YAML loading belongs to the file backend in the Chain
    end

    def available_locales
      cache_key = "i18n_onair:available_locales"

      if defined?(Rails) && Rails.cache && RailsI18nOnair.configuration.cache_translations
        Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
          fetch_available_locales
        end
      else
        fetch_available_locales
      end
    end

    def reload!(options = {})
      locale = options[:locale]

      if locale
        reload_locale(locale)
      else
        @mutex.synchronize do
          @initialized = false
          @memory_cache.clear
          @loaded_locales.clear
          @translations = {}
        end

        if defined?(Rails) && Rails.cache
          Rails.cache.delete_matched("i18n_onair:*")
        end

        if options[:warm_up] != false && defined?(I18n)
          load_locale(I18n.default_locale)
        end
      end
    end

    def reload_locale(locale)
      locale_sym = locale.to_sym

      @mutex.synchronize do
        @memory_cache.delete(locale_sym)
        @loaded_locales.delete(locale_sym)
        @translations.delete(locale_sym) if @translations

        if defined?(Rails) && Rails.cache
          Rails.cache.delete("i18n_onair:locale:#{locale}")
        end
      end

      load_locale(locale)
    end

    protected

    def load_translations_from_database
      return unless defined?(I18n)

      if RailsI18nOnair.configuration.lazy_load_locales
        load_locale(I18n.default_locale)
      else
        load_all_locales
      end
    end

    def load_all_locales
      return unless defined?(RailsI18nOnair::Translation)

      RailsI18nOnair::Translation.find_each do |translation|
        store_translations(translation.language.to_sym, translation.translation, escape: false)
        @loaded_locales.add(translation.language.to_sym)
      end
    end

    def load_locale(locale)
      return unless defined?(RailsI18nOnair::Translation)

      locale_sym = locale.to_sym
      return if @loaded_locales.include?(locale_sym)

      @mutex.synchronize do
        return if @loaded_locales.include?(locale_sym)

        translation_data = fetch_from_cache_or_database(locale)

        unless translation_data.nil? || translation_data.empty?
          store_translations(locale_sym, translation_data, escape: false)
          @memory_cache[locale_sym] = translation_data
          @loaded_locales.add(locale_sym)
        end
      end
    end

    def fetch_from_cache_or_database(locale)
      cache_key = "i18n_onair:locale:#{locale}"

      if defined?(Rails) && Rails.cache && RailsI18nOnair.configuration.cache_translations
        Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          translation_record = RailsI18nOnair::Translation.load_locale(locale)
          translation_record&.translation || {}
        end
      else
        translation_record = RailsI18nOnair::Translation.load_locale(locale)
        translation_record&.translation || {}
      end
    end

    def lookup(locale, key, scope = [], options = {})
      # Ensure locale is loaded from DB (lazy)
      load_locale(locale) unless @loaded_locales.include?(locale.to_sym)

      # In-memory lookup (stored via store_translations from DB data)
      result = super(locale, key, scope, options)

      # If found in DB data, return it; otherwise return nil so Chain falls back to file backend
      return result if result

      # Try direct JSONB query for keys not yet in memory (e.g. dynamic or uncached)
      if RailsI18nOnair.configuration.cache_translations
        full_key = I18n.normalize_keys(locale, key, scope, options[:separator]).join(".")

        if defined?(RailsI18nOnair::Current)
          request_cache_key = "#{locale}:#{full_key}"
          RailsI18nOnair::Current.translation_cache.fetch(request_cache_key) do
            lookup_from_database(locale, full_key)
          end
        else
          lookup_from_database(locale, full_key)
        end
      end
      # Returns nil if not found → Chain backend will try next backend (YAML files)
    end

    private

    def fetch_available_locales
      if defined?(RailsI18nOnair::Translation)
        RailsI18nOnair::Translation.pluck(:language).map(&:to_sym)
      else
        []
      end
    end

    def lookup_from_database(locale, key_path)
      return nil unless defined?(RailsI18nOnair::Translation)

      RailsI18nOnair::Translation.lookup_key(locale, key_path)
    end
  end
end
