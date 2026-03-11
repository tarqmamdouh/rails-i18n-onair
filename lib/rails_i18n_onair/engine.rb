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

    # ── Live UI ──
    # Prepend our translation helper override into ActionView so that t()
    # wraps output in editable <span> tags when a translator is signed in.
    initializer "rails_i18n_onair.live_ui_helper" do
      ActiveSupport.on_load(:action_view) do
        prepend RailsI18nOnair::LiveUi::TranslationHelper
      end

      # Override f.submit to render <button> instead of <input> so the
      # translated label can be wrapped in an editable <span>.
      ActionView::Helpers::FormBuilder.prepend RailsI18nOnair::LiveUi::FormHelper
    end

    # Override controller t() so flash messages and other controller-level
    # translations carry i18n markers that the middleware converts to
    # editable <span> wrappers.
    initializer "rails_i18n_onair.live_ui_controller_helper" do
      ActiveSupport.on_load(:action_controller) do
        prepend RailsI18nOnair::LiveUi::ControllerHelper
      end
    end

    # Append Live UI middleware to the end of the stack. The session
    # middleware (CookieStore, CacheStore, etc.) is always earlier in the
    # stack, so env["rack.session"] is populated by the time we run.
    initializer "rails_i18n_onair.live_ui_middleware" do |app|
      app.middleware.use RailsI18nOnair::LiveUi::Middleware
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
