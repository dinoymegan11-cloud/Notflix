# NOTFLIX

NOTFLIX is a PHP and MySQL movie/series discovery catalog for XAMPP. It is an independent editorial-style design, not a copy of another streaming service.

## Run locally with XAMPP

1. Start **Apache** and **MySQL** in the XAMPP Control Panel.
2. Open phpMyAdmin at `http://localhost/phpmyadmin`.
3. Import [`database/schema.sql`](database/schema.sql). It creates the `notflix_db` database, its relational tables, and 92 sample catalog titles, including 82 films.
4. Open `http://localhost/xampp/notflex/`.

The default local connection is `127.0.0.1:3306`, database `notflix_db`, username `root`, and an empty password. Override these defaults with `NOTFLIX_DB_HOST`, `NOTFLIX_DB_PORT`, `NOTFLIX_DB_NAME`, `NOTFLIX_DB_USER`, and `NOTFLIX_DB_PASSWORD` environment variables when needed.

## Included database areas

- **Accounts:** `users`, with password hashes rather than stored passwords.
- **Catalog:** `movies`, `genres`, and `movie_genres` for titles and their many-to-many genre relationships.
- **Editorial browsing:** `collections` and `collection_movies` for ordered homepage rows, including Filipino, Thai, Korean, Indian, and Japanese film shelves.
- **Personal features:** `watchlist` for saved titles, `reviews` for member ratings and written reviews, and `watch_history` for titles members mark as watched.
- **Admin tools:** `admin.php` is a separate admin workspace for adding and editing movies and series, assigning genres and homepage shelves, managing catalog visibility, permanently deleting titles, and moderating reviews. Deleting a title also removes linked reviews, watchlists, and watch history; hiding a title keeps those records. Only accounts whose `users.role` is `admin` can access it.
- **Series and credits data:** `people`, `movie_credits`, `seasons`, and `episodes` remain available in the schema for future cast and episode pages; the current catalog does not yet populate or display these.

To grant admin access locally, create an account normally, then run this in phpMyAdmin's SQL tab (replace the email with that account's email):

```sql
UPDATE users SET role = 'admin' WHERE email = 'your-email@example.com';
```

Sign out and back in after changing the role so the Admin navigation link appears. Admin access is checked against the database on every dashboard request; account creation never grants admin privileges.

## Notes

- Account creation and sign-in use PHP sessions, CSRF tokens, prepared SQL statements, and `password_hash`/`password_verify`. Members can submit or update one review per title; only published reviews are shown publicly, and admins can hide or publish them.
- The catalog and saved lists are read from MySQL; the sample poster artwork is hosted by TMDB and TVmaze. Homepage collections use horizontally scrollable title rails.
- The app is a discovery catalog. Watch history records titles members manually mark as watched; playback/streaming rights and provider integrations are not included.
- For a deployed site, create a dedicated MySQL user with only the permissions the app needs instead of using XAMPP's local `root` account.

##Homepage Preview
![NOTFLIX Homepage](notflix_preview%20.png)