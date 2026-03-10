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

        # Fetch the raw template (with %{vars} intact) for the editor.
        # Only needed when interpolation variables are present in options.
        i18n_reserved = [:scope, :default, :separator, :resolve, :object, :fallback, :format, :cascade, :throw, :raise, :locale, :exception_handler]
        has_interpolation = (options.keys - i18n_reserved).any?

        attrs = {
          i18n_onair: "true",
          i18n_key: resolved_key.to_s,
          i18n_locale: locale.to_s
        }

        if has_interpolation
          begin
            raw_template = I18n.backend.translate(locale, resolved_key, {})
            if raw_template.is_a?(String) && raw_template.include?("%{")
              attrs[:i18n_raw] = raw_template
              interp_vars = options.except(*i18n_reserved)
              attrs[:i18n_vars] = interp_vars.to_json if interp_vars.any?
            end
          rescue
            # Ignore — raw template not available
          end
        end

        content_tag(
          :span,
          result,
          data: attrs,
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
