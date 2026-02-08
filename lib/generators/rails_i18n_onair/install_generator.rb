require "rails/generators"

module RailsI18nOnair
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates RailsI18nOnair initializer and copies migrations"

      def copy_initializer
        template "rails_i18n_onair.rb", "config/initializers/rails_i18n_onair.rb"
      end

      def copy_migrations
        rake "rails_i18n_onair:install:migrations"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
