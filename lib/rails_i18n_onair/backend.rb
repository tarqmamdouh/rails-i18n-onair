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

    # Database Backend Implementation
    class DatabaseBackend < I18n::Backend::Simple
      def initialize
        super
        load_translations_from_database
      end

      def available_locales
        if defined?(RailsI18nOnair::Translation)
          RailsI18nOnair::Translation.pluck(:language).map(&:to_sym)
        else
          []
        end
      end

      def reload!
        @initialized = false
        @translations = {}
        load_translations_from_database
      end

      protected

      def load_translations_from_database
        return unless defined?(RailsI18nOnair::Translation)

        RailsI18nOnair::Translation.find_each do |translation|
          store_translations(translation.language.to_sym, translation.translation, escape: false)
        end
      end

      def lookup(locale, key, scope = [], options = {})
        # Try to lookup in memory first
        result = super(locale, key, scope, options)

        # If not found and we have a default, return it
        return result if result || options[:default]

        # Otherwise return nil (translation missing)
        nil
      end
    end
  end
end
