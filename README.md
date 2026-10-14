# NovaOS – Windows XP Edition

NovaOS is a **Windows-XP-inspired desktop project for OpenComputers Modernized 1.21.1 (NeoForge)**, currently hosted within OpenOS.

**Project direction:** an authentic XP look and interaction model with real graphic assets, responsive rendering, an integrated desktop, start menu, taskbar, window manager and eventually a coherent application runtime. See [ROADMAP.md](ROADMAP.md).

## Current status
The repository still contains **two separate alpha prototypes**, not a completed OS:

- `desktop/xp_visual07.lua`: visual XP-style desktop and start menu. No real image assets or full app runtime yet.
- `system/xp05.lua`: earlier application prototype with windows, explorer-like view, editor, terminal and system screens. UI still uses text-cell graphics.

The active installer supports both, but **they are not yet merged into a unified desktop**. Do not mistake text-cell artwork for real icons. We are investigating a graphics backend / NeoForge addon for image assets.

## Requirements
OpenOS, Internet Card with working access to jsDelivr, GPU, screen at least 60x22, keyboard and a writable disk mounted at /home. Requirements may change as graphics support is developed.

## Repeatable versioned install / update (installer 0.8.0)
Use the **jsDelivr CDN**. Download a fresh installer when a new release is published:

```sh
rm /home/nova-install.lua
wget https://cdn.jsdelivr.net/gh/Madusanka2013-hub/NovaOS@main/install.lua /home/nova-install.lua
lua /home/nova-install.lua
lua /home/nova.lua
```

Other commands:
```sh
lua /home/nova-install.lua status
lua /home/nova-install.lua rollback
lua /home/nova-install.lua force
lua /home/nova.lua apps
```

The installer stores runnable files in `/home/novaos/versions/0.8.0/`, and records the active and previous versions in `current.version` and `previous.version`. Reinstalling the same version is harmless. Updating to a newer release leaves the previous version available for rollback. It downloads all app files and validates Lua syntax before activating. It does **not** replace OpenOS, remove user files or modify legacy `/home/novaos/boot.lua`.

Version 0.8.0 refers to **installer/update infrastructure**, not a completed desktop. CDN branch URLs can be cached; for future immutable releases, pin each published version to a Git commit/tag. No in-game verification has been completed.

## Limitations
- GPU rendering currently uses text cells; no image-backed XP icons.
- The two prototypes are not integrated.
- There is no independent kernel, Windows API compatibility or Windows executable support.
- Runtime behavior has not yet been verified in Minecraft for this update.

## Development
Implement and validate the hardware/graphics layer first, then complete the XP desktop and taskbar as **Phase 1**. Avoid unrelated new applications until Phase 1 passes manual in-game acceptance testing.

**Note:** jsDelivr caches branch-based links. Fresh changes on main can take time to reach the CDN. For reproducible production releases, use a pinned commit or release tag.
