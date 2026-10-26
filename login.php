<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$errors = [];
$email = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    require_valid_csrf();
    $rawEmail = $_POST['email'] ?? '';
    $rawPassword = $_POST['password'] ?? '';
    $email = is_string($rawEmail) ? strtolower(trim($rawEmail)) : '';
    $password = is_string($rawPassword) ? $rawPassword : '';

    if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($email) > 254) {
        $errors[] = 'Enter a valid email address.';
    }
    if ($password === '' || strlen($password) > 4096) {
        $errors[] = 'Enter your password.';
    }

    if ($errors === []) {
        try {
            $statement = database()->prepare('SELECT id, display_name, email, password_hash, role FROM users WHERE email = :email LIMIT 1');
            $statement->execute(['email' => $email]);
            $user = $statement->fetch();
            if ($user === false || !password_verify($password, $user['password_hash'])) {
                $errors[] = 'The email or password is incorrect.';
            } else {
                session_regenerate_id(true);
                $_SESSION['user'] = [
                    'id' => (int) $user['id'],
                    'display_name' => $user['display_name'],
                    'email' => $user['email'],
                    'role' => $user['role'],
                ];
                redirect('index.php');
            }
        } catch (PDOException $exception) {
            error_log('NOTFLIX sign-in failed: ' . $exception->getMessage());
            $errors[] = 'Unable to sign in right now. Make sure the database schema has been imported.';
        }
    }
}

$pageTitle = 'Sign in';
require __DIR__ . '/includes/header.php';
?>
<section class="auth-page">
  <div class="auth-aside">
    <span class="auth-issue">NOTFLIX / MEMBER ACCESS</span>
    <span class="auth-aside-number">01</span>
    <p>A considered collection<br>of stories worth finding.</p>
  </div>
  <div class="auth-card">
    <p class="eyebrow">WELCOME BACK</p>
    <h1>Sign in</h1>
    <p class="auth-subtitle">Sign in to keep your personal list in sync.</p>
    <?php if (($notice = flash('notice')) !== null): ?><p class="form-notice"><?= escape($notice) ?></p><?php endif; ?>
    <?php foreach ($errors as $error): ?><p class="form-error"><?= escape($error) ?></p><?php endforeach; ?>
    <form method="post" action="login.php" class="account-form">
      <?= csrf_field() ?>
      <label for="email">Email address</label>
      <input id="email" name="email" type="email" autocomplete="email" maxlength="254" value="<?= escape($email) ?>" required>
      <label for="password">Password</label>
      <input id="password" name="password" type="password" autocomplete="current-password" required>
      <button class="button button-primary auth-submit" type="submit">Sign in <span aria-hidden="true">→</span></button>
    </form>
    <p class="auth-switch">New to NOTFLIX? <a href="signup.php">Create an account</a></p>
  </div>
</section>
<?php require __DIR__ . '/includes/footer.php'; ?>
