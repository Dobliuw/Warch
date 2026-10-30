import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.bar
import qs.services

// Selector de wallpapers (SUPER + W o «> Wallpaper»): carrusel que sube desde el borde inferior del
// monitor con foco. ←→ elige, Enter aplica a este monitor, Shift+Enter a todos, escribir filtra, Esc cierra.
PanelWindow {
    id: win

    required property var modelData
    readonly property bool shown: Ui.open === "wallpaper" && Hyprland.focusedMonitor?.name === modelData.name
    readonly property int bodyW: Math.min(1100, modelData.width - 80)
    readonly property int bodyH: 250

    property var files: []
    property string current: ""
    property string query: ""
    property string toast: ""
    readonly property var shownFiles: files.filter(f => !query || name(f).toLowerCase().includes(query.toLowerCase()))

    property real progress: shown ? 1 : 0
    Behavior on progress { NumberAnimation { duration: Theme.drawerAnim; easing.type: Easing.OutCubic } }

    function name(f) { return f.split("/").pop().replace(/\.[^.]+$/, ""); }
    function apply(all) {
        const f = shownFiles[list.currentIndex];
        if (!f) return;
        Quickshell.execDetached(["warch", "wallpaper", "set", f, all ? "all" : modelData.name]);
        current = f;
        toast = all ? Tr.t("Aplicado en todos los monitores") : Tr.f("Aplicado en %1", modelData.name);
        toastTimer.restart();
    }

    onShownChanged: {
        if (!shown) return;
        query = ""; search.text = ""; toast = "";
        listProc.running = true;
        curProc.running = true;
    }
    onVisibleChanged: if (visible && shown) Qt.callLater(() => search.forceActiveFocus())

    Process {
        id: listProc
        command: ["warch", "wallpaper", "list"]
        stdout: StdioCollector { onStreamFinished: { win.files = text.trim().split("\n").filter(l => l !== ""); win.selectCurrent(); } }
    }
    Process {
        id: curProc
        command: ["readlink", "-f", Quickshell.env("HOME") + "/.local/state/warch/wallpaper/" + win.modelData.name]
        stdout: StdioCollector { onStreamFinished: { win.current = text.trim(); win.selectCurrent(); } }
    }
    function selectCurrent() {
        const i = shownFiles.indexOf(current);
        if (i >= 0) list.currentIndex = i;
    }
    Timer { id: toastTimer; interval: 2200; onTriggered: win.toast = "" }

    HyprlandFocusGrab { active: win.shown; windows: [win]; onCleared: Ui.close() }

    screen: modelData
    anchors { bottom: true }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: bodyW + Theme.corner * 2
    implicitHeight: bodyH
    color: "transparent"
    visible: progress > 0.001
    WlrLayershell.namespace: "warch-wallpaper"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: body }

    // Esquinas cóncavas contra el borde inferior
    ConcaveCorner { x: 0; y: win.bodyH - Theme.corner; corner: "bottomRight"; opacity: Math.min(1, win.progress * 4) }
    ConcaveCorner { x: Theme.corner + win.bodyW; y: win.bodyH - Theme.corner; corner: "bottomLeft"; opacity: Math.min(1, win.progress * 4) }

    Rectangle {
        id: body
        x: Theme.corner
        anchors.bottom: parent.bottom
        width: win.bodyW
        height: Math.max(1, win.bodyH * win.progress)
        color: Theme.panel
        topLeftRadius: Theme.drawerRadius
        topRightRadius: Theme.drawerRadius
        clip: true

        ColumnLayout {
            width: win.bodyW
            height: win.bodyH
            anchors.top: parent.top
            opacity: Math.max(0, (win.progress - 0.35) / 0.65)
            spacing: 6

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.preferredHeight: 182
                Layout.topMargin: 12
                orientation: ListView.Horizontal
                spacing: 14
                clip: true
                model: win.shownFiles
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: width / 2 - 120
                preferredHighlightEnd: width / 2 + 120
                highlightMoveDuration: 220
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: card
                    required property string modelData
                    required property int index
                    readonly property bool sel: ListView.isCurrentItem
                    readonly property bool active: modelData === win.current
                    width: 240
                    height: 182

                    ClippingRectangle {
                        id: thumb
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: card.sel ? 4 : 22
                        width: card.sel ? 240 : 200
                        height: card.sel ? 140 : 112
                        radius: 14
                        color: Theme.base
                        border.width: card.active ? 2 : 0
                        border.color: Theme.accent
                        opacity: card.sel ? 1 : 0.72
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Image {
                            anchors.fill: parent
                            source: "file://" + card.modelData
                            sourceSize: Qt.size(480, 280)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }
                    }
                    Label {
                        anchors { horizontalCenter: parent.horizontalCenter; top: thumb.bottom; topMargin: 6 }
                        text: win.name(card.modelData)
                        color: card.sel ? Theme.fg : Theme.dim
                        font.weight: card.sel ? Font.DemiBold : Font.Normal
                        font.pixelSize: Theme.fontSize - 1
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 220)
                    }
                    MouseArea {
                        anchors.fill: thumb
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => { if (card.sel) win.apply(mouse.modifiers & Qt.ShiftModifier); else list.currentIndex = card.index; }
                    }
                }
            }

            // Búsqueda + ayuda
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 320
                    implicitHeight: 34
                    radius: 17
                    color: Theme.base
                    border.width: 1
                    border.color: search.activeFocus ? Theme.accent : Theme.line
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 8
                        Icon { code: 0xF0349; size: 15; color: Theme.dim }
                        TextInput {
                            id: search
                            Layout.fillWidth: true
                            color: Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.fontSize - 1
                            onTextEdited: { win.query = text; list.currentIndex = 0; }
                            Keys.onLeftPressed: list.decrementCurrentIndex()
                            Keys.onRightPressed: list.incrementCurrentIndex()
                            Keys.onReturnPressed: event => win.apply(event.modifiers & Qt.ShiftModifier)
                            Keys.onEnterPressed: event => win.apply(event.modifiers & Qt.ShiftModifier)
                            Keys.onEscapePressed: Ui.close()
                            Label { anchors.verticalCenter: parent.verticalCenter; visible: search.text === ""; text: Tr.t("Buscar wallpaper"); muted: true; font.pixelSize: Theme.fontSize - 1 }
                        }
                    }
                }
                Label { text: win.toast; color: Theme.ok; font.weight: Font.DemiBold; visible: win.toast !== "" }
                Item { Layout.fillWidth: true }
                Label {
                    text: Tr.f("←→ elegir · Enter este monitor · Shift+Enter todos · %1 en ~/.config/warch/wallpapers", win.files.length)
                    mono: true; muted: true; font.pixelSize: Theme.fontSize - 4
                }
            }
        }
    }
}
