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
        language_code = extract_language_code(File.basename(file_path))
        Translation.import_from_yaml(language_code, file_path)
        @imported_count += 1
      rescue => e
        @errors << { file: file_path, error: e.message }
        @skipped_count += 1
      end

      {
        imported: @imported_count,
        skipped: @skipped_count,
        errors: @errors
      }
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
