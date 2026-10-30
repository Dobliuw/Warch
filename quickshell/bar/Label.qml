import QtQuick
import qs

Text {
    property bool mono: false
    property bool muted: false

    color: muted ? Theme.dim : Theme.fg
    font.family: mono ? Theme.fontMono : Theme.fontUi
    font.pixelSize: mono ? Theme.fontSize - 1 : Theme.fontSize
    font.features: mono ? { "tnum": 1 } : ({})
    verticalAlignment: Text.AlignVCenter
}
