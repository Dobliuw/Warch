import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services

// Isla que cambia según el modo: sistema, pentest o estudio.
Island {
    id: root

    readonly property var icons: ({ sistema: 0xF0EE0, pentest: 0xF04FE, estudio: 0xF14F7 })

    function copy(text, what) {
        Quickshell.execDetached(["wl-copy", text]);
        Quickshell.execDetached(["notify-send", "-a", "warch", "-t", "1500", Tr.f("%1 copiada", what), text]);
    }

    // Botón de modo (solo icono): clic = siguiente, clic derecho = anterior
    Chip {
        active: true
        padX: 7
        onClicked: mouse => Store.run(["mode", mouse.button === Qt.RightButton ? "prev" : "next"])

        Icon { code: root.icons[Store.mode] ?? 0xF0EE0; color: Theme.accent2 }
    }

    // ---------- Sistema ----------
    RowLayout {
        visible: Store.mode === "sistema"
        spacing: 6

        Label { mono: true; text: "↓" + Sys.rxMBs.toFixed(1) + " ↑" + Sys.txMBs.toFixed(1) + " MB/s"; Layout.leftMargin: 4 }
        Sep {}
        Chip {
            onClicked: Quickshell.execDetached(["kitty", "--title", "warch-update", "-e", "sh", "-c", "yay -Syu; echo; read -p '" + Tr.t("Enter para cerrar") + "'"])
            Icon { code: 0xF06B0; color: Sys.updates > 0 ? Theme.accent : Theme.dim }
            Label { mono: true; text: Sys.updates < 0 ? "…" : Sys.updates }
        }
    }

    // ---------- Pentest ----------
    RowLayout {
        visible: Store.mode === "pentest"
        spacing: 6

        Chip {
            visible: Store.target !== null
            onClicked: root.copy(Store.target.ip, Tr.t("IP del objetivo"))
            Icon { code: 0xF04FE; color: Theme.accent2 }
            Label { mono: true; text: Store.target?.ip ?? ""; font.weight: Font.DemiBold }
            Label { text: Store.target?.name ?? ""; muted: true; visible: text !== ""; elide: Text.ElideRight; Layout.maximumWidth: 110 }
        }
        Label {
            visible: Store.target === null
            text: Tr.t("sin objetivo")
            muted: true
            Layout.leftMargin: 6
        }
        Sep {}
        Chip {
            onClicked: if (Sys.vpnIp) root.copy(Sys.vpnIp, Sys.tun0 ? "LHOST" : Tr.t("IP de NordVPN"))
            Rectangle {
                implicitWidth: 7; implicitHeight: 7; radius: 3.5
                color: Sys.vpnIp ? Theme.ok : Theme.bad
            }
            Label { mono: true; text: Sys.vpnIp ? Sys.vpnName + " " + Sys.vpnIp : Tr.t("sin VPN"); muted: !Sys.vpnIp }
        }
    }

    // ---------- Estudio ----------
    RowLayout {
        visible: Store.mode === "estudio"
        spacing: 6

        Chip {
            onClicked: Store.run(["pomo", Pomo.running ? "stop" : "start"])

            Canvas {
                id: ring
                implicitWidth: Theme.iconSize + 1
                implicitHeight: Theme.iconSize + 1
                property real p: Pomo.progress
                onPChanged: requestPaint()
                onPaint: {
                    const c = getContext("2d"), r = width / 2;
                    c.reset();
                    c.lineWidth = 3;
                    c.strokeStyle = Theme.surface2;
                    c.beginPath(); c.arc(r, r, r - 2, 0, Math.PI * 2); c.stroke();
                    c.strokeStyle = Pomo.inFocus ? Theme.accent2 : Theme.ok;
                    c.beginPath(); c.arc(r, r, r - 2, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p); c.stroke();
                }
            }
            Label { mono: true; text: Pomo.label }
            Label { muted: true; text: Pomo.running ? Tr.t(Pomo.phase) + " " + Pomo.session : Tr.t("iniciar") }
        }
        Sep {}
        Label {
            text: Todo.focus?.task?.title ?? Tr.t("sin tarea enfocada")
            muted: !Todo.focus
            elide: Text.ElideRight
            Layout.maximumWidth: 150
            Layout.rightMargin: 6
        }
    }
}
