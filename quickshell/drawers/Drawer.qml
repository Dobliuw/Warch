import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.bar

// Panel que cuelga de la banda: crece hacia abajo desde la barra y se une a ella con esquinas cóncavas.
// Se cierra con Esc o con un clic fuera (incluida la barra, salvo que esté en `grabWith`).
PanelWindow {
    id: win

    required property var modelData
    property bool shown: false
    property string align: "center"          // "center" | "right"
    property int contentWidth: 860
    property int contentHeight: 440
    property var grabWith: []                // ventanas que no cuentan como "afuera" (la barra)
    property int topOffset: Theme.barHeight  // 0 en monitores sin banda: cuelga del borde de la pantalla
    default property alias content: inner.data
    signal closeRequested
    signal opened            // la ventana ya es visible: recién ahí se puede dar foco a un campo

    // El foco del teclado solo se puede dar cuando la ventana existe y es visible
    onVisibleChanged: if (visible && shown) Qt.callLater(() => { inner.forceActiveFocus(); win.opened(); })
    onShownChanged: if (shown && visible) Qt.callLater(() => { inner.forceActiveFocus(); win.opened(); })

    readonly property bool right: align === "right"
    property real progress: shown ? 1 : 0
    Behavior on progress { NumberAnimation { duration: Theme.drawerAnim; easing.type: Easing.OutCubic } }

    screen: modelData
    anchors { top: true; right: win.right }
    exclusionMode: ExclusionMode.Ignore
    margins.top: topOffset
    implicitWidth: contentWidth + (right ? Theme.corner : Theme.corner * 2)
    implicitHeight: contentHeight
    color: "transparent"
    visible: progress > 0.001
    WlrLayershell.namespace: "warch-drawer"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: body }

    HyprlandFocusGrab {
        active: win.shown
        windows: [win].concat(win.grabWith)
        onCleared: win.closeRequested()
    }

    // Esquinas cóncavas que unen el panel con la banda
    ConcaveCorner {
        x: 0; y: 0
        corner: "topRight"
        opacity: Math.min(1, win.progress * 4)
    }
    ConcaveCorner {
        visible: !win.right
        x: Theme.corner + win.contentWidth; y: 0
        corner: "topLeft"
        opacity: Math.min(1, win.progress * 4)
    }

    Rectangle {
        id: body
        x: Theme.corner
        width: win.contentWidth
        height: Math.max(1, win.contentHeight * win.progress)
        color: Theme.panel
        bottomLeftRadius: Theme.drawerRadius
        bottomRightRadius: win.right ? 0 : Theme.drawerRadius
        clip: true

        FocusScope {
            id: inner
            width: win.contentWidth
            height: win.contentHeight
            y: body.height - height          // el contenido sale desde debajo de la banda
            opacity: Math.max(0, (win.progress - 0.35) / 0.65)
            Keys.onEscapePressed: win.closeRequested()
        }
    }
}
