<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$user = current_user();
$watchedTitles = [];
if ($user !== null) {
    $statement = database()->prepare("SELECT m.*,
        (SELECT GROUP_CONCAT(g.name ORDER BY g.name SEPARATOR ' · ')
         FROM movie_genres mg JOIN genres g ON g.id = mg.genre_id WHERE mg.movie_id = m.id) AS genre_names,
        wh.last_watched_at
        FROM watch_history wh
        JOIN movies m ON m.id = wh.movie_id
        WHERE wh.user_id = :user_id AND m.is_published = 1
        ORDER BY wh.last_watched_at DESC");
    $statement->execute(['user_id' => $user['id']]);
    $watchedTitles = $statement->fetchAll();
}

$pageTitle = 'Watch history';
require __DIR__ . '/includes/header.php';
?>
<section class="page-intro compact-intro">
  <p class="eyebrow">YOUR PERSONAL LIBRARY</p>
  <h1>Watch history</h1>
  <p>Titles you have marked as watched.</p>
</section>
<?php if ($user === null): ?>
  <section class="empty-library"><h2>Sign in to keep your history.</h2><p>Your watched titles are saved to your account.</p><a class="button button-primary" href="login.php">Sign in</a></section>
<?php elseif ($watchedTitles === []): ?>
  <section class="empty-library"><span class="empty-mark">◷</span><h2>Your history is empty.</h2><p>Open a title and mark it as watched to keep track here.</p><a class="button button-primary" href="index.php#collections">Explore the catalog</a></section>
<?php else: ?>
  <section class="catalog-grid saved-catalog">
    <?php foreach ($watchedTitles as $movie): ?>
      <?php $returnView = ''; require __DIR__ . '/includes/movie-card.php'; ?>
    <?php endforeach; ?>
  </section>
<?php endif; ?>
<?php require __DIR__ . '/includes/footer.php'; ?>
