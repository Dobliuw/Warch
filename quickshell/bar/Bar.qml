import QtQuick
import QtQuick.Effects
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

            // Logo kalirch (assets/kalirch.png); se tiñe con el color del tema al presionarlo. sourceClipRect toma solo la zona con contenido
            // (el PNG tiene margen transparente); si cambiás la imagen, ajustá el rectángulo y la proporción.
            // El logo W sigue en el dashboard, el bloqueo y el wallpaper (assets/w_logo.svg).
            Chip {
                id: logo
                padX: 8
                active: Ui.open === "dashboard"
                implicitHeight: Theme.barHeight - 12
                onClicked: Ui.toggle("dashboard")

                // Blanco (original) normalmente; al presionarlo (dashboard abierto) toma el acento del tema.
                // Lo blanco toma el color y el contorno oscuro se mantiene.
                Item {
                    Layout.preferredHeight: Theme.barHeight - 18
                    Layout.preferredWidth: Layout.preferredHeight * 457 / 333

                    Image {
                        id: kalirch
                        anchors.fill: parent
                        source: Qt.resolvedUrl("../assets/kalirch.png")
                        sourceClipRect: Qt.rect(65, 32, 457, 333)
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        visible: false
                    }
                    MultiEffect {
                        anchors.fill: kalirch
                        source: kalirch
                        colorization: logo.active ? 1.0 : 0.0
                        colorizationColor: Theme.accent
                        brightness: logo.hovered && !logo.active ? 0.08 : 0
                        Behavior on colorization { NumberAnimation { duration: Theme.anim + 60; easing.type: Easing.OutCubic } }
                    }
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
