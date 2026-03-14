require "spec_helper"
require "rails_i18n_onair/configuration"

RSpec.describe RailsI18nOnair::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "defaults storage_mode to :file" do
      expect(config.storage_mode).to eq(:file)
    end

    it "defaults locale_files_path to 'config/locales'" do
      expect(config.locale_files_path).to eq("config/locales")
    end

    it "defaults cache_translations to true" do
      expect(config.cache_translations).to be(true)
    end

    it "defaults lazy_load_locales to true" do
      expect(config.lazy_load_locales).to be(true)
    end

    it "defaults live_ui to false" do
      expect(config.live_ui).to be(false)
    end
  end

  describe "#storage_mode=" do
    it "accepts :database" do
      config.storage_mode = :database
      expect(config.storage_mode).to eq(:database)
    end

    it "accepts :file" do
      config.storage_mode = :file
      expect(config.storage_mode).to eq(:file)
    end

    it "accepts string values and converts to symbol" do
      config.storage_mode = "database"
      expect(config.storage_mode).to eq(:database)
    end

    it "raises ArgumentError for invalid mode" do
      expect { config.storage_mode = :redis }.to raise_error(ArgumentError, /Invalid storage mode/)
    end

    it "includes the invalid mode name in the error message" do
      expect { config.storage_mode = :invalid }.to raise_error(ArgumentError, /invalid/)
    end
  end

  describe "#database_mode?" do
    it "returns true when storage_mode is :database" do
      config.storage_mode = :database
      expect(config.database_mode?).to be(true)
    end

    it "returns false when storage_mode is :file" do
      config.storage_mode = :file
      expect(config.database_mode?).to be(false)
    end
  end

  describe "#file_mode?" do
    it "returns true when storage_mode is :file" do
      expect(config.file_mode?).to be(true)
    end

    it "returns false when storage_mode is :database" do
      config.storage_mode = :database
      expect(config.file_mode?).to be(false)
    end
  end

  describe "#live_ui?" do
    it "returns false by default" do
      expect(config.live_ui?).to be(false)
    end

    it "returns true when live_ui is set to true" do
      config.live_ui = true
      expect(config.live_ui?).to be(true)
    end

    it "returns false when live_ui is any truthy non-boolean value" do
      config.live_ui = "yes"
      expect(config.live_ui?).to be(false)
    end
  end
end

RSpec.describe RailsI18nOnair do
  describe ".configure" do
    it "yields the configuration object" do
      yielded = nil
      described_class.configure { |c| yielded = c }
      expect(yielded).to be_a(RailsI18nOnair::Configuration)
    end

    it "persists changes made in the block" do
      described_class.configure { |c| c.live_ui = true }
      expect(described_class.configuration.live_ui?).to be(true)
    end
  end

  describe ".configuration" do
    it "returns the same object on multiple calls" do
      first  = described_class.configuration
      second = described_class.configuration
      expect(first).to equal(second)
    end
  end

  describe ".reset_configuration!" do
    it "resets to a fresh Configuration instance" do
      described_class.configuration.live_ui = true
      described_class.reset_configuration!
      expect(described_class.configuration.live_ui?).to be(false)
    end
  end
end
