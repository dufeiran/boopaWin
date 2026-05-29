param(
    [ValidateSet('flash','attention','working')]
    [string]$Mode = 'flash',
    [string]$Color = '#FF4444',
    [double]$Duration = 5,
    [int]$Thickness = 8,
    [ValidateSet('breathe','pulse','solid')]
    [string]$Animation = 'breathe',
    [double]$Speed = 1.0
)

$myPid = $PID
$parentPid = 0
try { $parentPid = (Get-WmiObject Win32_Process -Filter "ProcessId=$myPid").ParentProcessId } catch {}

$global:boopaTimers = New-Object System.Collections.ArrayList

Get-WmiObject Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" | Where-Object { 
    $_.CommandLine -like '*boopa-notify.ps1*' -and $_.ProcessId -ne $myPid -and $_.ProcessId -ne $parentPid 
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

# Build Win32 helpers via Reflection
$domain = [AppDomain]::CurrentDomain
$name = New-Object System.Reflection.AssemblyName('MyWin32')
$assembly = $domain.DefineDynamicAssembly($name, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
$module = $assembly.DefineDynamicModule('MyWin32')
$type = $module.DefineType('BoopaWin32', 'Public')
$type.DefinePInvokeMethod('GetWindowLong', 'user32.dll', 'Public, Static, PinvokeImpl', [System.Runtime.InteropServices.CallingConvention]::Winapi, [int32], [Type[]]@([IntPtr], [int32]), [System.Runtime.InteropServices.CallingConvention]::Winapi, [System.Runtime.InteropServices.CharSet]::Auto) | Out-Null
$type.DefinePInvokeMethod('SetWindowLong', 'user32.dll', 'Public, Static, PinvokeImpl', [System.Runtime.InteropServices.CallingConvention]::Winapi, [int32], [Type[]]@([IntPtr], [int32], [int32]), [System.Runtime.InteropServices.CallingConvention]::Winapi, [System.Runtime.InteropServices.CharSet]::Auto) | Out-Null
$type.DefinePInvokeMethod('GetForegroundWindow', 'user32.dll', 'Public, Static, PinvokeImpl', [System.Runtime.InteropServices.CallingConvention]::Winapi, [IntPtr], [Type]::EmptyTypes, [System.Runtime.InteropServices.CallingConvention]::Winapi, [System.Runtime.InteropServices.CharSet]::Auto) | Out-Null
$type.DefinePInvokeMethod('GetWindowThreadProcessId', 'user32.dll', 'Public, Static, PinvokeImpl', [System.Runtime.InteropServices.CallingConvention]::Winapi, [uint32], [Type[]]@([IntPtr], [uint32].MakeByRefType()), [System.Runtime.InteropServices.CallingConvention]::Winapi, [System.Runtime.InteropServices.CharSet]::Auto) | Out-Null
$type.DefinePInvokeMethod('GetAsyncKeyState', 'user32.dll', 'Public, Static, PinvokeImpl', [System.Runtime.InteropServices.CallingConvention]::Winapi, [int16], [Type[]]@([int32]), [System.Runtime.InteropServices.CallingConvention]::Winapi, [System.Runtime.InteropServices.CharSet]::Auto) | Out-Null
$type.DefinePInvokeMethod('GetWindowText', 'user32.dll', 'Public, Static, PinvokeImpl', [System.Runtime.InteropServices.CallingConvention]::Winapi, [int32], [Type[]]@([IntPtr], [System.Text.StringBuilder], [int32]), [System.Runtime.InteropServices.CallingConvention]::Winapi, [System.Runtime.InteropServices.CharSet]::Auto) | Out-Null
$global:BoopaWin32 = $type.CreateType()

# Must be accessible in event handler
$global:terminalNames = @(
    'cmd', 'conhost', 'OpenConsole', 'powershell', 'pwsh', 'WindowsTerminal',
    'WindowsTerminalPreview', 'wt', 'mintty', 'bash', 'sh', 'zsh', 'nu',
    'ConEmu64', 'ConEmuC64', 'Hyper', 'Tabby', 'Alacritty', 'wezterm-gui',
    'codex', 'Code', 'Code - Insiders', 'Cursor', 'Windsurf', 'Trae'
)

function Exit-Boopa {
    param($WindowList)
    foreach ($timer in $global:boopaTimers) { try { $timer.Stop() } catch {} }
    foreach ($ww in $WindowList) { try { $ww.Close() } catch {} }
    try { [System.Windows.Application]::Current.Shutdown() } catch {}
}

try { $brushColor = [System.Windows.Media.ColorConverter]::ConvertFromString($Color) } catch { $brushColor = [System.Windows.Media.Colors]::Red }

$glowHi = [System.Windows.Media.Color]::FromArgb(200, $brushColor.R, $brushColor.G, $brushColor.B)
$glowLo = [System.Windows.Media.Color]::FromArgb(0, $brushColor.R, $brushColor.G, $brushColor.B)

$screens = [System.Windows.Forms.Screen]::AllScreens
$windows = New-Object System.Collections.ArrayList

foreach ($scr in $screens) {
    $bx = $scr.Bounds.X; $by = $scr.Bounds.Y
    $bw = $scr.Bounds.Width; $bh = $scr.Bounds.Height

    $w = New-Object System.Windows.Window
    $w.WindowStyle = 'None'
    $w.AllowsTransparency = $true
    $w.Background = [System.Windows.Media.Brushes]::Transparent
    $w.Topmost = $true
    $w.ShowInTaskbar = $false
    $w.ResizeMode = 'NoResize'
    $w.ShowActivated = $false
    $w.Focusable = $false
    $w.Left = $bx; $w.Top = $by; $w.Width = $bw; $w.Height = $bh

    $cv = New-Object System.Windows.Controls.Canvas
    $cv.Width = $bw; $cv.Height = $bh; $cv.IsHitTestVisible = $false

    $mkBrush = {
        param($sx,$sy,$ex,$ey)
        $br = New-Object System.Windows.Media.LinearGradientBrush
        $br.StartPoint = New-Object System.Windows.Point($sx,$sy)
        $br.EndPoint = New-Object System.Windows.Point($ex,$ey)
        $br.GradientStops.Add((New-Object System.Windows.Media.GradientStop($glowHi, 0)))
        $br.GradientStops.Add((New-Object System.Windows.Media.GradientStop($glowLo, 1)))
        return $br
    }

    $r = New-Object System.Windows.Shapes.Rectangle; $r.Width = $bw; $r.Height = $Thickness; $r.Fill = (& $mkBrush 0.5 0 0.5 1)
    [System.Windows.Controls.Canvas]::SetLeft($r, 0); [System.Windows.Controls.Canvas]::SetTop($r, 0); $cv.Children.Add($r) | Out-Null

    $r = New-Object System.Windows.Shapes.Rectangle; $r.Width = $bw; $r.Height = $Thickness; $r.Fill = (& $mkBrush 0.5 1 0.5 0)
    [System.Windows.Controls.Canvas]::SetLeft($r, 0); [System.Windows.Controls.Canvas]::SetTop($r, $bh - $Thickness); $cv.Children.Add($r) | Out-Null

    $r = New-Object System.Windows.Shapes.Rectangle; $r.Width = $Thickness; $r.Height = $bh; $r.Fill = (& $mkBrush 0 0.5 1 0.5)
    [System.Windows.Controls.Canvas]::SetLeft($r, 0); [System.Windows.Controls.Canvas]::SetTop($r, 0); $cv.Children.Add($r) | Out-Null

    $r = New-Object System.Windows.Shapes.Rectangle; $r.Width = $Thickness; $r.Height = $bh; $r.Fill = (& $mkBrush 1 0.5 0 0.5)
    [System.Windows.Controls.Canvas]::SetLeft($r, $bw - $Thickness); [System.Windows.Controls.Canvas]::SetTop($r, 0); $cv.Children.Add($r) | Out-Null

    $w.Content = $cv
    $w.Add_SourceInitialized({
        try {
            $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($this)).Handle
            $exStyle = $global:BoopaWin32::GetWindowLong($hwnd, -20)
            $global:BoopaWin32::SetWindowLong($hwnd, -20, $exStyle -bor 0x00000020 -bor 0x00000080 -bor 0x00080000 -bor 0x08000000) | Out-Null
        } catch {}
    }.GetNewClosure())
    $windows.Add($w) | Out-Null
}

$app = [System.Windows.Application]::Current
if (-not $app) { $app = New-Object System.Windows.Application; $app.ShutdownMode = 'OnExplicitShutdown' }

foreach ($w in $windows) {
    $w.Show()
    $c = $w.Content
    if ($Animation -eq 'breathe') {
        $a = New-Object System.Windows.Media.Animation.DoubleAnimation
        $a.From = 0.25; $a.To = 1.0; $a.Duration = New-Object System.Windows.Duration([TimeSpan]::FromSeconds(1.4 / $Speed))
        $a.AutoReverse = $true; $a.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $a.EasingFunction = New-Object System.Windows.Media.Animation.SineEase
        $c.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $a)
    } elseif ($Animation -eq 'pulse') {
        $a = New-Object System.Windows.Media.Animation.DoubleAnimation
        $a.From = 0.1; $a.To = 1.0; $a.Duration = New-Object System.Windows.Duration([TimeSpan]::FromSeconds(0.3 / $Speed))
        $a.AutoReverse = $true; $a.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
        $c.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $a)
    } elseif ($Animation -eq 'solid') {
        $c.Opacity = 1.0
    }
}

if ($Mode -eq 'flash') {
    $t = New-Object System.Windows.Threading.DispatcherTimer
    $global:boopaTimers.Add($t) | Out-Null
    $t.Interval = [TimeSpan]::FromSeconds($Duration)
    $wRef = $windows
    $t.Add_Tick({
        $fo = New-Object System.Windows.Media.Animation.DoubleAnimation; $fo.To = 0.0; $fo.Duration = New-Object System.Windows.Duration([TimeSpan]::FromSeconds(0.6))
        foreach ($ww in $wRef) { $ww.Content.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fo) }
        $ct = New-Object System.Windows.Threading.DispatcherTimer; $ct.Interval = [TimeSpan]::FromSeconds(0.7)
        $global:boopaTimers.Add($ct) | Out-Null
        $ct.Add_Tick({ Exit-Boopa $wRef }.GetNewClosure())
        $ct.Start(); $this.Stop()
    }.GetNewClosure())
    $t.Start()
} elseif ($Mode -eq 'attention') {
    $pollTimer = New-Object System.Windows.Threading.DispatcherTimer
    $global:boopaTimers.Add($pollTimer) | Out-Null
    $pollTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    
    $wRef = $windows
    $global:pollTicks = 0

    $pollTimer.Add_Tick({
        $global:pollTicks++
        if ($global:pollTicks -lt 3) { return } # wait ~1.5 seconds

        try {
            $focused = [System.Windows.Automation.AutomationElement]::FocusedElement
            if ($focused) {
                $pidVal = $focused.Current.ProcessId
                if ($pidVal -gt 0) {
                    $proc = [System.Diagnostics.Process]::GetProcessById($pidVal)
                    $pName = $proc.ProcessName
                    
                    if ($global:terminalNames -contains $pName) {
                        Add-Content -Path "$env:USERPROFILE\.codex\boopa-debug.log" -Value "[Tick] UIAutomation matched: $pName. Dismissing."
                        Exit-Boopa $wRef
                    }
                }
            }
        } catch { }
    }.GetNewClosure())
    
    $pollTimer.Start()
} elseif ($Mode -eq 'working') {
    $safetyTimer = New-Object System.Windows.Threading.DispatcherTimer
    $global:boopaTimers.Add($safetyTimer) | Out-Null
    $safetyTimer.Interval = [TimeSpan]::FromHours(1)
    $wRef = $windows
    $safetyTimer.Add_Tick({ Exit-Boopa $wRef }.GetNewClosure())
    $safetyTimer.Start()
}

[System.Windows.Threading.Dispatcher]::Run()
