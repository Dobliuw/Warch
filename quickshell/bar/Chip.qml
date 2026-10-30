import QtQuick
import QtQuick.Layouts
import qs

// Botón dentro de una isla: fondo al pasar el mouse, clic izquierdo/derecho/medio y rueda.
// Con teclado (en paneles que tienen foco): Tab o flechas para llegar, Enter o Espacio para activar.
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

    activeFocusOnTab: true
    function press() { root.clicked({ button: Qt.LeftButton, modifiers: 0 }); }
    function move(forward) {
        const next = nextItemInFocusChain(forward);
        if (next) next.forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason);
    }
    Keys.onReturnPressed: press()
    Keys.onEnterPressed: press()
    Keys.onSpacePressed: press()
    Keys.onDownPressed: move(true)
    Keys.onRightPressed: move(true)
    Keys.onUpPressed: move(false)
    Keys.onLeftPressed: move(false)

    Behavior on color {
        ColorAnimation { duration: Theme.anim }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }

    FocusRing {}

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
