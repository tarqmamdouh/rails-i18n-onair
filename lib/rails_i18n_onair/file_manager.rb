module RailsI18nOnair
  class FileManager
    LOCALE_FILE_PATTERN = /^([a-z]{2}(-[A-Z]{2})?)\.yml$/.freeze

    attr_reader :errors

    def initialize
      @errors = []
    end

    def list_files
      locale_path = full_locale_path
      return [] unless File.directory?(locale_path)

      Dir.glob("#{locale_path}/*.yml").map do |file_path|
        filename = File.basename(file_path)
        next unless filename.match?(LOCALE_FILE_PATTERN)

        {
          filename: filename,
          language: extract_language_code(filename),
          path: file_path,
          size: File.size(file_path),
          modified_at: File.mtime(file_path)
        }
      end.compact.sort_by { |f| f[:filename] }
    end

    def read_file(filename)
      return nil unless valid_filename?(filename)

      file_path = File.join(full_locale_path, filename)
      return nil unless File.exist?(file_path)

      File.read(file_path)
    end

    def write_file(filename, content)
      return false unless valid_filename?(filename)

      # Validate YAML syntax before writing
      errors = validate_yaml(content)
      if errors.any?
        @errors = errors
        return false
      end

      file_path = File.join(full_locale_path, filename)

      # Atomic write: write to temp file, then move
      temp_path = "#{file_path}.tmp"

      begin
        File.write(temp_path, content)
        File.rename(temp_path, file_path)
        true
      rescue StandardError => e
        @errors << "Failed to write file: #{e.message}"
        File.delete(temp_path) if File.exist?(temp_path)
        false
      end
    end

    def validate_yaml(content)
      errors = []

      begin
        parsed = YAML.safe_load(content, permitted_classes: [Symbol], aliases: true)

        unless parsed.is_a?(Hash)
          errors << "YAML content must be a hash/object"
        end
      rescue Psych::SyntaxError => e
        errors << "Invalid YAML syntax: #{e.message}"
      rescue StandardError => e
        errors << "Error parsing YAML: #{e.message}"
      end

      errors
    end

    def file_exists?(filename)
      return false unless valid_filename?(filename)

      file_path = File.join(full_locale_path, filename)
      File.exist?(file_path)
    end

    def get_file_info(filename)
      return nil unless valid_filename?(filename)

      file_path = File.join(full_locale_path, filename)
      return nil unless File.exist?(file_path)

      {
        filename: filename,
        language: extract_language_code(filename),
        path: file_path,
        size: File.size(file_path),
        modified_at: File.mtime(file_path),
        content: File.read(file_path)
      }
    end

    private

    def full_locale_path
      Rails.root.join(RailsI18nOnair.configuration.locale_files_path)
    end

    def valid_filename?(filename)
      filename.match?(LOCALE_FILE_PATTERN)
    end

    def extract_language_code(filename)
      match = filename.match(LOCALE_FILE_PATTERN)
      match ? match[1] : nil
    end
  end
end
