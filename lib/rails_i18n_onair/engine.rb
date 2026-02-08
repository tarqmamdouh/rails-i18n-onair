module RailsI18nOnair
  class Engine < ::Rails::Engine
    isolate_namespace RailsI18nOnair

    config.generators do |g|
      g.test_framework :rspec
    end

    # Configure asset pipeline
    config.assets.paths << root.join("app", "assets", "stylesheets")
    config.assets.paths << root.join("app", "assets", "javascripts")
    config.assets.precompile += %w[rails_i18n_onair/application.css rails_i18n_onair/application.js]

    # Load rake tasks
    rake_tasks do
      load "tasks/rails_i18n_onair_tasks.rake"
    end

    # Initialize the backend after Rails initialization
    config.after_initialize do
      # Only setup I18n backend if explicitly configured to do so
      # This allows the gem to be more flexible
      if RailsI18nOnair.configuration.database_mode?
        Rails.logger.info "RailsI18nOnair: Using database storage mode"
        # Optionally switch the I18n backend (commented out by default)
        # I18n.backend = RailsI18nOnair::Backend.new
      else
        Rails.logger.info "RailsI18nOnair: Using file storage mode"
      end
    end
  end
end
