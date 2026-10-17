Unicode True
SetCompressor /SOLID lzma

!include "MUI2.nsh"
!include "LogicLib.nsh"

Name "SULTAN VPN"
OutFile "D:\TEZ VPN APP\downloads\TEZVPN-Setup.exe"
InstallDir "$LOCALAPPDATA\TEZVPN"
RequestExecutionLevel user
ShowInstDetails nevershow

!define MUI_ICON "D:\TEZ VPN APP\flutter\windows\runner\resources\app_icon.ico"
!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Russian"

Section
  ; The app locks flutter_assets (fonts) while it is open.
  ExecWait '"$SYSDIR\taskkill.exe" /F /IM TEZVPN.exe /T'
  Sleep 700
  ExecWait '"$SYSDIR\taskkill.exe" /F /IM TEZVPN.exe /T'
  Sleep 400
  SetOverwrite on
  SetOutPath "$INSTDIR"
  File "D:\TEZ VPN APP\flutter\build\windows\x64\runner\Release\TEZVPN.exe"
  File "D:\TEZ VPN APP\flutter\build\windows\x64\runner\Release\*.dll"
  SetOutPath "$INSTDIR\data"
  File /r "D:\TEZ VPN APP\flutter\build\windows\x64\runner\Release\data\*.*"
  SetOutPath "$INSTDIR\engine"
  File "D:\TEZ VPN APP\flutter\build\windows\x64\runner\Release\engine\*.*"
  CreateShortcut "$DESKTOP\SULTAN VPN.lnk" "$INSTDIR\TEZVPN.exe" "" "$INSTDIR\TEZVPN.exe" 0
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  IfSilent done
  Exec '"$INSTDIR\TEZVPN.exe"'
  done:
SectionEnd

Section "Uninstall"
  ExecWait '"$SYSDIR\taskkill.exe" /F /IM TEZVPN.exe /T'
  Sleep 400
  Delete "$DESKTOP\TEZVPN.lnk"
  RMDir /r "$INSTDIR"
SectionEnd
