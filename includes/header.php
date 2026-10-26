<?php
$pageTitle = $pageTitle ?? 'Discover films and series';
$user = current_user();
$searchValue = isset($_GET['q']) && is_string($_GET['q']) ? $_GET['q'] : '';
$isCatalogHome = basename($_SERVER['SCRIPT_NAME'] ?? '') === 'index.php'
    && !isset($_GET['q'])
    && !isset($_GET['genre'])
    && !isset($_GET['type'])
    && !isset($_GET['view']);
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#090909">
  <title><?= escape($pageTitle) ?> · NOTFLIX</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Manrope:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="styles.css">
</head>
<body<?= $isCatalogHome ? ' class="catalog-home"' : '' ?>>
<header class="site-header">
  <a class="wordmark" href="index.php" aria-label="NOTFLIX home"><span class="wordmark-mark">N</span> NOTFLIX</a>
  <nav class="main-nav" aria-label="Main navigation">
    <a class="nav-link" href="index.php">Discover</a>
    <a class="nav-link" href="index.php?type=movie">Films</a>
    <a class="nav-link" href="index.php?type=series">Series</a>
    <?php if ($user !== null): ?>
      <a class="nav-link" href="index.php?view=my-list#my-list">My List</a>
      <a class="nav-link" href="history.php">Watch history</a>
      <?php if (($user['role'] ?? '') === 'admin'): ?>
        <a class="nav-link" href="admin.php">Admin</a>
      <?php endif; ?>
    <?php endif; ?>
  </nav>
  <div class="header-actions">
    <form class="search-form" action="index.php" method="get" role="search">
      <label class="visually-hidden" for="site-search">Search the catalog</label>
      <span aria-hidden="true">⌕</span>
      <input id="site-search" type="search" name="q" value="<?= escape($searchValue) ?>" placeholder="Search titles or genres">
      <button class="search-submit" type="submit">Search</button>
    </form>
    <?php if ($user !== null): ?>
      <span class="signed-in-name"><?= escape($user['display_name']) ?></span>
      <form action="logout.php" method="post">
        <?= csrf_field() ?>
        <button class="header-account" type="submit">Sign out</button>
      </form>
    <?php else: ?>
      <a class="header-account" href="login.php">Sign in</a>
      <a class="header-account account-create" href="signup.php">Create account</a>
    <?php endif; ?>
  </div>
</header>
<main>
