module RailsI18nOnair
  # Request-level caching using ActiveSupport::CurrentAttributes
  # This caches translations for the duration of a single request
  class Current < ActiveSupport::CurrentAttributes
    attribute :translation_cache

    def translation_cache
      super || self.translation_cache = {}
    end
  end
end
