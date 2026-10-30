pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Integración con TO-DOsh: tarea en foco, tareas abiertas y proyectos, vía `todosh ... --json`.
Singleton {
    id: root

    readonly property string bin: "/opt/todosh/bin/todosh"
    readonly property var prioRank: ({ urgent: 0, high: 1, normal: 2, medium: 2, low: 3 })

    property var focus: null        // { task, since, session_seconds, total_seconds, ... }
    property var tasks: []          // abiertas, en curso primero y luego por prioridad
    property var projects: []       // solo los de primer nivel

    function refresh() {
        listProc.running = true;
        focusProc.running = true;
        projProc.running = true;
    }

    // Ejecuta una acción de todosh y refresca; si falla, avisa con la salida de error.
    function act(args) {
        const cmd = [root.bin].concat(args).map(a => "'" + String(a).replace(/'/g, "'\\''") + "'").join(" ");
        Quickshell.execDetached(["sh", "-c", cmd + " >/dev/null 2>/tmp/warch-todosh.err || notify-send -a warch TO-DOsh \"$(cat /tmp/warch-todosh.err)\""]);
        refreshSoon.restart();
    }
    function done(id) { act(["done", id]); }
    function start(id) { act(["start", id]); }
    function focusOn(id) { act(["focus", id]); }
    function unfocus() { act(["unfocus"]); }

    function fmtDuration(s) {
        s = Math.max(0, Math.floor(s || 0));
        const h = Math.floor(s / 3600), m = Math.floor(s / 60) % 60;
        return h > 0 ? h + "h " + m + "m" : m + "m";
    }

    Timer { id: refreshSoon; interval: 600; onTriggered: root.refresh() }
    Timer { interval: 15000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Process {
        id: listProc
        command: [root.bin, "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const open = JSON.parse(text).filter(t => ["TODO", "IN_PROGRESS", "BLOCKED"].includes(t.status));
                    open.sort((a, b) => (a.status === "IN_PROGRESS" ? 0 : 1) - (b.status === "IN_PROGRESS" ? 0 : 1)
                        || (root.prioRank[a.priority] ?? 2) - (root.prioRank[b.priority] ?? 2)
                        || a.id - b.id);
                    root.tasks = open;
                } catch (e) {}
            }
        }
    }

    Process {
        id: focusProc
        command: [root.bin, "focus", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.focus = JSON.parse(text).focus ?? null; } catch (e) { root.focus = null; }
            }
        }
    }

    Process {
        id: projProc
        command: [root.bin, "projects", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.projects = JSON.parse(text).filter(p => p.depth === 0); } catch (e) {}
            }
        }
    }
}
