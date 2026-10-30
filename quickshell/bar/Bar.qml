import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.services

// Barra principal (DP-2) en modo marco: una banda de borde a borde con esquinas cóncavas debajo.
// De la banda cuelgan el dashboard (centro) y los ajustes (derecha).
PanelWindow {
    id: bar

    required property var modelData
    readonly property var hmon: Hyprland.monitorFor(modelData)
    // Pantallas chicas (notebooks): se esconden el título de la ventana y luego la fecha
    readonly property bool compact: modelData.width < 1700
    readonly property bool tiny: modelData.width < 1400

    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight + Theme.corner
    exclusiveZone: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "warch-bar"
    // Solo la banda recibe clics; las esquinas dejan pasar el mouse a las ventanas
    mask: Region { item: band }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: band
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Theme.barHeight
        color: Theme.panel
    }

    ConcaveCorner { anchors { left: parent.left; top: band.bottom } corner: "topLeft" }
    ConcaveCorner { anchors { right: parent.right; top: band.bottom } corner: "topRight" }

    Item {
        anchors { fill: band; leftMargin: Theme.marginSide - 4; rightMargin: Theme.marginSide - 4 }

        // ---------- Izquierda ----------
        RowLayout {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            spacing: Theme.gap

            Island {
                Chip {
                    active: Ui.open === "launcher"
                    onClicked: Ui.toggle("launcher")
                    Icon { code: 0xF003B }
                }
                Chip {
                    active: Ui.open === "overview"
                    onClicked: Ui.toggle("overview")
                    Icon { code: 0xF0570; size: Theme.iconSize - 1 }
                }
                Workspaces { monitor: bar.hmon }
            }

            Island {
                visible: !bar.compact && (Hyprland.activeToplevel?.title ?? "") !== ""
                Label {
                    text: Hyprland.activeToplevel?.title ?? ""
                    muted: true
                    elide: Text.ElideRight
                    Layout.maximumWidth: 280
                    Layout.leftMargin: 4
                }
            }
        }

        // ---------- Centro ----------
        Island {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
            spacing: 12

            Label {
                visible: !bar.tiny
                text: Qt.locale().toString(clock.date, Tr.fmtBarDate)
                muted: true
                Layout.leftMargin: 8
            }

            Chip {
                id: logo
                padX: 4
                active: Ui.open === "dashboard"
                implicitHeight: Theme.barHeight - 12
                onClicked: Ui.toggle("dashboard")

                Image {
                    source: Qt.resolvedUrl("../assets/logo.svg")
                    sourceSize.height: (Theme.barHeight - 16) * 2
                    Layout.preferredHeight: Theme.barHeight - 16
                    Layout.preferredWidth: Layout.preferredHeight * 805 / 655
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }
            }

            Label {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                font.pixelSize: Theme.fontSize + 3
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                Layout.rightMargin: 8
            }
        }

        // ---------- Derecha ----------
        RowLayout {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            spacing: Theme.gap

            ModeIsland {}
            SysIsland { compact: bar.compact }
            Controls {}
        }
    }
}
