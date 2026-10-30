import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.bar

// Calendario mensual, semana de lunes a domingo, con navegación entre meses.
Card {
    id: root

    property int offset: 0
    readonly property date today: clock.date
    readonly property date first: new Date(today.getFullYear(), today.getMonth() + offset, 1)
    readonly property int lead: (first.getDay() + 6) % 7
    readonly property int days: new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()

    title: Qt.locale().toString(first, "MMMM yyyy")
    action: offset !== 0 ? Tr.t("hoy") : ""
    onActionClicked: offset = 0

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    RowLayout {
        Layout.fillWidth: true

        Label {
            text: Qt.locale().toString(root.today, Tr.fmtDayNum)
            font.pixelSize: Theme.fontSize + 6
            font.weight: Font.DemiBold
            Layout.fillWidth: true
        }
        Chip { padX: 6; onClicked: root.offset--; Icon { code: 0xF0141; size: Theme.iconSize - 3 } }
        Chip { padX: 6; onClicked: root.offset++; Icon { code: 0xF0142; size: Theme.iconSize - 3 } }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: Tr.weekLetters
            delegate: Label {
                required property string modelData
                text: modelData
                mono: true
                muted: true
                font.pixelSize: Theme.fontSize - 3
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
            }
        }

        Repeater {
            model: 42

            delegate: Rectangle {
                id: cell
                required property int index
                readonly property int day: index - root.lead + 1
                readonly property bool inMonth: day >= 1 && day <= root.days
                readonly property bool isToday: inMonth && root.offset === 0 && day === root.today.getDate()
                readonly property bool weekend: index % 7 >= 5

                visible: index < Math.ceil((root.lead + root.days) / 7) * 7
                Layout.fillWidth: true
                implicitHeight: 32
                radius: Theme.radiusInner
                color: isToday ? Theme.accent : "transparent"

                Label {
                    anchors.centerIn: parent
                    text: cell.inMonth ? cell.day : ""
                    mono: true
                    color: cell.isToday ? Theme.surface : cell.weekend ? Theme.dim : Theme.fg
                    font.weight: cell.isToday ? Font.Bold : Font.Normal
                }
            }
        }
    }
}
