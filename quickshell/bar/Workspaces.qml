import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs

// Workspaces del monitor como puntos; el activo se abre y muestra los iconos de sus apps.
RowLayout {
    id: root

    required property var monitor   // HyprlandMonitor
    spacing: 3

    function appIcon(tl) {
        const id = (tl.wayland && tl.wayland.appId) || (tl.lastIpcObject && tl.lastIpcObject.class) || "";
        const entry = DesktopEntries.heuristicLookup(id);
        return Quickshell.iconPath(entry ? entry.icon : id, "application-x-executable");
    }

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            id: ws

            required property var modelData
            readonly property bool mine: modelData.id > 0 && root.monitor !== null && modelData.monitor !== null && modelData.monitor.name === root.monitor.name
            readonly property bool current: root.monitor !== null && root.monitor.activeWorkspace !== null && root.monitor.activeWorkspace.id === modelData.id
            readonly property bool empty: modelData.toplevels.values.length === 0

            visible: mine
            Layout.preferredHeight: Theme.chipHeight - 4
            Layout.preferredWidth: current ? apps.implicitWidth + 20 : 24
            radius: Theme.radiusInner
            color: current ? Theme.surface2 : area.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
            clip: true

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: Theme.anim }
            }

            // Punto (inactivo)
            Rectangle {
                anchors.centerIn: parent
                width: 8; height: 8; radius: 4
                visible: !ws.current
                color: ws.empty ? "transparent" : (ws.modelData.urgent ? Theme.bad : Theme.dim)
                border.width: ws.empty ? 1.5 : 0
                border.color: Theme.dim
            }

            // Apps (activo)
            Row {
                id: apps
                anchors.centerIn: parent
                spacing: 5
                opacity: ws.current ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.anim }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6; height: 6; radius: 3
                    color: Theme.accent
                }

                Repeater {
                    model: ws.modelData.toplevels
                    delegate: IconImage {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: Theme.iconSize - 1
                        source: root.appIcon(modelData)
                    }
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + ws.modelData.id + " })")
            }
        }
    }
}
