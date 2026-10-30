import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.bar
import qs.services

// Menú de sesión a pantalla completa. Flechas + Enter, o mouse. Esc o clic afuera cancela.
// Apagar, reiniciar y firmware piden un segundo Enter/clic.
PanelWindow {
    id: win

    required property var modelData
    readonly property bool shown: Ui.open === "session"
    property int sel: 0
    property int armed: -1

    property real progress: shown ? 1 : 0
    Behavior on progress { NumberAnimation { duration: Theme.drawerAnim; easing.type: Easing.OutCubic } }

    readonly property var actions: [
        { icon: 0xF033E, text: Tr.t("Bloquear"), run: () => Ui.lock() },
        { icon: 0xF04B2, text: Tr.t("Suspender"), run: () => { Ui.lock(); suspendLater.start(); } },
        { icon: 0xF0343, text: Tr.t("Cerrar sesión"), danger: true, run: () => Hyprland.dispatch("hl.dsp.exit()") },
        { icon: 0xF0128, text: Tr.t("Monitor del sistema"), run: () => Quickshell.execDetached(["kitty", "--title", "warch-btop", "-e", "btop"]) },
        { icon: 0xF0904, text: Tr.t("Hibernar"), run: () => Quickshell.execDetached(["systemctl", "hibernate"]) },
        { icon: 0xF0425, text: Tr.t("Apagar"), danger: true, run: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
        { icon: 0xF0709, text: Tr.t("Reiniciar"), danger: true, run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { icon: 0xF0493, text: Tr.t("Reiniciar al firmware"), danger: true, run: () => Quickshell.execDetached(["systemctl", "reboot", "--firmware-setup"]) }
    ]

    function choose(i) {
        sel = i;
        const a = actions[i];
        if (a.danger && armed !== i) { armed = i; return; }
        armed = -1;
        Ui.close();
        a.run();
    }

    onShownChanged: { sel = 0; armed = -1; }

    Timer { id: suspendLater; interval: 600; onTriggered: Quickshell.execDetached(["systemctl", "suspend"]) }

    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: progress > 0.001
    WlrLayershell.namespace: "warch-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.05, 0.05, 0.07, 0.93)
        opacity: win.progress

        MouseArea { anchors.fill: parent; onClicked: Ui.close() }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 14
        opacity: win.progress
        scale: 0.94 + 0.06 * win.progress
        focus: win.shown

        Keys.onPressed: event => {
            const n = win.actions.length, cols = 4;
            const move = { [Qt.Key_Right]: 1, [Qt.Key_Left]: -1, [Qt.Key_Down]: cols, [Qt.Key_Up]: -cols }[event.key];
            if (move !== undefined) { win.armed = -1; win.sel = (win.sel + move + n) % n; event.accepted = true; }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) { win.choose(win.sel); event.accepted = true; }
            else if (event.key === Qt.Key_Escape) { Ui.close(); event.accepted = true; }
        }

        Label { Layout.alignment: Qt.AlignHCenter; text: Tr.t("Sesión"); font.pixelSize: 20; font.weight: Font.Bold }
        Label { Layout.alignment: Qt.AlignHCenter; text: Tr.t("Flechas para moverte, Enter para elegir\nEsc o clic afuera para cancelar"); muted: true; horizontalAlignment: Text.AlignHCenter; font.pixelSize: Theme.fontSize - 1 }

        GridLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6
            columns: 4
            rowSpacing: 12
            columnSpacing: 12

            Repeater {
                model: win.actions
                delegate: Rectangle {
                    id: b
                    required property var modelData
                    required property int index
                    readonly property bool selected: win.sel === index

                    implicitWidth: 86; implicitHeight: 86
                    radius: selected ? 43 : 22
                    color: selected ? (modelData.danger ? Theme.bad : Theme.accent) : bArea.containsMouse ? Qt.rgba(0.9, 0.9, 0.86, 0.15) : Qt.rgba(0.9, 0.9, 0.86, 0.08)
                    Behavior on radius { NumberAnimation { duration: Theme.drawerAnim; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.anim } }

                    Icon { anchors.centerIn: parent; code: b.modelData.icon; size: 28; color: b.selected ? Theme.surface : Theme.fg }

                    MouseArea {
                        id: bArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: { if (win.sel !== b.index) win.armed = -1; win.sel = b.index; }
                        onClicked: win.choose(b.index)
                    }
                }
            }
        }

        Label { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4; text: win.actions[win.sel].text; font.weight: Font.DemiBold }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: win.armed === win.sel ? Tr.t("Presiona Enter o haz clic otra vez para confirmar") : " "
            mono: true
            color: Theme.accent2
            font.pixelSize: Theme.fontSize - 2
        }
    }
}
