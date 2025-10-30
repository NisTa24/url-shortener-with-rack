# frozen_string_literal: true

require 'rack'
require 'erb'
require 'uri'
require_relative 'store'

module URLShortener
  class ShortenerApp
    def initialize(store: Store.new)
      @store = store
    end

    def call(env)
      # wraps the env hash with convenient methods
      request = Rack::Request.new(env)

      route(request)
    end

    private

    def route(request) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # a little bit of pattern matching
      case [request.request_method, request.path_info]
      when ['GET', '/']
        render_home
      when ['POST', '/shorten']
        create_short_url(request)
      else
        if request.get? && (match = request.path_info.match(%r{^/([a-z0-9]{4})/info$}))
          slug = match[1]
          render_info(slug)
        elsif request.get? && request.path_info.match(%r{^/([a-z0-9]{4})$})
          slug = request.path_info[1..-1] # rubocop:disable Style/SlicingWithRange
          redirect_to_original(slug)
        else
          not_found
        end
      end
    end

    def create_short_url(request)
      original_url = request.params['url']&.strip

      return bad_request('Invalid URL') unless valid_url?(original_url)

      original_url.strip!

      slug = @store.save(original_url)

      redirect("/#{slug}/info")
    end

    def valid_url?(url)
      return false if url.nil? || url.empty?

      uri = URI.parse(url)

      (uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)) && !uri.host.nil?
    rescue URI::InvalidURIError
      false
    end

    def redirect(location)
      [302, { 'location' => location }, []]
    end

    def redirect_to_original(slug)
      record = @store.find(slug)

      return not_found unless record

      @store.increment_clicks(slug)

      [302, { 'location' => record['url'], 'cache-control' => 'no-cache, no-store' }, []]
    end

    def render(view_name, locals = {})
      layout = File.read("#{__dir__}/views/layout.erb")
      view_code = File.read("#{__dir__}/views/#{view_name}.erb")

      view_content = ERB.new(view_code).result_with_hash(locals)
      final_body = ERB.new(layout).result_with_hash(content: view_content)

      ok_html(final_body)
    end

    def render_home
      render('home', links: @store.all)
    end

    def render_info(slug)
      record = @store.find(slug)

      return not_found unless record

      render('info', slug: slug, data: record)
    end

    def ok_html(body)
      [200, { 'content-type' => 'text/html', 'content-length' => body.bytesize.to_s }, [body]]
    end

    def not_found
      [404, { 'content-type' => 'text/plain' }, ['Not Found']]
    end

    def bad_request(message)
      [400, { 'content-type' => 'text/plain' }, [message]]
    end
  end
end
