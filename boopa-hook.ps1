$logFile = "$env:USERPROFILE\.codex\boopa-debug.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

if (Test-Path "$env:USERPROFILE\.codex\boopa-disabled") {
    Add-Content -Path $logFile -Value "[$timestamp] Hook disabled by boopa-disabled flag."
    Write-Output '{"continue": true}'
    exit 0
}

# Fix encoding issues for stdin reading
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

$event = "Unknown"
$stdinData = ""

if ([Console]::IsInputRedirected) {
    try { 
        $stdinData = [Console]::In.ReadToEnd() 
        # Sometimes UTF-8 chars still cause ConvertFrom-Json to fail if poorly formed
        # So we can just use regex as a fallback!
        $inputJson = $stdinData | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($inputJson -and $inputJson.hook_event_name) {
            $event = $inputJson.hook_event_name
        } elseif ($stdinData -match '"hook_event_name"\s*:\s*"([^"]+)"') {
            $event = $matches[1]
        }
    } catch {}
}

$argsStr = $args -join " "

# If event not in stdin, check args using regex
if ($event -eq "Unknown" -and $argsStr) {
    if ($argsStr -match "agent-turn-complete") { $event = "Stop" }
    elseif ($argsStr -match "approval-requested") { $event = "PermissionRequest" }
}

Add-Content -Path $logFile -Value "[$timestamp] Hook called. Parsed Event: $event | Args: $argsStr | Stdin: $stdinData"

# Defaults
$mode = 'flash'
$color = '#FF4444'
$animation = 'breathe'
$duration = 5

switch ($event) {
    'UserPromptSubmit' {
        # Working: green, solid, waits for next state to override it, with a safety timeout.
        $mode = 'working'
        $color = '#44FF88'
        $animation = 'solid'
        $duration = 120
    }
    'SessionStart' {
        $mode = 'working'
        $color = '#44FF88'
        $animation = 'solid'
        $duration = 120
    }
    'PermissionRequest' {
        # Waiting for approval: blue, pulse, attention (stays until focused)
        $mode = 'attention'
        $color = '#4488FF'
        $animation = 'pulse'
    }
    'Stop' {
        # Finished: red, breathe, attention (stays until focused)
        $mode = 'attention'
        $color = '#FF4444'
        $animation = 'breathe'
    }
}

# Start the notification script
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$env:USERPROFILE\.codex\boopa-notify.ps1`" -Mode $mode -Color `"$color`" -Animation $animation -Duration $duration" -WindowStyle Hidden

# Must return valid JSON object to continue
Write-Output '{"continue": true}'
