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
      if RailsI18nOnair.configuration.backend_enabled?
        if RailsI18nOnair.configuration.database_mode?
          # Verify database table exists before activating in database mode
          begin
            if ActiveRecord::Base.connection.table_exists?('rails_i18n_onair_translations')
              Rails.logger.info "RailsI18nOnair: Activating backend in database mode"
              I18n.backend = RailsI18nOnair::Backend.new
            else
              Rails.logger.warn "RailsI18nOnair: Database table not found, falling back to default I18n backend"
            end
          rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid => e
            Rails.logger.warn "RailsI18nOnair: Database not available (#{e.message}), using default I18n backend"
          end
        else
          # File mode with backend enabled — install backend so t() uses file backend via our proxy
          Rails.logger.info "RailsI18nOnair: Activating backend in file mode"
          I18n.backend = RailsI18nOnair::Backend.new
        end
      else
        Rails.logger.info "RailsI18nOnair: Backend not enabled, using default I18n backend"
      end
    end
  end
end
