module RailsI18nOnair
  class SessionsController < ActionController::Base
    protect_from_forgery with: :exception

    layout "rails_i18n_onair/authentication"

    before_action :redirect_if_authenticated, only: [:new, :create]

    def new
      # Render login form
    end

    def create
      translator = RailsI18nOnair::Translator.find_by(username: params[:username])

      if translator&.authenticate(params[:password])
        session[:translator_id] = translator.id
        redirect_to main_app.rails_i18n_onair_path, notice: "Signed in successfully"
      else
        flash.now[:alert] = "Invalid username or password"
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session[:translator_id] = nil
      redirect_to login_path, notice: "Signed out successfully"
    end

    private

    def redirect_if_authenticated
      if session[:translator_id].present?
        redirect_to main_app.rails_i18n_onair_path
      end
    end
  end
end
