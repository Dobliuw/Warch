import QtQuick
import QtQuick.Layouts
import qs
import qs.bar

// Bloque del dashboard: fondo base, título opcional en mono y contenido en columna.
Rectangle {
    id: root

    property string title: ""
    default property alias content: col.data
    property alias spacing: col.spacing

    radius: 14
    color: Theme.base
    implicitHeight: col.implicitHeight + 28
    implicitWidth: col.implicitWidth + 28

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: 14 }
        spacing: 8

        Label {
            visible: root.title !== ""
            text: root.title.toUpperCase()
            mono: true
            muted: true
            font.pixelSize: Theme.fontSize - 4
            font.letterSpacing: 1.5
        }
    }
}
