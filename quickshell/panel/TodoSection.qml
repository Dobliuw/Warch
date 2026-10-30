import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.bar
import qs.services

// TO-DOsh: tarea en foco, tareas abiertas (clic en el círculo = hecha, clic en el título = enfocar) y avance por proyecto.
ColumnLayout {
    id: root

    spacing: 10

    readonly property var prioColor: ({ urgent: Theme.bad, high: Theme.accent2, normal: Theme.accent, medium: Theme.accent, low: Theme.dim })

    // ---------- En foco ----------
    Card {
        title: Tr.t("TO-DOsh · en foco")
        action: Todo.focus ? Tr.t("soltar") : Tr.t("abrir")
        onActionClicked: Todo.focus ? Todo.unfocus() : Quickshell.execDetached(["kitty", "--title", "todosh", "-e", Todo.bin])

        Label {
            visible: !Todo.focus
            text: Tr.t("Ninguna tarea en foco. Haz clic en el título de una tarea para enfocarla.")
            muted: true
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        ColumnLayout {
            visible: !!Todo.focus
            spacing: 4
            Layout.fillWidth: true

            Label {
                text: Todo.focus?.task?.title ?? ""
                font.pixelSize: Theme.fontSize + 3
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            RowLayout {
                spacing: 10
                Label { text: Todo.focus?.task?.project ?? ""; muted: true }
                Label { text: Tr.f("sesión %1", Todo.fmtDuration(Todo.focus?.session_seconds)); mono: true; color: Theme.accent2 }
                Label { text: Tr.f("total %1", Todo.fmtDuration(Todo.focus?.total_seconds)); mono: true; muted: true }
            }
        }
    }

    // ---------- Tareas abiertas ----------
    Card {
        title: Tr.f("Tareas · %1 abiertas", Todo.tasks.length)
        action: Tr.t("actualizar")
        onActionClicked: Todo.refresh()
        Layout.fillHeight: true

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 200
            clip: true
            spacing: 2
            model: Todo.tasks
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property bool inProgress: modelData.status === "IN_PROGRESS"
                readonly property bool focused: Todo.focus?.task?.id === modelData.id

                width: list.width
                implicitHeight: 40
                radius: Theme.radiusInner
                color: rowArea.containsMouse ? Theme.surface2 : focused ? Theme.surface : "transparent"

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Todo.focusOn(row.modelData.id)
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 10 }
                    spacing: 10

                    // Círculo: marcar como hecha
                    Rectangle {
                        implicitWidth: 18; implicitHeight: 18; radius: 9
                        color: doneArea.containsMouse ? Theme.ok : "transparent"
                        border.width: 2
                        border.color: doneArea.containsMouse ? Theme.ok : row.inProgress ? Theme.accent2 : Theme.dim
                        MouseArea {
                            id: doneArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Todo.done(row.modelData.id)
                        }
                    }

                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Label {
                            text: row.modelData.title
                            elide: Text.ElideRight
                            font.weight: row.focused ? Font.DemiBold : Font.Normal
                            Layout.fillWidth: true
                        }
                        Label {
                            text: row.modelData.project + (row.modelData.subtasks ? "  ·  " + row.modelData.subtasks.done + "/" + row.modelData.subtasks.total : "")
                            muted: true
                            font.pixelSize: Theme.fontSize - 3
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Label {
                        visible: row.inProgress || row.modelData.status === "BLOCKED"
                        text: row.inProgress ? Tr.t("en curso") : Tr.t("bloqueada")
                        mono: true
                        font.pixelSize: Theme.fontSize - 4
                        color: row.inProgress ? Theme.accent2 : Theme.bad
                    }
                    Rectangle {
                        implicitWidth: 7; implicitHeight: 7; radius: 3.5
                        color: root.prioColor[row.modelData.priority] ?? Theme.dim
                    }
                }
            }
        }
    }

    // ---------- Proyectos ----------
    Card {
        title: Tr.t("Proyectos")

        Repeater {
            model: Todo.projects

            delegate: ColumnLayout {
                id: proj
                required property var modelData
                spacing: 4
                Layout.fillWidth: true

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: proj.modelData.name; Layout.fillWidth: true; elide: Text.ElideRight }
                    Label { text: proj.modelData.done + "/" + proj.modelData.total; mono: true; muted: true }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 4; radius: 2
                    color: Theme.surface2
                    Rectangle {
                        width: parent.width * (proj.modelData.total ? proj.modelData.done / proj.modelData.total : 0)
                        height: parent.height; radius: 2
                        color: Theme.accent
                    }
                }
            }
        }
    }
}
