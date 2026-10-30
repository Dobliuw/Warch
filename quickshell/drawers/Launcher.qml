import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs
import qs.bar
import qs.services

// Lanzador (SUPER + D): busca aplicaciones; con «>» muestra comandos (esquema, wallpaper, variante,
// transparencia, claro/oscuro, bloquear…). ↑↓ elige, Enter ejecuta, Esc vuelve o cierra.
Drawer {
    id: root

    readonly property bool hasBand: Mon.isMain(modelData)
    topOffset: hasBand ? Theme.barHeight : 0
    contentWidth: Math.min(640, modelData.width - Theme.corner * 2 - 24)
    contentHeight: Math.min(540, modelData.height - topOffset - 40)
    shown: Ui.open === "launcher" && Hyprland.focusedMonitor?.name === modelData.name
    onCloseRequested: back()

    property string query: ""
    property string page: ""          // "" | "scheme" | "variant" | "opacity" | "mode"
    readonly property bool commandMode: query.startsWith(">") || page !== ""

    onShownChanged: if (shown) { page = ""; setQuery(""); }
    onOpened: input.forceActiveFocus()

    function setQuery(q) { query = q; input.text = q; list.currentIndex = 0; }
    function back() {
        if (page !== "") { page = ""; setQuery(">"); }
        else Ui.close();
    }
    function warch(args) { Quickshell.execDetached(["warch"].concat(args)); }

    readonly property var commands: [
        { icon: 0xF03D8, title: Tr.t("Esquema"), sub: Tr.t("Cambiar la paleta de colores"), go: "scheme" },
        { icon: 0xF02E9, title: "Wallpaper", sub: Tr.t("Cambiar el wallpaper"), keep: true, run: () => Ui.open = "wallpaper" },
        { icon: 0xF0266, title: Tr.t("Variante"), sub: Tr.t("Cambiar la variante del esquema"), go: "variant" },
        { icon: 0xF058C, title: Tr.t("Transparencia"), sub: Tr.t("Transparencia de la barra y los paneles"), go: "opacity" },
        { icon: 0xF05A8, title: Tr.t("Claro"), sub: Tr.t("Pasar al modo claro"), run: () => root.warch(["theme", "mode", "light"]) },
        { icon: 0xF0594, title: Tr.t("Oscuro"), sub: Tr.t("Pasar al modo oscuro"), run: () => root.warch(["theme", "mode", "dark"]) },
        { icon: 0xF0335, title: Tr.t("Luz nocturna"), sub: Night.on ? Tr.f("Apagar (ahora %1K)", Night.temp) : Tr.t("Encender"), run: () => Night.toggle() },
        { icon: 0xF0EE0, title: Tr.t("Modo de la barra"), sub: Tr.t("Sistema, pentest o estudio"), go: "mode" },
        { icon: 0xF030C, title: Tr.t("Atajos"), sub: Tr.t("Abrir el cheat sheet"), keep: true, run: () => Ui.open = "cheatsheet" },
        { icon: 0xF033E, title: Tr.t("Bloquear"), sub: Tr.t("Bloquear la sesión"), run: () => Ui.lock() },
        { icon: 0xF04B2, title: Tr.t("Suspender"), sub: Tr.t("Bloquear y suspender"), run: () => { Ui.lock(); Quickshell.execDetached(["sh", "-c", "sleep 0.6; systemctl suspend"]); } },
        { icon: 0xF0425, title: Tr.t("Sesión"), sub: Tr.t("Apagar, reiniciar, cerrar sesión…"), keep: true, run: () => Ui.open = "session" }
    ]

    readonly property var pages: ({
        scheme: Object.keys(Theme.schemes).map(k => ({
            title: Tr.t(Theme.schemes[k].name), sub: "", swatches: [Theme.schemes[k].base, Theme.schemes[k].surface2, Theme.schemes[k].accent, Theme.schemes[k].accent2],
            current: Theme.scheme === k, run: () => root.warch(["theme", "scheme", k])
        })).concat([{ icon: 0xF02E9, title: Tr.t("Desde el wallpaper"), sub: Tr.t("Colores sacados del wallpaper principal"), current: Theme.scheme === "wallpaper", run: () => root.warch(["theme", "scheme", "wallpaper"]) }]),
        variant: [
            { v: "tonal", t: Tr.t("Tonal"), s: Tr.t("Acentos suaves (por defecto)") },
            { v: "vibrante", t: Tr.t("Vibrante"), s: Tr.t("Acentos más saturados") },
            { v: "neutral", t: Tr.t("Neutral"), s: Tr.t("Casi sin color") },
            { v: "mono", t: Tr.t("Monocromo"), s: Tr.t("Solo grises") }
        ].map(o => ({ icon: 0xF0266, title: o.t, sub: o.s, current: Theme.variant === o.v, run: () => root.warch(["theme", "variant", o.v]) })),
        opacity: [100, 90, 80, 70, 60, 50].map(o => ({
            icon: 0xF058C, title: o + "%", sub: o === 100 ? Tr.t("Sólida") : Tr.t("Deja ver el wallpaper"), current: Math.round(Theme.opacity * 100) === o,
            run: () => root.warch(["theme", "opacity", String(o)])
        })),
        mode: [["sistema", 0xF0EE0], ["pentest", 0xF04FE], ["estudio", 0xF14F7]].map(m => ({
            icon: m[1], title: Tr.t(m[0].charAt(0).toUpperCase() + m[0].slice(1)), sub: "", current: Store.mode === m[0], run: () => Store.run(["mode", m[0]])
        }))
    })

    readonly property var items: {
        if (page !== "") return pages[page];
        const q = query.toLowerCase();
        if (commandMode) {
            const c = q.slice(1).trim();
            return commands.filter(x => !c || (x.title + " " + x.sub).toLowerCase().includes(c));
        }
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        const scored = apps.map(e => {
            const n = (e.name || "").toLowerCase(), extra = ((e.genericName || "") + " " + (e.keywords || "") + " " + (e.comment || "")).toLowerCase();
            const sc = !q ? 1 : n.startsWith(q) ? 0 : n.includes(q) ? 1 : extra.includes(q) ? 2 : -1;
            return { e, sc };
        }).filter(x => x.sc >= 0);
        scored.sort((a, b) => a.sc - b.sc || a.e.name.localeCompare(b.e.name));
        return scored.slice(0, 40).map(x => ({ app: x.e, title: x.e.name, sub: x.e.genericName || x.e.comment || "", run: () => x.e.execute() }));
    }

    function activate(i) {
        const it = items[i];
        if (!it) return;
        if (it.go) { page = it.go; query = ""; input.text = ""; list.currentIndex = Math.max(0, pages[it.go].findIndex(x => x.current)); return; }
        it.run();
        // Los submenús quedan abiertos para probar opciones; el resto cierra
        if (page === "" && !it.keep) Ui.close();
    }

    ColumnLayout {
        anchors { fill: parent; margins: 16; topMargin: 12 }
        spacing: 10

        // Búsqueda
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 46
            radius: 23
            color: Theme.base
            border.width: 1
            border.color: input.activeFocus ? Theme.accent : Theme.line

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                spacing: 10
                Icon { code: root.page !== "" ? 0xF004D : root.commandMode ? 0xF0BA9 : 0xF0349; size: 17; color: root.commandMode ? Theme.accent : Theme.dim }
                Label {
                    visible: root.page !== ""
                    text: Tr.t(({ scheme: "Esquema", variant: "Variante", opacity: "Transparencia", mode: "Modo" })[root.page] ?? "")
                    color: Theme.accent; font.weight: Font.Bold
                }
                TextInput {
                    id: input
                    focus: true
                    Layout.fillWidth: true
                    visible: root.page === ""
                    color: Theme.fg
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.fontSize + 1
                    onTextEdited: { root.query = text; list.currentIndex = 0; }
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onReturnPressed: root.activate(list.currentIndex)
                    Keys.onEnterPressed: root.activate(list.currentIndex)
                    Keys.onEscapePressed: root.back()
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Backspace && root.page !== "") { root.back(); event.accepted = true; }
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === ""
                        text: Tr.t("Buscar aplicaciones · escribe > para comandos")
                        muted: true
                    }
                }
                Item { Layout.fillWidth: true; visible: root.page !== "" }
                Label { text: root.page !== "" ? Tr.t("Esc vuelve") : root.items.length; mono: true; muted: true; font.pixelSize: Theme.fontSize - 3 }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: root.shown ? root.items : []
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 120
            highlight: Rectangle { radius: 12; color: Theme.surface2 }
            keyNavigationEnabled: false
            // En submenús el foco va a la lista (no hay campo de texto)
            focus: root.page !== ""
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onUpPressed: decrementCurrentIndex()
            Keys.onReturnPressed: root.activate(currentIndex)
            Keys.onEnterPressed: root.activate(currentIndex)
            Keys.onEscapePressed: root.back()
            Keys.onPressed: event => { if (event.key === Qt.Key_Backspace) { root.back(); event.accepted = true; } }
            onModelChanged: if (root.page !== "") forceActiveFocus()

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                width: list.width
                height: 54

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: list.currentIndex = row.index
                    onClicked: root.activate(row.index)
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 14 }
                    spacing: 14

                    Item {
                        implicitWidth: 30; implicitHeight: 30
                        IconImage {
                            anchors.fill: parent
                            visible: !!row.modelData.app
                            source: row.modelData.app ? Quickshell.iconPath(row.modelData.app.icon, "application-x-executable") : ""
                        }
                        Icon { anchors.centerIn: parent; visible: !row.modelData.app && !row.modelData.swatches; code: row.modelData.icon ?? 0; size: 22; color: row.modelData.current ? Theme.accent : Theme.fg }
                        Grid {
                            anchors.centerIn: parent
                            visible: !!row.modelData.swatches
                            columns: 2; spacing: 2
                            Repeater {
                                model: row.modelData.swatches ?? []
                                delegate: Rectangle { required property string modelData; width: 13; height: 13; radius: 3; color: modelData; border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.1) }
                            }
                        }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Label { text: row.modelData.title; font.weight: Font.DemiBold; elide: Text.ElideRight; Layout.fillWidth: true; color: row.modelData.current ? Theme.accent : Theme.fg }
                        Label { visible: text !== ""; text: row.modelData.sub; muted: true; font.pixelSize: Theme.fontSize - 2; elide: Text.ElideRight; Layout.fillWidth: true }
                    }
                    Icon { visible: !!row.modelData.current; code: 0xF012C; size: 16; color: Theme.accent }
                    Icon { visible: !!row.modelData.go; code: 0xF0142; size: 16; color: Theme.dim }
                }
            }
        }
    }
}
