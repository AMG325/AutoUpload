<?php
// Получение файла от Windows-приложения, проверка ключа, привязка к пользователю

if (empty($_FILES['file'])) {
    trace($_SERVER['REMOTE_ADDR'], 'Empty request');
    exit('Empty request');
}

if (empty($_SERVER['HTTP_X_AUTHKEY'])) {
    trace($_SERVER['REMOTE_ADDR'], 'Empty HTTP_X_AUTHKEY');
    exit('Empty key');
}

$user = find_user_by_key($_SERVER['HTTP_X_AUTHKEY']);
if (empty($user['id'])) {
    trace($_SERVER['REMOTE_ADDR'], 'Invalid key=' . $_SERVER['HTTP_X_AUTHKEY']);
    exit('User not found');
}
$id = 'u=' . $user['id'];

$file = save_user_file($user['login'], date('Y-m-d H:i:s'));
if (empty($file)) {
    trace($id, 'Failed save_user_file');
    exit('File not saved');
}

// все норм, вернуть пустую строку
trace($id, "{$file} <-- {$_FILES['file']['name']}");



function find_user_by_key($key) {
    if ($key === 'abcd1234') {
        return ['id' => 1, 'login' => 'test'];
    }
}

// вернуть ссылку в хранилище или пустоту при ошибке
function save_user_file($login, $dt) {
    // ошибка при загрузке
    if ($_FILES['file']['error'] !== 0) {
        trace('Form upload error:', $_FILES['file']['error']);
        return;
    }

    // взять расширение с точкой
    $ext = pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION);
    if (strlen($ext)) {
        $ext = '.' . $ext;
    }

    // имя файла по шаблону 2017-12-31 22:33:44 --> 2017/12-31_22-33-44.mp3
    if (!preg_match('|(\d{4})-(\d\d)-(\d\d)\s(\d\d):(\d\d):(\d\d)|', $dt, $m)) {
        trace('Wrong datetime:', $dt);
        return;
    }
    $name = "{$m[2]}-{$m[3]}_{$m[4]}-{$m[5]}-{$m[6]}{$ext}";

    // путь относительно корня сайта
    // /storage/user/2017/12-31_22-33-44.mp3
    $path = "/storage/{$login}/{$m[1]}/";

    // отдельный каталог в хранилище
    $dir = $_SERVER['DOCUMENT_ROOT'] . $path;
    if (!is_dir($dir) and !mkdir($dir, 0777, true)) {
        trace('Failed mkdir:', $dir);
        return;
    }

    // переместить файл
    $full = $dir . $name;
    if (!@move_uploaded_file($_FILES['file']['tmp_name'], $full)) {
        trace('Failed move:', $full);
    }

    // return 'https://' . $_SERVER['NAME'] . $path . $name;
    return $path . $name;
}

// сообщение в журнал для отладки, с разбивкой по месяцам
function trace() {
    $s = '';
    foreach (func_get_args() as $x) {
        $s .= ' ' . (is_string($x) ? $x : var_export($x, true));
    }
    file_put_contents(
        __DIR__ . '/log' . date('ym') . '.txt',
        date('d/m H:i:s') . $s . PHP_EOL,
        FILE_APPEND
    );
}
