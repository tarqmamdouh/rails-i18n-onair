require "spec_helper"
require "rails_i18n_onair/live_ui/script"

RSpec.describe RailsI18nOnair::LiveUi::Script do
  describe ".render" do
    subject(:output) { described_class.render("/i18n") }

    it "returns a String" do
      expect(output).to be_a(String)
    end

    it "contains an HTML comment marker" do
      expect(output).to include("RailsI18nOnair Live UI")
    end

    it "wraps CSS in a <style> tag" do
      expect(output).to match(/<style>.*<\/style>/m)
    end

    it "wraps JavaScript in a <script> tag" do
      expect(output).to match(/<script>.*<\/script>/m)
    end

    it "interpolates the mount_path into the API URL" do
      expect(output).to include("/i18n/api/live_translations")
    end

    it "uses the supplied mount_path" do
      output = described_class.render("/translations")
      expect(output).to include("/translations/api/live_translations")
    end
  end

  describe ".css" do
    subject(:css) { described_class.css }

    it "returns a non-empty String" do
      expect(css).to be_a(String)
      expect(css).not_to be_empty
    end

    it "includes the toolbar attribute selector" do
      expect(css).to include("[data-i18n-onair-toolbar]")
    end

    it "includes the FAB attribute selector" do
      expect(css).to include("[data-i18n-onair-fab]")
    end

    it "includes the panel attribute selector" do
      expect(css).to include("[data-i18n-onair-panel]")
    end

    it "includes the editable span highlight selector" do
      expect(css).to include('[data-i18n-onair="true"][data-i18n-onair-editing="true"]')
    end

    it "includes the editor attribute selector" do
      expect(css).to include("[data-i18n-onair-editor]")
    end

    it "includes the toast attribute selector" do
      expect(css).to include("[data-i18n-onair-toast]")
    end

    it "uses !important on position-critical rules" do
      expect(css).to include("!important")
    end
  end

  describe ".js" do
    subject(:js) { described_class.js("/i18n") }

    it "returns a non-empty String" do
      expect(js).to be_a(String)
      expect(js).not_to be_empty
    end

    it "is wrapped in an IIFE" do
      expect(js).to match(/\(function\(\)\{/)
    end

    it "uses strict mode" do
      expect(js).to include('"use strict"')
    end

    it "interpolates the API URL with the given mount path" do
      expect(js).to include('"/i18n/api/live_translations"')
    end

    it "reads the CSRF token from the meta tag" do
      expect(js).to include('meta[name="csrf-token"]')
    end

    it "queries for editable spans using the data attribute" do
      expect(js).to include('[data-i18n-onair]')
    end

    it "uses fetch with PATCH method for saves" do
      expect(js).to include('"PATCH"')
    end

    it "includes keyboard shortcut handling (Ctrl/Cmd+Enter)" do
      expect(js).to include("ctrlKey")
      expect(js).to include('"Enter"')
    end

    it "includes Escape key handling" do
      expect(js).to include('"Escape"')
    end

    it "initialises via DOMContentLoaded" do
      expect(js).to include("DOMContentLoaded")
    end
  end
end
