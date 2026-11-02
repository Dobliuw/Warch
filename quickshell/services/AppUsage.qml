pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Uso de aplicaciones del lanzador (frecencia): cuántas veces se abrió cada app y cuándo.
// Se guarda en ~/.local/state/warch/apps.json como { "<desktop id>": { "n": 12, "last": 1730000000000 } }.
Singleton {
    id: root

    readonly property string path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/warch/apps.json"
    property var data: ({})

    // Puntaje: aperturas, con más peso si se usó hace poco (vida media de ~2 semanas).
    function score(id) {
        const u = data[id];
        if (!u) return 0;
        const days = (Date.now() - (u.last || 0)) / 86400000;
        return u.n * (0.5 + Math.pow(0.5, days / 14));
    }

    function record(id) {
        if (!id) return;
        const d = Object.assign({}, data);
        const u = d[id] || { n: 0, last: 0 };
        d[id] = { n: u.n + 1, last: Date.now() };
        data = d;
        file.setText(JSON.stringify(d));
    }

    FileView {
        id: file
        path: root.path
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try { root.data = JSON.parse(text()) || {}; } catch (e) { root.data = {}; }
        }
        onLoadFailed: root.data = {}
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.path.replace(/\/[^/]*$/, "")])
}
