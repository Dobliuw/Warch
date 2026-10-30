import QtQuick
import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs
import qs.services

// Bloqueo de sesión. Real: WlSessionLock (si Quickshell se cae, Hyprland mantiene la pantalla bloqueada).
// Vista previa (`warch lock --test`): ventanas comunes encima de todo, Esc para salir; valida la
// contraseña con PAM igual que el real, así se puede probar sin riesgo de quedar afuera.
Scope {
    id: root

    property string password: ""
    property bool busy: false
    property string message: ""

    function submit() {
        if (busy || password === "") return;
        busy = true;
        message = "";
        pam.start();
    }
    function finish() {
        if (Ui.lockTest) Ui.markLockVerified();
        password = "";
        message = "";
        Ui.locked = false;
        Ui.lockTest = false;
    }

    PamContext {
        id: pam
        config: "login"
        onPamMessage: { if (responseRequired) respond(root.password); }
        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) {
                root.finish();
            } else {
                root.password = "";
                root.message = result === PamResult.MaxTries ? Tr.t("Demasiados intentos") : Tr.t("Contraseña incorrecta");
            }
        }
        onError: err => { root.busy = false; root.password = ""; root.message = Tr.t("Error de PAM"); }
    }

    WlSessionLock {
        locked: Ui.locked
        WlSessionLockSurface {
            id: surface
            color: Theme.base
            LockContent { anchors.fill: parent; lock: root; screenName: surface.screen?.name ?? "" }
        }
    }

    Variants {
        model: Ui.lockTest ? Quickshell.screens : []
        delegate: Component {
            PanelWindow {
                id: preview
                required property var modelData
                screen: modelData
                anchors { top: true; bottom: true; left: true; right: true }
                exclusionMode: ExclusionMode.Ignore
                color: Theme.base
                WlrLayershell.namespace: "warch-lock-preview"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: Mon.isMain(modelData) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                LockContent { anchors.fill: parent; lock: root; screenName: preview.modelData.name; preview: true }
            }
        }
    }
}
