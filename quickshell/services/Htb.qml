pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// VPN de HackTheBox con openvpn. Los permisos los pide el diálogo de warch (pkexec vía Priv).
// Conectada = existe tun0 (lo mide Sys).
Singleton {
    id: root

    readonly property string config: Quickshell.env("HOME") + "/.config/warch/vpn/htb.ovpn"
    readonly property string pidFile: "/run/warch-htb.pid"
    readonly property bool connected: Sys.tun0 !== ""
    property bool busy: false
    property string remote: ""      // servidor del .ovpn (ej. edge-us-free-2 · udp 1337)
    property bool available: false

    function connect() {
        busy = true;
        Priv.run(["pkexec", "openvpn", "--config", config, "--daemon", "warch-htb", "--writepid", pidFile], finished);
    }
    function disconnect() {
        busy = true;
        Priv.run(["pkexec", "sh", "-c", "kill \"$(cat " + pidFile + ")\" && rm -f " + pidFile], finished);
    }
    function finished(code) {
        if (code !== 0 && code !== 126)   // 126 = cancelado en el diálogo
            Quickshell.execDetached(["notify-send", "-a", "warch", "-u", "critical", Tr.t("VPN de HTB"), Tr.f("openvpn terminó con código %1", code)]);
        settle.restart();
    }
    function toggle() { connected ? disconnect() : connect(); }

    // tun0 tarda unos segundos en aparecer; esperamos antes de soltar el estado "busy"
    Timer { id: settle; interval: 6000; onTriggered: root.busy = false }

    FileView {
        path: root.config
        printErrors: false
        onLoaded: {
            root.available = true;
            const m = text().match(/^remote\s+(\S+)\s+(\d+)/m), p = text().match(/^proto\s+(\S+)/m);
            if (m) root.remote = m[1].replace(".hackthebox.eu", "") + " · " + (p ? p[1] : "udp") + " " + m[2];
        }
        onLoadFailed: root.available = false
    }
}
