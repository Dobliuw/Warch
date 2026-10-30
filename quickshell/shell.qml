//@ pragma UseQApplication
//@ pragma IconTheme breeze-dark

import QtQuick
import Quickshell
import qs.drawers
import qs.lock
import qs.overlays
import qs.panel
import qs.services

// warch shell (los roles de cada monitor salen de services/Mon.qml):
//   principal  banda + dashboard, ajustes, notificaciones, sesión y vista general (Desk)
//   lateral    panel oculto (SidePanel); si no hay monitor vertical, va en el principal
//   todos     cheat sheet, lanzador y wallpapers (en el monitor con foco) y bloqueo (Lock)
ShellRoot {
    Variants {
        model: Quickshell.screens.filter(s => s.name === Mon.main)
        delegate: Component { Desk {} }
    }

    // Barra inferior de DP-1: desactivada (repetía música y sistema de la principal).
    // Variants {
    //     model: Quickshell.screens.filter(s => s.name === "DP-1")
    //     delegate: Component { BottomBar {} }
    // }

    Variants {
        model: Quickshell.screens.filter(s => s.name === Mon.side)
        delegate: Component { SidePanel {} }
    }

    // En el monitor con foco: cheat sheet, lanzador y selector de wallpapers
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Scope {
                id: perScreen
                required property var modelData
                CheatSheet { modelData: perScreen.modelData }
                Launcher { modelData: perScreen.modelData }
                WallPicker { modelData: perScreen.modelData }
            }
        }
    }

    Lock {}
}
