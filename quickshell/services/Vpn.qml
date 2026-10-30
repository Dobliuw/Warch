pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// NordVPN a través de su CLI.
Singleton {
    id: root

    property bool connected: false
    property bool busy: false
    property string server: ""
    property string country: ""
    property string tech: ""

    function refresh() { statusProc.running = true; }
    function connect(country) { run(["nordvpn", "connect"].concat(country ? [country] : [])); }
    function disconnect() { run(["nordvpn", "disconnect"]); }
    function toggle() { connected ? disconnect() : connect(""); }

    function run(cmd) {
        busy = true;
        actProc.command = cmd;
        actProc.running = true;
    }

    Process {
        id: actProc
        onExited: { root.busy = false; root.refresh(); }
    }

    Process {
        id: statusProc
        command: ["nordvpn", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const get = k => { const m = text.match(new RegExp("^" + k + ":\\s*(.+)$", "m")); return m ? m[1].trim() : ""; };
                root.connected = get("Status") === "Connected";
                root.server = get("Server");
                root.country = get("Country");
                root.tech = get("Current technology");
            }
        }
    }

    Timer { interval: 6000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
}
