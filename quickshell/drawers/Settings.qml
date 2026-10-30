import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs
import qs.bar
import qs.services

// Ajustes rápidos: interruptores, volumen, micrófono, luz nocturna, salida de audio y NordVPN.
Drawer {
    id: root

    align: "right"
    contentWidth: Math.min(700, modelData.width - Theme.corner - 12)
    contentHeight: Math.min(450, modelData.height - Theme.barHeight - 30)
    shown: Ui.open === "settings"
    onCloseRequested: Ui.close()

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    property bool docker: false
    readonly property var countryNames: ({ Canada: Tr.t("Canadá"), United_States: Tr.t("Estados Unidos"), Argentina: "Argentina" })

    PwObjectTracker { objects: [root.sink, root.source].concat(root.sinks) }

    Process {
        id: dockerProc
        command: ["systemctl", "is-active", "docker"]
        stdout: StdioCollector { onStreamFinished: root.docker = text.trim() === "active" }
    }
    Timer { interval: 8000; running: root.shown; repeat: true; triggeredOnStart: true; onTriggered: dockerProc.running = true }

    // systemctl pide permisos por polkit: como lo lanza la GUI, aparece el diálogo de warch
    function systemctl(action, unit) {
        Priv.run(["systemctl", action, unit], () => dockerProc.running = true);
    }
    property string vpnTab: "nord"
    onShownChanged: if (shown) vpnTab = Htb.connected && !Vpn.connected ? "htb" : vpnTab

    component Toggle: Rectangle {
        id: tg
        property int icon
        property string name
        property string sub
        property bool on
        signal toggled

        Layout.fillWidth: true
        implicitHeight: 74
        radius: 13
        color: on ? Theme.accent : tgArea.containsMouse ? Theme.surface2 : Theme.base
        Behavior on color { ColorAnimation { duration: Theme.anim } }

        ColumnLayout {
            anchors { fill: parent; margins: 11 }
            spacing: 2
            Icon { code: tg.icon; size: 19; color: tg.on ? Theme.surface : Theme.fg }
            Item { Layout.fillHeight: true }
            Label { text: tg.name; color: tg.on ? Theme.surface : Theme.fg; font.weight: Font.DemiBold; font.pixelSize: Theme.fontSize - 1 }
            Label { text: tg.sub; mono: true; color: tg.on ? Qt.rgba(0.1, 0.1, 0.14, 0.7) : Theme.dim; font.pixelSize: Theme.fontSize - 4; elide: Text.ElideRight; Layout.fillWidth: true }
        }
        MouseArea { id: tgArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tg.toggled() }
    }

    RowLayout {
        anchors { fill: parent; margins: 18; topMargin: 14 }
        spacing: 14

        // ---------- Columna izquierda ----------
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            spacing: 12

            GridLayout {
                columns: 3
                rowSpacing: 6
                columnSpacing: 6
                Layout.fillWidth: true

                Toggle {
                    icon: 0xF0565; name: "NordVPN"
                    on: Vpn.connected
                    sub: Vpn.busy ? "…" : Vpn.connected ? (root.countryNames[Vpn.country.replace(/ /g, "_")] ?? Vpn.country) : Tr.t("apagado")
                    onToggled: Vpn.toggle()
                }
                Toggle {
                    icon: 0xF00AF; name: "Bluetooth"
                    on: root.adapter?.enabled ?? false
                    sub: !root.adapter ? Tr.t("servicio detenido") : root.adapter.enabled ? Tr.t("encendido") : Tr.t("apagado")
                    onToggled: root.adapter ? root.adapter.enabled = !root.adapter.enabled : root.systemctl("start", "bluetooth")
                }
                Toggle {
                    icon: 0xF009B; name: Tr.t("No molestar")
                    on: Notifs.dnd
                    sub: Notifs.dnd ? Tr.t("silencio") : Tr.t("apagado")
                    onToggled: Notifs.dnd = !Notifs.dnd
                }
                Toggle {
                    icon: 0xF0594; name: Tr.t("Luz nocturna")
                    on: Night.on
                    sub: Night.on ? Night.temp + "K" : Tr.t("apagada")
                    onToggled: Night.toggle()
                }
                Toggle {
                    icon: root.source?.audio?.muted ? 0xF036D : 0xF036C; name: Tr.t("Micrófono")
                    on: !(root.source?.audio?.muted ?? true)
                    sub: root.source?.audio?.muted ? Tr.t("silenciado") : Tr.t("activo")
                    onToggled: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
                }
                Toggle {
                    icon: 0xF0868; name: "Docker"
                    on: root.docker
                    sub: root.docker ? Tr.t("activo") : Tr.t("detenido")
                    onToggled: root.systemctl(root.docker ? "stop" : "start", "docker")
                }
            }

            // Deslizadores
            GridLayout {
                columns: 3
                rowSpacing: 10
                columnSpacing: 10
                Layout.fillWidth: true
                Layout.topMargin: 4

                Icon { code: root.sink?.audio?.muted ? 0xF075F : 0xF057E; size: 17 }
                WSlider { Layout.fillWidth: true; value: root.sink?.audio?.volume ?? 0; onMoved: v => { if (root.sink?.audio) root.sink.audio.volume = v; } }
                Label { text: Math.round((root.sink?.audio?.volume ?? 0) * 100) + "%"; mono: true; muted: true; Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight }

                Icon { code: 0xF036C; size: 17 }
                WSlider { Layout.fillWidth: true; value: root.source?.audio?.volume ?? 0; onMoved: v => { if (root.source?.audio) root.source.audio.volume = v; } }
                Label { text: Math.round((root.source?.audio?.volume ?? 0) * 100) + "%"; mono: true; muted: true; Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight }

                Icon { code: 0xF0594; size: 17 }
                WSlider { Layout.fillWidth: true; color: Theme.accent2; value: (6500 - Night.temp) / 4000; onMoved: v => Night.set(6500 - v * 4000) }
                Label { text: Night.temp + "K"; mono: true; muted: true; Layout.preferredWidth: 46; horizontalAlignment: Text.AlignRight }
            }

            // Salida de audio
            Label { text: Tr.t("SALIDA DE AUDIO"); mono: true; muted: true; font.pixelSize: Theme.fontSize - 4; font.letterSpacing: 1.5; Layout.topMargin: 2 }
            Repeater {
                model: root.sinks
                delegate: Rectangle {
                    id: out
                    required property var modelData
                    readonly property bool current: root.sink === modelData
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 9
                    color: outArea.containsMouse ? Theme.surface2 : current ? Theme.base : "transparent"
                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        Rectangle { implicitWidth: 7; implicitHeight: 7; radius: 3.5; color: out.current ? Theme.accent : "transparent"; border.width: 1.5; border.color: out.current ? Theme.accent : Theme.dim }
                        Label { text: out.modelData.description || out.modelData.nickname || out.modelData.name; elide: Text.ElideRight; Layout.fillWidth: true; font.pixelSize: Theme.fontSize - 1; muted: !out.current }
                    }
                    MouseArea { id: outArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Pipewire.preferredDefaultAudioSink = out.modelData }
                }
            }
            Item { Layout.fillHeight: true }
        }

        // ---------- VPN: NordVPN / HackTheBox ----------
        Rectangle {
            id: vpnCard
            Layout.fillHeight: true
            Layout.preferredWidth: 270
            radius: 14
            color: Theme.base

            readonly property bool htb: root.vpnTab === "htb"
            readonly property bool on: htb ? Htb.connected : Vpn.connected
            readonly property bool busy: htb ? Htb.busy : Vpn.busy

            ColumnLayout {
                anchors { fill: parent; margins: 16 }
                spacing: 12

                // Perfil
                RowLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    Repeater {
                        model: [{ id: "nord", text: "NordVPN" }, { id: "htb", text: "HackTheBox" }]
                        delegate: Chip {
                            id: seg
                            required property var modelData
                            readonly property bool current: root.vpnTab === modelData.id
                            Layout.fillWidth: true
                            implicitHeight: 34
                            color: current ? Theme.surface2 : hovered ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                            onClicked: root.vpnTab = modelData.id
                            Rectangle {
                                implicitWidth: 6; implicitHeight: 6; radius: 3
                                color: (seg.modelData.id === "htb" ? Htb.connected : Vpn.connected) ? Theme.ok : Theme.dim
                            }
                            Label { text: seg.modelData.text; color: seg.current ? Theme.accent : Theme.dim; font.weight: Font.DemiBold; font.pixelSize: Theme.fontSize - 1 }
                        }
                    }
                }

                RowLayout {
                    spacing: 12
                    Item {
                        implicitWidth: 48; implicitHeight: 48
                        Rectangle {
                            anchors.centerIn: parent
                            width: 48; height: 48; radius: 24
                            color: "transparent"
                            border.width: 2
                            border.color: vpnCard.on ? Theme.ok : Theme.bad
                            SequentialAnimation on scale {
                                running: vpnCard.on && root.shown
                                loops: Animation.Infinite
                                NumberAnimation { from: 1; to: 1.35; duration: 1800; easing.type: Easing.OutCubic }
                            }
                            SequentialAnimation on opacity {
                                running: vpnCard.on && root.shown
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.6; to: 0; duration: 1800; easing.type: Easing.OutCubic }
                            }
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 24
                            color: vpnCard.on ? Qt.rgba(0.62, 0.84, 0.71, 0.15) : Qt.rgba(0.94, 0.54, 0.54, 0.12)
                            Icon { anchors.centerIn: parent; code: vpnCard.htb ? 0xF04FE : 0xF0565; size: 22; color: vpnCard.on ? Theme.ok : Theme.bad }
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Label { text: vpnCard.busy ? Tr.t("Conectando…") : vpnCard.on ? Tr.t("Conectado") : Tr.t("Desconectado"); font.weight: Font.Bold; font.pixelSize: Theme.fontSize + 1 }
                        Label {
                            text: vpnCard.htb ? (Htb.connected ? Sys.tunName + " " + Sys.tun0 : Htb.remote || Tr.t("sin .ovpn"))
                                              : (Vpn.connected ? Vpn.server.replace(".nordvpn.com", "") : Tr.t("tu IP real es visible"))
                            mono: true; muted: true; font.pixelSize: Theme.fontSize - 3; elide: Text.ElideRight; Layout.fillWidth: true
                        }
                    }
                }

                Chip {
                    Layout.fillWidth: true
                    implicitHeight: 38
                    color: hovered ? Theme.surface2 : Qt.rgba(1, 1, 1, 0.04)
                    opacity: vpnCard.htb && !Htb.available ? 0.4 : 1
                    onClicked: vpnCard.htb ? (Htb.available ? Htb.toggle() : null) : Vpn.toggle()
                    Label { text: vpnCard.on ? Tr.t("Desconectar") : vpnCard.htb ? Tr.t("Conectar a HTB") : Tr.t("Conexión rápida"); font.weight: Font.DemiBold }
                }

                // NordVPN: países
                Label { visible: !vpnCard.htb; text: Tr.t("PAÍSES"); mono: true; muted: true; font.pixelSize: Theme.fontSize - 4; font.letterSpacing: 1.5 }
                Repeater {
                    model: vpnCard.htb ? [] : Theme.vpnCountries
                    delegate: Chip {
                        id: c
                        required property string modelData
                        readonly property bool current: Vpn.connected && Vpn.country.replace(/ /g, "_") === modelData
                        Layout.fillWidth: true
                        implicitHeight: 36
                        color: current || hovered ? Theme.surface2 : "transparent"
                        border.width: current ? 1 : 0
                        border.color: Theme.accent
                        onClicked: Vpn.connect(modelData)
                        Label { text: root.countryNames[c.modelData] ?? c.modelData; Layout.fillWidth: true; color: c.current ? Theme.accent : Theme.fg }
                        Icon { visible: c.current; code: 0xF012C; size: 15; color: Theme.accent }
                    }
                }

                // HackTheBox: datos
                ColumnLayout {
                    visible: vpnCard.htb
                    spacing: 8
                    Layout.fillWidth: true
                    Label { text: Tr.t("SERVIDOR"); mono: true; muted: true; font.pixelSize: Theme.fontSize - 4; font.letterSpacing: 1.5 }
                    Label { text: Htb.available ? Htb.remote : Tr.t("Falta ~/.config/warch/vpn/htb.ovpn"); mono: true; font.pixelSize: Theme.fontSize - 2; color: Htb.available ? Theme.fg : Theme.bad }
                    Chip {
                        visible: Htb.connected
                        Layout.fillWidth: true
                        implicitHeight: 36
                        color: hovered ? Theme.surface2 : "transparent"
                        onClicked: { Quickshell.execDetached(["wl-copy", Sys.tun0]); Quickshell.execDetached(["notify-send", "-a", "warch", Tr.t("LHOST copiada"), Sys.tun0]); }
                        Icon { code: 0xF018F; size: 15 }
                        Label { text: Tr.f("Copiar LHOST %1", Sys.tun0); mono: true; Layout.fillWidth: true; font.pixelSize: Theme.fontSize - 2 }
                    }
                    Label {
                        visible: Vpn.connected
                        text: Tr.t("NordVPN también está conectada. Si las máquinas no responden, desconéctala.")
                        color: Theme.accent2
                        wrapMode: Text.WordWrap
                        font.pixelSize: Theme.fontSize - 3
                        Layout.fillWidth: true
                    }
                }

                Item { Layout.fillHeight: true }
                Label { visible: !vpnCard.htb; text: Vpn.tech ? Tr.f("tecnología: %1", Vpn.tech.toLowerCase()) : ""; mono: true; muted: true; font.pixelSize: Theme.fontSize - 4 }
            }
        }
    }
}
