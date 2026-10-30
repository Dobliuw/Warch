import QtQuick
import QtQuick.Layouts
import qs
import qs.bar

// Tarjeta del panel: título de sección opcional, acción a la derecha y contenido en columna.
Rectangle {
    id: root

    property string title: ""
    property string action: ""          // texto del botón de la cabecera
    default property alias content: col.data
    signal actionClicked

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 28
    radius: Theme.radiusInner + 2
    color: Theme.base
    border.width: 1
    border.color: Theme.line

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: 14 }
        spacing: 10

        RowLayout {
            visible: root.title !== ""
            Layout.fillWidth: true

            Label {
                text: root.title.toUpperCase()
                mono: true
                muted: true
                font.pixelSize: Theme.fontSize - 3
                font.letterSpacing: 1.5
                Layout.fillWidth: true
            }
            Label {
                visible: root.action !== ""
                text: root.action
                color: actionArea.containsMouse ? Theme.accent : Theme.dim
                font.pixelSize: Theme.fontSize - 2
                MouseArea {
                    id: actionArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.actionClicked()
                }
            }
        }
    }
}
