import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.bar
import qs.services

// Vista general de los workspaces 1–10 (grilla 2×5) con miniaturas en vivo.
// Arrastrar una ventana a otro workspace la mueve; clic en un workspace o ventana va a él; Esc sale.
// Teclado: flechas (o Tab / Shift+Tab) mueven la selección, Enter va al workspace seleccionado.
PanelWindow {
    id: win

    required property var modelData
    readonly property var hmon: Hyprland.monitorFor(modelData)
    readonly property bool shown: Ui.open === "overview"
    readonly property int cols: 5
    readonly property int tileW: Math.min(300, Math.floor((modelData.width - 160 - gap * (cols - 1)) / cols))
    readonly property int tileH: Math.round(tileW * 9 / 16)
    readonly property int gap: 10

    property real progress: shown ? 1 : 0
    Behavior on progress { NumberAnimation { duration: Theme.drawerAnim; easing.type: Easing.OutCubic } }

    property int sel: 1
    onShownChanged: if (shown) { sel = hmon?.activeWorkspace?.id ?? 1; if (sel < 1 || sel > 10) sel = 1; Hyprland.refreshToplevels(); Hyprland.refreshWorkspaces(); }
    function moveSel(dc, dr) {
        const i = sel - 1, c = (i % cols + dc + cols) % cols, rr = (Math.floor(i / cols) + dr + 2) % 2;
        sel = rr * cols + c + 1;
    }
    onVisibleChanged: if (visible && shown) Qt.callLater(() => panel.forceActiveFocus())

    function addr(t) { const a = t.address || ""; return a.startsWith("0x") ? a : "0x" + a; }
    function goWorkspace(n) { Ui.close(); Hyprland.dispatch("hl.dsp.focus({ workspace = " + n + " })"); }
    function goWindow(t) { Ui.close(); Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + addr(t) + "\" })"); }
    function moveTo(t, n) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + n + ", window = \"address:" + addr(t) + "\", follow = false })");
        refreshLater.restart();
    }
    Timer { id: refreshLater; interval: 150; onTriggered: Hyprland.refreshToplevels() }

    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: progress > 0.001
    WlrLayershell.namespace: "warch-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.03, 0.035, 0.05, 0.55)
        opacity: win.progress
        MouseArea { anchors.fill: parent; onClicked: Ui.close() }
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: grid.width + 28
        height: grid.height + 28
        radius: 20
        color: Theme.surface
        border.width: 1
        border.color: Theme.line
        opacity: win.progress
        scale: 0.95 + 0.05 * win.progress
        focus: win.shown
        Keys.onEscapePressed: Ui.close()
        Keys.onLeftPressed: win.moveSel(-1, 0)
        Keys.onRightPressed: win.moveSel(1, 0)
        Keys.onUpPressed: win.moveSel(0, -1)
        Keys.onDownPressed: win.moveSel(0, 1)
        Keys.onTabPressed: win.sel = win.sel % 10 + 1
        Keys.onBacktabPressed: win.sel = (win.sel + 8) % 10 + 1
        Keys.onReturnPressed: win.goWorkspace(win.sel)
        Keys.onEnterPressed: win.goWorkspace(win.sel)
        MouseArea { anchors.fill: parent }   // no cerrar al hacer clic dentro

        Grid {
            id: grid
            anchors.centerIn: parent
            columns: win.cols
            spacing: win.gap

            Repeater {
                model: 10

                delegate: Rectangle {
                    id: tile
                    required property int index
                    readonly property int ws: index + 1
                    readonly property bool current: win.hmon?.activeWorkspace?.id === ws
                    readonly property bool selected: win.sel === ws
                    property bool dropTarget: false
                    property bool hasDrag: false
                    z: hasDrag ? 10 : 0

                    width: win.tileW
                    height: win.tileH
                    radius: 12
                    color: dropTarget || selected ? Theme.surface2 : Theme.base
                    border.width: selected ? 3 : 2
                    border.color: dropTarget || selected ? Theme.accent2 : current ? Theme.accent : "transparent"
                    scale: selected ? 1.03 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    clip: !hasDrag

                    Label {
                        anchors.centerIn: parent
                        text: tile.ws
                        font.pixelSize: 44
                        font.weight: Font.ExtraBold
                        color: tile.selected ? Qt.rgba(0.9, 0.89, 0.86, 0.18) : Qt.rgba(0.9, 0.89, 0.86, 0.07)
                    }

                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: win.goWorkspace(tile.ws) }

                    Repeater {
                        model: Hyprland.toplevels.values.filter(t => t.workspace?.id === tile.ws)

                        delegate: Rectangle {
                            id: w
                            required property var modelData
                            readonly property var ipc: modelData.lastIpcObject
                            readonly property var mon: modelData.monitor
                            readonly property real s: mon ? win.tileW / Math.max(mon.width, mon.height * 16 / 9) : 0.15
                            readonly property real homeX: ipc?.at && mon ? (ipc.at[0] - mon.x) * s : 6
                            readonly property real homeY: ipc?.at && mon ? (ipc.at[1] - mon.y) * s : 6
                            property bool dragging: false

                            x: homeX
                            y: homeY
                            width: ipc?.size ? Math.max(24, ipc.size[0] * s) : win.tileW - 12
                            height: ipc?.size ? Math.max(18, ipc.size[1] * s) : win.tileH - 12
                            z: dragging ? 100 : 1
                            radius: 6
                            color: Theme.surface
                            border.width: wArea.containsMouse || dragging ? 2 : 1
                            border.color: wArea.containsMouse || dragging ? Theme.accent : Qt.rgba(1, 1, 1, 0.08)
                            clip: true
                            scale: dragging ? 1.05 : 1
                            Behavior on scale { NumberAnimation { duration: 120 } }

                            ScreencopyView {
                                id: shot
                                anchors { fill: parent; margins: 1 }
                                captureSource: win.shown ? w.modelData.wayland : null
                                live: true
                            }
                            IconImage {
                                anchors.centerIn: parent
                                visible: !shot.hasContent || wArea.containsMouse
                                implicitSize: Math.min(32, Math.min(parent.width, parent.height) * 0.5)
                                source: {
                                    const id = w.modelData.wayland?.appId || w.ipc?.class || "";
                                    const e = DesktopEntries.heuristicLookup(id);
                                    return Quickshell.iconPath(e ? e.icon : id, "application-x-executable");
                                }
                            }

                            MouseArea {
                                id: wArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: w.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                drag.target: w
                                drag.threshold: 6
                                onPressed: { w.dragging = false; }
                                onPositionChanged: {
                                    if (!drag.active) return;
                                    w.dragging = true;
                                    tile.hasDrag = true;
                                    const p = w.mapToItem(grid, w.width / 2, w.height / 2);
                                    win.hover = win.tileAt(p.x, p.y);
                                }
                                onReleased: {
                                    if (w.dragging) {
                                        const p = w.mapToItem(grid, w.width / 2, w.height / 2);
                                        const n = win.tileAt(p.x, p.y);
                                        if (n > 0 && n !== tile.ws) win.moveTo(w.modelData, n);
                                    } else {
                                        win.goWindow(w.modelData);
                                    }
                                    w.dragging = false;
                                    tile.hasDrag = false;
                                    win.hover = 0;
                                    w.x = Qt.binding(() => w.homeX);
                                    w.y = Qt.binding(() => w.homeY);
                                }
                            }
                        }
                    }

                    Binding { target: tile; property: "dropTarget"; value: win.hover === tile.ws && win.hover !== 0 }
                }
            }
        }
    }

    property int hover: 0
    function tileAt(px, py) {
        const c = Math.floor(px / (tileW + gap)), r = Math.floor(py / (tileH + gap));
        if (px < 0 || py < 0 || c >= cols || r >= 2) return 0;
        return r * cols + c + 1;
    }
}
