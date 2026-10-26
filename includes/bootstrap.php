<?php
declare(strict_types=1);

if (session_status() !== PHP_SESSION_ACTIVE) {
    ini_set('session.use_strict_mode', '1');
    session_set_cookie_params([
        'httponly' => true,
        'secure' => !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
        'samesite' => 'Lax',
        'path' => '/',
    ]);
    session_start();
}

require_once __DIR__ . '/database.php';

function escape(?string $value): string
{
    return htmlspecialchars($value ?? '', ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function csrf_token(): string
{
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }

    return $_SESSION['csrf_token'];
}

function csrf_field(): string
{
    return '<input type="hidden" name="csrf_token" value="' . escape(csrf_token()) . '">';
}

function csrf_is_valid(): bool
{
    return isset($_POST['csrf_token'], $_SESSION['csrf_token'])
        && is_string($_POST['csrf_token'])
        && hash_equals($_SESSION['csrf_token'], $_POST['csrf_token']);
}

function current_user(): ?array
{
    return isset($_SESSION['user']) && is_array($_SESSION['user'])
        ? $_SESSION['user']
        : null;
}

function require_admin(): array
{
    $user = current_user();
    if ($user === null) {
        redirect('login.php');
    }

    $statement = database()->prepare('SELECT role FROM users WHERE id = :id LIMIT 1');
    $statement->execute(['id' => $user['id']]);
    $role = $statement->fetchColumn();
    if ($role !== 'admin') {
        http_response_code(403);
        exit('You do not have permission to access this page.');
    }

    $_SESSION['user']['role'] = $role;
    return $_SESSION['user'];
}

function flash(string $key, ?string $message = null): ?string
{
    if ($message !== null) {
        $_SESSION['flash'][$key] = $message;
        return null;
    }

    $value = $_SESSION['flash'][$key] ?? null;
    unset($_SESSION['flash'][$key]);
    return is_string($value) ? $value : null;
}

function redirect(string $url): never
{
    header('Location: ' . $url);
    exit;
}

function require_valid_csrf(): void
{
    if (!csrf_is_valid()) {
        http_response_code(400);
        exit('Your session token expired. Refresh the page and try again.');
    }
}
