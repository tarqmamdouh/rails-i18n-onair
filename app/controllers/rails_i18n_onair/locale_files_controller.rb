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
    end

    def update
      unless @file_info
        redirect_to locale_files_path, alert: "File not found"
        return
      end

      new_content = params[:content]

      if @file_manager.write_file(params[:filename], new_content)
        redirect_to locale_file_path(filename: params[:filename]), notice: "File updated successfully"
      else
        flash.now[:alert] = "Failed to update file: #{@file_manager.errors.join(', ')}"
        @content = new_content
        render :edit, status: :unprocessable_entity
      end
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
      @file_info = @file_manager.get_file_info(params[:filename])
    end
  end
end
