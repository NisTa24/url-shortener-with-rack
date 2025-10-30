# frozen_string_literal: true

require 'json'
require 'securerandom'

module URLShortener
  class Store
    DB_FILE = 'db.json'

    def initialize
      File.write(DB_FILE, '{}') unless File.exist?(DB_FILE)

      # load file in memory
      @data = JSON.parse(File.read(DB_FILE))
    end

    def save(original_url)
      slug = generate_slug

      @data[slug] = {
        'url' => original_url,
        'created_at' => Time.now.to_i,
        'clicks' => 0
      }

      persist!

      slug
    end

    def find(slug)
      @data[slug]
    end

    def increment_clicks(slug)
      return unless @data[slug]

      @data[slug]['clicks'] += 1

      persist!
    end

    def all
      @data
    end

    private

    def generate_slug
      loop do
        slug = SecureRandom.alphanumeric(4).downcase

        return slug unless @data.key?(slug)
      end
    end

    def persist!
      File.write(DB_FILE, JSON.pretty_generate(@data))
    end
  end
end
