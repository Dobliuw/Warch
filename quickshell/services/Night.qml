pragma Singleton

import QtQuick
import Quickshell

// Luz nocturna (hyprsunset) a través de `warch night`, que guarda la temperatura en el estado.
Singleton {
    id: root

    readonly property int neutral: 6500
    readonly property int temp: Store.data?.night ?? neutral
    readonly property bool on: temp < neutral

    function run(arg) {
        Quickshell.execDetached(["sh", "-c", "out=$(warch night " + arg + " 2>&1) || notify-send -a warch '" + Tr.t("Luz nocturna") + "' \"$out\""]);
    }
    function set(t) { run(String(Math.round(t / 100) * 100)); }
    function toggle() { run("toggle"); }
}
