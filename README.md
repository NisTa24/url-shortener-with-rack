# url-shortener-with-rack

[https://develclan.com/build-url-shortener-rack/](https://develclan.com/build-url-shortener-rack/)

## Persistence

The original version stored data in a `db.json` file. This repository has been updated to use SQLite via the `sqlite3` gem. A local database file `urls.db` will be created automatically on first run with a single table:

```
urls(
	slug TEXT PRIMARY KEY,
	url TEXT NOT NULL,
	created_at INTEGER NOT NULL,
	clicks INTEGER NOT NULL DEFAULT 0
)
```

To create a DB locally, run
```
rackup -D
```

## Run locally

Install dependencies and start the Rack app (defaults to Puma):

```
bundle install
rackup
```

Then open http://localhost:9292

## Notes

If you want to reset the data, just delete the `urls.db` file and restart.
