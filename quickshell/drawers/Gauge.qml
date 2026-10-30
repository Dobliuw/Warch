import QtQuick
import qs
import qs.bar

// Medidor circular de 270° con valor grande, etiqueta y un dato secundario.
Item {
    id: root

    property real ratio: 0
    property color color: Theme.accent
    property string value: ""
    property string label: ""
    property string sub: ""

    implicitWidth: 180
    implicitHeight: 180

    property real shown: ratio
    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
    onShownChanged: arc.requestPaint()

    Canvas {
        id: arc
        anchors.fill: parent
        onPaint: {
            const c = getContext("2d"), r = width / 2 - 8, start = Math.PI * 0.75, span = Math.PI * 1.5;
            c.reset();
            c.lineWidth = 9;
            c.lineCap = "round";
            c.strokeStyle = Theme.surface2;
            c.beginPath(); c.arc(width / 2, height / 2, r, start, start + span); c.stroke();
            c.strokeStyle = root.color;
            c.beginPath(); c.arc(width / 2, height / 2, r, start, start + span * Math.max(0.005, Math.min(1, root.shown))); c.stroke();
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: root.value; font.pixelSize: 30; font.weight: Font.Bold; font.features: { "tnum": 1 } }
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: root.label; muted: true; font.pixelSize: Theme.fontSize - 2 }
    }

    Label {
        anchors { right: parent.right; bottom: parent.bottom; bottomMargin: 18 }
        text: root.sub
        mono: true
        muted: true
        font.pixelSize: Theme.fontSize - 3
        horizontalAlignment: Text.AlignRight
    }
}
