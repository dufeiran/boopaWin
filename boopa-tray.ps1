Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$disabledFile = "$env:USERPROFILE\.codex\boopa-disabled"

function Create-Icon {
    param([bool]$isEnabled)
    $bmp = New-Object System.Drawing.Bitmap 32, 32
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    $brush = if ($isEnabled) { 
        [System.Drawing.Brushes]::LimeGreen 
    } else { 
        [System.Drawing.Brushes]::Gray 
    }
    
    $g.FillEllipse($brush, 4, 4, 24, 24)
    $g.DrawEllipse([System.Drawing.Pens]::Black, 4, 4, 24, 24)
    
    $hIcon = $bmp.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($hIcon)
    
    $g.Dispose()
    return $icon
}

$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Text = "BoopaWin Toggle"

$contextMenu = New-Object System.Windows.Forms.ContextMenu

$toggleItem = New-Object System.Windows.Forms.MenuItem
$toggleItem.Text = "Enable Boopa"

$exitItem = New-Object System.Windows.Forms.MenuItem
$exitItem.Text = "Exit BoopaWin Tray"

$contextMenu.MenuItems.Add($toggleItem) | Out-Null
$contextMenu.MenuItems.Add("-") | Out-Null
$contextMenu.MenuItems.Add($exitItem) | Out-Null

$notifyIcon.ContextMenu = $contextMenu

function Update-State {
    $isDisabled = Test-Path $disabledFile
    $isEnabled = -not $isDisabled
    
    $notifyIcon.Icon = Create-Icon -isEnabled $isEnabled
    $toggleItem.Checked = $isEnabled
}

$toggleItem.Add_Click({
    if ($toggleItem.Checked) {
        # Currently enabled, disable it
        if (-not (Test-Path "$env:USERPROFILE\.codex")) { New-Item -ItemType Directory -Path "$env:USERPROFILE\.codex" -Force | Out-Null }
        New-Item -ItemType File -Path $disabledFile -Force | Out-Null
    } else {
        # Currently disabled, enable it
        if (Test-Path $disabledFile) { Remove-Item $disabledFile -Force }
    }
    Update-State
})

$exitItem.Add_Click({
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$notifyIcon.Add_DoubleClick({
    $toggleItem.PerformClick()
})

Update-State
$notifyIcon.Visible = $true

[System.Windows.Forms.Application]::Run()
