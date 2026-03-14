require "spec_helper"
require "rack"
require "action_dispatch"
require "rails_i18n_onair/configuration"
require "rails_i18n_onair/current"
require "rails_i18n_onair/live_ui/script"
require "rails_i18n_onair/live_ui/middleware"

RSpec.describe RailsI18nOnair::LiveUi::Middleware do
  # ── Helpers ─────────────────────────────────────────────────────────────────

  HTML_BODY = "<html><body><p>Hello</p></body></html>"

  def html_app(status: 200, body: HTML_BODY, content_type: "text/html; charset=utf-8")
    lambda do |_env|
      [status, { "Content-Type" => content_type, "Content-Length" => body.bytesize.to_s }, [body]]
    end
  end

  def build_env(method: "GET", path: "/", session: {})
    Rack::MockRequest.env_for(path, method: method).merge(
      "rack.session" => session
    )
  end

  def middleware(app = html_app)
    described_class.new(app)
  end

  before do
    RailsI18nOnair.configure { |c| c.live_ui = true }
    # Avoid real route detection during unit tests
    allow_any_instance_of(described_class).to receive(:detect_mount_path).and_return("/i18n")
    # Stub Script.render so tests are not dependent on its output
    allow(RailsI18nOnair::LiveUi::Script).to receive(:render).and_return("<script>onair</script>")
    # Reset CurrentAttributes between examples
    RailsI18nOnair::Current.reset
  end

  after { RailsI18nOnair::Current.reset }

  # ── Fast path when Live UI is disabled ─────────────────────────────────────

  describe "fast path" do
    before { RailsI18nOnair.configure { |c| c.live_ui = false } }

    it "passes the request straight through to the app without modification" do
      called = false
      app = lambda { |_env| called = true; [200, { "Content-Type" => "text/html" }, ["<html><body></body></html>"]] }
      mw = described_class.new(app)
      mw.call(build_env)
      expect(called).to be(true)
    end

    it "does not set Current.live_ui_active" do
      described_class.new(html_app).call(build_env)
      expect(RailsI18nOnair::Current.live_ui_active).to be_falsy
    end
  end

  # ── Current.live_ui_active flag ────────────────────────────────────────────

  describe "Current.live_ui_active flag" do
    it "is set to true before the app runs when translator is signed in" do
      flag_during_call = nil
      app = lambda do |_env|
        flag_during_call = RailsI18nOnair::Current.live_ui_active
        [200, { "Content-Type" => "text/html" }, [HTML_BODY]]
      end

      described_class.new(app).call(build_env(session: { translator_id: 42 }))
      expect(flag_during_call).to be(true)
    end

    it "is set to false when no translator is signed in" do
      flag_during_call = nil
      app = lambda do |_env|
        flag_during_call = RailsI18nOnair::Current.live_ui_active
        [200, { "Content-Type" => "text/html" }, [HTML_BODY]]
      end

      described_class.new(app).call(build_env)
      expect(flag_during_call).to be(false)
    end
  end

  # ── HTML injection ─────────────────────────────────────────────────────────

  describe "HTML injection" do
    let(:env) { build_env(session: { translator_id: 42 }) }

    it "injects the Live UI script before </body>" do
      _status, _headers, body = middleware.call(env)
      expect(body.join).to include("<script>onair</script>")
    end

    it "injects before the closing </body> tag" do
      _status, _headers, body = middleware.call(env)
      expect(body.join).to match(/<script>onair<\/script>\s*<\/body>/i)
    end

    it "updates Content-Length to match the new body size" do
      _status, headers, body = middleware.call(env)
      expect(headers["Content-Length"].to_i).to eq(body.join.bytesize)
    end
  end

  # ── Non-injection conditions ────────────────────────────────────────────────

  describe "non-injection conditions" do
    it "does not inject when no translator is signed in" do
      _status, _headers, body = middleware.call(build_env)
      expect(body.join).not_to include("onair")
    end

    it "does not inject for non-GET requests" do
      _status, _headers, body = middleware.call(
        build_env(method: "POST", session: { translator_id: 42 })
      )
      expect(body.join).not_to include("onair")
    end

    it "does not inject for non-200 responses" do
      app = lambda { |_env| [302, { "Content-Type" => "text/html", "Location" => "/" }, [""]] }
      _status, _headers, body = described_class.new(app).call(
        build_env(session: { translator_id: 42 })
      )
      expect(body.join).not_to include("onair")
    end

    it "does not inject for non-HTML responses" do
      app = lambda { |_env| [200, { "Content-Type" => "application/json" }, ['{"ok":true}']] }
      _status, _headers, body = described_class.new(app).call(
        build_env(session: { translator_id: 42 })
      )
      expect(body.join).not_to include("onair")
    end

    it "does not inject for engine-scoped requests" do
      _status, _headers, body = middleware.call(
        build_env(path: "/i18n/settings", session: { translator_id: 42 })
      )
      expect(body.join).not_to include("onair")
    end

    it "does not inject for engine root path" do
      _status, _headers, body = middleware.call(
        build_env(path: "/i18n", session: { translator_id: 42 })
      )
      expect(body.join).not_to include("onair")
    end
  end

  # ── #translator_signed_in? ─────────────────────────────────────────────────

  describe "#translator_signed_in?" do
    let(:mw) { described_class.new(html_app) }

    it "returns true when session[:translator_id] is present" do
      env = build_env(session: { translator_id: 1 })
      expect(mw.send(:translator_signed_in?, env)).to be(true)
    end

    it "returns false when session[:translator_id] is nil" do
      env = build_env(session: {})
      expect(mw.send(:translator_signed_in?, env)).to be(false)
    end

    it "returns false when session access raises" do
      env = build_env
      allow(ActionDispatch::Request).to receive(:new).and_raise(StandardError)
      expect(mw.send(:translator_signed_in?, env)).to be(false)
    end
  end

  # ── #html_response? ────────────────────────────────────────────────────────

  describe "#html_response?" do
    let(:mw) { described_class.new(html_app) }

    it "returns true for text/html content type" do
      expect(mw.send(:html_response?, "Content-Type" => "text/html; charset=utf-8")).to be(true)
    end

    it "returns false for application/json content type" do
      expect(mw.send(:html_response?, "Content-Type" => "application/json")).to be(false)
    end

    it "returns false when Content-Type is absent" do
      expect(mw.send(:html_response?, {})).to be(false)
    end
  end

  # ── #engine_request? ───────────────────────────────────────────────────────

  describe "#engine_request?" do
    let(:mw) { described_class.new(html_app) }

    it "returns true for the exact mount path" do
      env = build_env(path: "/i18n")
      expect(mw.send(:engine_request?, env)).to be(true)
    end

    it "returns true for sub-paths under the mount path" do
      env = build_env(path: "/i18n/translations")
      expect(mw.send(:engine_request?, env)).to be(true)
    end

    it "returns false for paths outside the engine" do
      env = build_env(path: "/posts")
      expect(mw.send(:engine_request?, env)).to be(false)
    end
  end

  # ── Script caching ─────────────────────────────────────────────────────────

  describe "script caching" do
    it "calls Script.render only once across multiple requests" do
      env = build_env(session: { translator_id: 42 })
      mw = described_class.new(html_app)
      expect(RailsI18nOnair::LiveUi::Script).to receive(:render).once.and_return("<script></script>")
      3.times { mw.call(env) }
    end
  end
end
