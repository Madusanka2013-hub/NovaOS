# NovaOS XP Core 0.9.0

NovaOS is currently an OpenOS-hosted XP-style desktop core for OpenComputers Modernized (Minecraft 1.21.1 / NeoForge). **This milestone contains no additional applications.**

## Core delivered
- Separate desktop core `desktop/xp_core09.lua` selected by the versioned launcher.
- Desktop selection and double-click, click-driven two-column XP-style start menu.
- Taskbar with per-window buttons, focus changes, minimization and session uptime display.
- Core window frames with title-bar dragging, maximize/restore and close.
- Event-driven render loop, redrawing when needed instead of continuous animation.
- Native image backend detection through an **optional, future** `nova_graphics` component.

## Graphics limitation
**Real image icons and a genuine XP wallpaper are NOT rendered yet.** The stock OC GPU uses text cells; this build deliberately removes the fake character/block icon art and shows clean labels instead. The `nova_graphics.drawImage(asset,x,y,w,h)` contract is an integration hook for a NeoForge addon, **not an API currently implemented by OpenComputers Modernized**. An image-capable addon or verified native image API must be implemented before visual parity with XP can be claimed. No Windows XP copyrighted assets are bundled.

## Installation (use an immutable commit URL provided with a release)
Download the versioned installer from jsDelivr, then run:

```sh
rm /home/nova-install.lua
wget https://cdn.jsdelivr.net/gh/Madusanka2013-hub/NovaOS@main/install.lua /home/nova-install.lua
lua /home/nova-install.lua
lua /home/nova.lua
```

Commands:
```sh
lua /home/nova-install.lua status
lua /home/nova-install.lua rollback
lua /home/nova.lua apps
```

Note: `@main` on jsDelivr may cache older versions; use the immutable commit URL in the release message. The installer downloads the Lua components from `@main`, so its runtime may be affected by CDN propagation. OpenOS remains installed.

## Development priorities
1. Design and build an actual GPU image-display addon for OC:M or prove a compatible preexisting API.
2. Package appropriately licensed or custom-created PNG icons, window skins, cursor and wallpaper.
3. Implement efficient caching and asset compositing in the backend.
4. Complete the XP desktop, start menu and taskbar visual implementation.
5. Only then return to applications and file management.

No in-game execution has been performed by the assistant for this version.
