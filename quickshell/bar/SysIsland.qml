import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets
import qs
import qs.services

// CPU, RAM, GPU, batería (si hay) y bandeja del sistema. En pantallas chicas se compacta.
Island {
    id: root

    property bool compact: false

    component Meter: RowLayout {
        property string name
        property string value
        property real ratio: -1
        spacing: 5

        Label { text: parent.name; mono: true; muted: true; font.pixelSize: Theme.fontSize - 2 }
        Rectangle {
            visible: parent.ratio >= 0
            implicitWidth: 24; implicitHeight: 4; radius: 2
            color: Theme.surface2
            Rectangle {
                width: parent.width * Math.min(1, Math.max(0, parent.parent.ratio))
                height: parent.height; radius: 2
                color: parent.parent.ratio > 0.85 ? Theme.bad : Theme.accent
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            }
        }
        Label { text: parent.value; mono: true }
    }

    Chip {
        onClicked: Quickshell.execDetached(["kitty", "--title", "warch-btop", "-e", "btop"])
        Meter { name: "CPU"; value: Sys.cpu + "%"; ratio: Sys.cpu / 100 }
        Meter { name: "RAM"; value: Sys.ramUsedG.toFixed(1) + "G" }
        Meter { name: "GPU"; value: Sys.gpuTemp + "°"; visible: Sys.gpuTemp > 0 && !root.compact }
    }

    // Batería (notebooks)
    Chip {
        id: battery
        readonly property var dev: UPower.displayDevice
        readonly property bool present: dev?.isLaptopBattery && dev?.isPresent
        readonly property int pct: Math.round(dev?.percentage ?? 0)
        readonly property bool charging: dev?.state === UPowerDeviceState.Charging || dev?.state === UPowerDeviceState.FullyCharged
        visible: present
        padX: 6
        Icon {
            code: battery.charging ? 0xF0084 : battery.pct >= 95 ? 0xF0079 : 0xF007A + Math.max(0, Math.min(8, Math.floor(battery.pct / 10) - 1))
            color: battery.pct <= 15 && !battery.charging ? Theme.bad : battery.charging ? Theme.ok : Theme.fg
        }
        Label { text: battery.pct + "%"; mono: true }
    }

    Sep { visible: SystemTray.items.values.length > 0 }

    Repeater {
        model: SystemTray.items

        delegate: Chip {
            id: item
            required property var modelData
            padX: 5

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton || modelData.onlyMenu) {
                    if (modelData.hasMenu) menu.open();
                } else if (mouse.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else {
                    modelData.activate();
                }
            }

            IconImage {
                implicitSize: Theme.iconSize - 2
                source: item.modelData.icon
            }

            QsMenuAnchor {
                id: menu
                menu: item.modelData.menu
                anchor.item: item
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
            }
        }
    }
}
