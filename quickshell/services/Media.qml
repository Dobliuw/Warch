pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Reproductor activo: el que está sonando o, si ninguno, el primero disponible.
Singleton {
    id: root

    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null;
    }
    readonly property bool active: player !== null
    readonly property string title: player?.trackTitle || ""
    readonly property string artist: player?.trackArtist || ""
    readonly property real progress: player && player.length > 0 ? player.position / player.length : 0

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // Mpris no notifica la posición por sí solo
    Timer {
        interval: 1000
        repeat: true
        running: root.player?.isPlaying ?? false
        onTriggered: root.player.positionChanged()
    }
}
