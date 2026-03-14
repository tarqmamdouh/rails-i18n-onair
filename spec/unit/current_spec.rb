require "spec_helper"
require "active_support"
require "active_support/core_ext"
require "active_support/current_attributes"
require "rails_i18n_onair/current"

RSpec.describe RailsI18nOnair::Current do
  after { described_class.reset_all }

  describe ".live_ui_active" do
    it "is nil by default" do
      expect(described_class.live_ui_active).to be_nil
    end

    it "can be set to true" do
      described_class.live_ui_active = true
      expect(described_class.live_ui_active).to be(true)
    end

    it "can be set to false" do
      described_class.live_ui_active = false
      expect(described_class.live_ui_active).to be(false)
    end

    it "is reset to nil after reset_all" do
      described_class.live_ui_active = true
      described_class.reset_all
      expect(described_class.live_ui_active).to be_nil
    end
  end

  describe ".translation_cache" do
    it "returns an empty hash by default (lazy initialisation)" do
      expect(described_class.translation_cache).to eq({})
    end

    it "stores and retrieves values" do
      described_class.translation_cache["en:hello"] = "Hello"
      expect(described_class.translation_cache["en:hello"]).to eq("Hello")
    end

    it "is reset to an empty hash after reset_all" do
      described_class.translation_cache["en:hello"] = "Hello"
      described_class.reset_all
      expect(described_class.translation_cache).to eq({})
    end

    it "supports fetch with a block for lazy population" do
      value = described_class.translation_cache.fetch("key") { "computed" }
      expect(value).to eq("computed")
    end
  end
end
