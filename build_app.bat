@echo off
echo Building Flutter App...
cd /d "%~dp0"
C:\flutter\bin\flutter.bat build apk --release
echo Build completed.
pause
