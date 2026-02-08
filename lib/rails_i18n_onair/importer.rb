require "yaml"

module RailsI18nOnair
  class Importer
    # Regular expression to match locale files like en.yml, fr.yml, es-MX.yml, etc.
    LOCALE_FILE_PATTERN = /^([a-z]{2}(-[A-Z]{2})?)\.yml$/

    attr_reader :locale_path, :imported_count, :skipped_count, :errors

    def initialize(locale_path = nil)
      @locale_path = locale_path || RailsI18nOnair.configuration.locale_files_path
      @imported_count = 0
      @skipped_count = 0
      @errors = []
    end

    # Import all locale files from the configured path
    def import_all
      unless File.directory?(full_locale_path)
        raise Error, "Locale path does not exist: #{full_locale_path}"
      end

      locale_files = find_locale_files

      if locale_files.empty?
        raise Error, "No locale files found in: #{full_locale_path}"
      end

      locale_files.each do |file_path|
        import_file(file_path)
      end

      {
        imported: @imported_count,
        skipped: @skipped_count,
        errors: @errors
      }
    end

    # Import a specific locale file
    def import_file(file_path)
      file_name = File.basename(file_path)
      language_code = extract_language_code(file_name)

      unless language_code
        @skipped_count += 1
        @errors << "Skipped #{file_name}: Invalid file name format"
        return false
      end

      begin
        yaml_content = YAML.load_file(file_path)

        # The YAML file should have the language code as the root key
        # e.g., { "en" => { "hello" => "Hello" } }
        translation_data = yaml_content[language_code] || yaml_content[language_code.to_sym] || yaml_content

        # Check if translation_data is a hash
        unless translation_data.is_a?(Hash)
          @skipped_count += 1
          @errors << "Skipped #{file_name}: Invalid YAML structure (expected Hash)"
          return false
        end

        # Create or update the translation record
        translation = RailsI18nOnair::Translation.find_or_initialize_by(language: language_code)
        translation.translation = translation_data

        if translation.save
          @imported_count += 1
          true
        else
          @skipped_count += 1
          @errors << "Failed to save #{file_name}: #{translation.errors.full_messages.join(', ')}"
          false
        end
      rescue => e
        @skipped_count += 1
        @errors << "Error importing #{file_name}: #{e.message}"
        false
      end
    end

    # Import a specific language
    def import_language(language_code)
      file_name = "#{language_code}.yml"
      file_path = File.join(full_locale_path, file_name)

      unless File.exist?(file_path)
        raise Error, "Locale file not found: #{file_path}"
      end

      import_file(file_path)
    end

    private

    def full_locale_path
      if @locale_path.start_with?("/")
        @locale_path
      else
        File.join(Rails.root, @locale_path)
      end
    end

    def find_locale_files
      Dir.glob(File.join(full_locale_path, "*.yml")).select do |file|
        file_name = File.basename(file)
        file_name.match?(LOCALE_FILE_PATTERN)
      end.sort
    end

    def extract_language_code(file_name)
      match = file_name.match(LOCALE_FILE_PATTERN)
      match ? match[1] : nil
    end
  end
end
