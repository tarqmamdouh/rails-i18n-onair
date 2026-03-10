module RailsI18nOnair
  class SyncController < ApplicationController
    def new
      @locales = available_locales
    end

    def preview
      @source = params[:source]
      @destination = params[:destination]
      @locales = available_locales

      if @source.blank? || @destination.blank?
        flash.now[:alert] = "Please select both source and destination locales."
        render :new
        return
      end

      if @source == @destination
        flash.now[:alert] = "Source and destination must be different locales."
        render :new
        return
      end

      service = RailsI18nOnair::SyncService.new(@source, @destination)
      @missing_keys = service.compare
    end

    def create
      source = params[:source]
      destination = params[:destination]

      if source.blank? || destination.blank? || source == destination
        redirect_to sync_locales_path, alert: "Invalid source or destination."
        return
      end

      service = RailsI18nOnair::SyncService.new(source, destination)
      result = service.sync!

      if result[:synced] > 0
        redirect_to sync_locales_path, notice: "Synced #{result[:synced]} missing key(s) from #{source.upcase} to #{destination.upcase}."
      else
        redirect_to sync_locales_path, notice: "No missing keys found. #{destination.upcase} is already in sync with #{source.upcase}."
      end
    end

    private

    def available_locales
      if RailsI18nOnair.configuration.database_mode?
        RailsI18nOnair::Translation.pluck(:language).sort
      else
        file_manager = RailsI18nOnair::FileManager.new
        file_manager.list_files.map { |f| f[:language] }.sort
      end
    end
  end
end
