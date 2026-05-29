$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\BoopaWin.lnk"
$scriptPath = "$env:USERPROFILE\.codex\boopa-tray.ps1"
$vbsPath = "$env:USERPROFILE\.codex\boopa-tray.vbs"

Write-Host "Creating invisible VBS wrapper..."
$vbsContent = @"
Set objShell = CreateObject("Wscript.Shell")
objShell.Run "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$scriptPath""", 0, False
"@
Set-Content -Path $vbsPath -Value $vbsContent -Encoding Ascii

Write-Host "Creating BoopaWin auto-start shortcut..."
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($startupPath)
$Shortcut.TargetPath = "wscript.exe"
$Shortcut.Arguments = "`"$vbsPath`""
$Shortcut.IconLocation = "powershell.exe,0"
$Shortcut.Save()

Write-Host "Auto-start configured successfully!"
Write-Host "BoopaWin will now start completely invisibly when you log into Windows."

# Launch it now using the new VBS script for a clean, detached start
Start-Process "wscript.exe" -ArgumentList "`"$vbsPath`""
Write-Host "Tray icon has been launched silently."
Start-Sleep -Seconds 2
