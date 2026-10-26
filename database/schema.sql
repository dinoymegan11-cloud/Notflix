CREATE DATABASE IF NOT EXISTS notflix_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE notflix_db;

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  display_name VARCHAR(80) NOT NULL,
  email VARCHAR(254) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('member', 'admin') NOT NULL DEFAULT 'member',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS movies (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug VARCHAR(180) NOT NULL,
  title VARCHAR(200) NOT NULL,
  overview TEXT NOT NULL,
  release_year SMALLINT UNSIGNED NOT NULL,
  runtime_minutes SMALLINT UNSIGNED DEFAULT NULL,
  content_type ENUM('movie', 'series') NOT NULL,
  age_rating VARCHAR(16) DEFAULT NULL,
  poster_url VARCHAR(500) DEFAULT NULL,
  backdrop_url VARCHAR(500) DEFAULT NULL,
  external_rating DECIMAL(3,1) DEFAULT NULL,
  is_featured TINYINT(1) NOT NULL DEFAULT 0,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_movies_slug (slug),
  KEY idx_movies_title (title),
  KEY idx_movies_year (release_year),
  KEY idx_movies_type (content_type),
  KEY idx_movies_published (is_published, release_year)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS genres (
  id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(60) NOT NULL,
  slug VARCHAR(60) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_genres_name (name),
  UNIQUE KEY uq_genres_slug (slug)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS movie_genres (
  movie_id BIGINT UNSIGNED NOT NULL,
  genre_id SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (movie_id, genre_id),
  CONSTRAINT fk_movie_genres_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE,
  CONSTRAINT fk_movie_genres_genre FOREIGN KEY (genre_id) REFERENCES genres (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS collections (
  id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  slug VARCHAR(80) NOT NULL,
  name VARCHAR(100) NOT NULL,
  description VARCHAR(255) DEFAULT NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_collections_slug (slug)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS collection_movies (
  collection_id SMALLINT UNSIGNED NOT NULL,
  movie_id BIGINT UNSIGNED NOT NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (collection_id, movie_id),
  KEY idx_collection_movie_order (collection_id, sort_order),
  CONSTRAINT fk_collection_movies_collection FOREIGN KEY (collection_id) REFERENCES collections (id) ON DELETE CASCADE,
  CONSTRAINT fk_collection_movies_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS watchlist (
  user_id BIGINT UNSIGNED NOT NULL,
  movie_id BIGINT UNSIGNED NOT NULL,
  added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, movie_id),
  KEY idx_watchlist_added (user_id, added_at),
  CONSTRAINT fk_watchlist_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_watchlist_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS reviews (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  movie_id BIGINT UNSIGNED NOT NULL,
  rating TINYINT UNSIGNED NOT NULL,
  review_text TEXT DEFAULT NULL,
  status ENUM('published', 'hidden') NOT NULL DEFAULT 'published',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_review_user_movie (user_id, movie_id),
  KEY idx_reviews_movie (movie_id, status, created_at),
  CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 10),
  CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_reviews_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS watch_history (
  user_id BIGINT UNSIGNED NOT NULL,
  movie_id BIGINT UNSIGNED NOT NULL,
  progress_seconds INT UNSIGNED NOT NULL DEFAULT 0,
  completed_at DATETIME DEFAULT NULL,
  last_watched_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, movie_id),
  KEY idx_watch_history_recent (user_id, last_watched_at),
  CONSTRAINT fk_watch_history_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_watch_history_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS people (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(160) NOT NULL,
  biography TEXT DEFAULT NULL,
  profile_url VARCHAR(500) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_people_name (name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS movie_credits (
  movie_id BIGINT UNSIGNED NOT NULL,
  person_id BIGINT UNSIGNED NOT NULL,
  credit_type ENUM('cast', 'director', 'writer', 'producer') NOT NULL,
  character_name VARCHAR(160) DEFAULT NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (movie_id, person_id, credit_type),
  CONSTRAINT fk_movie_credits_movie FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE,
  CONSTRAINT fk_movie_credits_person FOREIGN KEY (person_id) REFERENCES people (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS seasons (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  series_id BIGINT UNSIGNED NOT NULL,
  season_number SMALLINT UNSIGNED NOT NULL,
  title VARCHAR(200) DEFAULT NULL,
  overview TEXT DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_series_season (series_id, season_number),
  CONSTRAINT fk_seasons_series FOREIGN KEY (series_id) REFERENCES movies (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS episodes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  season_id BIGINT UNSIGNED NOT NULL,
  episode_number SMALLINT UNSIGNED NOT NULL,
  title VARCHAR(200) NOT NULL,
  overview TEXT DEFAULT NULL,
  runtime_minutes SMALLINT UNSIGNED DEFAULT NULL,
  release_date DATE DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_season_episode (season_id, episode_number),
  CONSTRAINT fk_episodes_season FOREIGN KEY (season_id) REFERENCES seasons (id) ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT IGNORE INTO genres (name, slug) VALUES
  ('Action', 'action'), ('Adventure', 'adventure'), ('Animation', 'animation'),
  ('Comedy', 'comedy'), ('Crime', 'crime'), ('Drama', 'drama'), ('Western', 'western'),
  ('Fantasy', 'fantasy'), ('History', 'history'), ('Mystery', 'mystery'),
  ('Romance', 'romance'), ('Science Fiction', 'sci-fi'), ('Thriller', 'thriller'),
  ('Horror', 'horror');

INSERT IGNORE INTO collections (slug, name, description, sort_order) VALUES
  ('trending', 'Trending now', 'Popular titles across the catalog.', 1),
  ('series', 'Popular series', 'Series worth adding to your list.', 2),
  ('movies', 'Popular films', 'Feature films for your next movie night.', 3),
  ('anime', 'Anime & animation', 'Animated stories from around the world.', 4),
  ('acclaimed', 'Critically acclaimed', 'Highly rated films and series.', 5),
  ('mystery', 'Mystery & thrillers', 'Investigations, suspense, and surprises.', 6),
  ('filipino', 'Filipino stories', 'Beloved films from the Philippines.', 7),
  ('thai', 'Thai cinema', 'Romance, comedy, drama, and suspense from Thailand.', 8),
  ('korean', 'Korean movies', 'Standout stories from South Korea.', 9),
  ('indian', 'Indian cinema', 'Big-hearted dramas, music, comedy, and action from India.', 10),
  ('japanese', 'Japanese cinema', 'Animation, classics, and modern stories from Japan.', 11);

INSERT IGNORE INTO movies
  (slug, title, overview, release_year, runtime_minutes, content_type, age_rating, poster_url, backdrop_url, external_rating, is_featured)
VALUES
  ('interstellar', 'Interstellar', 'When Earth becomes increasingly uninhabitable, a former pilot joins a team on a journey through a wormhole in search of a new home for humanity.', 2014, 169, 'movie', 'PG-13', 'gEU2QniE6E77NI6lCU6MxlNBvIx.jpg', 'xJHokMbljvjADYdit5fK5VQsXEG.jpg', 8.7, 1),
  ('dune-part-two', 'Dune: Part Two', 'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.', 2024, 166, 'movie', 'PG-13', '1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg', '1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg', 8.5, 0),
  ('stranger-things', 'Stranger Things', 'In 1980s Indiana, a group of friends encounters secret experiments and supernatural events after a young boy disappears.', 2016, NULL, 'series', 'TV-14', '49WJfeN0moxb9IPfGn8AIqMGskD.jpg', '49WJfeN0moxb9IPfGn8AIqMGskD.jpg', 8.6, 0),
  ('everything-everywhere-all-at-once', 'Everything Everywhere All at Once', 'An exhausted laundromat owner discovers she is the key to protecting the multiverse from a growing threat.', 2022, 140, 'movie', 'R-16', 'w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg', 'w3LxiVYdWWRvEVdn5RYq6jIqkb1.jpg', 7.8, 0),
  ('the-bear', 'The Bear', 'A young chef returns to Chicago to run his family''s sandwich shop and works to transform both the restaurant and its close-knit staff.', 2022, NULL, 'series', 'TV-MA', 'https://static.tvmaze.com/uploads/images/medium_portrait/629/1574642.jpg', 'https://static.tvmaze.com/uploads/images/original_untouched/629/1574642.jpg', 8.5, 0),
  ('breaking-bad', 'Breaking Bad', 'After a terminal diagnosis, chemistry teacher Walter White turns to manufacturing illegal drugs to secure his family''s future.', 2008, NULL, 'series', 'TV-MA', '3xnWaLQjelJDDF7LT1WBo6f4BRe.jpg', '3xnWaLQjelJDDF7LT1WBo6f4BRe.jpg', 9.5, 0),
  ('wednesday', 'Wednesday', 'At Nevermore Academy, Wednesday Addams investigates a series of mysterious incidents while navigating a new school.', 2022, NULL, 'series', 'TV-14', '9PFonBhy4cQy7Jz20NpMygczOkv.jpg', '9PFonBhy4cQy7Jz20NpMygczOkv.jpg', 8.0, 0),
  ('squid-game', 'Squid Game', 'People facing severe financial hardship compete in a series of children''s games for a life-changing prize.', 2021, NULL, 'series', 'TV-MA', '1QdXdRYfktUSONkl1oD5gc6Be0s.jpg', '1QdXdRYfktUSONkl1oD5gc6Be0s.jpg', 8.0, 0),
  ('the-batman', 'The Batman', 'In his second year protecting Gotham, Batman investigates a series of crimes that reveal corruption across the city.', 2022, 176, 'movie', 'PG-13', '74xTEgt7R36Fpooo50r9T25onhq.jpg', '74xTEgt7R36Fpooo50r9T25onhq.jpg', 7.8, 0),
  ('oppenheimer', 'Oppenheimer', 'The life of physicist J. Robert Oppenheimer and his role in the development of the first atomic bomb.', 2023, 181, 'movie', 'R-16', 'ptpr0kGAckfQkJeJIt8st5dglvd.jpg', 'ptpr0kGAckfQkJeJIt8st5dglvd.jpg', 8.3, 0),
  ('barbie', 'Barbie', 'After an unexpected change in Barbie Land, Barbie and Ken travel to the real world and discover a different way of life.', 2023, 114, 'movie', 'PG-13', 'iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg', 'iuFNMS8U5cb6xfzi51Dbkovj7vM.jpg', 6.8, 0),
  ('poor-things', 'Poor Things', 'A young woman brought back to life by an unorthodox scientist sets out to explore the world and define her own independence.', 2023, 141, 'movie', 'R-16', 'kCGlIMHnOm8JPXq3rXM6c5wMxcT.jpg', 'kCGlIMHnOm8JPXq3rXM6c5wMxcT.jpg', 7.8, 0),
  ('arcane', 'Arcane', 'Two sisters find themselves on opposite sides of a growing conflict between the cities of Piltover and Zaun.', 2021, NULL, 'series', 'TV-14', 'fqldf2t8ztc9aiwn3k6mlX3tvRT.jpg', 'fqldf2t8ztc9aiwn3k6mlX3tvRT.jpg', 9.0, 0),
  ('spy-x-family', 'SPY x FAMILY', 'A spy, an assassin, and a telepath form a pretend family. None of them know the whole story.', 2022, NULL, 'series', 'TV-14', '3r4LYFuXrg3G8fepysr4xSLWnQL.jpg', '3r4LYFuXrg3G8fepysr4xSLWnQL.jpg', 8.2, 0),
  ('jujutsu-kaisen', 'Jujutsu Kaisen', 'A high-schooler enters the world of sorcerers after a cursed object changes his life.', 2020, NULL, 'series', 'TV-MA', 'hFWP5HkbVEe40hrXgtCeQxoccHE.jpg', 'hFWP5HkbVEe40hrXgtCeQxoccHE.jpg', 8.5, 0),
  ('the-fellowship-of-the-ring', 'The Lord of the Rings: The Fellowship of the Ring', 'A young hobbit inherits a powerful ring and joins a fellowship tasked with carrying it across Middle-earth.', 2001, 178, 'movie', 'PG-13', '6oom5QYQ2yQTMJIbnvbkBL9cHo6.jpg', '6oom5QYQ2yQTMJIbnvbkBL9cHo6.jpg', 8.9, 0),
  ('friends', 'Friends', 'Six friends in New York navigate careers, relationships, and the changing stages of adult life.', 1994, NULL, 'series', 'TV-14', '2koX1xLkpTQM4IZebYvKysFW1Nh.jpg', '2koX1xLkpTQM4IZebYvKysFW1Nh.jpg', 8.9, 0),
  ('spirited-away', 'Spirited Away', 'A girl enters a strange spirit world and must find her courage to help her family get home.', 2001, 125, 'movie', 'PG', '39wmItIWsg5sZMyRUHLkWBcuVCM.jpg', '39wmItIWsg5sZMyRUHLkWBcuVCM.jpg', 8.6, 0),
  ('inception', 'Inception', 'A skilled thief who steals secrets through shared dreams is offered a chance to erase his past by attempting an unprecedented task.', 2010, 148, 'movie', 'PG-13', 'oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg', 'oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg', 8.8, 0),
  ('the-dark-knight', 'The Dark Knight', 'Batman and Gotham''s allies face a criminal mastermind whose campaign pushes the city toward chaos.', 2008, 152, 'movie', 'PG-13', 'qJ2tW6WMUDux911r6m7haRef0WH.jpg', 'qJ2tW6WMUDux911r6m7haRef0WH.jpg', 9.0, 0),
  ('the-last-of-us', 'The Last of Us', 'Two survivors travel across a post-pandemic United States, forming a bond as they face a dangerous journey.', 2023, NULL, 'series', 'TV-MA', 'uKvVjHNqB5VmOrdxqAt2F7J78ED.jpg', 'uKvVjHNqB5VmOrdxqAt2F7J78ED.jpg', 8.7, 0),
  ('knives-out', 'Knives Out', 'A detective investigates the death of a celebrated crime novelist, questioning each member of the family.', 2019, 131, 'movie', 'PG-13', 'pThyQovXQrw2m0s9x82twj48Jq4.jpg', 'pThyQovXQrw2m0s9x82twj48Jq4.jpg', 7.9, 0);

INSERT IGNORE INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m JOIN genres g
  ON (m.slug = 'interstellar' AND g.slug IN ('sci-fi', 'adventure'))
  OR (m.slug = 'dune-part-two' AND g.slug IN ('sci-fi', 'adventure'))
  OR (m.slug = 'stranger-things' AND g.slug IN ('sci-fi', 'mystery'))
  OR (m.slug = 'everything-everywhere-all-at-once' AND g.slug IN ('sci-fi', 'comedy'))
  OR (m.slug = 'the-bear' AND g.slug IN ('drama', 'comedy'))
  OR (m.slug = 'breaking-bad' AND g.slug IN ('crime', 'drama'))
  OR (m.slug = 'wednesday' AND g.slug IN ('mystery', 'comedy'))
  OR (m.slug = 'squid-game' AND g.slug IN ('thriller', 'drama'))
  OR (m.slug = 'the-batman' AND g.slug IN ('crime', 'mystery'))
  OR (m.slug = 'oppenheimer' AND g.slug IN ('drama', 'history'))
  OR (m.slug = 'barbie' AND g.slug IN ('comedy', 'adventure'))
  OR (m.slug = 'poor-things' AND g.slug IN ('fantasy', 'comedy'))
  OR (m.slug = 'arcane' AND g.slug IN ('fantasy', 'action', 'animation'))
  OR (m.slug = 'spy-x-family' AND g.slug IN ('comedy', 'action', 'animation'))
  OR (m.slug = 'jujutsu-kaisen' AND g.slug IN ('fantasy', 'action', 'animation'))
  OR (m.slug = 'the-fellowship-of-the-ring' AND g.slug IN ('fantasy', 'adventure'))
  OR (m.slug = 'friends' AND g.slug IN ('comedy', 'romance'))
  OR (m.slug = 'spirited-away' AND g.slug IN ('fantasy', 'adventure', 'animation'))
  OR (m.slug = 'inception' AND g.slug IN ('sci-fi', 'thriller'))
  OR (m.slug = 'the-dark-knight' AND g.slug IN ('action', 'crime'))
  OR (m.slug = 'the-last-of-us' AND g.slug IN ('drama', 'thriller'))
  OR (m.slug = 'knives-out' AND g.slug IN ('mystery', 'comedy'));

INSERT IGNORE INTO collection_movies (collection_id, movie_id, sort_order)
SELECT c.id, m.id, CASE m.slug
  WHEN 'interstellar' THEN 1 WHEN 'dune-part-two' THEN 2 WHEN 'stranger-things' THEN 3 WHEN 'everything-everywhere-all-at-once' THEN 4
  WHEN 'the-bear' THEN 1 WHEN 'breaking-bad' THEN 2 WHEN 'wednesday' THEN 3 WHEN 'squid-game' THEN 4
  WHEN 'the-batman' THEN 1 WHEN 'oppenheimer' THEN 2 WHEN 'barbie' THEN 3 WHEN 'poor-things' THEN 4
  WHEN 'arcane' THEN 1 WHEN 'spy-x-family' THEN 2 WHEN 'jujutsu-kaisen' THEN 3
  WHEN 'the-fellowship-of-the-ring' THEN 1 WHEN 'friends' THEN 2 WHEN 'spirited-away' THEN 3
  WHEN 'inception' THEN 1 WHEN 'the-dark-knight' THEN 2 WHEN 'the-last-of-us' THEN 3 WHEN 'knives-out' THEN 4
  ELSE 50 + m.id END
FROM collections c
CROSS JOIN movies m
WHERE (c.slug = 'trending' AND m.slug IN ('interstellar', 'dune-part-two', 'stranger-things', 'everything-everywhere-all-at-once'))
   OR (c.slug = 'series' AND m.slug IN ('the-bear', 'breaking-bad', 'wednesday', 'squid-game', 'arcane', 'spy-x-family', 'jujutsu-kaisen', 'friends', 'the-last-of-us'))
   OR (c.slug = 'movies' AND m.content_type = 'movie')
   OR (c.slug = 'anime' AND m.slug IN ('arcane', 'spy-x-family', 'jujutsu-kaisen', 'spirited-away'))
   OR (c.slug = 'acclaimed' AND m.external_rating >= 8.5)
   OR (c.slug = 'mystery' AND m.slug IN ('the-batman', 'wednesday', 'inception', 'the-last-of-us', 'knives-out'));

INSERT IGNORE INTO movies
  (slug, title, overview, release_year, runtime_minutes, content_type, age_rating, poster_url, backdrop_url, external_rating)
VALUES
  ('the-matrix', 'The Matrix', 'A computer programmer discovers that reality is an elaborate simulation and joins a rebellion to uncover the truth.', 1999, 136, 'movie', 'R', 'f89U3ADr1oiB1s9GkdPOEpXUk5H.jpg', 'icmmSD4vTTDKOq2vvdulafOGw93.jpg', 8.7),
  ('arrival', 'Arrival', 'A linguist works with a team of scientists to communicate with visitors whose arrival changes how humanity understands time.', 2016, 116, 'movie', 'PG-13', 'x2FJsf1ElAgr63Y3PNPtJrcmpoe.jpg', 'yIZ1xendyqKvY3FGeeUYUd5X9Mm.jpg', 7.9),
  ('parasite', 'Parasite', 'A struggling family finds an unexpected opportunity when one of them begins working for a wealthy household.', 2019, 132, 'movie', 'R', '7IiTTgloJzvGI1TAYymCfbfl3vT.jpg', 'TU9NIjwzjoKPwQHoHshkFcQUCG.jpg', 8.5),
  ('the-shawshank-redemption', 'The Shawshank Redemption', 'An imprisoned banker builds a quiet friendship and holds on to hope through years inside Shawshank prison.', 1994, 142, 'movie', 'R', '9cqNxx0GxF0bflZmeSMuL5tnGzr.jpg', 'iNh3BIVovesLwXR4JdSxn1VKhG.jpg', 9.3),
  ('spider-man-into-the-spider-verse', 'Spider-Man: Into the Spider-Verse', 'Miles Morales discovers his powers and meets other Spider-heroes from across the multiverse.', 2018, 117, 'movie', 'PG', 'iiZZdoQBEYBv6id8su7ImL0oCbD.jpg', '6xKCYgH16UuwEGAyroLU6p8HLIn.jpg', 8.4),
  ('coco', 'Coco', 'A young musician journeys into the Land of the Dead to learn about his family and the stories that connect them.', 2017, 105, 'movie', 'PG', '6Ryitt95xrO8KXuqRGm1fUuNwqF.jpg', 'askg3SMvhqEl4OL52YuvdtY40Yb.jpg', 8.4),
  ('gladiator', 'Gladiator', 'A betrayed Roman general is forced into the arena, where he fights for survival and justice.', 2000, 155, 'movie', 'R', 'ty8TGRuvJLPUmAR1H1nRIsgwvim.jpg', 'hND7xAaxxBgaIspp9iMsaEXOSTz.jpg', 8.5),
  ('pulp-fiction', 'Pulp Fiction', 'The lives of two hitmen, a boxer, and a crime boss intersect in a series of stories set in Los Angeles.', 1994, 154, 'movie', 'R', 'd5iIlFn5s0ImszYzBPb8JPIfbXD.jpg', 'suaEOtk1N1sgg2MTM7oZd2cfVp3.jpg', 8.5),
  ('get-out', 'Get Out', 'A weekend visit to meet his girlfriend''s family becomes increasingly unsettling for a young photographer.', 2017, 104, 'movie', 'R', 'tFXcEccSQMf3lfhfXKSU9iRBpa3.jpg', 'mE24wUCfjK8AoBBjaMjho7Rczr7.jpg', 7.6),
  ('mad-max-fury-road', 'Mad Max: Fury Road', 'A lone survivor joins a daring escape across a desert wasteland in a world short on water and trust.', 2015, 121, 'movie', 'R', '8tZYtuWezp8JbcsvHYO0O46tFbo.jpg', '8yACFuoM9I7w1TWLHTZqV13x6rV.jpg', 8.1),
  ('the-grand-budapest-hotel', 'The Grand Budapest Hotel', 'A hotel concierge and his young protégé become caught up in a disputed inheritance and a changing Europe.', 2014, 100, 'movie', 'R', 'eWdyYQreja6JGCzqHWXpWHDrrPo.jpg', 'nX5XotM9yprCKarRH4fzOq1VM1J.jpg', 8.1),
  ('the-social-network', 'The Social Network', 'A college project grows into a global company, changing friendships and raising questions about ownership and ambition.', 2010, 120, 'movie', 'PG-13', 'n0ybibhJtQ5icDqTp8eRytcIHJx.jpg', 'n0ybibhJtQ5icDqTp8eRytcIHJx.jpg', 7.8),
  ('the-prestige', 'The Prestige', 'Two rival illusionists push their craft and their rivalry to dangerous extremes in turn-of-the-century London.', 2006, 130, 'movie', 'PG-13', 'Ag2B2KHKQPukjH7WutmgnnSNurZ.jpg', 'yaExZh6qE2cfyK3o4kAMEq0mkgy.jpg', 8.5),
  ('whiplash', 'Whiplash', 'An ambitious young drummer faces relentless pressure from a demanding instructor at a competitive music school.', 2014, 107, 'movie', 'R', '7fn624j5lj3xTme2SgiLCeuedmO.jpg', '6bbZ6XyvgfjhQwbplnUh1LSj1ky.jpg', 8.5),
  ('la-la-land', 'La La Land', 'A musician and an aspiring actor fall in love while pursuing creative careers in Los Angeles.', 2016, 129, 'movie', 'PG-13', 'uDO8zWDhfWwoFdKS4fzkUJt0Rf0.jpg', 'nMKdUUepR0i5zn0y1T4CsSB5chy.jpg', 8.0),
  ('the-truman-show', 'The Truman Show', 'A cheerful insurance salesman begins to suspect that his picture-perfect hometown is hiding a remarkable secret.', 1998, 103, 'movie', 'PG', 'vuza0WqY239yBXOadKlGwJsZJFE.jpg', 'vuza0WqY239yBXOadKlGwJsZJFE.jpg', 8.2),
  ('the-martian', 'The Martian', 'Stranded alone on Mars, an astronaut uses ingenuity and determination to survive while a rescue plan takes shape.', 2015, 141, 'movie', 'PG-13', '3ndAx3weG6KDkJIRMCi5vXX6Dyb.jpg', 'AuGiPiGMYMkSosOJ3BQjDEAiwtO.jpg', 8.0),
  ('top-gun-maverick', 'Top Gun: Maverick', 'After decades as a test pilot, Maverick returns to train a new generation for a demanding mission.', 2022, 130, 'movie', 'PG-13', '62HCnUTziyWcpDaBO2i1DX17ljH.jpg', 'AaV1YIdWKnjAIAOe8UUKBFm327v.jpg', 8.2);

INSERT IGNORE INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m JOIN genres g
  ON (m.slug = 'the-matrix' AND g.slug IN ('sci-fi', 'action'))
  OR (m.slug = 'arrival' AND g.slug IN ('sci-fi', 'drama', 'mystery'))
  OR (m.slug = 'parasite' AND g.slug IN ('thriller', 'drama', 'comedy'))
  OR (m.slug = 'the-shawshank-redemption' AND g.slug IN ('drama', 'crime'))
  OR (m.slug = 'spider-man-into-the-spider-verse' AND g.slug IN ('animation', 'action', 'adventure', 'sci-fi'))
  OR (m.slug = 'coco' AND g.slug IN ('animation', 'adventure', 'comedy'))
  OR (m.slug = 'gladiator' AND g.slug IN ('action', 'adventure', 'drama', 'history'))
  OR (m.slug = 'pulp-fiction' AND g.slug IN ('crime', 'drama', 'thriller'))
  OR (m.slug = 'get-out' AND g.slug IN ('mystery', 'thriller'))
  OR (m.slug = 'mad-max-fury-road' AND g.slug IN ('action', 'adventure', 'sci-fi'))
  OR (m.slug = 'the-grand-budapest-hotel' AND g.slug IN ('comedy', 'adventure'))
  OR (m.slug = 'the-social-network' AND g.slug IN ('drama', 'history'))
  OR (m.slug = 'the-prestige' AND g.slug IN ('mystery', 'drama', 'sci-fi'))
  OR (m.slug = 'whiplash' AND g.slug IN ('drama'))
  OR (m.slug = 'la-la-land' AND g.slug IN ('romance', 'comedy', 'drama'))
  OR (m.slug = 'the-truman-show' AND g.slug IN ('comedy', 'drama', 'sci-fi'))
  OR (m.slug = 'the-martian' AND g.slug IN ('sci-fi', 'adventure', 'drama'))
  OR (m.slug = 'top-gun-maverick' AND g.slug IN ('action', 'drama'));

INSERT IGNORE INTO collection_movies (collection_id, movie_id, sort_order)
SELECT c.id, m.id, 50 + m.id
FROM collections c
CROSS JOIN movies m
WHERE (c.slug = 'movies' AND m.content_type = 'movie' AND m.slug IN (
    'the-matrix', 'arrival', 'parasite', 'the-shawshank-redemption',
    'spider-man-into-the-spider-verse', 'coco', 'gladiator', 'pulp-fiction',
    'get-out', 'mad-max-fury-road', 'the-grand-budapest-hotel', 'the-social-network',
    'the-prestige', 'whiplash', 'la-la-land', 'the-truman-show', 'the-martian', 'top-gun-maverick'
  ))
  OR (c.slug = 'acclaimed' AND m.slug IN (
    'the-matrix', 'parasite', 'the-shawshank-redemption',
    'spider-man-into-the-spider-verse', 'coco', 'gladiator', 'pulp-fiction',
    'mad-max-fury-road', 'the-prestige', 'whiplash'
  ))
  OR (c.slug = 'mystery' AND m.slug IN ('arrival', 'parasite', 'get-out', 'the-prestige'))
  OR (c.slug = 'anime' AND m.slug = 'spider-man-into-the-spider-verse')
  OR (c.slug = 'trending' AND m.slug IN (
    'arrival', 'parasite', 'spider-man-into-the-spider-verse',
    'get-out', 'mad-max-fury-road', 'top-gun-maverick'
  ));

INSERT IGNORE INTO movies
  (slug, title, overview, release_year, runtime_minutes, content_type, age_rating, poster_url, backdrop_url, external_rating)
VALUES
  ('avatar', 'Avatar', 'A former Marine travels to a distant moon, where he must choose between following orders and protecting a new home.', 2009, 162, 'movie', 'PG-13', 'kyeqWdyUXW608qlYkRqosgbbJyK.jpg', '2lBOQK06tltt8SQRFwi8p3a8DiY.jpg', 7.9),
  ('avengers-endgame', 'Avengers: Endgame', 'After a devastating loss, the remaining heroes reunite for one final effort to restore what was lost.', 2019, 181, 'movie', 'PG-13', 'or06FN3Dka5tukK1e9sl16pB3iy.jpg', '7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg', 8.4),
  ('guardians-of-the-galaxy', 'Guardians of the Galaxy', 'A group of unlikely companions band together after a daring theft puts the fate of the galaxy in question.', 2014, 121, 'movie', 'PG-13', 'r7vmZjiyZw9rpJMQJdXpjgiCOk9.jpg', 'uLtVbjvS1O7gXL8lUOwsFOH4man.jpg', 8.0),
  ('black-panther', 'Black Panther', 'A newly crowned king returns home and faces a challenge that could put his nation and its future at risk.', 2018, 134, 'movie', 'PG-13', 'uxzzxijgPIY7slzFvMotPv8wjKA.jpg', 'b6ZJZHUdMEFECvGiDpJjlfUWela.jpg', 7.3),
  ('toy-story', 'Toy Story', 'A cowboy toy and a new space-ranger figure learn to share the spotlight when a child gets a new favorite.', 1995, 81, 'movie', 'G', 'uXDfjJbdP4ijW5hWSBrPrlKpxab.jpg', 'dji4Fm0gCDVb9DQQMRvAI8YNnTz.jpg', 8.3),
  ('finding-nemo', 'Finding Nemo', 'A cautious clownfish crosses the ocean with an optimistic companion to find his missing son.', 2003, 100, 'movie', 'G', 'eHuGQ10FUzK1mdOY69wF5pGgEf5.jpg', 'xVNSgrsv7gY9KvUwFZ3bx9Bl2D.jpg', 8.2),
  ('inside-out', 'Inside Out', 'A young girl navigates a major life change with help from the emotions working inside her mind.', 2015, 95, 'movie', 'PG', '2H1TmgdfNtsKlU9jKdeNyYL5y8T.jpg', 'aAmfIX3TT40zUHGcCKrlOZRKC7u.jpg', 8.1),
  ('ratatouille', 'Ratatouille', 'An ambitious rat with a remarkable sense of taste finds an unlikely chance to cook in Paris.', 2007, 111, 'movie', 'G', 't3vaWRPSf6WjDSamIkKDs1iQWna.jpg', 'xgDj56UWyeWQcxQ44f5A3RTWuSs.jpg', 8.1),
  ('up', 'Up', 'A widower sets off on the adventure he once promised his wife, with an unexpected young companion in tow.', 2009, 96, 'movie', 'PG', 'vpbaStTMt8qqXaEgnOR2EE4DNJk.jpg', 'mFvoEwSfLqbcWwFsDjQebn9bzFe.jpg', 8.3),
  ('john-wick', 'John Wick', 'A retired hitman returns to the underworld after a personal loss draws him back into danger.', 2014, 101, 'movie', 'R', 'fZPSd91yGE9fCcCe6OoQr6E3Bev.jpg', 'umC04Cozevu8nn3JTDJ1pc7PVTn.jpg', 7.4),
  ('mission-impossible-fallout', 'Mission: Impossible - Fallout', 'An impossible assignment sends Ethan Hunt and his team racing to stop a global catastrophe.', 2018, 147, 'movie', 'PG-13', 'AkJQpZp9WoNdj7pLYSj1L0RcMMN.jpg', '5qxePyMYDisLe8rJiBYX8HKEyv2.jpg', 7.7),
  ('edge-of-tomorrow', 'Edge of Tomorrow', 'A soldier caught in a time loop relives a losing battle and searches for a way to change its outcome.', 2014, 113, 'movie', 'PG-13', 'nBM9MMa2WCwvMG4IJ3eiGUdbPe6.jpg', '7mgKeg18Qml5nJQa56RBZO7dIu0.jpg', 7.9),
  ('shutter-island', 'Shutter Island', 'A federal investigator travels to an isolated hospital to investigate a patient''s disappearance.', 2010, 138, 'movie', 'R', '4GDy0PHYX3VRXUtwK5ysFbg3kEx.jpg', '4p1N2Qrt8j0H8xMhm6g2jOMF5eK.jpg', 8.2),
  ('joker', 'Joker', 'A lonely aspiring entertainer struggles to find his place in a city that increasingly turns against him.', 2019, 122, 'movie', 'R', 'udDclJoHjfjb8Ekgsd4FDteOkCU.jpg', 'n6bUvigpRFqSwmPp1m2YADdbRBc.jpg', 8.2),
  ('django-unchained', 'Django Unchained', 'A freed man joins a bounty hunter on a dangerous journey to reunite with his wife.', 2012, 165, 'movie', 'R', '7oWY8VDWW7thTzWh3OKYRkWUlD5.jpg', '2o0PKGmnSgCGk9jKE4e7mHe7z7W.jpg', 8.2),
  ('the-departed', 'The Departed', 'An undercover officer and a criminal informant each try to expose the other while protecting their cover.', 2006, 151, 'movie', 'R', 'nT97ifVT2J1yMQmeq20Qblg61T.jpg', '8Od5zV7Q7zNOX0y9tyNgpTmoiGA.jpg', 8.5),
  ('logan', 'Logan', 'In a bleak future, an aging Logan protects a young mutant while confronting the past he tried to leave behind.', 2017, 137, 'movie', 'R', 'fnbjcRDYn6YviCcePDnGdyAkYsB.jpg', '5pAGnkFYSsFJ99ZxDIYnhQbQFXs.jpg', 8.1),
  ('the-godfather', 'The Godfather', 'The aging head of a powerful crime family considers how to protect his legacy as a new generation takes charge.', 1972, 175, 'movie', 'R', '3bhkrj58Vtu7enYsRolD1fZdja1.jpg', 'tmU7GeKVybMWFButWEGl2M4GeiP.jpg', 9.2),
  ('the-lion-king', 'The Lion King', 'A young lion leaves home after a family tragedy and later returns to face the responsibilities of his past.', 1994, 89, 'movie', 'G', '2bXbqYdUdNVa8VIWXVfclP2ICtT.jpg', 'wXsQvli6tWqja51pYxXNG1LFIGV.jpg', 8.5),
  ('the-pianist', 'The Pianist', 'A pianist struggles to survive and hold on to his music during the destruction of his city in wartime.', 2002, 150, 'movie', 'R', '2hFvxCCWrTmCYwfy7yum0GKRi3Y.jpg', '5U1VZVbZq3qv9r3kV7M9jXm2l3L.jpg', 8.5),
  ('the-return-of-the-king', 'The Lord of the Rings: The Return of the King', 'The final members of a fellowship face their greatest battles as the fate of Middle-earth hangs in the balance.', 2003, 201, 'movie', 'PG-13', 'rCzpDGLbOoPwLjy3OAm5NUPOTrC.jpg', '2u7zbn8EudG6kLlBzUYqP8RyFU4.jpg', 9.0),
  ('the-incredibles', 'The Incredibles', 'A family of former superheroes returns to action when a new threat calls for all of their unique talents.', 2004, 115, 'movie', 'PG', '2LqaLgk4Z226KkgPJuiOQ58wvrm.jpg', 'x1FJkJkKx6JXx6m9G8c8hHBgHz2.jpg', 8.0);

INSERT IGNORE INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m JOIN genres g
  ON (m.slug = 'avatar' AND g.slug IN ('sci-fi', 'adventure', 'action'))
  OR (m.slug = 'avengers-endgame' AND g.slug IN ('sci-fi', 'adventure', 'action'))
  OR (m.slug = 'guardians-of-the-galaxy' AND g.slug IN ('sci-fi', 'adventure', 'comedy'))
  OR (m.slug = 'black-panther' AND g.slug IN ('action', 'adventure', 'sci-fi'))
  OR (m.slug = 'toy-story' AND g.slug IN ('animation', 'adventure', 'comedy'))
  OR (m.slug = 'finding-nemo' AND g.slug IN ('animation', 'adventure', 'comedy'))
  OR (m.slug = 'inside-out' AND g.slug IN ('animation', 'adventure', 'comedy'))
  OR (m.slug = 'ratatouille' AND g.slug IN ('animation', 'comedy'))
  OR (m.slug = 'up' AND g.slug IN ('animation', 'adventure', 'comedy'))
  OR (m.slug = 'john-wick' AND g.slug IN ('action', 'thriller', 'crime'))
  OR (m.slug = 'mission-impossible-fallout' AND g.slug IN ('action', 'adventure', 'thriller'))
  OR (m.slug = 'edge-of-tomorrow' AND g.slug IN ('action', 'sci-fi', 'adventure'))
  OR (m.slug = 'shutter-island' AND g.slug IN ('mystery', 'thriller', 'drama'))
  OR (m.slug = 'joker' AND g.slug IN ('crime', 'drama', 'thriller'))
  OR (m.slug = 'django-unchained' AND g.slug IN ('drama', 'western', 'action'))
  OR (m.slug = 'the-departed' AND g.slug IN ('crime', 'drama', 'thriller'))
  OR (m.slug = 'logan' AND g.slug IN ('action', 'drama', 'sci-fi'))
  OR (m.slug = 'the-godfather' AND g.slug IN ('crime', 'drama'))
  OR (m.slug = 'the-lion-king' AND g.slug IN ('animation', 'adventure', 'drama'))
  OR (m.slug = 'the-pianist' AND g.slug IN ('drama', 'history'))
  OR (m.slug = 'the-return-of-the-king' AND g.slug IN ('fantasy', 'adventure', 'action'))
  OR (m.slug = 'the-incredibles' AND g.slug IN ('animation', 'action', 'adventure', 'comedy'));

INSERT IGNORE INTO collection_movies (collection_id, movie_id, sort_order)
SELECT c.id, m.id, 100 + m.id
FROM collections c
CROSS JOIN movies m
WHERE (c.slug = 'movies' AND m.slug IN (
    'avatar', 'avengers-endgame', 'guardians-of-the-galaxy', 'black-panther',
    'toy-story', 'finding-nemo', 'inside-out', 'ratatouille', 'up', 'john-wick',
    'mission-impossible-fallout', 'edge-of-tomorrow', 'shutter-island', 'joker',
    'django-unchained', 'the-departed', 'logan', 'the-godfather', 'the-lion-king',
    'the-pianist', 'the-return-of-the-king', 'the-incredibles'
  ))
  OR (c.slug = 'trending' AND m.slug IN (
    'avatar', 'avengers-endgame', 'guardians-of-the-galaxy', 'black-panther',
    'john-wick', 'joker', 'the-incredibles'
  ))
  OR (c.slug = 'acclaimed' AND m.slug IN (
    'toy-story', 'finding-nemo', 'inside-out', 'ratatouille', 'up',
    'shutter-island', 'the-departed', 'logan', 'the-godfather',
    'the-lion-king', 'the-pianist', 'the-return-of-the-king'
  ))
  OR (c.slug = 'anime' AND m.slug IN (
    'toy-story', 'finding-nemo', 'inside-out', 'ratatouille', 'up', 'the-lion-king', 'the-incredibles'
  ))
  OR (c.slug = 'mystery' AND m.slug IN ('shutter-island', 'joker', 'the-departed'));

INSERT IGNORE INTO movies
  (slug, title, overview, release_year, runtime_minutes, content_type, age_rating, poster_url, backdrop_url, external_rating)
VALUES
  ('hello-love-goodbye', 'Hello, Love, Goodbye', 'Two overseas Filipino workers in Hong Kong balance family responsibilities, personal ambitions, and the possibility of building a life together.', 2019, 118, 'movie', 'NR', 'sJFouUfCgHFSUh5OKVSQBSfrfA1.jpg', 'sJFouUfCgHFSUh5OKVSQBSfrfA1.jpg', 7.7),
  ('heneral-luna', 'Heneral Luna', 'During the Philippine-American War, General Antonio Luna leads the revolutionary army while confronting divisions within his own ranks.', 2015, 118, 'movie', 'NR', 'fBv24gtxtiHSssgVg3QIITotYT9.jpg', 'fBv24gtxtiHSssgVg3QIITotYT9.jpg', 7.6),
  ('four-sisters-and-a-wedding', 'Four Sisters and a Wedding', 'Four sisters reunite to stop their youngest brother from marrying too soon, bringing old family tensions to the surface.', 2013, 125, 'movie', 'NR', 'yQgPveLenFJlA7jzmK0UuO59uVJ.jpg', 'yQgPveLenFJlA7jzmK0UuO59uVJ.jpg', 7.4),
  ('the-hows-of-us', 'The Hows of Us', 'A couple look back on their relationship as career pressures, shared responsibilities, and uncertain plans test their future.', 2018, 120, 'movie', 'NR', '2O3SS7Gh2OuKdzxi2bEOi7zNVue.jpg', '2O3SS7Gh2OuKdzxi2bEOi7zNVue.jpg', 7.1),
  ('die-beautiful', 'Die Beautiful', 'After a Filipino transgender woman dies, her friends honor her wish to celebrate the many different sides of her life.', 2016, 120, 'movie', 'NR', '5cZl3NKmC6iA4SfSquJCLncsv9X.jpg', '5cZl3NKmC6iA4SfSquJCLncsv9X.jpg', 7.5),
  ('bad-genius', 'Bad Genius', 'A gifted student turns her knack for exam tricks into a high-stakes scheme that reaches far beyond her school.', 2017, 130, 'movie', 'NR', 'g1gW6DQ7QFocDn24QBOZqoYpd3O.jpg', 'g1gW6DQ7QFocDn24QBOZqoYpd3O.jpg', 7.6),
  ('pee-mak', 'Pee Mak', 'A soldier returns from war to his village, where his friends suspect that something supernatural has joined his family.', 2013, 115, 'movie', 'NR', '5gY0EPvTdeGjEEIQ7337ZxHXV55.jpg', '5gY0EPvTdeGjEEIQ7337ZxHXV55.jpg', 7.2),
  ('how-to-make-millions-before-grandma-dies', 'How to Make Millions Before Grandma Dies', 'A young man moves in to care for his grandmother and discovers that their time together means more than he expected.', 2024, 125, 'movie', 'NR', '9Xa0Grd2jq2lM2gqcoTB4F9TjMd.jpg', '9Xa0Grd2jq2lM2gqcoTB4F9TjMd.jpg', 8.0),
  ('the-teachers-diary', 'The Teacher''s Diary', 'A teacher at a remote school finds a diary left by his predecessor and grows curious about the person behind its pages.', 2014, 110, 'movie', 'NR', 'xRwVmXZBzh6lZgKPVxwUdJpPI9p.jpg', 'xRwVmXZBzh6lZgKPVxwUdJpPI9p.jpg', 7.8),
  ('friend-zone', 'Friend Zone', 'A longtime friendship is tested when a woman and her closest male friend try to find out whether they could be more.', 2019, 119, 'movie', 'NR', 'ifJLg5uc0KQVrp8heSHwOFpBRK1.jpg', 'ifJLg5uc0KQVrp8heSHwOFpBRK1.jpg', 7.2),
  ('the-medium', 'The Medium', 'A documentary crew follows a shaman family in northern Thailand as a suspected possession takes a frightening turn.', 2021, 131, 'movie', 'NR', 'wOJbWVMqdKIerkvOegeHfORxWqV.jpg', 'wOJbWVMqdKIerkvOegeHfORxWqV.jpg', 7.0),
  ('train-to-busan', 'Train to Busan', 'A father and daughter board a train as a fast-moving outbreak turns the journey to safety into a fight to survive.', 2016, 118, 'movie', 'NR', 'vNVFt6dtcqnI7hqa6LFBUibuFiw.jpg', 'vNVFt6dtcqnI7hqa6LFBUibuFiw.jpg', 7.6),
  ('oldboy-2003', 'Oldboy', 'After being held captive for years without explanation, a man is released and begins searching for the truth behind his imprisonment.', 2003, 120, 'movie', 'NR', 'pWDtjs568ZfOTMbURQBYuT4Qxka.jpg', 'rwf5SUTiEsmfkXAgy15R0UtJUtv.jpg', 8.2),
  ('the-handmaiden', 'The Handmaiden', 'In 1930s Korea, a young pickpocket joins a plan involving a Japanese heiress, but hidden motives shift the balance between them.', 2016, 145, 'movie', 'NR', 'dLlH4aNHdnmf62umnInL8xPlPzw.jpg', '2b3RNXF7ca9bgX8FrjRBYfLnNQC.jpg', 8.1),
  ('the-wailing', 'The Wailing', 'A police officer investigates a mysterious illness spreading through a quiet village after the arrival of a stranger.', 2016, 156, 'movie', 'NR', 'lWE9ih9qgjx8HatYboP7fG0nri.jpg', 'lWE9ih9qgjx8HatYboP7fG0nri.jpg', 7.5),
  ('extreme-job', 'Extreme Job', 'An undercover detective squad opens a chicken restaurant to watch a criminal gang and accidentally makes the restaurant a hit.', 2019, 111, 'movie', 'NR', '52oLgq2gEiZyDjpJ7tgkGruoQI0.jpg', '52oLgq2gEiZyDjpJ7tgkGruoQI0.jpg', 7.1),
  ('decision-to-leave', 'Decision to Leave', 'A detective investigating a death on a mountain becomes increasingly drawn to the mysterious widow at the center of the case.', 2022, 139, 'movie', 'NR', 'zI8KZ4EdLUymWKX1YEkpZ0gtPUa.jpg', 'zI8KZ4EdLUymWKX1YEkpZ0gtPUa.jpg', 7.4),
  ('three-idiots', '3 Idiots', 'Three engineering students challenge their university''s rigid expectations and learn to follow their curiosity and friendships.', 2009, 170, 'movie', 'NR', 'pDGRC8Dbo9my6T5uun86uciGhz.jpg', 'pDGRC8Dbo9my6T5uun86uciGhz.jpg', 8.4),
  ('dangal', 'Dangal', 'A former wrestler trains his daughters to compete in a sport where women are rarely given the chance to shine.', 2016, 161, 'movie', 'NR', 'cJRPOLEexI7qp2DKtFfCh7YaaUG.jpg', 'cJRPOLEexI7qp2DKtFfCh7YaaUG.jpg', 8.2),
  ('rrr', 'RRR', 'Two legendary revolutionaries form an unexpected friendship in a fictional adventure set in colonial India.', 2022, 187, 'movie', 'NR', 'wE0I6efAW4cDDmZQWtwZMOW44EJ.jpg', 'wE0I6efAW4cDDmZQWtwZMOW44EJ.jpg', 7.8),
  ('andhadhun', 'Andhadhun', 'A pianist who pretends to be blind becomes entangled in a crime that turns his carefully constructed life upside down.', 2018, 139, 'movie', 'NR', 'dy3K6hNvwE05siGgiLJcEiwgpdO.jpg', 'dy3K6hNvwE05siGgiLJcEiwgpdO.jpg', 8.2),
  ('lagaan', 'Lagaan: Once Upon a Time in India', 'A village challenges its colonial rulers to a cricket match, wagering the land tax that threatens their future.', 2001, 224, 'movie', 'NR', 'yNX9lFRAFeNLNRIXdqZK9gYrYKa.jpg', 'yNX9lFRAFeNLNRIXdqZK9gYrYKa.jpg', 8.1),
  ('gully-boy', 'Gully Boy', 'A young man from Mumbai finds his voice and a path toward becoming a rapper despite the limits others place on him.', 2019, 154, 'movie', 'NR', '4RE7TD5TqEXbPKyUHcn7CSeMlrJ.jpg', '4RE7TD5TqEXbPKyUHcn7CSeMlrJ.jpg', 7.4),
  ('your-name', 'Your Name', 'Two teenagers who have never met begin waking up in each other''s lives and search for the reason their connection exists.', 2016, 106, 'movie', 'NR', 'vfJFJPepRKapMd5G2ro7klIRysq.jpg', 'vfJFJPepRKapMd5G2ro7klIRysq.jpg', 8.5),
  ('akira', 'Akira', 'A biker gang member develops dangerous psychic powers in a city still recovering from catastrophe.', 1988, 124, 'movie', 'NR', 'neZ0ykEsPqxamsX6o5QNUFILQrz.jpg', 'neZ0ykEsPqxamsX6o5QNUFILQrz.jpg', 8.0),
  ('shoplifters', 'Shoplifters', 'A family living on the margins takes in a young girl, and their close bond raises questions about what makes a family.', 2018, 121, 'movie', 'NR', '4nfRUOv3LX5zLn98WS1WqVBk9E9.jpg', '4nfRUOv3LX5zLn98WS1WqVBk9E9.jpg', 7.9),
  ('battle-royale', 'Battle Royale', 'A class of students is taken to an island and forced into a brutal survival game by the government.', 2000, 114, 'movie', 'NR', 'aLGKAQKgzWpJ6egyWzzC11jXBRJ.jpg', 'aLGKAQKgzWpJ6egyWzzC11jXBRJ.jpg', 7.6),
  ('perfect-blue', 'Perfect Blue', 'A former pop singer pursues an acting career as her sense of identity and reality begins to fracture.', 1997, 81, 'movie', 'NR', '6WTiOCfDPP8XV4jqfloiVWf7KHq.jpg', '6WTiOCfDPP8XV4jqfloiVWf7KHq.jpg', 8.0),
  ('godzilla-minus-one', 'Godzilla Minus One', 'In postwar Japan, a former pilot and a group of civilians face a devastating monster threatening their coastline.', 2023, 125, 'movie', 'NR', '2E2WTX0TJEflAged6kzErwqX1kt.jpg', '2E2WTX0TJEflAged6kzErwqX1kt.jpg', 7.7),
  ('rashomon', 'Rashomon', 'Several witnesses offer conflicting accounts of a violent crime, leaving the truth open to interpretation.', 1950, 88, 'movie', 'NR', 'ijWibsAU1iBcCD8tuIZfTmDzMVE.jpg', 'ijWibsAU1iBcCD8tuIZfTmDzMVE.jpg', 8.1);

INSERT IGNORE INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m JOIN genres g
  ON (m.slug = 'hello-love-goodbye' AND g.slug IN ('romance', 'drama'))
  OR (m.slug = 'heneral-luna' AND g.slug IN ('history', 'drama', 'action'))
  OR (m.slug = 'four-sisters-and-a-wedding' AND g.slug IN ('comedy', 'drama'))
  OR (m.slug = 'the-hows-of-us' AND g.slug IN ('romance', 'drama'))
  OR (m.slug = 'die-beautiful' AND g.slug IN ('comedy', 'drama'))
  OR (m.slug = 'bad-genius' AND g.slug IN ('thriller', 'drama', 'crime'))
  OR (m.slug = 'pee-mak' AND g.slug IN ('comedy', 'romance', 'horror'))
  OR (m.slug = 'how-to-make-millions-before-grandma-dies' AND g.slug IN ('drama', 'comedy'))
  OR (m.slug = 'the-teachers-diary' AND g.slug IN ('romance', 'drama', 'comedy'))
  OR (m.slug = 'friend-zone' AND g.slug IN ('romance', 'comedy'))
  OR (m.slug = 'the-medium' AND g.slug IN ('horror', 'mystery', 'thriller'))
  OR (m.slug = 'train-to-busan' AND g.slug IN ('action', 'horror', 'thriller'))
  OR (m.slug = 'oldboy-2003' AND g.slug IN ('thriller', 'mystery', 'drama'))
  OR (m.slug = 'the-handmaiden' AND g.slug IN ('thriller', 'romance', 'drama'))
  OR (m.slug = 'the-wailing' AND g.slug IN ('horror', 'mystery', 'thriller'))
  OR (m.slug = 'extreme-job' AND g.slug IN ('action', 'comedy', 'crime'))
  OR (m.slug = 'decision-to-leave' AND g.slug IN ('mystery', 'romance', 'thriller'))
  OR (m.slug = 'three-idiots' AND g.slug IN ('comedy', 'drama', 'romance'))
  OR (m.slug = 'dangal' AND g.slug IN ('drama', 'history', 'action'))
  OR (m.slug = 'rrr' AND g.slug IN ('action', 'drama', 'history'))
  OR (m.slug = 'andhadhun' AND g.slug IN ('thriller', 'crime', 'comedy'))
  OR (m.slug = 'lagaan' AND g.slug IN ('drama', 'romance', 'history'))
  OR (m.slug = 'gully-boy' AND g.slug IN ('drama', 'romance'))
  OR (m.slug = 'your-name' AND g.slug IN ('animation', 'romance', 'fantasy'))
  OR (m.slug = 'akira' AND g.slug IN ('animation', 'sci-fi', 'action'))
  OR (m.slug = 'shoplifters' AND g.slug IN ('drama', 'crime'))
  OR (m.slug = 'battle-royale' AND g.slug IN ('thriller', 'action', 'drama'))
  OR (m.slug = 'perfect-blue' AND g.slug IN ('animation', 'mystery', 'thriller'))
  OR (m.slug = 'godzilla-minus-one' AND g.slug IN ('sci-fi', 'drama', 'action'))
  OR (m.slug = 'rashomon' AND g.slug IN ('drama', 'crime', 'mystery'));

INSERT IGNORE INTO collection_movies (collection_id, movie_id, sort_order)
SELECT c.id, m.id, 50 + m.id
FROM collections c
CROSS JOIN movies m
WHERE (c.slug = 'movies' AND m.slug IN (
    'hello-love-goodbye', 'heneral-luna', 'four-sisters-and-a-wedding', 'the-hows-of-us', 'die-beautiful',
    'bad-genius', 'pee-mak', 'how-to-make-millions-before-grandma-dies', 'the-teachers-diary', 'friend-zone', 'the-medium',
    'train-to-busan', 'oldboy-2003', 'the-handmaiden', 'the-wailing', 'extreme-job', 'decision-to-leave',
    'three-idiots', 'dangal', 'rrr', 'andhadhun', 'lagaan', 'gully-boy',
    'your-name', 'akira', 'shoplifters', 'battle-royale', 'perfect-blue', 'godzilla-minus-one', 'rashomon'
  ))
  OR (c.slug = 'filipino' AND m.slug IN (
    'hello-love-goodbye', 'heneral-luna', 'four-sisters-and-a-wedding', 'the-hows-of-us', 'die-beautiful'
  ))
  OR (c.slug = 'thai' AND m.slug IN (
    'bad-genius', 'pee-mak', 'how-to-make-millions-before-grandma-dies', 'the-teachers-diary', 'friend-zone', 'the-medium'
  ))
  OR (c.slug = 'korean' AND m.slug IN (
    'train-to-busan', 'oldboy-2003', 'the-handmaiden', 'the-wailing', 'extreme-job', 'decision-to-leave'
  ))
  OR (c.slug = 'indian' AND m.slug IN (
    'three-idiots', 'dangal', 'rrr', 'andhadhun', 'lagaan', 'gully-boy'
  ))
  OR (c.slug = 'japanese' AND m.slug IN (
    'your-name', 'akira', 'shoplifters', 'battle-royale', 'perfect-blue', 'godzilla-minus-one', 'rashomon'
  ));

UPDATE movies SET poster_url = '9cqNxx0GxF0bflZmeSMuL5tnGzr.jpg' WHERE slug = 'the-shawshank-redemption';
UPDATE movies SET poster_url = '6Ryitt95xrO8KXuqRGm1fUuNwqF.jpg' WHERE slug = 'coco';
UPDATE movies SET poster_url = 'Ag2B2KHKQPukjH7WutmgnnSNurZ.jpg' WHERE slug = 'the-prestige';
UPDATE movies SET poster_url = 'nBM9MMa2WCwvMG4IJ3eiGUdbPe6.jpg' WHERE slug = 'edge-of-tomorrow';
UPDATE movies SET poster_url = 'fnbjcRDYn6YviCcePDnGdyAkYsB.jpg' WHERE slug = 'logan';
UPDATE movies SET poster_url = '3bhkrj58Vtu7enYsRolD1fZdja1.jpg' WHERE slug = 'the-godfather';
UPDATE movies SET backdrop_url = 'yaExZh6qE2cfyK3o4kAMEq0mkgy.jpg' WHERE slug = 'the-prestige';
