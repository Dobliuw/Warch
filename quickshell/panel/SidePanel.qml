import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

// Panel oculto del monitor vertical (HDMI-A-1).
// Se abre al llevar el mouse al borde izquierdo (se cierra al salir)
// o con `warch panel toggle` / la campana de la barra (queda fijo hasta volver a cerrarlo).
Scope {
    id: root

    required property var modelData
    readonly property int panelWidth: Math.min(540, Math.round(modelData.width * 0.45))

    function show(pin) { Ui.panelPinned = pin; Ui.panel = true; }
    function hide() { Ui.panel = false; Ui.panelPinned = false; }

    // ---------- Borde que despierta el panel ----------
    PanelWindow {
        screen: root.modelData
        anchors { left: true; top: true; bottom: true }
        implicitWidth: 3
        exclusiveZone: 0
        color: "transparent"
        visible: !Ui.panel
        WlrLayershell.namespace: "warch-panel-edge"

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 2
            color: Theme.accent
            opacity: edgeArea.containsMouse ? 0.9 : 0.45
            Behavior on opacity { NumberAnimation { duration: Theme.anim } }
        }

        MouseArea {
            id: edgeArea
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: containsMouse ? openDelay.restart() : openDelay.stop()
        }

        Timer { id: openDelay; interval: 150; onTriggered: root.show(false) }
    }

    // ---------- Panel ----------
    PanelWindow {
        id: win

        property real shown: Ui.panel ? 1 : 0
        Behavior on shown { NumberAnimation { duration: Theme.anim + 80; easing.type: Easing.OutCubic } }

        screen: root.modelData
        anchors { left: true; top: true; bottom: true }
        implicitWidth: root.panelWidth + Theme.marginSide * 2
        exclusiveZone: 0
        color: "transparent"
        visible: shown > 0
        WlrLayershell.namespace: "warch-panel"
        WlrLayershell.layer: WlrLayer.Top

        Item {
            anchors.fill: parent

            HoverHandler {
                onHoveredChanged: hovered ? closeDelay.stop() : (Ui.panelPinned ? null : closeDelay.restart())
            }
            Timer { id: closeDelay; interval: 450; onTriggered: if (!Ui.panelPinned) root.hide() }

            Rectangle {
                id: panel
                x: Theme.marginSide - (1 - win.shown) * (root.panelWidth + Theme.marginSide * 2)
                y: Theme.marginTop
                width: root.panelWidth
                height: parent.height - Theme.marginTop * 2
                opacity: 0.4 + 0.6 * win.shown
                radius: Theme.radius
                color: Theme.panel
                border.width: 1
                border.color: Theme.line

                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 10

                    Calendar {}
                    TodoSection { Layout.fillWidth: true; Layout.fillHeight: true }
                    NotifSection {}
                    MediaCard {}
                }
            }
        }
    }
}
