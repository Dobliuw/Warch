pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Store: estado compartido de warch: modo, objetivo y pomodoro.
// El único que escribe el archivo es el CLI `warch`; la barra solo lo lee y lo vigila.
Singleton {
    id: root

    readonly property string path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/warch/state.json"

    property var data: ({})
    readonly property string mode: (data && data.mode) || "sistema"
    readonly property var target: (data && data.target) || null
    readonly property var pomo: (data && data.pomo) || null

    function run(args) {
        Quickshell.execDetached(["warch"].concat(args));
    }

    FileView {
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.data = JSON.parse(text());
            } catch (e) {
                root.data = {};
            }
        }
        onLoadFailed: root.data = {}
    }
}
