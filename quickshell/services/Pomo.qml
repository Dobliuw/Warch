pragma Singleton

import QtQuick
import Quickshell

// Pomodoro sin estado propio: todo se calcula desde Store.pomo.start.
// Ciclo = foco + descanso; la sesión y la fase salen del tiempo transcurrido.
Singleton {
    id: root

    readonly property bool running: !!Store.pomo && Store.pomo.start !== undefined
    readonly property int focusMin: Store.pomo?.focus ?? 90
    readonly property int breakMin: Store.pomo?.brk ?? 20

    readonly property int now: Math.floor(clock.date.getTime() / 1000)
    readonly property int elapsed: running ? Math.max(0, now - Store.pomo.start) : 0
    readonly property int cycle: (focusMin + breakMin) * 60
    readonly property int within: running ? elapsed % cycle : 0
    readonly property int session: running ? Math.floor(elapsed / cycle) + 1 : 0
    readonly property bool inFocus: within < focusMin * 60
    readonly property int remaining: !running ? focusMin * 60 : inFocus ? focusMin * 60 - within : cycle - within
    readonly property real progress: !running ? 0 : inFocus ? within / (focusMin * 60) : (within - focusMin * 60) / (breakMin * 60)
    readonly property string phase: !running ? "" : inFocus ? "foco" : "descanso"
    readonly property string label: {
        const m = Math.floor(remaining / 60), s = remaining % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    onPhaseChanged: {
        if (phase === "descanso")
            Quickshell.execDetached(["notify-send", "-a", "warch", "Pomodoro", Tr.f("Descanso de %1 min", breakMin)]);
        else if (phase === "foco" && session > 1)
            Quickshell.execDetached(["notify-send", "-a", "warch", "Pomodoro", Tr.f("Sesión %1: %2 min de foco", session, focusMin)]);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
