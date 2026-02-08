require "i18n"

module RailsI18nOnair
  class Backend
    # This backend acts as a proxy that delegates to either
    # the database backend or file backend based on configuration

    def initialize
      @file_backend = I18n::Backend::Simple.new
      @database_backend = DatabaseBackend.new
    end

    def current_backend
      if RailsI18nOnair.configuration.database_mode?
        @database_backend
      else
        @file_backend
      end
    end

    # Delegate all I18n backend methods to the current backend
    def translate(locale, key, options = {})
      current_backend.translate(locale, key, options)
    end

    def localize(locale, object, format = :default, options = {})
      current_backend.localize(locale, object, format, options)
    end

    def store_translations(locale, data, options = {})
      current_backend.store_translations(locale, data, options)
    end

    def available_locales
      current_backend.available_locales
    end

    def reload!
      @file_backend.reload! if @file_backend.respond_to?(:reload!)
      @database_backend.reload! if @database_backend.respond_to?(:reload!)
    end

    def load_translations(*filenames)
      @file_backend.load_translations(*filenames)
    end

    # Database Backend Implementation with Three-Tier Caching
    class DatabaseBackend < I18n::Backend::Simple
      def initialize
        super
        @memory_cache = {}  # Layer 1: In-memory cache
        @loaded_locales = Set.new  # Track which locales are loaded
        @mutex = Mutex.new  # Thread-safety for cache access

        # Don't load translations upfront - use lazy loading
        load_translations_from_database if RailsI18nOnair.configuration.lazy_load_locales == false
      end

      def available_locales
        # Cache available locales for 5 minutes (Layer 3: Application cache)
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
          # Reload specific locale
          reload_locale(locale)
        else
          # Full reload
          @mutex.synchronize do
            @initialized = false
            @memory_cache.clear
            @loaded_locales.clear
            @translations = {}
          end

          # Clear application-level cache (Layer 3)
          if defined?(Rails) && Rails.cache
            Rails.cache.delete_matched("i18n_onair:*")
          end

          # Optional: Warm up cache with default locale
          if options[:warm_up] != false && defined?(I18n)
            load_locale(I18n.default_locale)
          end
        end
      end

      def reload_locale(locale)
        locale_sym = locale.to_sym

        @mutex.synchronize do
          # Remove from memory (Layer 1)
          @memory_cache.delete(locale_sym)
          @loaded_locales.delete(locale_sym)
          @translations.delete(locale_sym) if @translations

          # Clear application cache (Layer 3)
          if defined?(Rails) && Rails.cache
            Rails.cache.delete("i18n_onair:locale:#{locale}")
          end
        end

        # Reload immediately
        load_locale(locale)
      end

      protected

      def load_translations_from_database
        # This is now called selectively, not on initialization
        # Only loads locales that are actually requested
        return unless defined?(I18n)

        # Preload only default locale if lazy loading is enabled
        if RailsI18nOnair.configuration.lazy_load_locales
          load_locale(I18n.default_locale)
        else
          # Load all locales (legacy behavior)
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

      # Lazy load locale on first access
      def load_locale(locale)
        return unless defined?(RailsI18nOnair::Translation)

        locale_sym = locale.to_sym

        # Check if already loaded
        return if @loaded_locales.include?(locale_sym)

        @mutex.synchronize do
          # Double-check after acquiring lock
          return if @loaded_locales.include?(locale_sym)

          # Try Layer 3: Application cache
          translation_data = fetch_from_cache_or_database(locale)

          # Store in Layer 1: Memory
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
            # Load from database
            translation_record = RailsI18nOnair::Translation.load_locale(locale)
            translation_record&.translation || {}
          end
        else
          # Direct database fetch without caching
          translation_record = RailsI18nOnair::Translation.load_locale(locale)
          translation_record&.translation || {}
        end
      end

      def lookup(locale, key, scope = [], options = {})
        # Ensure locale is loaded (Layer 1: Memory)
        load_locale(locale) unless @loaded_locales.include?(locale.to_sym)

        # Try Layer 1: In-memory lookup (super calls parent Simple backend)
        result = super(locale, key, scope, options)

        return result if result || options[:default]

        # If not found and caching is enabled, try direct JSONB query
        # This is useful for dynamic keys not in cache
        if RailsI18nOnair.configuration.cache_translations
          full_key = I18n.normalize_keys(locale, key, scope, options[:separator]).join('.')

          # Layer 2: Request-level cache (if Current is available)
          if defined?(RailsI18nOnair::Current)
            request_cache_key = "#{locale}:#{full_key}"
            RailsI18nOnair::Current.translation_cache.fetch(request_cache_key) do
              lookup_from_database(locale, full_key)
            end
          else
            lookup_from_database(locale, full_key)
          end
        else
          nil
        end
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
        # Direct JSONB lookup for cache miss
        return nil unless defined?(RailsI18nOnair::Translation)

        RailsI18nOnair::Translation.lookup_key(locale, key_path)
      end
    end
  end
end
