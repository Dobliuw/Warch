import QtQuick
import Quickshell
import qs.bar
import qs.drawers
import qs.overlays

// Todo lo que vive en el monitor principal: la banda, los paneles que cuelgan de ella,
// las notificaciones emergentes, el menú de sesión, la vista general y el diálogo de permisos (polkit).
Scope {
    id: desk

    required property var modelData

    Bar { id: bar; modelData: desk.modelData }
    Dashboard { modelData: desk.modelData; grabWith: [bar] }
    Settings { modelData: desk.modelData; grabWith: [bar] }
    NotifPopups { modelData: desk.modelData }
    Session { modelData: desk.modelData }
    Overview { modelData: desk.modelData }
    PolkitDialog { modelData: desk.modelData }
}
