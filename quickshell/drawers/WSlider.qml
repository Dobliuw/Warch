import QtQuick
import qs
import qs.bar

// Deslizador con el estilo de warch. `value` va de 0 a 1; emite `moved(v)` al arrastrar o usar la rueda.
// Teclado: ←→ ajustan de a 5%, ↑↓ y Tab pasan al control siguiente.
Item {
    id: root

    property real value: 0
    property color color: Theme.accent
    signal moved(real v)

    implicitHeight: 22
    implicitWidth: 200
    activeFocusOnTab: true
    readonly property int radius: 11
    function step(d) { root.moved(Math.min(1, Math.max(0, root.value + d))); }
    function move(forward) { const n = nextItemInFocusChain(forward); if (n) n.forceActiveFocus(); }
    Keys.onLeftPressed: step(-0.05)
    Keys.onRightPressed: step(0.05)
    Keys.onDownPressed: move(true)
    Keys.onUpPressed: move(false)

    FocusRing { anchors.margins: -5 }

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
