pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Roles de los monitores de esta máquina (los escribe `warch setup` en ~/.config/warch/monitors.json):
//   main: lleva la banda, el dashboard y los paneles.  side: lleva el panel oculto (TO-DOsh, calendario…).
// Si no hay archivo: main = el monitor horizontal más grande; side = uno vertical si existe, si no el main.
Singleton {
    id: root

    property var cfg: ({})
    readonly property var screens: Quickshell.screens
    readonly property var names: screens.map(s => s.name)

    readonly property string autoMain: {
        const land = screens.filter(s => s.width >= s.height);
        const pool = land.length ? land : screens;
        const best = pool.slice().sort((a, b) => b.width * b.height - a.width * a.height)[0];
        return best ? best.name : "";
    }
    readonly property string main: names.includes(cfg.main) ? cfg.main : autoMain
    readonly property string side: {
        if (cfg.side && names.includes(cfg.side)) return cfg.side;
        const portrait = screens.find(s => s.height > s.width && s.name !== main);
        return portrait ? portrait.name : main;
    }
    readonly property bool sideIsMain: side === main

    function isMain(screen) { return screen?.name === main; }

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/warch/monitors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { root.cfg = JSON.parse(text()); } catch (e) { root.cfg = {}; } }
        onLoadFailed: root.cfg = {}
    }
}
