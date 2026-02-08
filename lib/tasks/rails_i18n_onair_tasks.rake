namespace :rails_i18n_onair do
  desc "Install RailsI18nOnair migrations"
  task :install do
    require "rails"
    require "rails/generators"
    require "rails/generators/migration"

    # Get the migrations path from the gem
    gem_root = File.expand_path("../..", __dir__)
    migrations_path = File.join(gem_root, "db", "migrate")

    # Get the target Rails app migrations path
    target_path = Rails.root.join("db", "migrate")

    puts "Installing RailsI18nOnair migrations..."

    # Copy each migration template
    Dir.glob(File.join(migrations_path, "*.rb")).each do |migration_file|
      migration_name = File.basename(migration_file)
      timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")

      # Generate timestamped migration name
      target_file = target_path.join("#{timestamp}_#{migration_name}")

      # Copy the migration
      FileUtils.cp(migration_file, target_file)
      puts "  Created migration: #{target_file}"

      # Sleep for 1 second to ensure unique timestamps
      sleep 1
    end

    puts "RailsI18nOnair migrations installed successfully!"
    puts "Run 'rails db:migrate' to apply the migrations."
  end

  namespace :import do
    desc "Import all locale files from config/locales into database"
    task all: :environment do
      require "rails_i18n_onair/importer"

      puts "Importing locale files from: #{RailsI18nOnair.configuration.locale_files_path}"
      puts "=" * 80

      importer = RailsI18nOnair::Importer.new
      result = importer.import_all

      puts "\nImport Summary:"
      puts "  Imported: #{result[:imported]} file(s)"
      puts "  Skipped:  #{result[:skipped]} file(s)"

      if result[:errors].any?
        puts "\nErrors:"
        result[:errors].each { |error| puts "  - #{error}" }
      end

      puts "=" * 80
      puts "Import completed!"
    end

    desc "Import a specific locale file (e.g., rake rails_i18n_onair:import:language[en])"
    task :language, [:locale] => :environment do |t, args|
      require "rails_i18n_onair/importer"

      locale = args[:locale]
      unless locale
        puts "Error: Please specify a locale (e.g., rake rails_i18n_onair:import:language[en])"
        exit 1
      end

      puts "Importing locale: #{locale}"
      puts "=" * 80

      importer = RailsI18nOnair::Importer.new

      if importer.import_language(locale)
        puts "Successfully imported #{locale}.yml"
      else
        puts "Failed to import #{locale}.yml"
        importer.errors.each { |error| puts "  - #{error}" }
        exit 1
      end

      puts "=" * 80
    end
  end
end
