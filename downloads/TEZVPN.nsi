Unicode True
SetCompressor /SOLID lzma

!include "MUI2.nsh"
!include "LogicLib.nsh"

Name "SULTAN VPN"
OutFile "D:\TEZ VPN APP\downloads\SULTANVPN-Setup.exe"
InstallDir "$LOCALAPPDATA\SULTAN VPN"
RequestExecutionLevel user
ShowInstDetails nevershow

!define MUI_ICON "D:\TEZ VPN APP\flutter\windows\runner\resources\app_icon.ico"
!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Russian"

Section
  ; The app locks flutter_assets (fonts) while it is open.
  ExecWait '"$SYSDIR\taskkill.exe" /F /IM "SULTAN VPN.exe" /T'
  ExecWait '"$SYSDIR\taskkill.exe" /F /IM SULTANVPN.exe /T'
  ExecWait '"$SYSDIR\taskkill.exe" /F /IM TEZVPN.exe /T'
  Sleep 700
  ExecWait '"$SYSDIR\taskkill.exe" /F /IM "SULTAN VPN.exe" /T'
  ExecWait '"$SYSDIR\taskkill.exe" /F /IM SULTANVPN.exe /T'
  ExecWait '"$SYSDIR\taskkill.exe" /F /IM TEZVPN.exe /T'
  Sleep 400
  SetOverwrite on
  SetOutPath "$INSTDIR"
  File "/oname=SULTAN VPN.exe" "D:\TEZ VPN APP\flutter\build\windows\x64\runner\Release\SULTANVPN.exe"
  File "D:\TEZ VPN APP\flutter\build\windows\x64\runner\Release\*.dll"
  File "D:\TEZ VPN APP\flutter\windows\runner\resources\app_icon.ico"
  File "/oname=sultan_icon_sq.ico" "D:\TEZ VPN APP\flutter\windows\runner\resources\app_icon.ico"
  Delete "$INSTDIR\TEZVPN.exe"
  Delete "$INSTDIR\SULTANVPN.exe"
  SetOutPath "$INSTDIR\data"
  File /r "D:\TEZ VPN APP\flutter\build\windows\x64\runner\Release\data\*.*"
  SetOutPath "$INSTDIR\engine"
  File "D:\TEZ VPN APP\flutter\build\windows\x64\runner\Release\engine\*.*"
  Delete "$DESKTOP\SULTAN VPN.lnk"
  Delete "$DESKTOP\TEZVPN.lnk"
  CreateShortcut "$DESKTOP\SULTAN VPN.lnk" "$INSTDIR\SULTAN VPN.exe" "" "$INSTDIR\sultan_icon_sq.ico" 0
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  IfSilent done
  Exec '"$INSTDIR\SULTAN VPN.exe"'
  done:
SectionEnd

Section "Uninstall"
  ExecWait '"$SYSDIR\taskkill.exe" /F /IM "SULTAN VPN.exe" /T'
  ExecWait '"$SYSDIR\taskkill.exe" /F /IM SULTANVPN.exe /T'
  ExecWait '"$SYSDIR\taskkill.exe" /F /IM TEZVPN.exe /T'
  Sleep 400
  Delete "$DESKTOP\SULTAN VPN.lnk"
  Delete "$DESKTOP\TEZVPN.lnk"
  RMDir /r "$INSTDIR"
SectionEnd
