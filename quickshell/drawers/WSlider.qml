import QtQuick
import qs

// Deslizador con el estilo de warch. `value` va de 0 a 1; emite `moved(v)` al arrastrar o usar la rueda.
Item {
    id: root

    property real value: 0
    property color color: Theme.accent
    signal moved(real v)

    implicitHeight: 22
    implicitWidth: 200

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 6; radius: 3
        color: Theme.surface2
        Rectangle {
            width: Math.max(height, parent.width * Math.min(1, Math.max(0, root.value)))
            height: parent.height; radius: 3
            color: root.color
        }
    }
    Rectangle {
        x: (root.width - width) * Math.min(1, Math.max(0, root.value))
        anchors.verticalCenter: parent.verticalCenter
        width: area.pressed || area.containsMouse ? 18 : 14
        height: width; radius: width / 2
        color: Theme.fg
        Behavior on width { NumberAnimation { duration: 120 } }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        function emitAt(x) { root.moved(Math.min(1, Math.max(0, x / width))); }
        onPressed: mouse => emitAt(mouse.x)
        onPositionChanged: mouse => { if (pressed) emitAt(mouse.x); }
        onWheel: wheel => root.moved(Math.min(1, Math.max(0, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
