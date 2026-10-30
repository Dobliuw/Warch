import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.services

// Volumen, notificaciones, ajustes y sesión.
Island {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int vol: Math.round((sink?.audio?.volume ?? 0) * 100)

    PwObjectTracker { objects: [root.sink] }

    // Volumen: clic = mute, rueda = ±5%, clic derecho = pavucontrol
    Chip {
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) Quickshell.execDetached(["pavucontrol"]);
            else if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted;
        }
        onScrolled: wheel => {
            if (!root.sink?.audio) return;
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            root.sink.audio.volume = Math.max(0, Math.min(1.0, root.sink.audio.volume + step));
        }
        Icon { code: root.muted ? 0xF075F : 0xF057E; color: root.muted ? Theme.dim : Theme.fg }
        Label { mono: true; text: root.vol; muted: root.muted }
    }

    // Notificaciones: clic = panel vertical, clic derecho = no molestar
    Chip {
        active: Ui.panel
        onClicked: mouse => mouse.button === Qt.RightButton ? Notifs.dnd = !Notifs.dnd : Ui.togglePanel(true)
        Icon { code: Notifs.dnd ? 0xF009B : 0xF009A; color: Notifs.dnd ? Theme.dim : Theme.fg }
        Rectangle {
            visible: Notifs.count > 0 && !Notifs.dnd
            implicitWidth: Math.max(16, badge.implicitWidth + 8); implicitHeight: 16; radius: 8
            color: Theme.accent
            Label { id: badge; anchors.centerIn: parent; mono: true; text: Notifs.count; color: Theme.surface; font.pixelSize: 10; font.weight: Font.Bold }
        }
    }

    // Ajustes rápidos
    Chip {
        active: Ui.open === "settings"
        onClicked: Ui.toggle("settings")
        Icon { code: 0xF1542 }
    }

    // Sesión
    Chip {
        active: Ui.open === "session"
        onClicked: Ui.toggle("session")
        Icon { code: 0xF0425 }
    }
}
