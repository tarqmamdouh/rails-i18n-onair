module RailsI18nOnair
  class Translation < ApplicationRecord
    validates :language, presence: true, uniqueness: true
    validates :translation, presence: true

    # Scope to get all available languages
    scope :available_languages, -> { pluck(:language) }

    # Optimized query methods for selective loading
    class << self
      # Load a single locale efficiently
      def load_locale(locale)
        find_by(language: locale.to_s)
      end

      # Load multiple locales in one query
      def load_locales(locales)
        where(language: locales.map(&:to_s))
          .pluck(:language, :translation)
          .to_h
      end

      # Check if locale exists without loading data
      def locale_exists?(locale)
        exists?(language: locale.to_s)
      end

      # Get specific translation key using JSONB query (leverages GIN index)
      def lookup_key(locale, key_path)
        translation_record = find_by(language: locale.to_s)
        return nil unless translation_record

        keys = key_path.split('.')
        keys.reduce(translation_record.translation) { |hash, key|
          hash&.dig(key) || hash&.dig(key.to_sym)
        }
      end
    end

    # Convert YAML file to JSON and store in database
    def self.import_from_yaml(language, yaml_file_path)
      yaml_content = YAML.load_file(yaml_file_path)
      translation_data = yaml_content[language] || yaml_content[language.to_sym] || yaml_content

      create_or_update_by_language(language, translation_data)
    end

    # Export translation to YAML format
    def export_to_yaml
      { language => translation }.to_yaml
    end

    # Get a translation value by key path (e.g., "user.name")
    def get_translation(key_path)
      keys = key_path.split(".")
      keys.reduce(translation) { |hash, key| hash&.dig(key) || hash&.dig(key.to_sym) }
    end

    # Set a translation value by key path
    def set_translation(key_path, value)
      keys = key_path.split(".")
      last_key = keys.pop
      hash = keys.reduce(translation) { |h, key| h[key] ||= {} }
      hash[last_key] = value
      save
    end

    # Merge new translations into existing ones
    def merge_translations(new_translations)
      self.translation = translation.deep_merge(new_translations)
      save
    end

    private

    def self.create_or_update_by_language(language, translation_data)
      translation_record = find_or_initialize_by(language: language)
      translation_record.translation = translation_data
      translation_record.save!
      translation_record
    end
  end
end
