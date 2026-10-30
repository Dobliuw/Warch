pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Qué superficie de warch está abierta. Solo una a la vez (salvo el panel vertical y el bloqueo).
// Se controla desde la barra o con `warch ui <superficie>` (IPC).
Singleton {
    id: root

    property string open: ""        // "", "dashboard", "settings", "session", "overview", "cheatsheet"
    property bool panel: false      // panel vertical de HDMI-A-1
    property bool panelPinned: false
    property bool locked: false     // bloqueo real (WlSessionLock)
    property bool lockTest: false   // vista previa del bloqueo, sin bloquear la sesión
    // Seguro: el bloqueo real solo se activa después de desbloquear bien la vista previa una vez
    property bool lockVerified: false
    readonly property string lockVerifiedFile: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/warch/lock-verified"

    function toggle(name) { open = open === name ? "" : name; }
    function close() { open = ""; }
    function togglePanel(pin) { panelPinned = pin && !panel; panel = !panel; }
    function lock() {
        open = "";
        if (lockVerified) { locked = true; return; }
        lockTest = true;
        Quickshell.execDetached(["notify-send", "-a", "warch", Tr.t("Bloqueo en vista previa"),
            Tr.t("Desbloquea una vez con tu contraseña para activar el bloqueo real. Así nunca quedas afuera.")]);
    }
    function markLockVerified() {
        if (lockVerified) return;
        lockVerified = true;
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname '" + lockVerifiedFile + "')\" && touch '" + lockVerifiedFile + "'"]);
    }

    FileView {
        path: root.lockVerifiedFile
        printErrors: false
        onLoaded: root.lockVerified = true
        onLoadFailed: root.lockVerified = false
    }

    IpcHandler {
        target: "ui"
        function dashboard(): void { root.toggle("dashboard"); }
        function settings(): void { root.toggle("settings"); }
        function session(): void { root.toggle("session"); }
        function overview(): void { root.toggle("overview"); }
        function cheatsheet(): void { root.toggle("cheatsheet"); }
        function launcher(): void { root.toggle("launcher"); }
        function wallpaper(): void { root.toggle("wallpaper"); }
        function close(): void { root.close(); }
        function lock(): void { root.lock(); }
        function locktest(): void { root.open = ""; root.lockTest = true; }
        function endtest(): void { root.lockTest = false; }
        function dnd(): void { Notifs.dnd = !Notifs.dnd; }
    }

    IpcHandler {
        target: "panel"
        function toggle(): void { root.togglePanel(true); }
        function open(): void { root.panelPinned = true; root.panel = true; }
        function close(): void { root.panel = false; root.panelPinned = false; }
    }
}
