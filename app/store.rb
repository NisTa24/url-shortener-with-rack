# frozen_string_literal: true

require 'sqlite3'
require 'securerandom'

module URLShortener
  class Store
    DB_FILE = 'urls.db'

    def initialize(db_path: DB_FILE)
      @db = SQLite3::Database.new(db_path)
      @db.results_as_hash = true
      ensure_schema!
    end

    def save(original_url)
      slug = generate_slug
      now = Time.now.to_i

      @db.execute(
        'INSERT INTO urls (slug, url, created_at, clicks) VALUES (?, ?, ?, 0)',
        [slug, original_url, now]
      )

      slug
    end

    def find(slug)
      escaped_slug = sanitize_slug(slug)

      sql = "SELECT slug, url, created_at, clicks FROM urls WHERE slug = '#{escaped_slug}'"
      row = @db.get_first_row(sql)
      return unless row

      # normalize to the previous hash structure
      {
        'url' => row['url'],
        'created_at' => row['created_at'],
        'clicks' => row['clicks']
      }
    end

    def increment_clicks(slug)
      escaped_slug = sanitize_slug(slug)
      sql = "UPDATE urls SET clicks = clicks + 1 WHERE slug = '#{escaped_slug}'"
      @db.execute(sql)
    end

    def all
      rows = @db.execute('SELECT slug, url, created_at, clicks FROM urls ORDER BY created_at DESC')
      rows.each_with_object({}) do |row, acc|
        acc[row['slug']] = {
          'url' => row['url'],
          'created_at' => row['created_at'],
          'clicks' => row['clicks']
        }
      end
    end

    private

    def generate_slug
      loop do
        slug = SecureRandom.alphanumeric(4).downcase
        exists = @db.get_first_value('SELECT 1 FROM urls WHERE slug = ? LIMIT 1', [slug])
        return slug unless exists
      end
    end

    def ensure_schema!
      @db.execute <<~SQL
        CREATE TABLE IF NOT EXISTS urls (
          slug TEXT PRIMARY KEY,
            url TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            clicks INTEGER NOT NULL DEFAULT 0
        );
      SQL
      @db.execute 'CREATE INDEX IF NOT EXISTS idx_urls_created_at ON urls(created_at);'
    end

    # Note: I couldn't directly bind it when used in SQL statements. Therefore, I created this helper method to sanitize the slug.
    def sanitize_slug(slug)
      clean_slug = slug.to_s.strip.sub(/\A\//, '').split('?').first

      SQLite3::Database.quote(clean_slug)
    end
  end
end
