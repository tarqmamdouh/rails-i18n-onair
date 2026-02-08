module RailsI18nOnair
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    layout "rails_i18n_onair/application"

    before_action :authenticate_translator!

    helper_method :current_translator, :storage_mode, :storage_mode_is_database?, :storage_mode_is_file?

    protected

    def authenticate_translator!
      unless current_translator
        redirect_to login_path, alert: "Please sign in to continue"
      end
    end

    def current_translator
      @current_translator ||= RailsI18nOnair::Translator.find_by(id: session[:translator_id]) if session[:translator_id]
    end

    def sign_in(translator)
      session[:translator_id] = translator.id
      @current_translator = translator
    end

    def sign_out
      session[:translator_id] = nil
      @current_translator = nil
    end

    def storage_mode
      RailsI18nOnair.configuration.storage_mode
    end

    def storage_mode_is_database?
      RailsI18nOnair.configuration.database_mode?
    end

    def storage_mode_is_file?
      RailsI18nOnair.configuration.file_mode?
    end
  end
end
