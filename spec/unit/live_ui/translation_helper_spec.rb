require "spec_helper"
require "action_view"
require "rails_i18n_onair/configuration"
require "rails_i18n_onair/current"
require "rails_i18n_onair/live_ui/translation_helper"

RSpec.describe RailsI18nOnair::LiveUi::TranslationHelper do
  # Build a minimal host object that behaves like an ActionView template
  # with the translation helper prepended.
  def build_helper(live_ui_active: false)
    host = Class.new do
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::TranslationHelper

      # Stub out scope_key_by_partial — in real views this resolves ".foo" keys
      def scope_key_by_partial(key)
        key
      end

      prepend RailsI18nOnair::LiveUi::TranslationHelper
    end.new

    RailsI18nOnair::Current.live_ui_active = live_ui_active
    host
  end

  before { RailsI18nOnair::Current.reset_all }
  after  { RailsI18nOnair::Current.reset_all }

  # ── Fast path (Live UI inactive) ────────────────────────────────────────────

  context "when Live UI is inactive" do
    let(:helper) { build_helper(live_ui_active: false) }

    it "returns plain translated string without wrapping" do
      result = helper.t("en.hello")
      expect(result.to_s).not_to include('data-i18n-onair')
    end

    it "delegates to the original translate implementation" do
      # 'en.hello' is a missing key; original helper returns a "translation missing" string
      result = helper.translate("en.missing_key_xyz")
      expect(result.to_s).to match(/translation missing/i)
    end
  end

  # ── Active path (Live UI active) ────────────────────────────────────────────

  context "when Live UI is active" do
    let(:helper) { build_helper(live_ui_active: true) }

    it "wraps the translation in a <span>" do
      result = helper.translate("en.hello")
      expect(result.to_s).to include("<span")
      expect(result.to_s).to include("</span>")
    end

    it "sets data-i18n-onair='true' on the span" do
      result = helper.translate("en.hello")
      expect(result.to_s).to include('data-i18n-onair="true"')
    end

    it "sets data-i18n-key to the resolved key" do
      result = helper.translate("en.hello")
      expect(result.to_s).to include('data-i18n-key="en.hello"')
    end

    it "sets data-i18n-locale to the current I18n locale" do
      allow(I18n).to receive(:locale).and_return(:fr)
      result = helper.translate("en.hello")
      expect(result.to_s).to include('data-i18n-locale="fr"')
    end

    it "respects an explicit :locale option in data-i18n-locale" do
      I18n.available_locales = (I18n.available_locales + [:ar]).uniq
      result = helper.translate("en.hello", locale: :ar)
      expect(result.to_s).to include('data-i18n-locale="ar"')
    end

    it "applies display:contents style so the span is invisible to layout" do
      result = helper.translate("en.hello")
      expect(result.to_s).to include("display:contents")
    end

    it "returns an html_safe string" do
      result = helper.translate("en.hello")
      expect(result).to be_html_safe
    end

    it "t() delegates to translate()" do
      expect(helper.t("en.hello")).to eq(helper.translate("en.hello"))
    end
  end

  # ── Opt-out ─────────────────────────────────────────────────────────────────

  context "when the caller opts out with i18n_onair: false" do
    let(:helper) { build_helper(live_ui_active: true) }

    it "does not wrap the translation in a <span>" do
      result = helper.translate("en.hello", i18n_onair: false)
      expect(result.to_s).not_to include('data-i18n-onair')
    end
  end

  # ── Ivar caching ────────────────────────────────────────────────────────────

  describe "per-instance caching of the active flag" do
    it "reads Current.live_ui_active only once per helper instance" do
      helper = build_helper(live_ui_active: false)
      expect(RailsI18nOnair::Current).to receive(:live_ui_active).once.and_return(false)
      helper.translate("en.hello")
      helper.translate("en.hello")
    end
  end
end
