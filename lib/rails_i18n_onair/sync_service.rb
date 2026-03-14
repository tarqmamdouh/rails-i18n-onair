module RailsI18nOnair
  class SyncService
    attr_reader :source_locale, :destination_locale, :missing_keys

    def initialize(source_locale, destination_locale)
      @source_locale = source_locale.to_s
      @destination_locale = destination_locale.to_s
      @missing_keys = []
    end

    # Compare source and destination, return list of missing keys with their source values
    def compare
      source_data = load_locale_data(source_locale)
      dest_data = load_locale_data(destination_locale)

      # Strip the top-level locale key (e.g. { "en" => { ... } } → { ... })
      source_tree = source_data[source_locale] || {}
      dest_tree = dest_data[destination_locale] || {}

      @missing_keys = []
      deep_compare(source_tree, dest_tree, "")
      @missing_keys
    end

    # Copy missing keys from source to destination
    def sync!
      missing = compare
      return { synced: 0, missing_keys: [] } if missing.empty?

      dest_data = load_locale_data(destination_locale)
      dest_tree = dest_data[destination_locale] || {}

      missing.each do |entry|
        set_nested_value(dest_tree, entry[:key], entry[:value])
      end

      save_locale_data(destination_locale, { destination_locale => dest_tree })

      { synced: missing.count, missing_keys: missing }
    end

    private

    def deep_compare(source, dest, prefix)
      source.each do |key, value|
        full_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"

        if value.is_a?(Hash)
          dest_value = dest.is_a?(Hash) ? dest[key.to_s] : nil
          deep_compare(value, dest_value || {}, full_key)
        else
          dest_value = dig_key(dest, key.to_s)
          if dest_value.nil?
            @missing_keys << { key: full_key, value: value }
          end
        end
      end
    end

    def dig_key(hash, key)
      return nil unless hash.is_a?(Hash)
      hash[key.to_s] || hash[key.to_sym]
    end

    def set_nested_value(hash, dotted_key, value)
      keys = dotted_key.split(".")
      last = keys.pop

      node = keys.reduce(hash) do |h, k|
        h[k] ||= {}
      end

      node[last] = value
    end

    def load_locale_data(locale)
      if RailsI18nOnair.configuration.database_mode?
        load_from_database(locale)
      else
        load_from_file(locale)
      end
    end

    def save_locale_data(locale, data)
      if RailsI18nOnair.configuration.database_mode?
        save_to_database(locale, data)
      else
        save_to_file(locale, data)
      end
    end

    def load_from_database(locale)
      record = RailsI18nOnair::Translation.load_locale(locale)
      return { locale => {} } unless record

      record.translation || { locale => {} }
    end

    def save_to_database(locale, data)
      record = RailsI18nOnair::Translation.load_locale(locale) ||
               RailsI18nOnair::Translation.create!(language: locale, translation: {})

      record.update!(translation: data)

      if I18n.backend.respond_to?(:reload!)
        I18n.backend.reload!
      end
    end

    def load_from_file(locale)
      file_manager = RailsI18nOnair::FileManager.new
      content = file_manager.read_file("#{locale}.yml")
      return { locale => {} } unless content

      YAML.safe_load(content, permitted_classes: [Symbol], aliases: true) || { locale => {} }
    end

    def save_to_file(locale, data)
      file_manager = RailsI18nOnair::FileManager.new
      file_manager.write_file("#{locale}.yml", data.to_yaml)
    end
  end
end
