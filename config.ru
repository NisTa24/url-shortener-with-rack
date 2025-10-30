# frozen_string_literal: true

require 'rack'
require_relative 'app/shortener'
require_relative 'app/middleware/logger'

app = Rack::Builder.new do
  use URLShortener::LoggerMiddleware

  run URLShortener::ShortenerApp.new
end

run app
