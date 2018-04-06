Unicode true
XPStyle on
RequestExecutionLevel user

; Первый язык - по-умолчанию
LoadLanguageFile "${NSISDIR}\Contrib\Language files\English.nlf"
LoadLanguageFile "${NSISDIR}\Contrib\Language files\Russian.nlf"

; Для 32- и 64-битных систем устанавливаются разные файлы
!include LogicLib.nsh
!include x64.nsh

!define APP "AutoUpload"
!define VERSION 1.0

Name ${APP}
OutFile "${APP}-${VERSION}-setup.exe"
InstallDir "$DOCUMENTS\${APP}"
InstallDirRegKey HKCU "Software\${APP}" "InstallDir"

!define SUBKEY_UNINST "Software\Microsoft\Windows\CurrentVersion\Uninstall\AutoUpload"

; Pages
Page components
Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles



LangString SectMain ${LANG_ENGLISH} "Main files (required)"
LangString SectMain ${LANG_RUSSIAN} "Основные файлы (обязательно)"

Section $(SectMain)

  ; Обязательная секция
  SectionIn RO

  SetOutPath $INSTDIR
  ${If} ${RunningX64}
    File "..\build\AutoUpload-x64.exe"
  ${Else}
    File "..\build\AutoUpload.exe"
  ${EndIf}
  File "..\src\config.ini"

  ; Write the installation path into the registry
  WriteRegStr HKCU "Software\${APP}" "InstallDir" "$INSTDIR"

  ; Write the uninstall keys for Windows
  WriteRegStr HKCU ${SUBKEY_UNINST} "DisplayName" ${APP}
  WriteRegStr HKCU ${SUBKEY_UNINST} "DisplayVersion" ${VERSION}
  WriteRegStr HKCU ${SUBKEY_UNINST} "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKCU ${SUBKEY_UNINST} "NoModify" 1
  WriteRegDWORD HKCU ${SUBKEY_UNINST} "NoRepair" 1
  WriteUninstaller "uninstall.exe"

SectionEnd



LangString SectLink ${LANG_ENGLISH} "Start Menu shortcut"
LangString SectLink ${LANG_RUSSIAN} "Ярлык в меню Пуск"

Section $(SectLink)

  ${If} ${RunningX64}
    CreateShortcut "$SMPROGRAMS\AutoUpload.lnk" \
      "$INSTDIR\AutoUpload-x64.exe" "" "$INSTDIR\AutoUpload-x64.exe" 0
  ${Else}
    CreateShortcut "$SMPROGRAMS\AutoUpload.lnk" \
      "$INSTDIR\AutoUpload.exe" "" "$INSTDIR\AutoUpload.exe" 0
  ${EndIf}

SectionEnd



; Uninstaller
Section "Uninstall"

  ; Remove registry keys
  DeleteRegKey HKCU ${SUBKEY_UNINST}
  DeleteRegKey HKCU "Software\${APP}"

  ; Remove files and uninstaller
  Delete $INSTDIR\AutoUpload.exe
  Delete $INSTDIR\AutoUpload-x64.exe
  Delete $INSTDIR\config.ini
  Delete $INSTDIR\log.txt
  Delete $INSTDIR\uninstall.exe

  ; Remove shortcut
  Delete "$SMPROGRAMS\AutoUpload.lnk"

  ; Remove directories used
  RMDir $INSTDIR

SectionEnd
