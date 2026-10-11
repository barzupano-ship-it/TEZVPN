@echo off
set DIR=%~dp0
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=%JAVA_HOME%\bin;%PATH%
if exist "%DIR%gradle\wrapper\gradle-wrapper.jar" (
  "%JAVA_HOME%\bin\java.exe" -jar "%DIR%gradle\wrapper\gradle-wrapper.jar" %*
  goto :eof
)
echo Missing gradle-wrapper.jar
exit /b 1
