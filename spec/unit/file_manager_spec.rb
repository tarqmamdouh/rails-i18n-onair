require "spec_helper"
require "tmpdir"
require "fileutils"
require "rails"
require "rails_i18n_onair/configuration"
require "rails_i18n_onair/file_manager"

RSpec.describe RailsI18nOnair::FileManager do
  let(:tmpdir) { Dir.mktmpdir("file_manager_spec") }
  let(:manager) { described_class.new }

  before do
    # Point Rails.root at our tmp directory
    allow(Rails).to receive(:root).and_return(Pathname.new(tmpdir))
    RailsI18nOnair.configure { |c| c.locale_files_path = "locales" }
    FileUtils.mkdir_p(File.join(tmpdir, "locales"))
  end

  after { FileUtils.rm_rf(tmpdir) }

  # ── Helpers ────────────────────────────────────────────────────────────────

  def write_locale(filename, content)
    File.write(File.join(tmpdir, "locales", filename), content)
  end

  VALID_EN_YAML = <<~YAML
    en:
      hello: Hello
      user:
        name: Name
  YAML

  # ── #list_files ────────────────────────────────────────────────────────────

  describe "#list_files" do
    it "returns an empty array when the directory has no locale files" do
      expect(manager.list_files).to eq([])
    end

    it "lists valid locale files sorted by filename" do
      write_locale("fr.yml", "fr:\n  hello: Bonjour\n")
      write_locale("en.yml", VALID_EN_YAML)
      filenames = manager.list_files.map { |f| f[:filename] }
      expect(filenames).to eq(%w[en.yml fr.yml])
    end

    it "returns hashes with expected keys" do
      write_locale("en.yml", VALID_EN_YAML)
      info = manager.list_files.first
      expect(info.keys).to include(:filename, :language, :path, :size, :modified_at)
    end

    it "extracts the correct language code" do
      write_locale("es-MX.yml", "es-MX:\n  hello: Hola\n")
      info = manager.list_files.find { |f| f[:filename] == "es-MX.yml" }
      expect(info[:language]).to eq("es-MX")
    end

    it "skips non-locale files" do
      write_locale("invalid_file.txt", "not yaml")
      write_locale("README.md", "# docs")
      expect(manager.list_files).to be_empty
    end

    it "returns an empty array when the directory does not exist" do
      RailsI18nOnair.configure { |c| c.locale_files_path = "nonexistent" }
      expect(manager.list_files).to eq([])
    end
  end

  # ── #read_file ─────────────────────────────────────────────────────────────

  describe "#read_file" do
    it "returns the file content for a valid locale file" do
      write_locale("en.yml", VALID_EN_YAML)
      expect(manager.read_file("en.yml")).to eq(VALID_EN_YAML)
    end

    it "returns nil when the file does not exist" do
      expect(manager.read_file("de.yml")).to be_nil
    end

    it "returns nil for an invalid filename" do
      expect(manager.read_file("../../etc/passwd")).to be_nil
      expect(manager.read_file("application.rb")).to be_nil
    end
  end

  # ── #write_file ────────────────────────────────────────────────────────────

  describe "#write_file" do
    it "writes valid YAML content and returns true" do
      result = manager.write_file("en.yml", VALID_EN_YAML)
      expect(result).to be(true)
      expect(File.read(File.join(tmpdir, "locales", "en.yml"))).to eq(VALID_EN_YAML)
    end

    it "returns false for an invalid filename" do
      expect(manager.write_file("../../hack.yml", "x: 1")).to be(false)
    end

    it "returns false and populates @errors for invalid YAML" do
      result = manager.write_file("en.yml", "key: [unclosed")
      expect(result).to be(false)
      expect(manager.errors).not_to be_empty
    end

    it "returns false when YAML is not a hash" do
      result = manager.write_file("en.yml", "- item1\n- item2\n")
      expect(result).to be(false)
      expect(manager.errors).to include("YAML content must be a hash/object")
    end

    it "does not leave a temp file behind on failure" do
      allow(File).to receive(:rename).and_raise(StandardError, "disk full")
      manager.write_file("en.yml", VALID_EN_YAML)
      expect(Dir.glob(File.join(tmpdir, "locales", "*.tmp"))).to be_empty
    end
  end

  # ── #validate_yaml ─────────────────────────────────────────────────────────

  describe "#validate_yaml" do
    it "returns an empty array for valid YAML hash" do
      expect(manager.validate_yaml(VALID_EN_YAML)).to be_empty
    end

    it "returns errors for syntax-invalid YAML" do
      errors = manager.validate_yaml("key: [unclosed")
      expect(errors).not_to be_empty
      expect(errors.first).to match(/Invalid YAML syntax/i)
    end

    it "returns an error when YAML is not a hash" do
      errors = manager.validate_yaml("- a\n- b\n")
      expect(errors).to include("YAML content must be a hash/object")
    end

    it "returns an empty array for empty hash YAML" do
      expect(manager.validate_yaml("{}\n")).to be_empty
    end
  end

  # ── #file_exists? ──────────────────────────────────────────────────────────

  describe "#file_exists?" do
    it "returns true when the file exists" do
      write_locale("en.yml", VALID_EN_YAML)
      expect(manager.file_exists?("en.yml")).to be(true)
    end

    it "returns false when the file does not exist" do
      expect(manager.file_exists?("de.yml")).to be(false)
    end

    it "returns false for an invalid filename" do
      expect(manager.file_exists?("application.rb")).to be(false)
    end
  end

  # ── #get_file_info ─────────────────────────────────────────────────────────

  describe "#get_file_info" do
    it "returns a hash with file metadata and content" do
      write_locale("en.yml", VALID_EN_YAML)
      info = manager.get_file_info("en.yml")
      expect(info).to include(
        filename: "en.yml",
        language: "en",
        content: VALID_EN_YAML
      )
      expect(info[:size]).to be > 0
      expect(info[:modified_at]).to be_a(Time)
    end

    it "returns nil when the file does not exist" do
      expect(manager.get_file_info("de.yml")).to be_nil
    end

    it "returns nil for an invalid filename" do
      expect(manager.get_file_info("README.md")).to be_nil
    end
  end
end
