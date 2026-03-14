require "rails_helper"

RSpec.describe RailsI18nOnair::Translation, type: :model do
  FIXTURES_LOCALES = File.expand_path("../fixtures/locales", __dir__)

  def build_translation(language: "en", translation: { "en" => { "hello" => "Hello" } })
    described_class.new(language: language, translation: translation)
  end

  def create_translation(language: "en", translation: { "en" => { "hello" => "Hello" } })
    described_class.create!(language: language, translation: translation)
  end

  # ── Validations ─────────────────────────────────────────────────────────────

  describe "validations" do
    it "is valid with a language and translation" do
      expect(build_translation).to be_valid
    end

    it "is invalid without a language" do
      expect(build_translation(language: nil)).not_to be_valid
    end

    it "is invalid with a duplicate language" do
      create_translation(language: "en")
      dup = build_translation(language: "en")
      expect(dup).not_to be_valid
    end

    it "is invalid without a translation" do
      t = described_class.new(language: "en", translation: nil)
      expect(t).not_to be_valid
    end
  end

  # ── Scopes ──────────────────────────────────────────────────────────────────

  describe ".available_languages" do
    it "returns all stored language codes" do
      create_translation(language: "en")
      create_translation(language: "fr", translation: { "fr" => { "hello" => "Bonjour" } })
      expect(described_class.available_languages).to contain_exactly("en", "fr")
    end

    it "returns an empty array when there are no records" do
      expect(described_class.available_languages).to eq([])
    end
  end

  # ── .load_locale ────────────────────────────────────────────────────────────

  describe ".load_locale" do
    it "finds a record by locale string" do
      create_translation(language: "en")
      record = described_class.load_locale("en")
      expect(record).to be_a(described_class)
      expect(record.language).to eq("en")
    end

    it "returns nil when the locale does not exist" do
      expect(described_class.load_locale("de")).to be_nil
    end
  end

  # ── .load_locales ────────────────────────────────────────────────────────────

  describe ".load_locales" do
    it "returns a hash mapping language -> translation for multiple locales" do
      create_translation(language: "en", translation: { "en" => { "hello" => "Hello" } })
      create_translation(language: "fr", translation: { "fr" => { "hello" => "Bonjour" } })

      result = described_class.load_locales(["en", "fr"])
      expect(result.keys).to contain_exactly("en", "fr")
    end

    it "returns an empty hash for unknown locales" do
      expect(described_class.load_locales(["xx"])).to eq({})
    end
  end

  # ── .locale_exists? ──────────────────────────────────────────────────────────

  describe ".locale_exists?" do
    it "returns true when the locale exists" do
      create_translation(language: "en")
      expect(described_class.locale_exists?("en")).to be(true)
    end

    it "returns false when the locale does not exist" do
      expect(described_class.locale_exists?("zz")).to be(false)
    end
  end

  # ── .lookup_key ──────────────────────────────────────────────────────────────

  describe ".lookup_key" do
    before do
      create_translation(
        language: "en",
        translation: {
          "en" => {
            "hello" => "Hello",
            "user"  => { "name" => "Name", "email" => "Email" }
          }
        }
      )
    end

    it "retrieves a top-level key" do
      expect(described_class.lookup_key("en", "en.hello")).to eq("Hello")
    end

    it "retrieves a nested key using dot notation" do
      expect(described_class.lookup_key("en", "en.user.name")).to eq("Name")
    end

    it "returns nil for a missing key" do
      expect(described_class.lookup_key("en", "en.missing")).to be_nil
    end

    it "returns nil when the locale does not exist" do
      expect(described_class.lookup_key("de", "de.hello")).to be_nil
    end
  end

  # ── .import_from_yaml ────────────────────────────────────────────────────────

  describe ".import_from_yaml" do
    it "creates a new record from a YAML file" do
      path = File.join(FIXTURES_LOCALES, "en.yml")
      record = described_class.import_from_yaml("en", path)
      expect(record).to be_persisted
      expect(record.language).to eq("en")
    end

    it "updates an existing record when called again for the same language" do
      path = File.join(FIXTURES_LOCALES, "en.yml")
      described_class.import_from_yaml("en", path)
      expect { described_class.import_from_yaml("en", path) }
        .not_to change(described_class, :count)
    end
  end

  # ── #export_to_yaml ──────────────────────────────────────────────────────────

  describe "#export_to_yaml" do
    it "returns a YAML string keyed by language" do
      # translation stores the raw YAML content (which already includes the locale key)
      record = create_translation(
        language: "en",
        translation: { "hello" => "Hello" }
      )
      yaml = record.export_to_yaml
      parsed = YAML.safe_load(yaml)
      expect(parsed["en"]["hello"]).to eq("Hello")
    end
  end

  # ── #get_translation ─────────────────────────────────────────────────────────

  describe "#get_translation" do
    let(:record) do
      create_translation(
        language: "en",
        translation: {
          "en" => { "hello" => "Hello", "user" => { "name" => "Name" } }
        }
      )
    end

    it "retrieves a simple key" do
      expect(record.get_translation("en.hello")).to eq("Hello")
    end

    it "retrieves a nested key" do
      expect(record.get_translation("en.user.name")).to eq("Name")
    end

    it "returns nil for a missing key" do
      expect(record.get_translation("en.missing")).to be_nil
    end
  end

  # ── #set_translation ─────────────────────────────────────────────────────────

  describe "#set_translation" do
    let(:record) do
      create_translation(
        language: "en",
        translation: {
          "en" => { "hello" => "Hello", "user" => { "name" => "Name" } }
        }
      )
    end

    it "updates an existing key and persists it" do
      record.set_translation("en.hello", "Hi")
      record.reload
      expect(record.get_translation("en.hello")).to eq("Hi")
    end

    it "creates a new nested key" do
      record.set_translation("en.user.email", "Email")
      record.reload
      expect(record.get_translation("en.user.email")).to eq("Email")
    end

    it "returns true on success" do
      expect(record.set_translation("en.hello", "Hi")).to be_truthy
    end
  end

  # ── #merge_translations ──────────────────────────────────────────────────────

  describe "#merge_translations" do
    it "merges new keys into the existing translation and persists" do
      record = create_translation(
        language: "en",
        translation: { "en" => { "hello" => "Hello" } }
      )
      record.merge_translations("en" => { "goodbye" => "Goodbye" })
      record.reload
      expect(record.translation["en"]).to include("hello" => "Hello", "goodbye" => "Goodbye")
    end
  end
end
