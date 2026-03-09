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

        # Determine if this request should get Live UI treatment.
        # Set the flag via CurrentAttributes BEFORE the app renders —
        # the t() helper reads Current.live_ui_active during view rendering.
        active = env["REQUEST_METHOD"] == "GET" &&
                 !engine_request?(env) &&
                 translator_signed_in?(env)

        RailsI18nOnair::Current.live_ui_active = active

        status, headers, response = @app.call(env)

        if active && status == 200 && html_response?(headers)
          body = collect_body(response)
          body = inject_live_ui(body)
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
