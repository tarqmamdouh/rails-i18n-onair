require "rails_helper"
GEM_ROOT = File.expand_path("../..", __dir__) unless defined?(GEM_ROOT)

require "#{GEM_ROOT}/app/controllers/rails_i18n_onair/application_controller"
require "#{GEM_ROOT}/app/controllers/rails_i18n_onair/settings_controller"

RSpec.describe RailsI18nOnair::SettingsController do
  let(:translator) { RailsI18nOnair::Translator.create!(username: "admin", password: "secret123") }

  # Minimal controller double — gives us a plain object with a real session hash
  # so we can call action methods directly without needing routing or a full stack.
  def build_controller(session_data = {})
    ctrl = described_class.new
    allow(ctrl).to receive(:session).and_return(session_data)
    allow(ctrl).to receive(:redirect_to)
    allow(ctrl).to receive(:flash).and_return({})
    allow(ctrl).to receive(:settings_path).and_return("/i18n/settings")
    allow(ctrl).to receive(:login_path).and_return("/i18n/login")
    ctrl
  end

  # ── #index ────────────────────────────────────────────────────────────────────

  describe "#index" do
    it "sets @live_ui_enabled to false when Live UI is off" do
      ctrl = build_controller(translator_id: translator.id)
      ctrl.index
      expect(ctrl.instance_variable_get(:@live_ui_enabled)).to be(false)
    end

    it "sets @live_ui_enabled to true when Live UI is on" do
      RailsI18nOnair.configure { |c| c.live_ui = true }
      ctrl = build_controller(translator_id: translator.id)
      ctrl.index
      expect(ctrl.instance_variable_get(:@live_ui_enabled)).to be(true)
    end
  end

  # ── #update ───────────────────────────────────────────────────────────────────

  describe "#update" do
    def run_update(params, session_data = { translator_id: translator.id })
      flash = {}
      ctrl = described_class.new
      allow(ctrl).to receive(:session).and_return(session_data)
      allow(ctrl).to receive(:params).and_return(ActionController::Parameters.new(params))
      allow(ctrl).to receive(:flash).and_return(flash)
      allow(ctrl).to receive(:redirect_to)
      allow(ctrl).to receive(:settings_path).and_return("/i18n/settings")
      allow(ctrl).to receive(:login_path).and_return("/i18n/login")
      ctrl.update
      [ctrl, flash]
    end

    context "setting=live_ui, enabled=true" do
      it "enables Live UI in configuration" do
        run_update(setting: "live_ui", enabled: "true")
        expect(RailsI18nOnair.configuration.live_ui?).to be(true)
      end

      it "sets a notice flash message mentioning 'enabled'" do
        _, flash = run_update(setting: "live_ui", enabled: "true")
        expect(flash[:notice]).to match(/enabled/i)
      end
    end

    context "setting=live_ui, enabled=false" do
      before { RailsI18nOnair.configure { |c| c.live_ui = true } }

      it "disables Live UI in configuration" do
        run_update(setting: "live_ui", enabled: "false")
        expect(RailsI18nOnair.configuration.live_ui?).to be(false)
      end

      it "sets a notice flash message mentioning 'disabled'" do
        _, flash = run_update(setting: "live_ui", enabled: "false")
        expect(flash[:notice]).to match(/disabled/i)
      end
    end

    context "unknown setting" do
      it "sets an alert flash message" do
        _, flash = run_update(setting: "nonexistent")
        expect(flash[:alert]).to match(/unknown setting/i)
      end
    end
  end
end
