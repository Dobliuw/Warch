import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.bar
import qs.services

// Notificaciones emergentes: arriba a la derecha, debajo de la banda. Entran deslizándose,
// se van solas a los 6 s (las críticas se quedan) y el mouse encima pausa el tiempo.
PanelWindow {
    id: win

    required property var modelData

    screen: modelData
    anchors { top: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    margins { top: Theme.barHeight + 12; right: 14 }
    implicitWidth: 380
    implicitHeight: Math.max(1, col.implicitHeight)
    color: "transparent"
    visible: Notifs.popups.length > 0 && !Ui.locked
    WlrLayershell.namespace: "warch-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region { item: col }

    Column {
        id: col
        width: parent.width
        spacing: 8

        move: Transition { NumberAnimation { properties: "y"; duration: Theme.anim; easing.type: Easing.OutCubic } }

        Repeater {
            model: Notifs.popups

            delegate: Rectangle {
                id: card
                required property var modelData
                readonly property bool critical: modelData.urgency === 2

                width: col.width
                implicitHeight: body.implicitHeight + 26
                radius: Theme.radius + 2
                color: Theme.panel
                border.width: 1
                border.color: critical ? Theme.bad : Theme.line

                // Entrada: desliza desde la derecha
                x: 0
                opacity: 1
                Component.onCompleted: { x = 40; opacity = 0; enter.start(); }
                ParallelAnimation {
                    id: enter
                    NumberAnimation { target: card; property: "x"; to: 0; duration: Theme.drawerAnim; easing.type: Easing.OutCubic }
                    NumberAnimation { target: card; property: "opacity"; to: 1; duration: Theme.drawerAnim }
                }

                Timer {
                    interval: 6000
                    running: !card.critical && !area.containsMouse
                    onTriggered: Notifs.dismissPopup(card.modelData.id)
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => mouse.button === Qt.RightButton ? Notifs.dismissPopup(card.modelData.id) : Notifs.invoke(card.modelData.id)
                }

                RowLayout {
                    id: body
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 13 }
                    spacing: 12

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: 40; implicitHeight: 40; radius: 11
                        color: Theme.base
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 26
                            visible: card.modelData.icon !== ""
                            source: card.modelData.icon.startsWith("/") ? "file://" + card.modelData.icon : card.modelData.icon.includes("://") ? card.modelData.icon : Quickshell.iconPath(card.modelData.icon, true)
                        }
                        Icon { anchors.centerIn: parent; visible: card.modelData.icon === ""; code: 0xF009A; size: 18; color: Theme.accent }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: card.modelData.summary || card.modelData.app; font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label { text: card.modelData.app; mono: true; muted: true; font.pixelSize: Theme.fontSize - 4 }
                        }
                        Label {
                            visible: text !== ""
                            text: card.modelData.body
                            muted: true
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            font.pixelSize: Theme.fontSize - 1
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
