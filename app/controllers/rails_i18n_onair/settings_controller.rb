module RailsI18nOnair
  class SettingsController < ApplicationController
    def index
      @live_ui_enabled = RailsI18nOnair.configuration.live_ui?
    end

    def update
      case params[:setting]
      when "live_ui"
        enabled = params[:enabled] == "true"
        RailsI18nOnair.configuration.live_ui = enabled
        flash[:notice] = "Live UI has been #{enabled ? 'enabled' : 'disabled'}."
      else
        flash[:alert] = "Unknown setting."
      end

      redirect_to settings_path
    end
  end
end
