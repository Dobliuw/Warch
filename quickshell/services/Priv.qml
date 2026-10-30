pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Acciones con permisos lanzadas desde la GUI (barra, paneles).
// El agente de polkit de warch solo se registra mientras corren estas acciones: así los comandos
// escritos en la terminal (systemctl, pkexec) siguen pidiendo la contraseña en la terminal.
Singleton {
    id: root

    property bool wanted: false     // PolkitDialog carga el agente mientras esto es true
    property bool ready: false      // el agente ya está registrado
    property var queue: []
    property var current: null

    // cmd: lista de argumentos; done(exitCode) opcional
    function run(cmd, done) {
        queue = queue.concat([{ cmd: cmd, done: done }]);
        release.stop();
        wanted = true;
        if (ready) next();
    }

    function next() {
        if (proc.running || queue.length === 0) return;
        current = queue[0];
        queue = queue.slice(1);
        proc.command = current.cmd;
        proc.running = true;
    }

    onReadyChanged: if (ready) next()

    Process {
        id: proc
        onExited: code => {
            const job = root.current;
            root.current = null;
            if (job && job.done) job.done(code);
            if (root.queue.length > 0) root.next();
            else release.restart();
        }
    }

    // Soltar el agente un momento después de terminar (por si hay otra acción encadenada)
    Timer {
        id: release
        interval: 1500
        onTriggered: if (!proc.running && root.queue.length === 0) { root.wanted = false; root.ready = false; }
    }
}
