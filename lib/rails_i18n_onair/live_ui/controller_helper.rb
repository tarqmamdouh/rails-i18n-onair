module RailsI18nOnair
  module LiveUi
    # Prepended to AbstractController::Translation so that controller-level
    # t() calls (used for flash messages, mailers, etc.) embed invisible
    # markers around the translated text.
    #
    # The LiveUi::Middleware later replaces these markers with editable
    # <span> wrappers — the same ones TranslationHelper uses in views.
    #
    # Markers use Unicode mathematical brackets (⟦ ⟧) which:
    #   • survive ERB HTML-escaping (only & < > " ' are escaped)
    #   • survive flash session serialization (just string bytes)
    #   • are extremely unlikely in real translation text
    #
    # When Live UI is OFF or no translator is signed in, the call falls
    # straight through — zero overhead.
    module ControllerHelper
      I18N_MARKER_OPEN  = "\u27E6".freeze # ⟦
      I18N_MARKER_CLOSE = "\u27E7".freeze # ⟧

      def translate(key, **options)
        result = super

        return result unless RailsI18nOnair.configuration.live_ui?
        return result unless _i18n_onair_translator_signed_in?

        # Resolve lazy keys (.title → controller.action.title)
        resolved_key = if key.to_s.start_with?(".")
                         "#{controller_path.tr('/', '.')}.#{action_name}#{key}"
                       else
                         key.to_s
                       end

        # Strip region from locale: "en_FRA" → "en"
        locale = (options[:locale] || I18n.locale).to_s.split(/[-_]/).first

        # ⟦i18n:key:locale⟧translated text⟦/i18n⟧
        "#{I18N_MARKER_OPEN}i18n:#{resolved_key}:#{locale}#{I18N_MARKER_CLOSE}" \
        "#{result}" \
        "#{I18N_MARKER_OPEN}/i18n#{I18N_MARKER_CLOSE}"
      end

      alias :t :translate

      private

      def _i18n_onair_translator_signed_in?
        session[:translator_id].present?
      rescue StandardError
        false
      end
    end
  end
end
