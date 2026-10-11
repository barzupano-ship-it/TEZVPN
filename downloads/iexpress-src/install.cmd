@echo off
setlocal
set DEST=%LOCALAPPDATA%\TEZVPN
mkdir "%DEST%\data\flutter_assets\assets" 2>nul
mkdir "%DEST%\data\flutter_assets\fonts" 2>nul
mkdir "%DEST%\data\flutter_assets\shaders" 2>nul
mkdir "%DEST%\engine" 2>nul
copy /Y "%~dp0TEZVPN.exe" "%DEST%\TEZVPN.exe" >nul
copy /Y "%~dp0flutter_windows.dll" "%DEST%\flutter_windows.dll" >nul
copy /Y "%~dp0file_selector_windows_plugin.dll" "%DEST%\file_selector_windows_plugin.dll" >nul
copy /Y "%~dp0url_launcher_windows_plugin.dll" "%DEST%\url_launcher_windows_plugin.dll" >nul
copy /Y "%~dp0app.so" "%DEST%\data\app.so" >nul
copy /Y "%~dp0icudtl.dat" "%DEST%\data\icudtl.dat" >nul
copy /Y "%~dp0AssetManifest.bin" "%DEST%\data\flutter_assets\AssetManifest.bin" >nul
copy /Y "%~dp0FontManifest.json" "%DEST%\data\flutter_assets\FontManifest.json" >nul
copy /Y "%~dp0NativeAssetsManifest.json" "%DEST%\data\flutter_assets\NativeAssetsManifest.json" >nul
copy /Y "%~dp0NOTICES.Z" "%DEST%\data\flutter_assets\NOTICES.Z" >nul
copy /Y "%~dp0brand.json" "%DEST%\data\flutter_assets\assets\brand.json" >nul
copy /Y "%~dp0MaterialIcons-Regular.otf" "%DEST%\data\flutter_assets\fonts\MaterialIcons-Regular.otf" >nul
copy /Y "%~dp0ink_sparkle.frag" "%DEST%\data\flutter_assets\shaders\ink_sparkle.frag" >nul
copy /Y "%~dp0stretch_effect.frag" "%DEST%\data\flutter_assets\shaders\stretch_effect.frag" >nul
copy /Y "%~dp0amneziawg.exe" "%DEST%\engine\amneziawg.exe" >nul
copy /Y "%~dp0awg.exe" "%DEST%\engine\awg.exe" >nul
copy /Y "%~dp0wintun.dll" "%DEST%\engine\wintun.dll" >nul
cscript //nologo "%~dp0shortcut.vbs" "%DEST%"
start "" "%DEST%\TEZVPN.exe"
