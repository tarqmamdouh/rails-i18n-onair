require "spec_helper"
require "tmpdir"
require "fileutils"
require "rails"
require "rails_i18n_onair/configuration"
require "rails_i18n_onair/importer"

RSpec.describe RailsI18nOnair::Importer do
  FIXTURES_PATH = File.expand_path("../fixtures/locales", __dir__).freeze

  let(:importer) { described_class.new(FIXTURES_PATH) }

  # ── Initialization ─────────────────────────────────────────────────────────

  describe "#initialize" do
    it "accepts an explicit locale path" do
      imp = described_class.new("/some/path")
      expect(imp.locale_path).to eq("/some/path")
    end

    it "falls back to configured locale_files_path when no path given" do
      RailsI18nOnair.configure { |c| c.locale_files_path = "config/locales" }
      imp = described_class.new
      expect(imp.locale_path).to eq("config/locales")
    end

    it "starts with zero counts and empty errors" do
      expect(importer.imported_count).to eq(0)
      expect(importer.skipped_count).to eq(0)
      expect(importer.errors).to be_empty
    end
  end

  # ── #import_all ────────────────────────────────────────────────────────────

  describe "#import_all" do
    context "when the locale path does not exist" do
      let(:importer) { described_class.new("/nonexistent/path") }

      it "raises RailsI18nOnair::Error" do
        expect { importer.import_all }.to raise_error(RailsI18nOnair::Error, /does not exist/)
      end
    end

    context "when the locale path exists but has no locale files" do
      let(:tmpdir) { Dir.mktmpdir("importer_spec_empty") }
      let(:importer) { described_class.new(tmpdir) }

      after { FileUtils.rm_rf(tmpdir) }

      it "raises RailsI18nOnair::Error about no locale files found" do
        expect { importer.import_all }.to raise_error(RailsI18nOnair::Error, /No locale files found/)
      end
    end

    context "when locale files exist" do
      before do
        # Stub Translation.import_from_yaml to avoid a DB dependency
        stub_const("RailsI18nOnair::Translation", Class.new do
          def self.import_from_yaml(lang, path)
            # no-op stub
          end
        end)
      end

      it "returns a hash with :imported, :skipped, :errors keys" do
        result = importer.import_all
        expect(result.keys).to contain_exactly(:imported, :skipped, :errors)
      end

      it "imports all valid locale files from the fixtures directory" do
        result = importer.import_all
        # en.yml, es.yml, fr.yml — invalid_file.txt is skipped by pattern
        expect(result[:imported]).to eq(3)
        expect(result[:skipped]).to eq(0)
      end

      it "does not import files that do not match the locale pattern" do
        result = importer.import_all
        # invalid_file.txt must not be counted
        expect(result[:imported]).to eq(3)
      end

      it "records errors and increments skipped_count when import_from_yaml raises" do
        call_count = 0
        allow(RailsI18nOnair::Translation).to receive(:import_from_yaml) do
          call_count += 1
          raise StandardError, "DB error" if call_count == 1
        end

        result = importer.import_all
        expect(result[:skipped]).to eq(1)
        expect(result[:errors].first).to include(error: "DB error")
      end
    end
  end
end
