<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$adminUser = require_admin();
$pdo = database();
$allowedTabs = ['dashboard', 'movies', 'add', 'edit', 'reviews'];
$requestedTab = $_GET['tab'] ?? 'dashboard';
$adminTab = is_string($requestedTab) && in_array($requestedTab, $allowedTabs, true) ? $requestedTab : 'dashboard';
$formErrors = [];
$formValues = [
    'title' => '',
    'overview' => '',
    'release_year' => (string) date('Y'),
    'runtime_minutes' => '',
    'content_type' => 'movie',
    'age_rating' => '',
    'poster_url' => '',
    'backdrop_url' => '',
    'external_rating' => '',
    'genre_ids' => [],
    'collection_ids' => [],
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    require_valid_csrf();
    $action = $_POST['action'] ?? '';

    if (in_array($action, ['add-title', 'update-title'], true)) {
        $isEditing = $action === 'update-title';
        $editId = $isEditing ? filter_var($_POST['record_id'] ?? null, FILTER_VALIDATE_INT) : null;
        if ($isEditing && ($editId === false || $editId === null || $editId < 1)) {
            http_response_code(400);
            exit('Invalid title.');
        }
        if ($isEditing) {
            $existingTitle = $pdo->prepare('SELECT id FROM movies WHERE id = :id');
            $existingTitle->execute(['id' => $editId]);
            if (!$existingTitle->fetchColumn()) {
                http_response_code(404);
                exit('Title not found.');
            }
        }

        foreach (['title', 'overview', 'release_year', 'runtime_minutes', 'content_type', 'age_rating', 'poster_url', 'backdrop_url', 'external_rating'] as $field) {
            $rawValue = $_POST[$field] ?? '';
            $formValues[$field] = is_string($rawValue) ? trim($rawValue) : '';
        }

        $rawGenreIds = $_POST['genre_ids'] ?? [];
        $rawCollectionIds = $_POST['collection_ids'] ?? [];
        $formValues['genre_ids'] = is_array($rawGenreIds) ? $rawGenreIds : [];
        $formValues['collection_ids'] = is_array($rawCollectionIds) ? $rawCollectionIds : [];

        $title = $formValues['title'];
        $overview = $formValues['overview'];
        $year = filter_var($formValues['release_year'], FILTER_VALIDATE_INT);
        $runtime = $formValues['runtime_minutes'] === '' ? null : filter_var($formValues['runtime_minutes'], FILTER_VALIDATE_INT);
        $contentType = $formValues['content_type'];
        $ageRating = $formValues['age_rating'];
        $posterUrl = $formValues['poster_url'];
        $backdropUrl = $formValues['backdrop_url'];
        $externalRating = $formValues['external_rating'] === '' ? null : filter_var($formValues['external_rating'], FILTER_VALIDATE_FLOAT);
        $genreIds = [];
        $collectionIds = [];

        if ($title === '' || mb_strlen($title) > 200) {
            $formErrors[] = 'Enter a title between 1 and 200 characters.';
        }
        if ($overview === '' || mb_strlen($overview) > 4000) {
            $formErrors[] = 'Enter an overview of up to 4,000 characters.';
        }
        if ($year === false || $year < 1888 || $year > (int) date('Y') + 5) {
            $formErrors[] = 'Enter a valid release year.';
        }
        if ($runtime === false || ($runtime !== null && ($runtime < 1 || $runtime > 1000))) {
            $formErrors[] = 'Runtime must be between 1 and 1,000 minutes.';
        }
        if (!in_array($contentType, ['movie', 'series'], true)) {
            $formErrors[] = 'Choose movie or series.';
        }
        if (mb_strlen($ageRating) > 16) {
            $formErrors[] = 'Age rating must be 16 characters or fewer.';
        }
        foreach (['poster_url' => $posterUrl, 'backdrop_url' => $backdropUrl] as $label => $imageUrl) {
            $isHttpsUrl = str_starts_with($imageUrl, 'https://')
                && filter_var($imageUrl, FILTER_VALIDATE_URL) !== false;
            $isImagePath = preg_match('/^[A-Za-z0-9._\/-]+$/', $imageUrl) === 1
                && !str_starts_with($imageUrl, '//')
                && preg_match('/(^|\/)\.\.(\/|$)/', $imageUrl) !== 1;
            if (strlen($imageUrl) > 500 || ($imageUrl !== '' && !$isHttpsUrl && !$isImagePath)) {
                $formErrors[] = 'Enter a valid HTTPS image URL or a poster path for ' . ($label === 'poster_url' ? 'the poster' : 'the backdrop') . '.';
            }
        }
        if ($externalRating === false || ($externalRating !== null && ($externalRating < 0 || $externalRating > 10))) {
            $formErrors[] = 'External rating must be between 0 and 10.';
        }
        foreach ($formValues['genre_ids'] as $rawId) {
            $id = filter_var($rawId, FILTER_VALIDATE_INT);
            if ($id !== false && $id > 0) {
                $genreIds[] = $id;
            } else {
                $formErrors[] = 'A selected genre is invalid.';
            }
        }
        $genreIds = array_values(array_unique($genreIds));
        if ($genreIds === []) {
            $formErrors[] = 'Choose at least one genre.';
        }
        foreach ($formValues['collection_ids'] as $rawId) {
            $id = filter_var($rawId, FILTER_VALIDATE_INT);
            if ($id !== false && $id > 0) {
                $collectionIds[] = $id;
            } else {
                $formErrors[] = 'A selected homepage shelf is invalid.';
            }
        }
        $collectionIds = array_values(array_unique($collectionIds));

        if ($formErrors === []) {
            $asciiTitle = iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $title);
            $slugSource = strtolower($asciiTitle ?: $title);
            $slug = trim((string) preg_replace('/[^a-z0-9]+/', '-', $slugSource), '-');
            $slug = rtrim(substr($slug, 0, 180), '-');
            if ($slug === '') {
                $formErrors[] = 'This title cannot be converted into a URL slug.';
            } else {
                $genreLookup = $pdo->prepare('SELECT COUNT(*) FROM genres WHERE id IN (' . implode(',', array_fill(0, count($genreIds), '?')) . ')');
                $genreLookup->execute($genreIds);
                if ((int) $genreLookup->fetchColumn() !== count($genreIds)) {
                    $formErrors[] = 'One or more selected genres no longer exist.';
                }
                if ($collectionIds !== []) {
                    $collectionLookup = $pdo->prepare("SELECT COUNT(*) FROM collections WHERE is_published = 1 AND slug NOT IN ('movies', 'series') AND id IN (" . implode(',', array_fill(0, count($collectionIds), '?')) . ')');
                    $collectionLookup->execute($collectionIds);
                    if ((int) $collectionLookup->fetchColumn() !== count($collectionIds)) {
                        $formErrors[] = 'One or more selected collections are unavailable.';
                    }
                }
                $slugCheck = $pdo->prepare('SELECT 1 FROM movies WHERE slug = :slug AND id <> :id LIMIT 1');
                $slugCheck->execute(['slug' => $slug, 'id' => $isEditing ? $editId : 0]);
                if ($slugCheck->fetchColumn()) {
                    $formErrors[] = $isEditing
                        ? 'Another title already uses this name. Choose a distinguishing title.'
                        : 'A title with this name already exists. Add a distinguishing word to its title.';
                }
            }
        }

        if ($formErrors === []) {
            try {
                $pdo->beginTransaction();
                $movieData = [
                    'slug' => $slug,
                    'title' => $title,
                    'overview' => $overview,
                    'release_year' => $year,
                    'runtime_minutes' => $runtime,
                    'content_type' => $contentType,
                    'age_rating' => $ageRating !== '' ? $ageRating : null,
                    'poster_url' => $posterUrl !== '' ? $posterUrl : null,
                    'backdrop_url' => $backdropUrl !== '' ? $backdropUrl : null,
                    'external_rating' => $externalRating,
                ];
                if ($isEditing) {
                    $movieData['id'] = $editId;
                    $saveTitle = $pdo->prepare('UPDATE movies SET slug = :slug, title = :title, overview = :overview,
                        release_year = :release_year, runtime_minutes = :runtime_minutes, content_type = :content_type,
                        age_rating = :age_rating, poster_url = :poster_url, backdrop_url = :backdrop_url,
                        external_rating = :external_rating WHERE id = :id');
                    $saveTitle->execute($movieData);
                    $movieId = $editId;
                    $pdo->prepare('DELETE FROM movie_genres WHERE movie_id = :movie_id')->execute(['movie_id' => $movieId]);
                    $pdo->prepare('DELETE FROM collection_movies WHERE movie_id = :movie_id')->execute(['movie_id' => $movieId]);
                } else {
                    $insertTitle = $pdo->prepare('INSERT INTO movies
                        (slug, title, overview, release_year, runtime_minutes, content_type, age_rating, poster_url, backdrop_url, external_rating)
                        VALUES (:slug, :title, :overview, :release_year, :runtime_minutes, :content_type, :age_rating, :poster_url, :backdrop_url, :external_rating)');
                    $insertTitle->execute($movieData);
                    $movieId = (int) $pdo->lastInsertId();
                }
                $insertGenre = $pdo->prepare('INSERT INTO movie_genres (movie_id, genre_id) VALUES (:movie_id, :genre_id)');
                foreach ($genreIds as $genreId) {
                    $insertGenre->execute(['movie_id' => $movieId, 'genre_id' => $genreId]);
                }

                $defaultCollection = $pdo->prepare('SELECT id FROM collections WHERE slug = :slug LIMIT 1');
                $defaultCollection->execute(['slug' => $contentType === 'series' ? 'series' : 'movies']);
                $defaultCollectionId = $defaultCollection->fetchColumn();
                if ($defaultCollectionId !== false) {
                    $collectionIds[] = (int) $defaultCollectionId;
                }
                $collectionIds = array_values(array_unique($collectionIds));
                $insertCollection = $pdo->prepare('INSERT INTO collection_movies (collection_id, movie_id, sort_order) VALUES (:collection_id, :movie_id, :sort_order)');
                foreach ($collectionIds as $collectionId) {
                    $insertCollection->execute([
                        'collection_id' => $collectionId,
                        'movie_id' => $movieId,
                        'sort_order' => 50 + $movieId,
                    ]);
                }
                $pdo->commit();
                flash('notice', $isEditing ? '“' . $title . '” was updated.' : '“' . $title . '” was added to the catalog.');
                redirect('admin.php?tab=movies');
            } catch (PDOException $exception) {
                if ($pdo->inTransaction()) {
                    $pdo->rollBack();
                }
                if ($exception->getCode() === '23000') {
                    $formErrors[] = 'This title could not be added because its name or catalog record already exists.';
                } else {
                    error_log('NOTFLIX admin catalog insert failed: ' . $exception->getMessage());
                    $formErrors[] = 'The title could not be added due to a database error.';
                }
            }
        }
        $adminTab = $isEditing ? 'edit' : 'add';
        if ($isEditing) {
            $_GET['id'] = (string) $editId;
        }
    } elseif ($action === 'delete-title') {
        $recordId = filter_var($_POST['record_id'] ?? null, FILTER_VALIDATE_INT);
        $confirmation = $_POST['confirm_delete'] ?? '';
        if ($recordId === false || $recordId === null || $recordId < 1 || $confirmation !== 'DELETE') {
            http_response_code(400);
            exit('Type DELETE exactly to confirm permanent removal.');
        }
        $deleteTitle = $pdo->prepare('DELETE FROM movies WHERE id = :id');
        $deleteTitle->execute(['id' => $recordId]);
        if ($deleteTitle->rowCount() !== 1) {
            http_response_code(404);
            exit('Title not found.');
        }
        flash('notice', 'Title and its linked reviews, watchlists, and watch history were permanently deleted.');
        redirect('admin.php?tab=movies');
    } elseif (in_array($action, ['set-review-status', 'set-title-visibility'], true)) {
        $recordId = filter_var($_POST['record_id'] ?? null, FILTER_VALIDATE_INT);
        if ($recordId === false || $recordId === null || $recordId < 1) {
            http_response_code(400);
            exit('Invalid record.');
        }

        if ($action === 'set-review-status') {
            $status = $_POST['status'] ?? '';
            if (!in_array($status, ['published', 'hidden'], true)) {
                http_response_code(400);
                exit('Invalid review status.');
            }
            $statement = $pdo->prepare('UPDATE reviews SET status = :status WHERE id = :id');
            $statement->execute(['status' => $status, 'id' => $recordId]);
            if ($statement->rowCount() === 0) {
                $check = $pdo->prepare('SELECT 1 FROM reviews WHERE id = :id');
                $check->execute(['id' => $recordId]);
                if (!$check->fetchColumn()) {
                    http_response_code(404);
                    exit('Review not found.');
                }
            }
            flash('notice', 'Review moderation updated.');
            redirect('admin.php?tab=reviews');
        }

        $published = filter_var($_POST['is_published'] ?? null, FILTER_VALIDATE_INT);
        if (!in_array($published, [0, 1], true)) {
            http_response_code(400);
            exit('Invalid catalog visibility.');
        }
        $statement = $pdo->prepare('UPDATE movies SET is_published = :published WHERE id = :id');
        $statement->execute(['published' => $published, 'id' => $recordId]);
        if ($statement->rowCount() === 0) {
            $check = $pdo->prepare('SELECT 1 FROM movies WHERE id = :id');
            $check->execute(['id' => $recordId]);
            if (!$check->fetchColumn()) {
                http_response_code(404);
                exit('Title not found.');
            }
        }
        flash('notice', $published === 1 ? 'Title is now visible in the catalog.' : 'Title has been hidden from the catalog.');
        redirect('admin.php?tab=movies');
    } else {
        http_response_code(400);
        exit('Invalid action.');
    }
}

$counts = [
    'titles' => (int) $pdo->query('SELECT COUNT(*) FROM movies')->fetchColumn(),
    'published' => (int) $pdo->query('SELECT COUNT(*) FROM movies WHERE is_published = 1')->fetchColumn(),
    'members' => (int) $pdo->query("SELECT COUNT(*) FROM users WHERE role = 'member'")->fetchColumn(),
    'reviews' => (int) $pdo->query('SELECT COUNT(*) FROM reviews')->fetchColumn(),
    'hidden_reviews' => (int) $pdo->query("SELECT COUNT(*) FROM reviews WHERE status = 'hidden'")->fetchColumn(),
];
$genres = $pdo->query('SELECT id, name FROM genres ORDER BY name')->fetchAll();
$collections = $pdo->query("SELECT id, name FROM collections WHERE is_published = 1 AND slug NOT IN ('movies', 'series') ORDER BY sort_order, name")->fetchAll();
$editTitle = null;
if ($adminTab === 'edit' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    $editId = filter_var($_GET['id'] ?? null, FILTER_VALIDATE_INT);
    if ($editId === false || $editId === null || $editId < 1) {
        http_response_code(400);
        exit('Invalid title.');
    }
    $editQuery = $pdo->prepare('SELECT * FROM movies WHERE id = :id LIMIT 1');
    $editQuery->execute(['id' => $editId]);
    $editTitle = $editQuery->fetch();
    if ($editTitle === false) {
        http_response_code(404);
        exit('Title not found.');
    }
    foreach (['title', 'overview', 'release_year', 'runtime_minutes', 'content_type', 'age_rating', 'poster_url', 'backdrop_url', 'external_rating'] as $field) {
        $formValues[$field] = (string) ($editTitle[$field] ?? '');
    }
    $editGenres = $pdo->prepare('SELECT genre_id FROM movie_genres WHERE movie_id = :movie_id');
    $editGenres->execute(['movie_id' => $editId]);
    $formValues['genre_ids'] = array_map('strval', $editGenres->fetchAll(PDO::FETCH_COLUMN));
    $editCollections = $pdo->prepare("SELECT cm.collection_id FROM collection_movies cm JOIN collections c ON c.id = cm.collection_id WHERE cm.movie_id = :movie_id AND c.slug NOT IN ('movies', 'series')");
    $editCollections->execute(['movie_id' => $editId]);
    $formValues['collection_ids'] = array_map('strval', $editCollections->fetchAll(PDO::FETCH_COLUMN));
}
$titleSearch = isset($_GET['q']) && is_string($_GET['q']) ? trim($_GET['q']) : '';
$titleStatement = $pdo->prepare("SELECT m.id, m.title, m.slug, m.release_year, m.content_type, m.is_published,
    (SELECT GROUP_CONCAT(g.name ORDER BY g.name SEPARATOR ', ')
     FROM movie_genres mg JOIN genres g ON g.id = mg.genre_id WHERE mg.movie_id = m.id) AS genre_names
    FROM movies m
    WHERE (:query = '' OR m.title LIKE :title_query)
    ORDER BY m.created_at DESC, m.title
    LIMIT 500");
$titleStatement->execute(['query' => $titleSearch, 'title_query' => '%' . $titleSearch . '%']);
$titles = $titleStatement->fetchAll();
$reviews = $pdo->query("SELECT r.id, r.rating, r.review_text, r.status, r.created_at,
    u.display_name, m.title, m.slug
    FROM reviews r
    JOIN users u ON u.id = r.user_id
    JOIN movies m ON m.id = r.movie_id
    ORDER BY r.created_at DESC LIMIT 100")->fetchAll();

$adminTitle = match ($adminTab) {
    'movies' => 'Movies & series',
    'add' => 'Add a title',
    'edit' => 'Edit title',
    'reviews' => 'Review moderation',
    default => 'Overview',
};
require __DIR__ . '/includes/admin-header.php';
?>
<?php if (($notice = flash('notice')) !== null): ?><div class="notice-bar"><?= escape($notice) ?></div><?php endif; ?>
<?php if ($formErrors !== []): ?>
  <div class="form-error" role="alert"><?php foreach ($formErrors as $error): ?><p><?= escape($error) ?></p><?php endforeach; ?></div>
<?php endif; ?>

<?php if ($adminTab === 'dashboard'): ?>
  <section class="admin-page">
    <div class="admin-page-heading"><div><p class="eyebrow">NOTFLIX / ADMINISTRATION</p><h1>Overview</h1><p>Manage your catalog and community from here.</p></div><a class="button button-primary" href="admin.php?tab=add">＋ Add a title</a></div>
    <div class="admin-stats">
      <article><span>CATALOG TITLES</span><strong><?= $counts['titles'] ?></strong></article>
      <article><span>PUBLISHED</span><strong><?= $counts['published'] ?></strong></article>
      <article><span>MEMBERS</span><strong><?= $counts['members'] ?></strong></article>
      <article><span>REVIEWS</span><strong><?= $counts['reviews'] ?></strong></article>
    </div>
    <div class="admin-dashboard-grid">
      <a class="admin-action-card" href="admin.php?tab=movies"><span>01 / CATALOG</span><strong>Movies &amp; series</strong><small>Browse titles and manage what appears on the public site.</small></a>
      <a class="admin-action-card" href="admin.php?tab=add"><span>02 / NEW TITLE</span><strong>Add a title</strong><small>Add a movie or series, its poster, genres, and homepage shelves.</small></a>
      <a class="admin-action-card" href="admin.php?tab=reviews"><span>03 / COMMUNITY</span><strong>Review moderation</strong><small>Publish or hide member reviews. <?= $counts['hidden_reviews'] ?> currently hidden.</small></a>
    </div>
    <section class="admin-section">
      <div class="admin-section-heading"><div><p class="collection-index">RECENT ADDITIONS</p><h2>Latest catalog titles</h2></div><a class="text-link" href="admin.php?tab=movies">Manage titles →</a></div>
      <div class="admin-title-list">
        <?php foreach (array_slice($titles, 0, 8) as $title): ?>
          <article class="admin-title"><div><strong><?= escape($title['title']) ?></strong><span><?= (int) $title['release_year'] ?> · <?= escape(ucfirst($title['content_type'])) ?><?= $title['genre_names'] ? ' · ' . escape($title['genre_names']) : '' ?></span></div><span class="admin-status status-<?= $title['is_published'] ? 'published' : 'hidden' ?>"><?= $title['is_published'] ? 'PUBLISHED' : 'HIDDEN' ?></span><a class="button button-secondary" href="title.php?slug=<?= rawurlencode($title['slug']) ?>">View</a></article>
        <?php endforeach; ?>
      </div>
    </section>
  </section>
<?php elseif ($adminTab === 'movies'): ?>
  <section class="admin-page">
    <div class="admin-page-heading"><div><p class="eyebrow">CATALOG MANAGEMENT</p><h1>Movies &amp; series</h1><p>Manage <?= $counts['titles'] ?> titles. Hidden titles stay in the database but are removed from public browsing.</p></div><a class="button button-primary" href="admin.php?tab=add">＋ Add a title</a></div>
    <form class="admin-search" action="admin.php" method="get"><input type="hidden" name="tab" value="movies"><label class="visually-hidden" for="admin-title-search">Search titles</label><input id="admin-title-search" type="search" name="q" value="<?= escape($titleSearch) ?>" placeholder="Search title names"><button class="button button-secondary" type="submit">Search</button></form>
    <div class="admin-title-list">
      <?php foreach ($titles as $title): ?>
        <article class="admin-title">
          <div><strong><?= escape($title['title']) ?></strong><span><?= (int) $title['release_year'] ?> · <?= escape(ucfirst($title['content_type'])) ?><?= $title['genre_names'] ? ' · ' . escape($title['genre_names']) : '' ?></span></div>
          <span class="admin-status status-<?= $title['is_published'] ? 'published' : 'hidden' ?>"><?= $title['is_published'] ? 'PUBLISHED' : 'HIDDEN' ?></span>
          <div class="admin-title-actions">
            <?php if ((int) $title['is_published'] === 1): ?><a class="button button-secondary" href="title.php?slug=<?= rawurlencode($title['slug']) ?>">View</a><?php endif; ?>
            <a class="button button-secondary" href="admin.php?tab=edit&amp;id=<?= (int) $title['id'] ?>">Edit</a>
            <form method="post" action="admin.php?tab=movies">
              <?= csrf_field() ?>
              <input type="hidden" name="action" value="set-title-visibility">
              <input type="hidden" name="record_id" value="<?= (int) $title['id'] ?>">
              <input type="hidden" name="is_published" value="<?= $title['is_published'] ? '0' : '1' ?>">
              <button class="button button-secondary" type="submit"><?= $title['is_published'] ? 'Hide title' : 'Publish title' ?></button>
            </form>
            <details class="admin-delete-details">
              <summary>Delete</summary>
              <form method="post" action="admin.php?tab=movies" class="admin-delete-form">
                <?= csrf_field() ?>
                <input type="hidden" name="action" value="delete-title">
                <input type="hidden" name="record_id" value="<?= (int) $title['id'] ?>">
                <label>Type DELETE to permanently remove this title<input name="confirm_delete" autocomplete="off" required pattern="DELETE" title="Type DELETE exactly"></label>
                <p>This also deletes associated reviews, watchlists, and watch history. Hide the title instead if you want to keep those records.</p>
                <button class="button button-danger" type="submit">Delete permanently</button>
              </form>
            </details>
          </div>
        </article>
      <?php endforeach; ?>
      <?php if ($titles === []): ?><p class="review-empty">No titles match that search.</p><?php endif; ?>
    </div>
  </section>
<?php elseif ($adminTab === 'add'): ?>
  <section class="admin-page">
    <div class="admin-page-heading"><div><p class="eyebrow">CATALOG MANAGEMENT</p><h1>Add a title</h1><p>New titles are published to the public catalog and added to the matching Movies or Series shelf.</p></div></div>
    <form class="admin-form" method="post" action="admin.php?tab=add">
      <?= csrf_field() ?>
      <input type="hidden" name="action" value="add-title">
      <div class="admin-form-grid">
        <label class="admin-field admin-field-wide" for="title-name">Title<input id="title-name" name="title" maxlength="200" value="<?= escape($formValues['title']) ?>" required></label>
        <label class="admin-field" for="release-year">Release year<input id="release-year" name="release_year" type="number" min="1888" max="<?= (int) date('Y') + 5 ?>" value="<?= escape($formValues['release_year']) ?>" required></label>
        <label class="admin-field" for="content-type">Type<select id="content-type" name="content_type"><option value="movie"<?= $formValues['content_type'] === 'movie' ? ' selected' : '' ?>>Movie</option><option value="series"<?= $formValues['content_type'] === 'series' ? ' selected' : '' ?>>Series</option></select></label>
        <label class="admin-field" for="runtime">Runtime (minutes)<input id="runtime" name="runtime_minutes" type="number" min="1" max="1000" value="<?= escape($formValues['runtime_minutes']) ?>" placeholder="Optional"></label>
        <label class="admin-field" for="age-rating">Age rating<input id="age-rating" name="age_rating" maxlength="16" value="<?= escape($formValues['age_rating']) ?>" placeholder="e.g. PG-13"></label>
        <label class="admin-field" for="external-rating">External rating (0–10)<input id="external-rating" name="external_rating" type="number" min="0" max="10" step="0.1" value="<?= escape($formValues['external_rating']) ?>" placeholder="Optional"></label>
        <label class="admin-field admin-field-wide" for="poster-url">Poster image URL or TMDB path<input id="poster-url" name="poster_url" maxlength="500" value="<?= escape($formValues['poster_url']) ?>" placeholder="https://… or poster-file.jpg"></label>
        <label class="admin-field admin-field-wide" for="backdrop-url">Backdrop image URL or TMDB path<input id="backdrop-url" name="backdrop_url" maxlength="500" value="<?= escape($formValues['backdrop_url']) ?>" placeholder="Optional"></label>
        <label class="admin-field admin-field-wide" for="overview">Overview<textarea id="overview" name="overview" rows="5" maxlength="4000" required><?= escape($formValues['overview']) ?></textarea></label>
      </div>
      <fieldset class="admin-choice-group"><legend>Genres <span>Choose at least one</span></legend><div class="admin-choice-list">
        <?php foreach ($genres as $genre): ?><label><input type="checkbox" name="genre_ids[]" value="<?= (int) $genre['id'] ?>"<?= in_array((string) $genre['id'], $formValues['genre_ids'], true) ? ' checked' : '' ?>><?= escape($genre['name']) ?></label><?php endforeach; ?>
      </div></fieldset>
      <fieldset class="admin-choice-group"><legend>Homepage shelves <span>Default Movies or Series shelf is included automatically</span></legend><div class="admin-choice-list">
        <?php foreach ($collections as $collection): ?><label><input type="checkbox" name="collection_ids[]" value="<?= (int) $collection['id'] ?>"<?= in_array((string) $collection['id'], $formValues['collection_ids'], true) ? ' checked' : '' ?>><?= escape($collection['name']) ?></label><?php endforeach; ?>
      </div></fieldset>
      <div class="admin-form-actions"><button class="button button-primary" type="submit">Add to catalog</button><a class="button button-secondary" href="admin.php?tab=movies">Cancel</a></div>
    </form>
  </section>
<?php elseif ($adminTab === 'edit'): ?>
  <section class="admin-page">
    <div class="admin-page-heading"><div><p class="eyebrow">CATALOG MANAGEMENT</p><h1>Edit title</h1><p>Update title details, artwork, genres, and homepage shelves.</p></div><a class="button button-secondary" href="admin.php?tab=movies">← Back to catalog</a></div>
    <?php if ($editTitle !== null): ?><p class="admin-edit-status">Currently <?= $editTitle['is_published'] ? 'published' : 'hidden' ?>. Visibility can be changed from the Movies &amp; series list.</p><?php endif; ?>
    <form class="admin-form" method="post" action="admin.php?tab=edit&amp;id=<?= (int) ($_GET['id'] ?? $editTitle['id'] ?? 0) ?>">
      <?= csrf_field() ?>
      <input type="hidden" name="action" value="update-title">
      <input type="hidden" name="record_id" value="<?= (int) ($_GET['id'] ?? $editTitle['id'] ?? 0) ?>">
      <div class="admin-form-grid">
        <label class="admin-field admin-field-wide" for="title-name">Title<input id="title-name" name="title" maxlength="200" value="<?= escape($formValues['title']) ?>" required></label>
        <label class="admin-field" for="release-year">Release year<input id="release-year" name="release_year" type="number" min="1888" max="<?= (int) date('Y') + 5 ?>" value="<?= escape($formValues['release_year']) ?>" required></label>
        <label class="admin-field" for="content-type">Type<select id="content-type" name="content_type"><option value="movie"<?= $formValues['content_type'] === 'movie' ? ' selected' : '' ?>>Movie</option><option value="series"<?= $formValues['content_type'] === 'series' ? ' selected' : '' ?>>Series</option></select></label>
        <label class="admin-field" for="runtime">Runtime (minutes)<input id="runtime" name="runtime_minutes" type="number" min="1" max="1000" value="<?= escape($formValues['runtime_minutes']) ?>" placeholder="Optional"></label>
        <label class="admin-field" for="age-rating">Age rating<input id="age-rating" name="age_rating" maxlength="16" value="<?= escape($formValues['age_rating']) ?>" placeholder="e.g. PG-13"></label>
        <label class="admin-field" for="external-rating">External rating (0–10)<input id="external-rating" name="external_rating" type="number" min="0" max="10" step="0.1" value="<?= escape($formValues['external_rating']) ?>" placeholder="Optional"></label>
        <label class="admin-field admin-field-wide" for="poster-url">Poster image URL or TMDB path<input id="poster-url" name="poster_url" maxlength="500" value="<?= escape($formValues['poster_url']) ?>" placeholder="https://… or poster-file.jpg"></label>
        <label class="admin-field admin-field-wide" for="backdrop-url">Backdrop image URL or TMDB path<input id="backdrop-url" name="backdrop_url" maxlength="500" value="<?= escape($formValues['backdrop_url']) ?>" placeholder="Optional"></label>
        <label class="admin-field admin-field-wide" for="overview">Overview<textarea id="overview" name="overview" rows="5" maxlength="4000" required><?= escape($formValues['overview']) ?></textarea></label>
      </div>
      <fieldset class="admin-choice-group"><legend>Genres <span>Choose at least one</span></legend><div class="admin-choice-list">
        <?php foreach ($genres as $genre): ?><label><input type="checkbox" name="genre_ids[]" value="<?= (int) $genre['id'] ?>"<?= in_array((string) $genre['id'], $formValues['genre_ids'], true) ? ' checked' : '' ?>><?= escape($genre['name']) ?></label><?php endforeach; ?>
      </div></fieldset>
      <fieldset class="admin-choice-group"><legend>Homepage shelves</legend><div class="admin-choice-list">
        <?php foreach ($collections as $collection): ?><label><input type="checkbox" name="collection_ids[]" value="<?= (int) $collection['id'] ?>"<?= in_array((string) $collection['id'], $formValues['collection_ids'], true) ? ' checked' : '' ?>><?= escape($collection['name']) ?></label><?php endforeach; ?>
      </div></fieldset>
      <div class="admin-form-actions"><button class="button button-primary" type="submit">Save changes</button><a class="button button-secondary" href="admin.php?tab=movies">Cancel</a></div>
    </form>
  </section>
<?php else: ?>
  <section class="admin-page">
    <div class="admin-page-heading"><div><p class="eyebrow">COMMUNITY</p><h1>Review moderation</h1><p>Publish member reviews or hide content that should not appear publicly.</p></div></div>
    <?php if ($reviews === []): ?>
      <p class="review-empty">No member reviews yet. Reviews posted on title pages will appear here.</p>
    <?php else: ?>
      <div class="admin-review-list">
        <?php foreach ($reviews as $review): ?>
          <article class="admin-review">
            <div class="review-card-head"><strong><?= escape($review['display_name']) ?></strong><span><?= escape($review['title']) ?> · ★ <?= (int) $review['rating'] ?>/10</span><span class="admin-status status-<?= escape($review['status']) ?>"><?= escape(strtoupper($review['status'])) ?></span></div>
            <p><?= nl2br(escape($review['review_text'])) ?></p>
            <div class="admin-review-actions">
              <a class="button button-secondary" href="title.php?slug=<?= rawurlencode($review['slug']) ?>#reviews">View title</a>
              <form method="post" action="admin.php?tab=reviews">
                <?= csrf_field() ?>
                <input type="hidden" name="action" value="set-review-status">
                <input type="hidden" name="record_id" value="<?= (int) $review['id'] ?>">
                <input type="hidden" name="status" value="<?= $review['status'] === 'published' ? 'hidden' : 'published' ?>">
                <button class="button <?= $review['status'] === 'published' ? 'button-secondary' : 'button-primary' ?>" type="submit"><?= $review['status'] === 'published' ? 'Hide review' : 'Publish review' ?></button>
              </form>
            </div>
          </article>
        <?php endforeach; ?>
      </div>
    <?php endif; ?>
  </section>
<?php endif; ?>
<?php require __DIR__ . '/includes/admin-footer.php'; ?>
