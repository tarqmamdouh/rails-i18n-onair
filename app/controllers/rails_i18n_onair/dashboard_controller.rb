module RailsI18nOnair
  class DashboardController < ApplicationController
    def index
      @translator = current_translator
      @storage_mode = RailsI18nOnair.configuration.storage_mode

      if storage_mode_is_database?
        @statistics = {
          total_translations: RailsI18nOnair::Translation.count,
          languages: RailsI18nOnair::Translation.pluck(:language),
          recent_updates: RailsI18nOnair::Translation.order(updated_at: :desc).limit(5)
        }
      else
        locale_path = Rails.root.join(RailsI18nOnair.configuration.locale_files_path)
        yaml_files = Dir.glob("#{locale_path}/**/*.yml")

        @statistics = {
          locale_files_path: RailsI18nOnair.configuration.locale_files_path,
          file_count: yaml_files.count,
          files: yaml_files.map { |f| File.basename(f) }.sort,
          mode: :file
        }
      end
    end
  end
end
