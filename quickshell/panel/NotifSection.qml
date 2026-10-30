import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.bar
import qs.services

// Historial de notificaciones: clic = volver a mostrarla, x = quitarla.
Card {
    id: root

    title: Tr.f("Notificaciones · %1", Notifs.count)
    action: Notifs.count > 0 ? Tr.t("limpiar") : ""
    onActionClicked: Notifs.clear()

    Label {
        visible: Notifs.count === 0
        text: Tr.t("Sin notificaciones.")
        muted: true
    }

    Repeater {
        model: Notifs.items.slice(0, 5)

        delegate: Rectangle {
            id: n
            required property var modelData

            Layout.fillWidth: true
            implicitHeight: body.implicitHeight + 18
            radius: Theme.radiusInner
            color: area.containsMouse ? Theme.surface2 : Theme.surface

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
            }

            ColumnLayout {
                id: body
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 9; rightMargin: 30 }
                spacing: 2

                RowLayout {
                    spacing: 8
                    Label { text: n.modelData.summary || n.modelData.app; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true }
                    Label { text: n.modelData.app; mono: true; muted: true; font.pixelSize: Theme.fontSize - 4 }
                }
                Label {
                    visible: text !== "" && text !== n.modelData.summary
                    text: n.modelData.body
                    muted: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSize - 1
                    Layout.fillWidth: true
                }
            }

            Chip {
                anchors { right: parent.right; top: parent.top; margins: 4 }
                implicitHeight: 24
                padX: 4
                visible: area.containsMouse || hovered
                onClicked: Notifs.remove(n.modelData.id)
                Icon { code: 0xF0156; size: Theme.iconSize - 5; color: Theme.dim }
            }
        }
    }
}
