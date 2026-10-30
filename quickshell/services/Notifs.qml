pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Servidor de notificaciones propio (reemplaza a dunst).
// `popups`: las que se muestran ahora; `items`: historial, la más reciente primero.
Singleton {
    id: root

    property bool dnd: false
    property var items: []
    property var popups: []
    readonly property int count: items.length
    readonly property int maxHistory: 50

    function entry(n) {
        return {
            id: n.id,
            app: n.appName,
            summary: n.summary,
            body: (n.body || "").replace(/<[^>]*>/g, ""),
            icon: n.image || n.appIcon || "",
            urgency: n.urgency,
            time: new Date(),
            ref: n
        };
    }

    function dismissPopup(id) { popups = popups.filter(p => p.id !== id); }
    function remove(id) {
        const it = items.find(i => i.id === id);
        if (it && it.ref && it.ref.tracked) it.ref.dismiss();
        items = items.filter(i => i.id !== id);
        dismissPopup(id);
    }
    function clear() {
        items.forEach(i => { if (i.ref && i.ref.tracked) i.ref.dismiss(); });
        items = [];
        popups = [];
    }
    function closeAll() { popups = []; }
    function invoke(id) {
        const it = items.find(i => i.id === id);
        const act = it?.ref?.actions?.find(a => a.identifier === "default") ?? it?.ref?.actions?.[0];
        if (act) act.invoke();
        dismissPopup(id);
    }

    NotificationServer {
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const e = root.entry(n);
            root.items = [e].concat(root.items.filter(i => i.id !== n.id)).slice(0, root.maxHistory);
            const critical = n.urgency === NotificationUrgency.Critical;
            if (!root.dnd || critical)
                root.popups = [e].concat(root.popups.filter(p => p.id !== n.id)).slice(0, 4);
            n.closed.connect(() => root.dismissPopup(n.id));
        }
    }
}
