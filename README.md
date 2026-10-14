# NovaOS XP Edition 0.3.0

Resource-conscious Windows XP-inspired Lua desktop preview for OpenComputers: Modernized 1.21.1.

**Requirements:** OpenOS, Internet Card, GPU, screen at least 50x18, keyboard, disk. Works as an OpenOS-hosted app, not a replacement boot OS.

## Install
```sh
wget https://cdn.jsdelivr.net/gh/Madusanka2013-hub/NovaOS@1918d2329580934c209deff3b675ff7382b5b9db/install.lua /home/nova-install.lua
lua /home/nova-install.lua
lua /home/nova.lua
```
Remove the old /home/nova-install.lua before downloading if wget says it already exists.

## Apps
Start menu, XP-like window borders, taskbar, file explorer, My Documents, terminal, temporary Notepad, control panel and free-memory monitor.

## Controls
Click desktop icons, green START or title bar controls. Drag title bars to move. Keyboard 1-7 opens an app when not entering text. Ctrl+C exits via OpenOS interrupt.

## Limitations
Notepad text is currently session-only. The clock displays session uptime, not world time. No actual multitasking, persistent desktop settings, full filesystem operations or independent boot kernel yet. This is an untested in-game alpha.

## Performance
Event-driven rendering, no animation or image assets. Redraws happen on input and minute updates. Maximum four app windows.
