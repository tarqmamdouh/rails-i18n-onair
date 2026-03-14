require "spec_helper"

# ── Rails components (loaded individually — no full Rails boot) ───────────────
require "active_support"
require "active_support/core_ext"
require "active_model"
require "active_record"
require "action_dispatch"
require "action_controller"
require "action_view"
require "bcrypt"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :rails_i18n_onair_translations, force: true do |t|
    t.string :language,    null: false
    t.text   :translation, null: false, default: "{}"
    t.timestamps
  end
  add_index :rails_i18n_onair_translations, :language, unique: true

  create_table :rails_i18n_onair_translators, force: true do |t|
    t.string :username,        null: false
    t.string :password_digest, null: false
    t.timestamps
  end
  add_index :rails_i18n_onair_translators, :username, unique: true
end

# ── Load gem (without triggering Engine / Railtie) ───────────────────────────
# Define the top-level module + Error class before loading sub-files
module RailsI18nOnair
  class Error < StandardError; end
end

require "rails_i18n_onair/configuration"
require "rails_i18n_onair/current"
require "rails_i18n_onair/file_manager"
require "rails_i18n_onair/importer"
require "rails_i18n_onair/backend"

GEM_ROOT = File.expand_path("..", __dir__) unless defined?(GEM_ROOT)

# Models need ApplicationRecord base; load it before the models themselves
require "rails_i18n_onair/version"
module RailsI18nOnair
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    self.table_name_prefix = "rails_i18n_onair_"
  end
end

require "#{GEM_ROOT}/app/models/rails_i18n_onair/translation"
require "#{GEM_ROOT}/app/models/rails_i18n_onair/translator"

# SQLite stores JSON as text — tell AR to (de)serialize automatically
RailsI18nOnair::Translation.serialize :translation, coder: JSON

RSpec.configure do |config|
  # Wrap every example in a transaction that is rolled back afterwards,
  # keeping the in-memory DB clean without needing rspec-rails.
  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  config.before(:each) do
    RailsI18nOnair.reset_configuration!
    RailsI18nOnair::Current.reset_all if defined?(RailsI18nOnair::Current)
  end
end
