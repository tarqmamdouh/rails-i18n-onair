module RailsI18nOnair
  class LocaleFilesController < ApplicationController
    before_action :set_file_manager
    before_action :set_file_info, only: [:show, :edit, :update]

    def index
      @locale_files = @file_manager.list_files
    end

    def show
      unless @file_info
        redirect_to locale_files_path, alert: "File not found"
        return
      end

      @content = @file_info[:content]
      @parsed_yaml = YAML.safe_load(@content, permitted_classes: [Symbol], aliases: true) rescue {}
    end

    def edit
      unless @file_info
        redirect_to locale_files_path, alert: "File not found"
        return
      end

      @content = @file_info[:content]
      @parsed_yaml = YAML.safe_load(@content, permitted_classes: [Symbol], aliases: true) rescue {}
    end

    def update
      unless @file_info
        redirect_to locale_files_path, alert: "File not found"
        return
      end

      filename = "#{params[:locale]}.yml"

      # Convert nested form params back to hash
      translations_hash = reconstruct_hash_from_params(params[:translations] || {})

      # Validate that we have data
      if translations_hash.empty?
        flash.now[:alert] = "No translation data received. Please ensure all fields are filled."
        @parsed_yaml = @file_info[:content] ? YAML.safe_load(@file_info[:content], permitted_classes: [Symbol], aliases: true) : {}
        render :edit, status: :unprocessable_entity
        return
      end

      # Convert to YAML with proper formatting
      new_content = translations_hash.to_yaml

      # Log for debugging (remove in production)
      Rails.logger.info "Saving translations: #{translations_hash.inspect}"

      if @file_manager.write_file(filename, new_content)
        redirect_to locale_file_path(locale: params[:locale]), notice: "File updated successfully"
      else
        flash.now[:alert] = "Failed to update file: #{@file_manager.errors.join(', ')}"
        @parsed_yaml = translations_hash
        @content = new_content
        render :edit, status: :unprocessable_entity
      end
    rescue StandardError => e
      flash.now[:alert] = "Error processing translations: #{e.message}"
      @parsed_yaml = @file_info[:content] ? YAML.safe_load(@file_info[:content], permitted_classes: [Symbol], aliases: true) : {}
      @content = @file_info[:content]
      render :edit, status: :unprocessable_entity
    end

    def sync
      require "rails_i18n_onair/importer"

      importer = RailsI18nOnair::Importer.new
      result = importer.import_all

      if result[:errors].empty?
        redirect_to locale_files_path, notice: "Successfully imported #{result[:imported]} file(s) to database"
      else
        redirect_to locale_files_path, alert: "Import completed with errors: #{result[:errors].join(', ')}"
      end
    end

    def reload
      # Reload I18n backend
      I18n.backend.reload!

      redirect_to locale_files_path, notice: "I18n backend reloaded successfully"
    end

    private

    def set_file_manager
      @file_manager = RailsI18nOnair::FileManager.new
    end

    def set_file_info
      filename = "#{params[:locale]}.yml"
      @file_info = @file_manager.get_file_info(filename)
    end

    def reconstruct_hash_from_params(params_hash)
      # Rails nested params come as ActionController::Parameters or Hash
      # Convert to regular hash recursively
      result = {}

      params_hash.each do |key, value|
        if value.is_a?(ActionController::Parameters) || value.is_a?(Hash)
          result[key] = reconstruct_hash_from_params(value)
        else
          result[key] = value
        end
      end

      result
    end
  end
end
