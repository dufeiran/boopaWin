# BoopaWin 🌟

A beautiful, Windows-native screen edge glow notification system for [Codex CLI](https://github.com/codex-team/codex). Inspired by the macOS version of Boopa.

BoopaWin creates stunning visual light effects on the edges of your screen to let you know the exact state of your AI agent without needing to constantly check your terminal.

## ✨ Features

- 🟡 **Working State**: Continuous yellow/gold glow while the agent is processing.
- 🔴 **Blocked/Question State**: Pulsing red light when the agent is waiting for your approval or input.
- 🟢 **Finished State**: Breathing green light when the task is fully complete.
- 👁️ **Smart Auto-Dismiss**: Uses advanced UIAutomation to detect when you refocus your terminal window, instantly and automatically dismissing the notification.
- 🛡️ **Zero Dependencies**: Pure PowerShell & .NET Reflection implementation. No C# compilation issues, no third-party libraries, works out of the box on Windows.

## 🚀 Installation

1. Download `boopa-notify.ps1` and `boopa-hook.ps1`.
2. Place both files in your Codex configuration directory (usually `~/.codex/`).

## ⚙️ Configuration

Open your `~/.codex/hooks.json` (create it if it doesn't exist) and add the following hooks to route Codex events to BoopaWin:

```json
{
  "Stop": {
    "command": ["powershell", "-ExecutionPolicy", "Bypass", "-File", "C:\\Users\\YOUR_USERNAME\\.codex\\boopa-hook.ps1"]
  },
  "SessionStart": {
    "command": ["powershell", "-ExecutionPolicy", "Bypass", "-File", "C:\\Users\\YOUR_USERNAME\\.codex\\boopa-hook.ps1"]
  },
  "UserPromptSubmit": {
    "command": ["powershell", "-ExecutionPolicy", "Bypass", "-File", "C:\\Users\\YOUR_USERNAME\\.codex\\boopa-hook.ps1"]
  },
  "PermissionRequest": {
    "command": ["powershell", "-ExecutionPolicy", "Bypass", "-File", "C:\\Users\\YOUR_USERNAME\\.codex\\boopa-hook.ps1"]
  }
}
```
*(Remember to replace `YOUR_USERNAME` with your actual Windows username!)*

## 🔒 Trusting the Hooks

Codex requires you to explicitly trust new hooks before they will execute.
1. Start your `codex` CLI.
2. Type `/hooks` and press Enter.
3. Select and **Trust** all the newly added events (`Stop`, `SessionStart`, `UserPromptSubmit`, `PermissionRequest`).

## 🛠️ How It Works under the Hood

- **boopa-hook.ps1**: The smart dispatcher. It intercepts JSON events from Codex via `stdin`, determines the state of the agent, and launches the visual layer with the correct colors and animations.
- **boopa-notify.ps1**: The visual powerhouse. It generates a transparent, click-through WPF overlay across all your monitors. It uses `System.Windows.Automation` to reliably detect when you interact with your terminal, ensuring notifications only disappear when you're actually looking at them.
- **boopa-tray.ps1**: The background system tray toggle. Run this script to place a green icon in your Windows Taskbar tray. Right-click the icon to easily enable or disable BoopaWin globally without touching any files.

## 🎛️ System Tray Toggle (Optional)

If you want the ability to easily turn BoopaWin on or off:
1. Run `boopa-tray.ps1` in the background:
   ```powershell
   powershell -WindowStyle Hidden -File "C:\Users\YOUR_USERNAME\.codex\boopa-tray.ps1"
   ```
2. A small colored dot will appear in your system tray (bottom right).
   - 🟢 **Green Dot**: BoopaWin is enabled.
   - 🔘 **Gray Dot**: BoopaWin is disabled (Silent mode).
3. Right-click the icon to toggle the state or double-click to quick-toggle.

## 📝 Customization

You can easily tweak colors, animations, and speeds by editing the `$color` and `$animation` variables inside the `switch` block in `boopa-hook.ps1`.

## 👏 Credits & Acknowledgements

A massive thank you to the original [Eilgnaw/boopa](https://github.com/Eilgnaw/boopa) project! 
This Windows version (`boopaWin`) was entirely inspired by and developed based on the brilliant concept and design of the original macOS `boopa`. Without their pioneering work on screen-edge glow notifications for AI agents, this project would not exist. 

---
*Created to bring the beautiful Boopa experience to Windows users.*
