import QtQuick
import qs

// Borde de acento que marca el control con foco de teclado (Tab / flechas).
// Se dibuja 3px por fuera del control para que se vea aunque el control esté relleno del acento.
Rectangle {
    anchors.fill: parent
    anchors.margins: -3
    z: 10
    radius: (parent.radius ?? Theme.radiusInner) + 3
    color: "transparent"
    border.width: 2
    border.color: Theme.accent
    visible: parent.activeFocus
}
