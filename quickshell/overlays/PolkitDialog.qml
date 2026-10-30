import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import qs
import qs.bar
import qs.services

// Agente de polkit de warch, solo para acciones lanzadas desde la GUI (ver services/Priv.qml).
// Se registra mientras dura la acción; los comandos de la terminal piden la contraseña en la terminal.
PanelWindow {
    id: win

    required property var modelData
    readonly property var agent: agentLoader.item
    readonly property var flow: agent?.flow ?? null
    readonly property bool shown: (agent?.isActive ?? false) && flow !== null
    property bool reveal: false

    property real progress: shown ? 1 : 0
    Behavior on progress { NumberAnimation { duration: Theme.drawerAnim; easing.type: Easing.OutCubic } }

    LazyLoader {
        id: agentLoader
        active: Priv.wanted
        PolkitAgent {
            onIsRegisteredChanged: Priv.ready = isRegistered
            Component.onCompleted: Priv.ready = isRegistered
        }
    }
    onShownChanged: reveal = false
    onVisibleChanged: if (visible && shown) Qt.callLater(() => input.forceActiveFocus())

    function submit() {
        if (!flow || !flow.isResponseRequired || input.text === "") return;
        flow.submit(input.text);
        input.text = "";
    }
    function cancel() { if (flow) flow.cancelAuthenticationRequest(); input.text = ""; }

    Connections {
        target: win.flow
        ignoreUnknownSignals: true
        function onAuthenticationFailed() { shake.start(); }
    }

    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: progress > 0.001
    WlrLayershell.namespace: "warch-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.04, 0.04, 0.06, 0.7)
        opacity: win.progress
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 0
        width: 440
        height: col.implicitHeight + 48
        radius: Theme.drawerRadius
        color: Theme.surface
        border.width: 1
        border.color: Theme.line
        opacity: win.progress
        scale: 0.94 + 0.06 * win.progress

        SequentialAnimation {
            id: shake
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -14; duration: 60 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 12; duration: 70 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -6; duration: 70 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
        }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
            spacing: 12

            RowLayout {
                spacing: 14
                Rectangle {
                    implicitWidth: 46; implicitHeight: 46; radius: 23
                    color: Qt.rgba(0.74, 0.71, 0.93, 0.15)
                    Icon { anchors.centerIn: parent; code: 0xF0565; size: 22; color: Theme.accent }
                }
                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Label { text: Tr.t("Se necesitan permisos"); font.pixelSize: Theme.fontSize + 3; font.weight: Font.Bold }
                    Label { text: win.flow?.actionId ?? ""; mono: true; muted: true; font.pixelSize: Theme.fontSize - 4; elide: Text.ElideMiddle; Layout.fillWidth: true }
                }
            }

            Label {
                text: win.flow?.message ?? ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                muted: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 4
                implicitHeight: 48
                radius: 24
                color: Theme.base
                border.width: 1
                border.color: win.flow?.supplementaryIsError ? Theme.bad : input.activeFocus ? Theme.accent : Theme.line

                Icon {
                    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                    code: win.reveal ? 0xF0209 : 0xF0208
                    size: 18
                    color: eyeArea.containsMouse || win.reveal ? Theme.accent : Theme.dim
                    MouseArea { id: eyeArea; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { win.reveal = !win.reveal; input.forceActiveFocus(); } }
                }
                TextInput {
                    id: input
                    anchors { fill: parent; leftMargin: 20; rightMargin: 44 }
                    verticalAlignment: TextInput.AlignVCenter
                    focus: win.shown
                    echoMode: win.flow?.responseVisible || win.reveal ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "•"
                    color: Theme.fg
                    font.family: Theme.fontMono
                    font.pixelSize: 17
                    enabled: win.flow?.isResponseRequired ?? false
                    onAccepted: win.submit()
                    Keys.onEscapePressed: win.cancel()
                    onVisibleChanged: if (visible) forceActiveFocus()

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === ""
                        text: (win.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || Tr.t("Contraseña")
                        muted: true
                    }
                }
            }

            Label {
                visible: text !== ""
                text: win.flow?.supplementaryMessage ?? ""
                color: win.flow?.supplementaryIsError ? Theme.bad : Theme.dim
                font.pixelSize: Theme.fontSize - 1
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.topMargin: 6
                spacing: 8
                Item { Layout.fillWidth: true }
                Chip {
                    padX: 18
                    implicitHeight: 40
                    color: hovered ? Theme.surface2 : Qt.rgba(1, 1, 1, 0.04)
                    onClicked: win.cancel()
                    Label { text: Tr.t("Cancelar") }
                }
                Chip {
                    padX: 18
                    implicitHeight: 40
                    color: hovered ? Qt.lighter(Theme.accent, 1.08) : Theme.accent
                    onClicked: win.submit()
                    Label { text: Tr.t("Autorizar"); color: Theme.surface; font.weight: Font.Bold }
                }
            }
        }
    }
}
