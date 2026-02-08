namespace :rails_i18n_onair do
  namespace :install do
    namespace :migrations do
      desc "Install translator migration (required for authentication)"
      task :translator do
        require "rails"
        require "fileutils"

        # Get the migrations path from the gem
        gem_root = File.expand_path("../..", __dir__)
        migrations_path = File.join(gem_root, "db", "migrate")

        # Get the target Rails app migrations path
        target_path = Rails.root.join("db", "migrate")

        puts "Installing translator migration..."

        migration_file = File.join(migrations_path, "create_translators.rb")
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        target_file = target_path.join("#{timestamp}_create_translators.rb")

        FileUtils.cp(migration_file, target_file)
        puts "  ✓ Created migration: #{File.basename(target_file)}"
        puts "\nTranslator migration installed successfully!"
      end

      desc "Install translation migration (required for database storage mode)"
      task :translation do
        require "rails"
        require "fileutils"

        # Get the migrations path from the gem
        gem_root = File.expand_path("../..", __dir__)
        migrations_path = File.join(gem_root, "db", "migrate")

        # Get the target Rails app migrations path
        target_path = Rails.root.join("db", "migrate")

        puts "Installing translation migration..."

        migration_file = File.join(migrations_path, "create_translations.rb")
        timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
        target_file = target_path.join("#{timestamp}_create_translations.rb")

        FileUtils.cp(migration_file, target_file)
        puts "  ✓ Created migration: #{File.basename(target_file)}"
        puts "\nTranslation migration installed successfully!"
      end

      desc "Install all migrations (translator + translation)"
      task all: [:translator] do
        # Wait 1 second to ensure unique timestamps
        sleep 1
        Rake::Task["rails_i18n_onair:install:migrations:translation"].invoke
      end
    end
  end

  # Deprecated task - kept for backwards compatibility
  desc "Install RailsI18nOnair migrations (deprecated - use rails_i18n_onair:install:migrations:all)"
  task :install do
    puts "⚠️  Warning: This task is deprecated. Use 'rails_i18n_onair:install:migrations:all' instead."
    Rake::Task["rails_i18n_onair:install:migrations:all"].invoke
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
