# frozen_string_literal: true

require 'rack'
require_relative 'app/shortener'
require_relative 'app/middleware/logger'

app = Rack::Builder.new do
  use Rack::Deflater, if: lambda { |_, _, headers, body|
    # only compress HTML files
    headers['Content-Type']&.include?('text/html') && body.respond_to?(:each)
  }

  use Rack::ConditionalGet
  use Rack::ETag

  use URLShortener::LoggerMiddleware

  run URLShortener::ShortenerApp.new
end

run app
