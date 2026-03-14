require "rails_helper"

RSpec.describe RailsI18nOnair::Translator, type: :model do
  def build_translator(username: "alice", password: "secret123")
    described_class.new(username: username, password: password)
  end

  def create_translator(username: "alice", password: "secret123")
    described_class.create!(username: username, password: password)
  end

  # ── Validations ──────────────────────────────────────────────────────────────

  describe "validations" do
    it "is valid with a username and password" do
      expect(build_translator).to be_valid
    end

    it "is invalid without a username" do
      expect(build_translator(username: nil)).not_to be_valid
    end

    it "is invalid with a duplicate username" do
      create_translator(username: "alice")
      dup = build_translator(username: "alice")
      expect(dup).not_to be_valid
    end

    it "is invalid when the password is shorter than 6 characters" do
      expect(build_translator(password: "12345")).not_to be_valid
    end

    it "is valid when the password is exactly 6 characters" do
      expect(build_translator(password: "123456")).to be_valid
    end
  end

  # ── has_secure_password ──────────────────────────────────────────────────────

  describe "password hashing" do
    it "stores a password_digest, not the plain-text password" do
      translator = create_translator
      expect(translator.password_digest).not_to eq("secret123")
      expect(translator.password_digest).not_to be_blank
    end

    it "authenticates with the correct password" do
      translator = create_translator
      expect(translator.authenticate("secret123")).to eq(translator)
    end

    it "does not authenticate with the wrong password" do
      translator = create_translator
      expect(translator.authenticate("wrongpass")).to be(false)
    end
  end

  # ── password_required? (private) ─────────────────────────────────────────────

  describe "password validation is skipped when no new password is given" do
    it "allows save without providing a password when digest already exists" do
      translator = create_translator
      translator.username = "alice_updated"
      # password not re-supplied — only username is changing
      expect(translator).to be_valid
    end
  end
end
