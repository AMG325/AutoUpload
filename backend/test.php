<?php
// Отправка файла через cURL для проверки скрипта приёма файлов

// см. ../src/config.ini
$URL = 'http://localhost:8000/upload.php';
$AuthKey = 'abcd1234';

$ch = curl_init($URL);

// добавить ключ в заголовок
curl_setopt($ch, CURLOPT_HTTPHEADER, ['X-AuthKey: ' . $AuthKey]);

// отправить файл
$cfile = curl_file_create(realpath('../README.md'), 'text/plain', 'readme.txt');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, ['file' => $cfile]);

if (curl_exec($ch) === false) {
    echo PHP_EOL, "cURL Error: ", curl_error($ch);
} else {
    echo PHP_EOL, "HTTP code: ", curl_getinfo($ch, CURLINFO_HTTP_CODE);
}

curl_close($ch);
