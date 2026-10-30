import QtQuick
import QtQuick.Layouts
import qs

// Botón dentro de una isla: fondo al pasar el mouse, clic izquierdo/derecho/medio y rueda.
Rectangle {
    id: root

    default property alias content: row.data
    property bool active: false
    property alias hovered: area.containsMouse
    property int padX: 8

    signal clicked(var mouse)
    signal scrolled(var wheel)

    implicitHeight: Theme.chipHeight
    implicitWidth: row.implicitWidth + padX * 2
    radius: Theme.radiusInner
    color: active || area.containsMouse ? Theme.surface2 : "transparent"

    Behavior on color {
        ColorAnimation { duration: Theme.anim }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.scrolled(wheel)
    }
}
