<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$rawSlug = $_GET['slug'] ?? '';
$slug = is_string($rawSlug) ? trim($rawSlug) : '';
if ($slug === '' || strlen($slug) > 180) {
    http_response_code(404);
    exit('Title not found.');
}

try {
    $pdo = database();
    $statement = $pdo->prepare("SELECT m.*,
      (SELECT GROUP_CONCAT(g.name ORDER BY g.name SEPARATOR ' · ')
       FROM movie_genres mg JOIN genres g ON g.id = mg.genre_id WHERE mg.movie_id = m.id) AS genre_names
      FROM movies m WHERE m.slug = :slug AND m.is_published = 1 LIMIT 1");
    $statement->execute(['slug' => $slug]);
    $movie = $statement->fetch();
} catch (PDOException $exception) {
    error_log('NOTFLIX title lookup failed: ' . $exception->getMessage());
    http_response_code(503);
    exit('The catalog is unavailable. Start MySQL and import database/schema.sql.');
}

if ($movie === false) {
    http_response_code(404);
    exit('Title not found.');
}

$user = current_user();
$reviewErrors = [];
$reviewText = '';
$reviewRating = 8;
$userReview = null;
$isWatched = false;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    require_valid_csrf();
    if ($user === null) {
        flash('notice', 'Sign in to review titles or update your watch history.');
        redirect('login.php');
    }

    $action = $_POST['action'] ?? '';
    if ($action === 'save-review') {
        $rawRating = $_POST['rating'] ?? '';
        $rawReview = $_POST['review_text'] ?? '';
        $validatedRating = is_string($rawRating) ? filter_var($rawRating, FILTER_VALIDATE_INT) : false;
        $reviewRating = $validatedRating === false ? 0 : $validatedRating;
        $reviewText = is_string($rawReview) ? trim($rawReview) : '';

        if ($reviewRating < 1 || $reviewRating > 10) {
            $reviewErrors[] = 'Choose a rating from 1 to 10.';
        }
        if ($reviewText === '' || mb_strlen($reviewText) > 2000) {
            $reviewErrors[] = 'Write a review of up to 2,000 characters.';
        }

        if ($reviewErrors === []) {
            $saveReview = $pdo->prepare("INSERT INTO reviews (user_id, movie_id, rating, review_text)
                VALUES (:user_id, :movie_id, :rating, :review_text)
                ON DUPLICATE KEY UPDATE rating = VALUES(rating), review_text = VALUES(review_text)");
            $saveReview->execute([
                'user_id' => $user['id'],
                'movie_id' => $movie['id'],
                'rating' => $reviewRating,
                'review_text' => $reviewText,
            ]);
            flash('notice', 'Your review has been saved.');
            redirect('title.php?slug=' . rawurlencode($slug) . '#reviews');
        }
    } elseif ($action === 'toggle-watched') {
        $existingHistory = $pdo->prepare('SELECT 1 FROM watch_history WHERE user_id = :user_id AND movie_id = :movie_id');
        $existingHistory->execute(['user_id' => $user['id'], 'movie_id' => $movie['id']]);
        if ($existingHistory->fetchColumn()) {
            $removeHistory = $pdo->prepare('DELETE FROM watch_history WHERE user_id = :user_id AND movie_id = :movie_id');
            $removeHistory->execute(['user_id' => $user['id'], 'movie_id' => $movie['id']]);
            flash('notice', 'Title removed from your watch history.');
        } else {
            $addHistory = $pdo->prepare('INSERT INTO watch_history (user_id, movie_id, progress_seconds, completed_at) VALUES (:user_id, :movie_id, :progress, CURRENT_TIMESTAMP)');
            $addHistory->execute([
                'user_id' => $user['id'],
                'movie_id' => $movie['id'],
                'progress' => ((int) ($movie['runtime_minutes'] ?? 0)) * 60,
            ]);
            flash('notice', 'Title added to your watched history.');
        }
        redirect('title.php?slug=' . rawurlencode($slug));
    } else {
        http_response_code(400);
        exit('Invalid action.');
    }
}

$relatedQuery = $pdo->prepare("SELECT DISTINCT m.*,
    (SELECT GROUP_CONCAT(g.name ORDER BY g.name SEPARATOR ' · ')
     FROM movie_genres mg2 JOIN genres g ON g.id = mg2.genre_id WHERE mg2.movie_id = m.id) AS genre_names
  FROM movies m
  JOIN movie_genres related_mg ON related_mg.movie_id = m.id
  WHERE related_mg.genre_id IN (SELECT genre_id FROM movie_genres WHERE movie_id = :movie_id)
    AND m.id <> :exclude_id AND m.is_published = 1
  ORDER BY m.external_rating DESC LIMIT 4");
$relatedQuery->execute(['movie_id' => $movie['id'], 'exclude_id' => $movie['id']]);
$relatedMovies = $relatedQuery->fetchAll();

$isSaved = false;
$savedIds = [];
if ($user !== null) {
    $savedQuery = $pdo->prepare('SELECT movie_id FROM watchlist WHERE user_id = :user_id');
    $savedQuery->execute(['user_id' => $user['id']]);
    $savedIds = array_map('intval', $savedQuery->fetchAll(PDO::FETCH_COLUMN));
    $isSaved = in_array((int) $movie['id'], $savedIds, true);

    $reviewQuery = $pdo->prepare('SELECT rating, review_text, status FROM reviews WHERE user_id = :user_id AND movie_id = :movie_id LIMIT 1');
    $reviewQuery->execute(['user_id' => $user['id'], 'movie_id' => $movie['id']]);
    $userReview = $reviewQuery->fetch() ?: null;
    if ($userReview !== null && $_SERVER['REQUEST_METHOD'] !== 'POST') {
        $reviewRating = (int) $userReview['rating'];
        $reviewText = (string) $userReview['review_text'];
    }

    $historyQuery = $pdo->prepare('SELECT 1 FROM watch_history WHERE user_id = :user_id AND movie_id = :movie_id');
    $historyQuery->execute(['user_id' => $user['id'], 'movie_id' => $movie['id']]);
    $isWatched = (bool) $historyQuery->fetchColumn();
}

$reviewsQuery = $pdo->prepare("SELECT r.rating, r.review_text, r.created_at, u.display_name
    FROM reviews r JOIN users u ON u.id = r.user_id
    WHERE r.movie_id = :movie_id AND r.status = 'published'
    ORDER BY r.created_at DESC LIMIT 50");
$reviewsQuery->execute(['movie_id' => $movie['id']]);
$reviews = $reviewsQuery->fetchAll();

$poster = (string) ($movie['poster_url'] ?? '');
if ($poster !== '' && !str_starts_with($poster, 'http')) {
    $poster = 'https://image.tmdb.org/t/p/w780/' . ltrim($poster, '/');
}
$pageTitle = $movie['title'];
require __DIR__ . '/includes/header.php';
?>
<section class="title-detail">
  <a class="back-link" href="index.php">← Back to discover</a>
  <div class="detail-layout">
    <div class="detail-poster"><?php if ($poster !== ''): ?><img src="<?= escape($poster) ?>" alt="<?= escape($movie['title']) ?> poster"><?php endif; ?></div>
    <div class="detail-copy">
      <p class="eyebrow"><?= escape($movie['genre_names'] ?? '') ?></p>
      <h1><?= escape($movie['title']) ?></h1>
      <div class="detail-meta"><span><?= (int) $movie['release_year'] ?></span><span><?= escape($movie['age_rating'] ?: strtoupper($movie['content_type'])) ?></span><span><?= $movie['runtime_minutes'] ? (int) $movie['runtime_minutes'] . ' min' : 'Series' ?></span><span class="detail-rating">★ <?= escape((string) $movie['external_rating']) ?></span></div>
      <p class="detail-overview"><?= escape($movie['overview']) ?></p>
      <div class="detail-actions">
        <?php if ($user !== null): ?>
          <form action="index.php" method="post">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="toggle-watchlist">
            <input type="hidden" name="movie_id" value="<?= (int) $movie['id'] ?>">
            <button class="button button-primary" type="submit"><?= $isSaved ? '✓ In My List' : '+ Add to My List' ?></button>
          </form>
          <form action="title.php?slug=<?= rawurlencode($slug) ?>" method="post">
            <?= csrf_field() ?>
            <input type="hidden" name="action" value="toggle-watched">
            <button class="button button-secondary" type="submit"><?= $isWatched ? '✓ Watched · Remove' : 'Mark as watched' ?></button>
          </form>
        <?php else: ?>
          <a class="button button-primary" href="login.php">Sign in to save</a>
        <?php endif; ?>
      </div>
      <div class="detail-note"><span>CATALOG ENTRY</span><span>Playback availability is not included in this student catalog.</span></div>
    </div>
  </div>
</section>
<?php if (($notice = flash('notice')) !== null): ?><div class="notice-bar"><?= escape($notice) ?></div><?php endif; ?>
<section class="reviews-section" id="reviews">
  <div class="collection-head"><div><p class="collection-index">MEMBER REVIEWS</p><h2>Reviews</h2></div></div>
  <?php if ($user !== null): ?>
    <form class="review-form" action="title.php?slug=<?= rawurlencode($slug) ?>#reviews" method="post">
      <?= csrf_field() ?>
      <input type="hidden" name="action" value="save-review">
      <label for="review-rating">Your rating</label>
      <select id="review-rating" name="rating" required>
        <?php for ($rating = 10; $rating >= 1; $rating--): ?>
          <option value="<?= $rating ?>"<?= $reviewRating === $rating ? ' selected' : '' ?>><?= $rating ?> / 10</option>
        <?php endfor; ?>
      </select>
      <label for="review-text">Your review</label>
      <textarea id="review-text" name="review_text" rows="5" maxlength="2000" required><?= escape($reviewText) ?></textarea>
      <?php foreach ($reviewErrors as $error): ?><p class="form-error"><?= escape($error) ?></p><?php endforeach; ?>
      <?php if ($userReview !== null && $userReview['status'] === 'hidden'): ?><p class="form-notice">Your previous review is hidden by a moderator. Editing it will not automatically publish it.</p><?php endif; ?>
      <button class="button button-primary" type="submit"><?= $userReview === null ? 'Post review' : 'Update review' ?></button>
    </form>
  <?php else: ?>
    <p class="review-signin"><a href="login.php">Sign in</a> to rate and review this title.</p>
  <?php endif; ?>
  <?php if ($reviews === []): ?>
    <p class="review-empty">No published reviews yet. Be the first to share your thoughts.</p>
  <?php else: ?>
    <div class="review-list">
      <?php foreach ($reviews as $review): ?>
        <article class="review-card">
          <div class="review-card-head"><strong><?= escape($review['display_name']) ?></strong><span>★ <?= (int) $review['rating'] ?>/10</span><time datetime="<?= escape(date(DATE_ATOM, strtotime($review['created_at']))) ?>"><?= escape(date('M j, Y', strtotime($review['created_at']))) ?></time></div>
          <p><?= nl2br(escape($review['review_text'])) ?></p>
        </article>
      <?php endforeach; ?>
    </div>
  <?php endif; ?>
</section>
<?php if ($relatedMovies !== []): ?>
  <section class="collection">
    <div class="collection-head"><div><p class="collection-index">RELATED TITLES</p><h2>More to explore</h2></div></div>
    <div class="catalog-grid">
      <?php $returnView = ''; foreach ($relatedMovies as $index => $movie): require __DIR__ . '/includes/movie-card.php'; endforeach; ?>
    </div>
  </section>
<?php endif; ?>
<?php require __DIR__ . '/includes/footer.php'; ?>
