require "rails_i18n_onair/version"
require "rails_i18n_onair/configuration"
require "rails_i18n_onair/backend"
require "rails_i18n_onair/importer"
require "rails_i18n_onair/file_manager"

module RailsI18nOnair
  class Error < StandardError; end
end

require "rails_i18n_onair/engine" if defined?(Rails::Engine)
