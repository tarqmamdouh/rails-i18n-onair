module RailsI18nOnair
  module Api
    class LiveTranslationsController < ApplicationController
      before_action :require_live_ui_enabled

      def update
        locale = normalize_locale(params[:locale])
        key    = params[:key]
        value  = params[:value]

        if key.blank?
          return render json: { error: "key is required" }, status: :unprocessable_entity
        end

        # Build the full key path including locale prefix
        # (DB stores data as { "en" => { "user" => { "name" => "..." } } })
        full_key = "#{locale}.#{key}"

        success = if RailsI18nOnair.configuration.database_mode?
                    update_database_translation(locale, full_key, value)
                  else
                    update_file_translation(locale, full_key, value)
                  end

        if success
          render json: { status: "ok", key: key, locale: locale, value: value }
        else
          render json: { error: "Failed to save translation" }, status: :unprocessable_entity
        end
      end

      private

      # Strip region/variant from locale: "en_FRA" → "en", "pt-BR" → "pt"
      # Translation files use language-only keys (en.yml, fr.yml, etc.)
      def normalize_locale(locale)
        locale.to_s.split(/[-_]/).first
      end

      def require_live_ui_enabled
        unless RailsI18nOnair.configuration.live_ui?
          render json: { error: "Live UI is not enabled" }, status: :forbidden
        end
      end

      def update_database_translation(locale, full_key, value)
        record = RailsI18nOnair::Translation.load_locale(locale)
        return false unless record

        record.set_translation(full_key, value)

        # Bust cache so the new value is served immediately
        if I18n.backend.respond_to?(:reload!)
          I18n.backend.reload!
        end

        true
      rescue StandardError => e
        Rails.logger&.error "RailsI18nOnair LiveUI: DB save failed — #{e.message}"
        false
      end

      def update_file_translation(locale, _full_key, value)
        key_path = params[:key]
        file_manager = RailsI18nOnair::FileManager.new
        filename = "#{locale}.yml"
        content  = file_manager.read_file(filename)
        return false unless content

        data = YAML.safe_load(content, permitted_classes: [Symbol], aliases: true) || {}
        data = {} unless data.is_a?(Hash)

        # Navigate to the correct nested key and update the value
        keys = [locale, *key_path.split(".")].map(&:to_s)
        last = keys.pop
        node = keys.reduce(data) { |h, k| h.is_a?(Hash) ? (h[k] ||= {}) : break }
        return false unless node.is_a?(Hash)

        node[last] = value
        file_manager.write_file(filename, data.to_yaml)
      rescue StandardError => e
        Rails.logger&.error "RailsI18nOnair LiveUI: file save failed — #{e.message}"
        false
      end
    end
  end
end
