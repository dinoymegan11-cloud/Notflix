<?php
$adminTab = $adminTab ?? 'dashboard';
$adminTitle = $adminTitle ?? 'Admin';
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#090909">
  <title><?= escape($adminTitle) ?> · NOTFLIX Admin</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Manrope:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="styles.css">
</head>
<body class="admin-shell">
<aside class="admin-sidebar">
  <a class="admin-brand" href="admin.php"><span class="wordmark-mark">N</span><span>NOTFLIX<small>ADMIN STUDIO</small></span></a>
  <nav class="admin-nav" aria-label="Admin navigation">
    <a class="<?= $adminTab === 'dashboard' ? 'is-current' : '' ?>" href="admin.php">Overview</a>
    <a class="<?= $adminTab === 'movies' ? 'is-current' : '' ?>" href="admin.php?tab=movies">Movies &amp; series</a>
    <a class="<?= $adminTab === 'add' ? 'is-current' : '' ?>" href="admin.php?tab=add">Add a title</a>
    <a class="<?= $adminTab === 'reviews' ? 'is-current' : '' ?>" href="admin.php?tab=reviews">Reviews</a>
  </nav>
  <div class="admin-sidebar-bottom">
    <span><?= escape($adminUser['display_name']) ?></span>
    <a href="index.php">View public site ↗</a>
    <form action="logout.php" method="post">
      <?= csrf_field() ?>
      <button type="submit">Sign out</button>
    </form>
  </div>
</aside>
<main class="admin-main">
  <header class="admin-topbar"><span>ADMINISTRATION</span><span><?= escape($adminUser['email']) ?></span></header>
  <div class="admin-content">
