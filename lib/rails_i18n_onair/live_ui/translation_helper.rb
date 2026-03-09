module RailsI18nOnair
  module LiveUi
    # Prepended to ActionView::Helpers::TranslationHelper so that every t() call
    # wraps its output in a <span> carrying data-attributes when Live UI is active.
    #
    # When Live UI is OFF or no translator is signed in the call falls straight
    # through to the original helper — zero overhead.
    module TranslationHelper
      def translate(key, **options)
        # Fast path: skip wrapping unless the middleware flagged this request
        unless _i18n_onair_live_ui_active?
          return super
        end

        # Allow callers to opt-out: t("key", i18n_onair: false)
        if options.delete(:i18n_onair) == false
          return super
        end

        # Resolve lazy keys (.title → controller.action.title)
        resolved_key = scope_key_by_partial(key)
        locale = options[:locale] || I18n.locale
        result = super

        # Wrap the translated value in a <span> the Live UI JS can target
        content_tag(
          :span,
          result,
          data: {
            i18n_onair: "true",
            i18n_key: resolved_key.to_s,
            i18n_locale: locale.to_s
          },
          style: "display:contents"
        )
      end

      # Re-alias so that both t() and translate() go through the override.
      def t(key, **options)
        translate(key, **options)
      end

      private

      # Reads the flag set by the middleware via CurrentAttributes.
      # No session/controller/request access needed — the middleware
      # already verified the translator is signed in and set the flag
      # before the app started rendering.
      def _i18n_onair_live_ui_active?
        return @_i18n_onair_active if defined?(@_i18n_onair_active)

        @_i18n_onair_active = (RailsI18nOnair::Current.live_ui_active == true)
      end
    end
  end
end
