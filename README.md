# NovaOS – Windows XP Edition

NovaOS is a **Windows-XP-inspired desktop project for OpenComputers Modernized 1.21.1 (NeoForge)**, currently hosted within OpenOS.

**Project direction:** an authentic XP look and interaction model with real graphic assets, responsive rendering, an integrated desktop, start menu, taskbar, window manager and eventually a coherent application runtime. See [ROADMAP.md](ROADMAP.md).

## Current status
The repository still contains **two separate alpha prototypes**, not a completed OS:

- `desktop/xp_visual07.lua`: visual XP-style desktop and start menu. No real image assets or full app runtime yet.
- `system/xp05.lua`: earlier application prototype with windows, explorer-like view, editor, terminal and system screens. UI still uses text-cell graphics.

The active installer supports both, but **they are not yet merged into a unified desktop**. Do not mistake text-cell artwork for real icons. We are investigating a graphics backend / NeoForge addon for image assets.

## Requirements
OpenOS, Internet Card with working access to GitHub, GPU, screen at least 60x22, keyboard and a writable disk mounted at /home. Requirements may change as graphics support is developed.

## Install / update
From the OpenOS shell:
```sh
rm /home/nova-install.lua
wget https://raw.githubusercontent.com/Madusanka2013-hub/NovaOS/main/install.lua /home/nova-install.lua
lua /home/nova-install.lua
lua /home/nova.lua
```

Run the older functional app prototype instead:
```sh
lua /home/nova.lua apps
```

The installer downloads the current main-branch Lua sources, stores backups of replaced files under `/home/novaos/*.bak`, and leaves OpenOS boot alone. If download fails, already installed files are left untouched. Backup is per file; it is not a transactional rollback of the entire install.

## Limitations
- GPU rendering currently uses text cells; no image-backed XP icons.
- The two prototypes are not integrated.
- There is no independent kernel, Windows API compatibility or Windows executable support.
- Runtime behavior has not yet been verified in Minecraft for this update.

## Development
Implement and validate the hardware/graphics layer first, then complete the XP desktop and taskbar as **Phase 1**. Avoid unrelated new applications until Phase 1 passes manual in-game acceptance testing.
