module RailsI18nOnair
  module LiveUi
    class Middleware
      def initialize(app)
        @app = app
        @mount_path    = nil
        @cached_script = nil
      end

      def call(env)
        # Fast exit: skip all work when Live UI is off
        return @app.call(env) unless RailsI18nOnair.configuration.live_ui?

        translator = translator_signed_in?(env)

        # Determine if this request should get Live UI treatment.
        # Set the flag via CurrentAttributes BEFORE the app renders —
        # the t() helper reads Current.live_ui_active during view rendering.
        active = env["REQUEST_METHOD"] == "GET" &&
                 !engine_request?(env) &&
                 translator

        RailsI18nOnair::Current.live_ui_active = active

        status, headers, response = @app.call(env)

        if translator && status == 200 && html_response?(headers)
          body = collect_body(response)
          # Replace ⟦i18n:key:locale⟧text⟦/i18n⟧ markers from controller t()
          # calls (flash messages, etc.) with editable <span> wrappers.
          body = replace_i18n_markers(body)
          body = inject_live_ui(body) if active
          headers["Content-Length"] = body.bytesize.to_s
          [status, headers, [body]]
        else
          [status, headers, response]
        end
      end

      private

      def translator_signed_in?(env)
        request = ActionDispatch::Request.new(env)
        request.session[:translator_id].present?
      rescue StandardError
        false
      end

      def html_response?(headers)
        content_type = headers["Content-Type"].to_s
        content_type.include?("text/html")
      end

      def engine_request?(env)
        path = env["PATH_INFO"].to_s
        mp   = mount_path
        path == mp || path.start_with?("#{mp}/")
      end

      def collect_body(response)
        parts = []
        response.each { |chunk| parts << chunk }
        parts.join
      end

      # Replace ⟦i18n:key:locale⟧text⟦/i18n⟧ markers with editable <span> wrappers.
      # Markers are embedded by ControllerHelper#translate for flash messages, etc.
      I18N_MARKER_PATTERN = /\u27E6i18n:(.+?):(.+?)\u27E7(.+?)\u27E6\/i18n\u27E7/m

      def replace_i18n_markers(html)
        html.gsub(I18N_MARKER_PATTERN) do
          key    = Rack::Utils.escape_html($1)
          locale = Rack::Utils.escape_html($2)
          text   = $3
          %(<span data-i18n-onair="true" data-i18n-key="#{key}" data-i18n-locale="#{locale}" style="display:contents">#{text}</span>)
        end
      end

      def inject_live_ui(html)
        html.sub(%r{</body>}i, "#{cached_script}\n</body>")
      end

      def cached_script
        @cached_script ||= RailsI18nOnair::LiveUi::Script.render(mount_path).freeze
      end

      def mount_path
        @mount_path ||= detect_mount_path.freeze
      end

      def detect_mount_path
        Rails.application.routes.routes.each do |route|
          rack_app = route.app
          rack_app = rack_app.app if rack_app.respond_to?(:app) && !rack_app.is_a?(Class)
          if rack_app == RailsI18nOnair::Engine
            return route.path.spec.to_s.sub(/\(.*\)$/, "")
          end
        end
        "/i18n"
      rescue StandardError
        "/i18n"
      end
    end
  end
end
