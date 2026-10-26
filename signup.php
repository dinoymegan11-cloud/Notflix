<?php
declare(strict_types=1);
require_once __DIR__ . '/includes/bootstrap.php';

$errors = [];
$name = '';
$email = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    require_valid_csrf();
    $rawName = $_POST['display_name'] ?? '';
    $rawEmail = $_POST['email'] ?? '';
    $rawPassword = $_POST['password'] ?? '';
    $rawConfirmation = $_POST['password_confirmation'] ?? '';
    $name = is_string($rawName) ? trim($rawName) : '';
    $email = is_string($rawEmail) ? strtolower(trim($rawEmail)) : '';
    $password = is_string($rawPassword) ? $rawPassword : '';
    $confirmation = is_string($rawConfirmation) ? $rawConfirmation : '';

    if ($name === '' || mb_strlen($name) > 80) {
        $errors[] = 'Your name must be between 1 and 80 characters.';
    }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($email) > 254) {
        $errors[] = 'Enter a valid email address.';
    }
    if (strlen($password) < 8 || strlen($password) > 4096) {
        $errors[] = 'Choose a password between 8 and 4096 characters.';
    }
    if ($password !== $confirmation) {
        $errors[] = 'The password confirmation does not match.';
    }

    if ($errors === []) {
        try {
            $statement = database()->prepare('INSERT INTO users (display_name, email, password_hash) VALUES (:display_name, :email, :password_hash)');
            $statement->execute([
                'display_name' => $name,
                'email' => $email,
                'password_hash' => password_hash($password, PASSWORD_DEFAULT),
            ]);
            session_regenerate_id(true);
            $_SESSION['user'] = [
                'id' => (int) database()->lastInsertId(),
                'display_name' => $name,
                'email' => $email,
                'role' => 'member',
            ];
            redirect('index.php');
        } catch (PDOException $exception) {
            if ($exception->getCode() === '23000') {
                $errors[] = 'An account with that email already exists.';
            } else {
                error_log('NOTFLIX registration failed: ' . $exception->getMessage());
                $errors[] = 'Unable to create your account right now. Make sure the database schema has been imported.';
            }
        }
    }
}

$pageTitle = 'Create an account';
require __DIR__ . '/includes/header.php';
?>
<section class="auth-page">
  <div class="auth-aside">
    <span class="auth-issue">NOTFLIX / MEMBER ACCESS</span>
    <span class="auth-aside-number">02</span>
    <p>Your next favorite<br>is a few discoveries away.</p>
  </div>
  <div class="auth-card">
    <p class="eyebrow">START YOUR COLLECTION</p>
    <h1>Create account</h1>
    <p class="auth-subtitle">Save titles and build a list that is yours.</p>
    <?php foreach ($errors as $error): ?><p class="form-error"><?= escape($error) ?></p><?php endforeach; ?>
    <form method="post" action="signup.php" class="account-form">
      <?= csrf_field() ?>
      <label for="display-name">Your name</label>
      <input id="display-name" name="display_name" type="text" autocomplete="name" maxlength="80" value="<?= escape($name) ?>" required>
      <label for="email">Email address</label>
      <input id="email" name="email" type="email" autocomplete="email" maxlength="254" value="<?= escape($email) ?>" required>
      <label for="password">Password <span class="label-note">At least 8 characters</span></label>
      <input id="password" name="password" type="password" autocomplete="new-password" minlength="8" required>
      <label for="password-confirmation">Confirm password</label>
      <input id="password-confirmation" name="password_confirmation" type="password" autocomplete="new-password" minlength="8" required>
      <button class="button button-primary auth-submit" type="submit">Create account <span aria-hidden="true">→</span></button>
    </form>
    <p class="auth-switch">Already have an account? <a href="login.php">Sign in</a></p>
  </div>
</section>
<?php require __DIR__ . '/includes/footer.php'; ?>
