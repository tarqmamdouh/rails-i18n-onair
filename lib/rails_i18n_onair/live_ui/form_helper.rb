module RailsI18nOnair
  module LiveUi
    # Prepended to ActionView::Helpers::FormBuilder so that f.submit renders
    # a <button> instead of an <input> when Live UI is active. This allows the
    # translated button text to be wrapped in an editable <span>.
    #
    # When Live UI is OFF the call falls straight through to the original
    # submit helper — zero overhead.
    module FormHelper
      def submit(value = nil, options = {})
        return super unless RailsI18nOnair::Current.live_ui_active == true

        # Resolve the i18n key the same way Rails' submit_default_value does,
        # but route through the view's t() so TranslationHelper wraps it in
        # an editable <span>.
        label = if value
                  value
                else
                  object = convert_to_model(@object)
                  key    = object ? (object.persisted? ? :update : :create) : :submit

                  model = if object.respond_to?(:model_name)
                            object.model_name.human
                          else
                            @object_name.to_s.humanize
                          end

                  i18n_key = if object.respond_to?(:model_name) && object_name.to_s == model.downcase
                              "helpers.submit.#{object.model_name.i18n_key}.#{key}"
                            else
                              "helpers.submit.#{object_name}.#{key}"
                            end

                  fallback = "#{key.to_s.humanize} #{model}"

                  # Use the view's t() which is wrapped by TranslationHelper
                  @template.t(i18n_key, model: model, default: fallback)
                end

        html_options = { type: "submit" }.merge(options)

        @template.content_tag(:button, label, html_options)
      end
    end
  end
end
