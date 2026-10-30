import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.services

// Barra inferior del monitor derecho (DP-1): workspaces y ventanas a la izquierda;
// reproductor, sistema y reloj a la derecha. Sin logo.
PanelWindow {
    id: bar

    required property var modelData
    readonly property var hmon: Hyprland.monitorFor(modelData)

    screen: modelData
    anchors { bottom: true; left: true; right: true }
    implicitHeight: Theme.barHeight + Theme.marginTop
    exclusiveZone: implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "warch-bar-bottom"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item {
        anchors {
            fill: parent
            bottomMargin: Theme.marginTop
            leftMargin: Theme.marginSide
            rightMargin: Theme.marginSide
        }

        // ---------- Izquierda: workspaces y ventanas de este monitor ----------
        RowLayout {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            spacing: Theme.gap

            Island {
                Workspaces { monitor: bar.hmon; Layout.leftMargin: 2; Layout.rightMargin: 2 }
            }

            Island {
                id: windows
                readonly property var list: Hyprland.toplevels.values.filter(t =>
                    t.monitor && bar.hmon && t.monitor.name === bar.hmon.name
                    && t.workspace && bar.hmon.activeWorkspace && t.workspace.id === bar.hmon.activeWorkspace.id)
                visible: list.length > 0

                Repeater {
                    model: windows.list

                    delegate: Chip {
                        id: win
                        required property var modelData
                        active: modelData.activated
                        padX: 9
                        Layout.maximumWidth: 240

                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton) modelData.wayland?.close();
                            else modelData.wayland?.activate();
                        }

                        Rectangle {
                            implicitWidth: 3; implicitHeight: 14; radius: 1.5
                            color: Theme.accent
                            visible: win.modelData.activated
                        }
                        IconImage {
                            implicitSize: Theme.iconSize - 1
                            source: {
                                const id = win.modelData.wayland?.appId || win.modelData.lastIpcObject?.class || "";
                                const e = DesktopEntries.heuristicLookup(id);
                                return Quickshell.iconPath(e ? e.icon : id, "application-x-executable");
                            }
                        }
                        Label {
                            text: win.modelData.title
                            muted: !win.modelData.activated
                            elide: Text.ElideRight
                            Layout.maximumWidth: 180
                        }
                    }
                }
            }
        }

        // ---------- Derecha: reproductor, sistema y reloj ----------
        RowLayout {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            spacing: Theme.gap

            Island {
                visible: Media.active

                Chip {
                    padX: 6
                    onClicked: Media.player?.previous()
                    Icon { code: 0xF04AE; size: Theme.iconSize - 2 }
                }
                Chip {
                    padX: 6
                    onClicked: Media.player?.togglePlaying()
                    Icon { code: Media.player?.isPlaying ? 0xF03E4 : 0xF040A; color: Theme.accent }
                }
                Chip {
                    padX: 6
                    onClicked: Media.player?.next()
                    Icon { code: 0xF04AD; size: Theme.iconSize - 2 }
                }
                ColumnLayout {
                    spacing: 3
                    Layout.rightMargin: 8
                    Label {
                        text: Media.title + (Media.artist ? "  ·  " + Media.artist : "")
                        elide: Text.ElideRight
                        Layout.maximumWidth: 260
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 3; radius: 1.5
                        color: Theme.surface2
                        Rectangle {
                            width: parent.width * Media.progress
                            height: parent.height; radius: 1.5
                            color: Theme.accent
                        }
                    }
                }
            }

            Island {
                Chip {
                    onClicked: Quickshell.execDetached(["kitty", "--title", "warch-btop", "-e", "btop"])
                    Label { text: "CPU"; mono: true; muted: true; font.pixelSize: Theme.fontSize - 2 }
                    Label { text: Sys.cpu + "%"; mono: true }
                    Label { text: "RAM"; mono: true; muted: true; font.pixelSize: Theme.fontSize - 2 }
                    Label { text: Sys.ramUsedG.toFixed(1) + "G"; mono: true }
                }
            }

            Island {
                Label {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: Theme.fontSize + 3
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                }
            }
        }
    }
}
