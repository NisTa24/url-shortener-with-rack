# frozen_string_literal: true

module URLShortener
  class LoggerMiddleware
    def initialize(app)
      @app = app
    end

    def call(env) # rubocop:disable Metrics/MethodLength
      started_at = Time.now

      method = env['REQUEST_METHOD']
      path = env['PATH_INFO']

      status, headers, body = @app.call(env)

      duration = ((Time.now - started_at) * 1000).round(2)

      color = case status
              when 200..299 then 32 # Green for success
              when 300..399 then 33 # Yellow for redirects
              when 400..499 then 31 # Red for client errors
              when 500..599 then 35 # Magenta for server errors
              else 37
              end

      timestamp = Time.now.strftime('%H:%M:%S')
      log_line = "[#{timestamp}] #{method.ljust(6)} #{path.ljust(20)} → #{status} (#{duration}ms)"

      puts "\e[#{color}m#{log_line}\e[0m"

      [status, headers, body]
    end
  end
end
