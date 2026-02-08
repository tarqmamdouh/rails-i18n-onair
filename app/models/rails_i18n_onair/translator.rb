module RailsI18nOnair
  class Translator < ApplicationRecord
    has_secure_password

    validates :username, presence: true, uniqueness: true
    validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

    private

    def password_required?
      password_digest.blank? || password.present?
    end
  end
end
