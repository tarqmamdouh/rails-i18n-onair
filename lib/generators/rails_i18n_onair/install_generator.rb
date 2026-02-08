require "rails/generators"

module RailsI18nOnair
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates RailsI18nOnair initializer, copies migrations, and sets up initial translator"

      class_option :storage_mode, type: :string, default: "file", desc: "Storage mode (file or database)"
      class_option :skip_translator, type: :boolean, default: false, desc: "Skip creating initial translator"

      def copy_initializer
        @storage_mode = options[:storage_mode]
        template "rails_i18n_onair.rb", "config/initializers/rails_i18n_onair.rb"
      end

      def install_migrations
        say "\n━━━ Installing Migrations ━━━", :bold

        # Always install translator migration (required for authentication)
        say "Installing translator migration (required)...", :green
        rake "rails_i18n_onair:install:migrations:translator"

        # Only install translation migration if using database mode
        if @storage_mode == "database"
          sleep 1 # Ensure unique timestamps
          say "\nInstalling translation migration (database mode)...", :green
          rake "rails_i18n_onair:install:migrations:translation"
        else
          say "\nSkipping translation migration (file mode selected)", :yellow
        end
      end

      def add_route_mounting
        say "\n━━━ Adding Routes ━━━", :bold

        route_code = 'mount RailsI18nOnair::Engine, at: "/i18n"'

        if File.read("config/routes.rb").include?(route_code)
          say "Routes already mounted", :yellow
        else
          route route_code
          say "✓ Mounted RailsI18nOnair::Engine at /i18n", :green
        end
      end

      def run_migrations
        say "\n━━━ Running Migrations ━━━", :bold

        if yes?("Run migrations now? (y/n)", :green)
          rails_command "db:migrate"
        else
          say "Remember to run 'rails db:migrate' later!", :yellow
        end
      end

      def create_initial_translator
        return if options[:skip_translator]

        say "\n━━━ Creating Initial Translator Account ━━━", :bold
        say "You need a translator account to access the i18n dashboard.\n", :cyan

        username = ask("Enter username:", :green, default: "admin")
        password = ask("Enter password (min 6 characters):", :green, echo: false)

        while password.to_s.length < 6
          say "\nPassword must be at least 6 characters!", :red
          password = ask("Enter password:", :green, echo: false)
        end

        password_confirmation = ask("\nConfirm password:", :green, echo: false)

        while password != password_confirmation
          say "\nPasswords don't match!", :red
          password = ask("Enter password:", :green, echo: false)
          password_confirmation = ask("Confirm password:", :green, echo: false)
        end

        create_file "db/seeds/rails_i18n_onair.rb", <<~RUBY
          # Create initial translator for RailsI18nOnair
          unless RailsI18nOnair::Translator.exists?(username: "#{username}")
            RailsI18nOnair::Translator.create!(
              username: "#{username}",
              password: "#{password}"
            )
            puts "✓ Created translator: #{username}"
          end
        RUBY

        append_to_file "db/seeds.rb", "\n# RailsI18nOnair seeds\nload Rails.root.join('db/seeds/rails_i18n_onair.rb')\n"

        say "\n"
        if yes?("Create translator account now? (y/n)", :green)
          rails_command "runner 'RailsI18nOnair::Translator.create!(username: \"#{username}\", password: \"#{password}\")'"
          say "✓ Translator account created successfully!", :green
        else
          say "Run 'rails db:seed' to create the translator account later.", :yellow
        end
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
