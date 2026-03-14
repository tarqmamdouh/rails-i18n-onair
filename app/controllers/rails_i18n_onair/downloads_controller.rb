require "zip"

module RailsI18nOnair
  class DownloadsController < ApplicationController
    def all
      zip_data = build_zip

      send_data zip_data,
                type: "application/zip",
                disposition: "attachment",
                filename: "translations_#{Date.today.iso8601}.zip"
    end

    private

    def build_zip
      buffer = Zip::OutputStream.write_buffer do |zip|
        if storage_mode_is_database?
          add_database_translations(zip)
        else
          add_file_translations(zip)
        end
      end

      buffer.string
    end

    def add_database_translations(zip)
      RailsI18nOnair::Translation.find_each do |record|
        yaml_content = { record.language => record.translation[record.language] || record.translation }.to_yaml
        zip.put_next_entry("#{record.language}.yml")
        zip.write(yaml_content)
      end
    end

    def add_file_translations(zip)
      file_manager = RailsI18nOnair::FileManager.new

      file_manager.list_files.each do |file_info|
        content = File.read(file_info[:path])
        zip.put_next_entry(file_info[:filename])
        zip.write(content)
      end
    end
  end
end
