require "rails_helper"
require "yaml"
require "action_controller"
GEM_ROOT = File.expand_path("../../..", __dir__) unless defined?(GEM_ROOT)

require "#{GEM_ROOT}/app/controllers/rails_i18n_onair/application_controller"
require "#{GEM_ROOT}/app/controllers/rails_i18n_onair/api/live_translations_controller"

RSpec.describe RailsI18nOnair::Api::LiveTranslationsController do
  let(:translator) { RailsI18nOnair::Translator.create!(username: "admin", password: "secret123") }

  # Invoke an action on a fresh controller instance, returning [ctrl, response_hash]
  def run_action(action, params: {}, session_data: { translator_id: translator.id })
    responses = {}
    ctrl = described_class.new

    allow(ctrl).to receive(:session).and_return(session_data)
    allow(ctrl).to receive(:params).and_return(ActionController::Parameters.new(params))
    allow(ctrl).to receive(:login_path).and_return("/i18n/login")

    allow(ctrl).to receive(:render) do |opts|
      responses[:status] = opts[:status] || :ok
      responses[:json]   = opts[:json]
    end

    allow(ctrl).to receive(:redirect_to) do |path|
      responses[:redirect] = path
    end

    # Run before_actions manually
    ctrl.send(:authenticate_translator!)
    ctrl.send(:require_live_ui_enabled) unless responses[:status]
    ctrl.send(action) unless responses[:status]

    [ctrl, responses]
  end

  before { RailsI18nOnair.configure { |c| c.live_ui = true } }

  # ── Live UI disabled guard ───────────────────────────────────────────────────

  describe "require_live_ui_enabled" do
    before { RailsI18nOnair.configure { |c| c.live_ui = false } }

    it "renders :forbidden when Live UI is off" do
      _, resp = run_action(:update, params: { locale: "en", key: "hello", value: "Hi" })
      expect(resp[:status]).to eq(:forbidden)
    end

    it "includes an error message in the JSON response" do
      _, resp = run_action(:update, params: { locale: "en", key: "hello", value: "Hi" })
      expect(resp[:json][:error]).to match(/not enabled/i)
    end
  end

  # ── Blank key guard ──────────────────────────────────────────────────────────

  describe "blank key" do
    it "renders :unprocessable_entity" do
      _, resp = run_action(:update, params: { locale: "en", key: "", value: "Hi" })
      expect(resp[:status]).to eq(:unprocessable_entity)
    end

    it "returns a JSON error mentioning 'key'" do
      _, resp = run_action(:update, params: { locale: "en", key: "", value: "Hi" })
      expect(resp[:json][:error]).to match(/key/i)
    end
  end

  # ── Database mode ────────────────────────────────────────────────────────────

  describe "database mode" do
    before { RailsI18nOnair.configure { |c| c.storage_mode = :database } }

    let!(:record) do
      RailsI18nOnair::Translation.create!(
        language: "en",
        translation: { "en" => { "hello" => "Hello" } }
      )
    end

    it "returns :ok on success" do
      _, resp = run_action(:update, params: { locale: "en", key: "hello", value: "Hi" })
      expect(resp[:status]).to be_nil.or eq(:ok)  # nil means default 200
    end

    it "returns status 'ok' in JSON" do
      _, resp = run_action(:update, params: { locale: "en", key: "hello", value: "Hi" })
      expect(resp[:json][:status]).to eq("ok")
    end

    it "persists the new value to the database" do
      run_action(:update, params: { locale: "en", key: "hello", value: "Howdy" })
      record.reload
      expect(record.get_translation("en.hello")).to eq("Howdy")
    end

    it "returns :unprocessable_entity when the locale record does not exist" do
      _, resp = run_action(:update, params: { locale: "de", key: "hello", value: "Hallo" })
      expect(resp[:status]).to eq(:unprocessable_entity)
    end
  end

  # ── File mode ────────────────────────────────────────────────────────────────

  describe "file mode" do
    let(:tmpdir) { Dir.mktmpdir("live_translations_spec") }

    before do
      RailsI18nOnair.configure { |c| c.locale_files_path = tmpdir }
      File.write(
        File.join(tmpdir, "en.yml"),
        "en:\n  hello: Hello\n  user:\n    name: Name\n"
      )
    end

    after { FileUtils.rm_rf(tmpdir) }

    # Override FileManager to use absolute path directly
    before do
      allow_any_instance_of(RailsI18nOnair::FileManager).to receive(:full_locale_path)
        .and_return(tmpdir)
    end

    it "returns :ok on success" do
      _, resp = run_action(:update, params: { locale: "en", key: "hello", value: "Hi" })
      expect(resp[:status]).to be_nil.or eq(:ok)
    end

    it "persists the updated value to the YAML file" do
      run_action(:update, params: { locale: "en", key: "hello", value: "Howdy" })
      parsed = YAML.safe_load(File.read(File.join(tmpdir, "en.yml")))
      expect(parsed["en"]["hello"]).to eq("Howdy")
    end

    it "updates a nested key" do
      run_action(:update, params: { locale: "en", key: "user.name", value: "Full Name" })
      parsed = YAML.safe_load(File.read(File.join(tmpdir, "en.yml")))
      expect(parsed["en"]["user"]["name"]).to eq("Full Name")
    end

    it "returns :unprocessable_entity when the locale file does not exist" do
      _, resp = run_action(:update, params: { locale: "de", key: "hello", value: "Hallo" })
      expect(resp[:status]).to eq(:unprocessable_entity)
    end
  end

  # ── Authentication ────────────────────────────────────────────────────────────

  describe "authentication" do
    it "redirects when no translator is signed in" do
      redirected = nil
      ctrl = described_class.new
      allow(ctrl).to receive(:session).and_return({})
      allow(ctrl).to receive(:login_path).and_return("/i18n/login")
      allow(ctrl).to receive(:redirect_to) { |path, **_| redirected = path }
      ctrl.send(:authenticate_translator!)
      expect(redirected).to eq("/i18n/login")
    end
  end
end
