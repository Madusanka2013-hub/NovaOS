# NovaOS – Entwicklungsplan (Windows-XP-Edition)

## Technisches Ziel
NovaOS ist zunächst eine OpenOS-gehostete Desktopumgebung für OpenComputers Modernized 1.21.1/NeoForge. Ein eigenständiger Kernel oder native Ausführung von Windows-Programmen wird **nicht** behauptet.

## Verbindliche Grundregeln
1. Die Benutzeroberfläche soll Windows XP möglichst authentisch nachbilden; keine ASCII-Art als Ersatz für echte Bild-Icons.
2. Vor UI-Versprechen die Grafik-API und reale GPU-/RAM-Grenzen auf dem Zielmod prüfen. Mit einer Textzellen-GPU ist eine PNG-basierte Desktop-Oberfläche nicht automatisch möglich. Falls nötig, separates NeoForge-Grafikaddon erstellen.
3. Keine neuen Anwendungen, bevor Desktop, Startmenü, Taskleiste, Icons und grundlegende Fensterverwaltung stabil sind.
4. Ereignisgesteuerte Eingaben; nur geänderte Bereiche neu zeichnen; Auflösung/Palette und Renderkosten messen.
5. Jede Änderung mit Start-/Update-/Rollback-Anleitung und manuellem Ingame-Test versehen.
6. OpenOS und vorhandene Benutzerdaten beim Installieren erhalten.

## Phase 0 – Bestand sichern und reproduzierbar installieren
- [x] Bestehende Implementierungen inventarisieren.
- [x] Installer bezieht Quellcode wieder aus dem aktuellen main-Zweig über jsDelivr, statt einem eingefrorenen Commit.
- [x] Installer lädt zuerst alle Dateien und legt Backups ersetzter Dateien an.
- [x] Visuellen Desktop und funktionalen App-Prototyp getrennt ausführbar machen.
- [ ] Hardware-/Kompatibilitätsmatrix für Modernized: Grafiktiefe, Auflösung, Speicher, Bild-APIs.
- [ ] Tests auf realem Minecraft-Computer.

## Phase 1 – Authentische XP-Desktopgrundlage (als Nächstes)
- [ ] Grafik-Backend: native Bild-/Icon-Darstellung über unterstützte API oder eigenes NeoForge-Addon.
- [ ] Asset-Pipeline: echte, für das Spiel lizenzierte oder selbst erstellte XP-nahe Icons, Cursor, Hintergrund und Fenster-Texturen.
- [ ] XP-typischer Desktop mit Icon-Auswahl, Drag/Drop und Doppelklick.
- [ ] Blaue XP-Taskleiste mit grünem Startbutton und Infobereich.
- [ ] Voll bedienbares, zweispaltiges Startmenü mit Untermenüs.
- [ ] Fenster: Fokus, Z-Reihenfolge, Ziehen, Minimieren, Maximieren, Schließen, Clipping.
- [ ] Aktualisierung nur betroffener Bildschirmbereiche und Latenz-/Speichertests.
- [ ] Abschlusskriterium: Visuelle Abnahme anhand von Windows-XP-Referenzen und flüssige Bedienung auf dem Zielrechner.

## Phase 2 – Systemkern und Dateiverwaltung
- [ ] Modulare App-Laufzeit und Ereignisverteilung.
- [ ] Explorer, Ordnernavigation, Dateioperationen, Papierkorb.
- [ ] Persistente Profile, Desktopanordnung und Einstellungen.
- [ ] Fehlerisolierung zwischen Anwendungen.

## Phase 3 – XP-Anwendungen
- [ ] Editor mit Speichern/Laden.
- [ ] Eingabeaufforderung und Programme-Launcher.
- [ ] Systemsteuerung, Taskmanager, Dialoge und Hilfesystem.

## Phase 4 – Hardware, Integration, Leistung
- [ ] Integration mit Komponenten und Minecraft-Automation.
- [ ] Speicherbudget, Renderprofiling, Caching und optionale Hardwarebeschleunigung.
- [ ] Installer, Updateverwaltung, Versionsprüfung, Wiederherstellung.

## Installation / Update (OpenOS)
Benötigt: beschreibbares /home, Internetkarte mit funktionierender Verbindung, GPU, Bildschirm und Tastatur.

```sh
wget -f https://cdn.jsdelivr.net/gh/Madusanka2013-hub/NovaOS@main/install.lua /home/nova-install.lua
lua /home/nova-install.lua
lua /home/nova.lua
```

Falls `wget -f` in deiner OpenOS-Version nicht unterstützt wird:
```sh
rm /home/nova-install.lua
wget https://cdn.jsdelivr.net/gh/Madusanka2013-hub/NovaOS@main/install.lua /home/nova-install.lua
lua /home/nova-install.lua
```

Funktionalen älteren App-Prototyp starten: `lua /home/nova.lua apps`.

Die bisherigen Dateien liegen vor einer Ersetzung als `.bak` vor. Dies ist **kein** Bootloader-Ersatz.

Hinweis: jsDelivr kann @main-Dateien zwischenspeichern. Für reproduzierbare Releases später Commit-SHA oder Versionstag verwenden.

## Installer-Meilenstein 0.8.0
- [x] Versionierte Installationsverzeichnisse unter `/home/novaos/versions/`.
- [x] Wiederholbare Installation und Wechsel der aktiven Version.
- [x] Befehle `status`, `rollback`, `force`.
- [x] jsDelivr statt raw.githubusercontent.com.
- [ ] Release-Dateien pro Version auf unveränderlichen Git-Commit oder Tag pinnen.
- [ ] Minecraft-Ingame-Test der Download-/Rollbackpfade.
- [ ] Vorhandenen Legacy-Autostart `/home/novaos/boot.lua` gesondert diagnostizieren und reparieren.
