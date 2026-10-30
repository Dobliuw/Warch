import QtQuick
import qs

// Icono de Nerd Font por código (ej. 0xF04FE). Se colorea como texto.
Text {
    property int code: 0
    property int size: Theme.iconSize

    text: code ? String.fromCodePoint(code) : ""
    color: Theme.fg
    font.family: Theme.fontIcon
    font.pixelSize: size
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
