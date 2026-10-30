import QtQuick
import qs

// Esquina cóncava: un cuadrado del color de la banda con un cuarto de círculo recortado.
// `corner` indica en qué esquina queda el hueco redondeado ("topLeft", "topRight", "bottomLeft", "bottomRight").
Canvas {
    id: root

    property string corner: "topLeft"
    property int size: Theme.corner
    property color color: Theme.panel

    width: size
    height: size
    onColorChanged: requestPaint()

    onPaint: {
        const c = getContext("2d");
        c.reset();
        c.fillStyle = root.color;
        c.fillRect(0, 0, width, height);
        c.globalCompositeOperation = "destination-out";
        const cx = corner.endsWith("Left") ? width : 0;
        const cy = corner.startsWith("top") ? height : 0;
        c.beginPath();
        c.arc(cx, cy, size, 0, Math.PI * 2);
        c.fill();
    }
}
