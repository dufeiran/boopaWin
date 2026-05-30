# BoopaWin 🌟

*其他语言版本: [English](README.md), [简体中文](README_zh.md).*

一款为 [Codex CLI](https://github.com/codex-team/codex) 打造的精美、Windows 原生屏幕边缘光环通知系统。灵感来源于 macOS 版的 Boopa。

BoopaWin 会在你的屏幕边缘创建令人惊叹的光效，让你无需频繁检查终端即可实时掌控 AI 代理的精确工作状态。

## ✨ 功能特性

- 🟡 **工作状态**：当 AI 代理正在处理任务时，显示持续的黄色/金色光环。
- 🔴 **阻塞/询问状态**：当 AI 代理等待你的批准或输入时，显示脉冲闪烁的红色光环。
- 🟢 **完成状态**：当任务彻底完成时，显示呼吸感的绿色光环。
- 👁️ **智能自动隐藏**：利用高级的 UIAutomation 技术精确检测你何时将焦点切回终端窗口，随后瞬间自动隐藏光环。
- 🛡️ **零依赖**：纯 PowerShell 和 .NET 反射技术实现。无 C# 编译问题，无需第三方库，在 Windows 上开箱即用。

## 🚀 安装步骤

1. 下载 `boopa-notify.ps1` 和 `boopa-hook.ps1`。
2. 将这两个文件放到你的 Codex 配置目录下（通常是 `~/.codex/`）。

## ⚙️ 配置方法

### 第一步：在 `config.toml` 中启用 Hooks

打开你的 `~/.codex/config.toml`，添加以下内容（如果还没有的话）：

```toml
[features]
hooks = true
```

### 第二步：配置 `hooks.json`

打开你的 `~/.codex/hooks.json`（如果没有则新建一个），并添加以下 Hook 配置，将 Codex 的事件路由给 BoopaWin：

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File C:\\Users\\你的用户名\\.codex\\boopa-hook.ps1",
            "timeout": 30
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File C:\\Users\\你的用户名\\.codex\\boopa-hook.ps1",
            "timeout": 30
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File C:\\Users\\你的用户名\\.codex\\boopa-hook.ps1",
            "timeout": 30
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File C:\\Users\\你的用户名\\.codex\\boopa-hook.ps1",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```
*(请记得把 `你的用户名` 替换为你实际的 Windows 用户名！)*

## 🔒 信任 Hooks

Codex 要求你必须显式“信任”新的 Hook 才能执行它们：
1. 启动 `codex` 终端。
2. 输入 `/hooks` 并回车。
3. 选中并 **Trust（信任）** 所有刚才添加的新事件（`Stop`、`SessionStart`、`UserPromptSubmit`、`PermissionRequest`）。

## 🛠️ 底层工作原理

- **boopa-hook.ps1**：智能调度器。通过 `stdin` 拦截 Codex 的 JSON 事件，判断 AI 代理的当前状态，并调用相应的颜色和动画启动视觉层。
- **boopa-notify.ps1**：视觉渲染引擎。跨显示器生成透明、可穿透点击的 WPF 浮层。它使用 `System.Windows.Automation` 准确检测你与终端的交互，确保只有当你真正查看终端时，通知才会消失。
- **boopa-tray.ps1**：后台系统托盘开关。运行后会在 Windows 任务栏右下角生成一个绿色图标。右键点击即可轻松全局启用或禁用 BoopaWin，无需修改任何文件。
- **install-autostart.ps1**：辅助脚本。自动配置隐藏的 VBScript，让 `boopa-tray.ps1` 在你每次开机时纯静默自启。

## 🎛️ 系统托盘开关（可选）

如果你希望能不用敲击任何命令，随时一键开关 BoopaWin，你可以启用系统托盘图标：

### 开机静默自启（推荐）
只需右键点击 `install-autostart.ps1` 并选择 **使用 PowerShell 运行**（或者在终端里执行它）。
这会自动在你的 Windows “启动”文件夹里放置一个无缝静默启动快捷方式，之后你每次开机，托盘图标都会自动就绪。

### 手动启动
如果你只想偶尔运行一下，可以在终端中粘贴执行这行命令：
```powershell
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\你的用户名\\.codex\boopa-tray.ps1"
```

运行后，右下角托盘区会出现一个小圆点：
- 🟢 **绿点**：BoopaWin 已开启。
- 🔘 **灰点**：BoopaWin 已禁用（静默模式）。
右键图标即可切换状态，或直接双击实现快速切换。

## 📝 个性化定制

你只需要编辑 `boopa-hook.ps1` 文件里 `switch` 代码块中的 `$color` 和 `$animation` 变量，就能轻松自定义喜欢的颜色、动画和速度。

## 👏 鸣谢与友情链接

非常感谢原版的 [Eilgnaw/boopa](https://github.com/Eilgnaw/boopa) 项目！
这款 Windows 版本的移植（`boopaWin`）完全受启发于原版 macOS `boopa` 卓越的设计理念。没有他们在 AI 代理屏幕光环通知上的先驱工作，就不会有本项目。

🔗 **友情链接**: [LINUX DO (linux.do)](https://linux.do)

---
*致力于为 Windows 用户带来极致优雅的 Boopa 体验。*
