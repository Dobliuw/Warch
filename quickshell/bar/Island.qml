import QtQuick
import QtQuick.Layouts
import qs

// Contenedor de una isla de la barra: fondo sólido, borde fino y contenido centrado.
Rectangle {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing

    implicitHeight: Theme.barHeight
    implicitWidth: row.implicitWidth + Theme.pad * 2 + 2
    radius: Theme.radius
    // En modo marco las islas no tienen fondo propio: viven dentro de la banda
    color: Theme.frame ? "transparent" : Theme.surface
    border.width: Theme.frame ? 0 : 1
    border.color: Theme.line
    clip: true

    Behavior on implicitWidth {
        NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }
}
