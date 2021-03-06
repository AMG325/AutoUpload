# AutoUpload

Автоматическая выгрузка новых файлов из Windows-папки на HTTP-сервер

Программа наблюдает за указанной в настройках папкой и при появлении в ней нового файла (с заданным расширением или любого), ждёт окончания записи в этот файл, после чего запускает его выгрузку (POST-запрос на сервер).

## Системные требования

* Для запуска и компиляции нужен [AutoIt](http://www.autoitscript.com/site/autoit/).
* Проверена работа на Windows 7 и Windows 10 (32-bit).
* Для отправки HTTP-запроса применяется [PowerShell](https://docs.microsoft.com/powershell), достаточно версии 2, встроенной в Windows 7.

## Настройки

См. файл `src/config.ini`:

* `Folder` = папка, в которой надо отслеживать файлы.
* `Extension` = расширение файла - если задано, то прочие файлы отслеживаться не будут.
* `IntervalInSeconds` = число секунд, периодичность проверки изменений в папке.
* `URL` = адрес HTTP(S)-сервера, куда будут отправляться файлы.
* `AuthKey` = ключ доступа, добавляется к каждому отправленному файлу.

Если значение `Folder` или `AuthKey` пустое, то при запуске программа запросит его у пользователя.

## Запуск

См. `_run.cmd`, там примерно такие команды:

    cd src
    AutoIt3.exe AutoUpload.au3

## Приём файла на сервере

Пример скрипта приёма файлов см. в `backend/upload.php`

Изначально в настройках этот скрипт уже прописан:

    URL=http://localhost:8000/upload.php

Запустить приём через встроенный в PHP веб-сервер:

    cd backend
    php -S localhost:8000

## Компиляция скрипта

Можно получить исполняемый файл для удобства запуска, но для многих антивирусов
он будет подозрительным. Это известная проблема AutoIt - https://www.autoitscript.com/wiki/AutoIt_and_Malware

См. `_build.cmd`, там примерно такие команды:

    cd src
    Aut2exe.exe /in AutoUpload.au3 /out AutoUpload-x64.exe /x64

## Значок

Для лучшей заметности в трее добавлен значок жёлтой молнии, `src/Lightning.ico`:

* Источник: https://www.iconfinder.com/icons/2682840/
* Автор: [Laura Reen](https://www.iconfinder.com/laurareen)
* Лицензия: [Creative Commons (Attribution-Noncommercial 3.0 Unported)](http://creativecommons.org/licenses/by-nc/3.0/)

## Инсталлятор

Для сборки инсталлятора нужна [NSIS](http://nsis.sourceforge.net).

* Запустить NSIS-компилятор `makensisw.exe`: Пуск - "NSIS" - "Compile NSI scripts".
* Загрузить в него скрипт `nsis/AutoUpload.nsi`. В этой же папке появится инсталлятор.
