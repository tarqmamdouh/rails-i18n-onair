module RailsI18nOnair
  class Engine < ::Rails::Engine
    isolate_namespace RailsI18nOnair

    config.generators do |g|
      g.test_framework :rspec
    end

    # Configure asset pipeline
    config.assets.paths << root.join("app", "assets", "stylesheets")
    config.assets.paths << root.join("app", "assets", "javascripts")
    config.assets.precompile += %w[rails_i18n_onair/application.css rails_i18n_onair/application.js rails_i18n_onair/logo.svg rails_i18n_onair/banner.svg]

    # Load rake tasks
    rake_tasks do
      load "tasks/rails_i18n_onair_tasks.rake"
    end

    # When storage_mode is :database, chain our DB backend in front of the
    # existing file backend so t(:key) checks the DB first and falls back
    # to YAML files for any missing keys.
    # When storage_mode is :file (default), normal I18n behavior is used.
    config.after_initialize do
      next unless RailsI18nOnair.configuration.database_mode?

      begin
        if ActiveRecord::Base.connection.table_exists?("rails_i18n_onair_translations")
          file_backend = I18n.backend  # capture existing YAML-based backend

          I18n.backend = I18n::Backend::Chain.new(
            RailsI18nOnair::DatabaseBackend.new,
            file_backend
          )

          Rails.logger.info "RailsI18nOnair: Activated — database-first with file fallback"
        else
          Rails.logger.warn "RailsI18nOnair: Database table not found, falling back to default I18n backend"
        end
      rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid => e
        Rails.logger.warn "RailsI18nOnair: Database not available (#{e.message}), using default I18n backend"
      end
    end
  end
end
