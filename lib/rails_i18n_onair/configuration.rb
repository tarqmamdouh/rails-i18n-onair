module RailsI18nOnair
  class Configuration
    attr_accessor :storage_mode, :locale_files_path

    # Storage modes:
    # :database - Use database (translations table) for storing translations
    # :file - Use local YAML files from the Rails app
    VALID_STORAGE_MODES = [:database, :file].freeze

    def initialize
      @storage_mode = :file # Default to file mode
      @locale_files_path = "config/locales" # Default Rails locale path
    end

    def storage_mode=(mode)
      unless VALID_STORAGE_MODES.include?(mode.to_sym)
        raise ArgumentError, "Invalid storage mode: #{mode}. Valid modes are: #{VALID_STORAGE_MODES.join(', ')}"
      end
      @storage_mode = mode.to_sym
    end

    def database_mode?
      @storage_mode == :database
    end

    def file_mode?
      @storage_mode == :file
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
