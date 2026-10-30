import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs
import qs.bar
import qs.services

// Contenido de la pantalla de bloqueo: wallpaper desenfocado, logo, reloj, fecha, contraseña y estado.
// El campo de contraseña está en todos los monitores (así nunca quedás afuera si DP-2 está apagado);
// logo y estado solo en el principal.
Item {
    id: root

    required property var lock
    property string screenName: ""
    property bool preview: false
    readonly property bool main: screenName === Mon.main || screenName === ""
    property bool reveal: false

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Image {
        id: wall
        anchors.fill: parent
        // Mismo wallpaper que el monitor (enlace que deja `warch wallpaper apply`)
        source: "file://" + Quickshell.env("HOME") + "/.local/state/warch/wallpaper/" + (root.screenName || Mon.main)
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: wall
        source: wall
        blurEnabled: true
        blur: 1.0
        blurMax: 64
        brightness: -0.12
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0.05, 0.05, 0.07, 0.45) }

    // Entrada suave
    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Image {
            visible: root.main
            Layout.alignment: Qt.AlignHCenter
            source: Qt.resolvedUrl("../assets/logo.svg")
            sourceSize.height: 200
            Layout.preferredHeight: 92
            Layout.preferredWidth: 92 * 805 / 655
            fillMode: Image.PreserveAspectFit
            mipmap: true
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: 110
            font.weight: Font.ExtraBold
            font.letterSpacing: -3
            font.features: { "tnum": 1 }
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.locale().toString(clock.date, Tr.fmtLongDate)
            muted: true
            font.pixelSize: 17
        }

        // Contraseña
        Rectangle {
            id: field
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 22
            implicitWidth: 320; implicitHeight: 50
            radius: 25
            color: Qt.rgba(0.9, 0.89, 0.86, 0.08)
            border.width: 1
            border.color: root.lock.message !== "" ? Theme.bad : input.activeFocus ? Theme.accent : Theme.line

            RowLayout {
                anchors { fill: parent; leftMargin: 20; rightMargin: 8 }
                spacing: 10

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    focus: true
                    Component.onCompleted: forceActiveFocus()
                    echoMode: root.reveal ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "•"
                    color: Theme.fg
                    font.family: Theme.fontMono
                    font.pixelSize: 20
                    font.letterSpacing: 3
                    enabled: !root.lock.busy
                    text: root.lock.password
                    onTextEdited: { root.lock.password = text; root.lock.message = ""; }
                    onAccepted: root.lock.submit()
                    Keys.onEscapePressed: {
                        if (root.preview) { root.lock.password = ""; Ui.lockTest = false; }
                        else root.lock.password = "";
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === ""
                        text: root.lock.busy ? Tr.t("Verificando…") : Tr.f("Contraseña de %1", Quickshell.env("USER"))
                        muted: true
                        font.letterSpacing: 0
                    }
                }
                Icon {
                    code: root.reveal ? 0xF0209 : 0xF0208
                    size: 18
                    color: eyeArea.containsMouse || root.reveal ? Theme.accent : Theme.dim
                    MouseArea { id: eyeArea; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.reveal = !root.reveal; input.forceActiveFocus(); } }
                }
                Rectangle {
                    implicitWidth: 36; implicitHeight: 36; radius: 18
                    color: Theme.accent
                    opacity: root.lock.busy ? 0.5 : 1
                    Icon { anchors.centerIn: parent; code: 0xF0054; size: 18; color: Theme.surface }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.lock.submit() }
                }
            }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: field; property: "Layout.leftMargin"; to: -16; duration: 60 }
                NumberAnimation { target: field; property: "Layout.leftMargin"; to: 14; duration: 70 }
                NumberAnimation { target: field; property: "Layout.leftMargin"; to: -8; duration: 70 }
                NumberAnimation { target: field; property: "Layout.leftMargin"; to: 0; duration: 60 }
            }
            Connections {
                target: root.lock
                function onMessageChanged() { if (root.lock.message !== "") shake.start(); }
            }
        }
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: root.lock.message || (root.preview ? Tr.t("Vista previa · Esc para salir") : " ")
            color: root.lock.message ? Theme.bad : Theme.dim
            font.pixelSize: Theme.fontSize - 1
        }
    }

    // Estado abajo: música, notificaciones y VPN (nunca el objetivo ni las tareas)
    RowLayout {
        visible: root.main
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 34 }
        spacing: 10

        component Pill: Rectangle {
            default property alias content: row.data
            implicitWidth: row.implicitWidth + 28
            implicitHeight: 36
            radius: 18
            color: Qt.rgba(0.9, 0.89, 0.86, 0.07)
            RowLayout { id: row; anchors.centerIn: parent; spacing: 8 }
        }

        Pill {
            visible: Media.active
            Icon { code: Media.player?.isPlaying ? 0xF040A : 0xF03E4; size: 15; color: Theme.dim }
            Label { text: Media.title + (Media.artist ? " · " + Media.artist : ""); muted: true; elide: Text.ElideRight; Layout.maximumWidth: 320 }
        }
        Pill {
            Icon { code: 0xF009A; size: 15; color: Theme.dim }
            Label { text: Tr.f("%1 notificaciones", Notifs.count); muted: true }
        }
        Pill {
            Icon { code: 0xF0565; size: 15; color: Vpn.connected ? Theme.ok : Theme.dim }
            Label { text: Vpn.connected ? "NordVPN · " + Vpn.country : Tr.t("VPN apagada"); muted: true }
        }
    }
}
