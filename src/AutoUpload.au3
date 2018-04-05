;Автоматическая выгрузка файлов из заданной папки на HTTP-сервер

#include <MsgBoxConstants.au3>
#include <TrayConstants.au3>
#include <Misc.au3> ;_Singleton()
#include <Date.au3> ;_Now()

;настройка меню
Opt("TrayAutoPause", 0) ;0=no pause, 1=pause
Opt("TrayMenuMode", 3) ;1=no default menu, 2=no automatic check

Global Const $APP_NAME = "AutoUpload"
Global Const $CONFIG_INI = "config.ini"
Global Const $LOG_FILE = "log.txt"

;не запускать повторно
If _Singleton($APP_NAME, 1) = 0 Then
    Message("Эта программа уже запущена, должен быть" & @CRLF & "значок жёлтой молнии в области уведомлений.", $MB_ICONWARNING)
    Exit
EndIf

;подписка на события в каталоге
SinkSubscribe(Config("Folder"))

Trace("## " & Config("URL") & " " & Config("AuthKey"))

;подробность журнала
Global $Debug = Config("Debug")

;при создании или изменении файла запускается таймер
;если таймер превысит определенное значение,
;значит запись файла закончена и можно выполнять команду
;также команда выполняется сразу после запуска программы
Global $FullName = ""
Global $bRecording = True
Global $hTimer = TimerInit()
Global $MaxDiff = (Config("IntervalInSeconds") + 5) * 1000 ;мс

;отслеживать окончание загрузки, не запускать повторно до ее завершения
Global $bUploading = False
Global $UploadProcess = 0

;пункты меню
Global $ItemAbout = TrayCreateItem("О программе")
Global $ItemConfig = TrayCreateItem("Открыть настройки")
Global $ItemLog = TrayCreateItem("Открыть журнал")
Global $ItemExit = TrayCreateItem("Выход")

TraySetIcon(@ScriptDir & "\Lightning.ico")

While 1
    Switch TrayGetMsg()
    Case $ItemAbout
        Message("Автоматическая выгрузка файлов из заданной папки:" _
            & @CRLF & Config("Folder"))
    Case $ItemConfig
        Run('notepad.exe "' & @ScriptDir & '\' & $CONFIG_INI & '"')
    Case $ItemLog
        Run('notepad.exe "' & @ScriptDir & '\' & $LOG_FILE & '"')
    Case $ItemExit
        Trace("## exit")
        ExitLoop
    EndSwitch

    If $bUploading Then
        If ProcessExists($UploadProcess) = 0 Then
            $bUploading = False
            Trace("stop " & $UploadProcess)
        EndIf
    ElseIf $bRecording And TimerDiff($hTimer) > $MaxDiff And StringLen($FullName) > 0 Then
        TrayTip("Выгрузка на сервер", $FullName, 3)
        $bRecording = False ;ждать появления других файлов
        $UploadProcess = Run(UploadCommand($FullName), "", @SW_HIDE)
        $FullName = ""
        If $UploadProcess = 0 Then
            Trace("run FAILED")
        Else
            $bUploading = True
            Trace("start " & $UploadProcess)
        EndIf
    EndIf

    Sleep(100)
WEnd


;НАСТРОЙКИ ПРИЛОЖЕНИЯ


Func Config($key)
    If Not FileExists($CONFIG_INI) Then
        Trace("Config not found")
        Exit
    EndIf

    ;URL и AuthKey в отдельной секции
    Local $sect = ($key = "URL" Or $key = "AuthKey") ? "HTTP" : "Monitor"

    Local $default = $key = "IntervalInSeconds" ? "3" : ""

    Local $str = IniRead($CONFIG_INI, $sect, $key, $default)

    If StringLen($str) = 0 Then
        Local $prompt = ""
        If $key = "Folder" Then
            $prompt = "Укажите каталог для наблюдения"
        ElseIf $key = "AuthKey" Then
            $prompt = "Укажите ключ доступа к серверу"
        EndIf

        If StringLen($prompt) > 0 Then
            $str = InputBox("Настройка выгрузки файлов", $prompt)
            IniWrite($CONFIG_INI, $sect, $key, $str)
        EndIf
    EndIf

    Return $str
EndFunc


;ЗАПРОСЫ К WMI В АСИНХРОННОМ РЕЖИМЕ
;http://www.script-coding.com/WMI.html


;Подписка на события в указанной папке
Func SinkSubscribe($folder)
    If StringLen($folder) < 4 Then
        Trace("Invalid folder, subscribe failed")
        Return
    EndIf

    Local $drive = StringLeft($folder, 2)
    Local $path = StringReplace(StringTrimLeft($folder, 2) & "\", "\", "\\") ;escaped!
    Local $query = "SELECT * FROM __InstanceOperationEvent WITHIN " _
        & Config("IntervalInSeconds") _
        & " WHERE TargetInstance ISA 'CIM_DataFile'" _
        & " AND TargetInstance.Drive = '" & $drive & "'" _
        & " AND TargetInstance.Path = '" & $path & "'"

    Local $ext = Config("Extension")
    If StringLen($ext) > 0 Then
        $query &= " AND TargetInstance.Extension = '" & $ext & "'"
    EndIf

    Local $objSink = ObjCreate("WbemScripting.SWbemSink")
    ObjEvent($objSink, "SINK_") ;префикс для процедур обработки событий

    Local $objWMIService = ObjGet("winmgmts:!\\.\root\cimv2")
    Local $objContext = ObjCreate("WbemScripting.SWbemNamedValueSet")
    $objWMIService.ExecNotificationQueryAsync($objSink, $query, Default, Default, Default, $objContext)
EndFunc

;Обработка событий, на которые ранее была оформлена подписка
;SINK_ - префикс, заданный при создании объекта WbemScripting.SWbemSink
;Событие OnObjectReady() происходит при появлении очередного объекта
;Параметр $objWbemObject содержит информацию о происшедшем событии
Func SINK_OnObjectReady($objWbemObject, $objWbemAsyncContext)
    Local $file = $objWbemObject.TargetInstance.Properties_.item("Name").value

    Switch $objWbemObject.Path_.Class()
    Case "__InstanceCreationEvent"
        If (StringLen($FullName) = 0) Then
            $FullName = $file
            Trace("created " & $file)
        Else
            Trace("skipped " & $file)
        EndIf
    Case "__InstanceModificationEvent"
        If $Debug > 0 Then Trace("mod " & $file)
    Case Else
        Return
    EndSwitch

    ;ждать окончания записи при помощи таймера
    $bRecording = True
    $hTimer = TimerInit()
EndFunc


;ВЫГРУЗКА ПО HTTP


;https://stackoverflow.com/a/45068012
;$wc = New-Object System.Net.WebClient; $wc.Headers.Add("key", "val"); $wc.UploadFile($URI, $FilePath)
Func UploadCommand($file)
    Local $cmd = 'powershell.exe -Command "' _
        & '$wc = New-Object System.Net.WebClient;' _
        & "$wc.Headers.Add('X-AuthKey','" & Config("AuthKey") & "');" _
        & "$wc.UploadFile('" & Config("URL") & "','" & $file & "')" _
        & '"'
    If $Debug > 0 Then Trace("cmd " & $cmd)
    Return $cmd
EndFunc


;ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ


Func Message($text, $icon = $MB_ICONINFORMATION)
    MsgBox($MB_SYSTEMMODAL + $icon, $APP_NAME, $text)
EndFunc

Func Trace($text)
    FileWriteLine($LOG_FILE, _Now() & " " & $text)
EndFunc
