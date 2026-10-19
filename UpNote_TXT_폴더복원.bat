@echo off
chcp 65001 >nul
title UpNote TXT 폴더 복원
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0UpNote_Restore.ps1"
if errorlevel 1 pause