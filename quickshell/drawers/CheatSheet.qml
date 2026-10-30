import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs
import qs.bar
import qs.services

// Cheat sheet de atajos (SUPER + K). Lee `hyprctl binds -j` cada vez que se abre, así que cualquier
// atajo con `description = "Grupo · Texto"` en hyprland.lua aparece solo. Escribe para buscar,
// Tab cambia de grupo, Esc cierra. Aparece en el monitor con foco.
Drawer {
    id: root

    readonly property bool hasBand: Mon.isMain(modelData)
    topOffset: hasBand ? Theme.barHeight : 0
    contentWidth: Math.min(940, modelData.width - Theme.corner * 2 - 24)
    readonly property bool oneColumn: contentWidth < 760
    contentHeight: Math.min(640, modelData.height - topOffset - 60)
    shown: Ui.open === "cheatsheet" && Hyprland.focusedMonitor?.name === modelData.name
    onCloseRequested: Ui.close()

    property var groups: []          // [{ g, rows: [{ mods, key, d, conflict }] }]
    property int total: 0
    property string query: ""
    property string group: "Todos"

    readonly property var order: ["warch", "Modos", "Pentest", "Estudio", "Sesión", "Apps", "Ventanas", "Workspaces", "Multimedia", "Captura", "Sistema"]
    readonly property var modBits: [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]]
    readonly property var names: ({
        left: "←", right: "→", up: "↑", down: "↓", Up: "↑", Down: "↓", Return: "Enter", grave: "`", Escape: "Esc", Print: "Impr",
        "mouse:272": "Clic izq", "mouse:273": "Clic der", mouse_down: "Rueda ↓", mouse_up: "Rueda ↑",
        XF86AudioRaiseVolume: "Vol +", XF86AudioLowerVolume: "Vol −", XF86AudioMute: "Mute", XF86AudioMicMute: "Mic",
        XF86MonBrightnessUp: "Brillo +", XF86MonBrightnessDown: "Brillo −", XF86AudioNext: "Siguiente", XF86AudioPause: "Pausa",
        XF86AudioPlay: "Play", XF86AudioPrev: "Anterior"
    })

    onShownChanged: {
        if (!shown) return;
        query = ""; group = "Todos"; search.text = "";
        flick.contentY = 0;
        proc.running = true;
    }
    onOpened: search.forceActiveFocus()

    Process {
        id: proc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector { onStreamFinished: { try { root.parse(JSON.parse(text)); } catch (e) {} } }
    }

    function parse(raw) {
        const dup = {};
        raw.forEach(b => { const id = b.modmask + "-" + b.key; dup[id] = (dup[id] || 0) + 1; });
        const byGroup = {}, ws = {};
        raw.forEach(b => {
            const desc = b.description || ((b.dispatcher || "") + " " + (b.arg || "")).trim();
            const parts = desc.split(" · ");
            const g = parts.length > 1 ? parts[0] : "Otros";   // clave interna en español; se traduce al mostrar
            const d = parts.length > 1 ? parts.slice(1).join(" · ") : desc;
            const mods = modBits.filter(m => b.modmask & m[0]).map(m => m[1]);
            const n = d.match(/^(.*) (\d+)$/);
            if (g === "Workspaces" && n) {               // «Ir al workspace 1…10» en una sola fila
                const id = b.modmask + n[1];
                if (!ws[id]) { ws[id] = { mods, key: "1…0", d: Tr.t(n[1]) + " 1–10", conflict: false }; (byGroup[g] = byGroup[g] || []).push(ws[id]); }
                return;
            }
            (byGroup[g] = byGroup[g] || []).push({ mods, key: Tr.t(names[b.key] ?? b.key), d: Tr.t(d), conflict: dup[b.modmask + "-" + b.key] > 1 });
        });
        const keys = order.filter(g => byGroup[g]).concat(Object.keys(byGroup).filter(g => !order.includes(g)));
        groups = keys.map(g => ({ g, rows: byGroup[g] }));
        total = groups.reduce((n, G) => n + G.rows.length, 0);
    }

    // Filtrado por grupo y búsqueda
    readonly property var shownGroups: {
        const q = query.trim().toLowerCase();
        return groups.filter(G => group === "Todos" || G.g === group)
            .map(G => ({ g: G.g, rows: G.rows.filter(r => !q || (G.g + " " + Tr.t(G.g) + " " + r.d + " " + r.key + " " + r.mods.join(" ")).toLowerCase().includes(q)) }))
            .filter(G => G.rows.length > 0);
    }
    // Reparto en dos columnas equilibradas (cabecera = 2 filas)
    readonly property var columns: {
        const a = [], b = [];
        let ha = 0, hb = 0;
        if (oneColumn) return [shownGroups];
        shownGroups.forEach(G => {
            const h = G.rows.length + 2;
            if (ha <= hb) { a.push(G); ha += h; } else { b.push(G); hb += h; }
        });
        return [a, b];
    }
    readonly property int matches: shownGroups.reduce((n, G) => n + G.rows.length, 0)

    // ---------- Tecla ----------
    component KeyCap: Rectangle {
        id: cap
        property string label
        property bool mod: false
        readonly property bool isSuper: label === "SUPER"
        implicitWidth: Math.max(26, (isSuper ? glyph.implicitWidth : txt.implicitWidth) + 14)
        implicitHeight: 24
        radius: 7
        color: "transparent"
        border.width: 1.5
        border.color: mod ? Qt.rgba(0.74, 0.71, 0.93, 0.55) : Qt.rgba(0.9, 0.89, 0.86, 0.35)

        Icon { id: glyph; anchors.centerIn: parent; visible: cap.isSuper; code: 0xEBCA; size: 14; color: Theme.accent }
        Text {
            id: txt
            anchors.centerIn: parent
            visible: !cap.isSuper
            text: cap.label
            color: cap.mod ? Theme.accent : Theme.fg
            font.family: Theme.fontMono
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    // ---------- Grupo ----------
    component GroupBlock: ColumnLayout {
        id: gb
        required property var modelData
        spacing: 1
        Layout.fillWidth: true

        RowLayout {
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            spacing: 8
            Label { text: Tr.t(gb.modelData.g); font.pixelSize: Theme.fontSize + 1; font.weight: Font.Bold; color: gb.modelData.g === "warch" ? Theme.accent : Theme.fg }
            Label { text: gb.modelData.rows.length; mono: true; muted: true; font.pixelSize: Theme.fontSize - 4 }
        }

        Repeater {
            model: gb.modelData.rows
            delegate: Rectangle {
                id: row
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 8
                color: rowArea.containsMouse ? Qt.rgba(0.9, 0.89, 0.86, 0.04) : "transparent"
                MouseArea { id: rowArea; anchors.fill: parent; hoverEnabled: true }

                RowLayout {
                    anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                    spacing: 10

                    Row {
                        Layout.preferredWidth: 196
                        spacing: 4
                        Repeater {
                            model: row.modelData.mods.concat([row.modelData.key])
                            delegate: Row {
                                required property string modelData
                                required property int index
                                spacing: 4
                                Text { visible: index > 0; text: "+"; color: Theme.dim; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                                KeyCap { label: modelData; mod: index < row.modelData.mods.length }
                            }
                        }
                    }
                    Label { text: row.modelData.d; elide: Text.ElideRight; Layout.fillWidth: true; font.pixelSize: Theme.fontSize - 1 }
                    Rectangle {
                        visible: row.modelData.conflict
                        implicitWidth: cl.implicitWidth + 12; implicitHeight: 18; radius: 9
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.bad
                        Label { id: cl; anchors.centerIn: parent; text: Tr.t("conflicto"); mono: true; color: Theme.bad; font.pixelSize: 10 }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors { fill: parent; margins: 20; topMargin: 14 }
        spacing: 12

        // Búsqueda
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            radius: 22
            color: Theme.base
            border.width: 1
            border.color: search.activeFocus ? Theme.accent : Theme.line

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                spacing: 10
                Icon { code: 0xF0349; size: 17; color: Theme.dim }
                TextInput {
                    id: search
                    focus: true
                    Layout.fillWidth: true
                    color: Theme.fg
                    font.family: Theme.fontUi
                    font.pixelSize: Theme.fontSize
                    onTextEdited: root.query = text
                    Keys.onTabPressed: {
                        const names = ["Todos"].concat(root.groups.map(G => G.g));
                        root.group = names[(names.indexOf(root.group) + 1) % names.length];
                    }
                    Keys.onDownPressed: flick.contentY = Math.min(flick.contentHeight - flick.height, flick.contentY + 60)
                    Keys.onUpPressed: flick.contentY = Math.max(0, flick.contentY - 60)
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text === ""
                        text: Tr.t("Buscar un atajo: «captura», «workspace», «vpn»…")
                        muted: true
                    }
                }
                Label { text: root.query || root.group !== "Todos" ? Tr.f("%1 de %2", root.matches, root.total) : Tr.f("%1 atajos", root.total); mono: true; muted: true; font.pixelSize: Theme.fontSize - 3 }
            }
        }

        // Grupos
        Flow {
            Layout.fillWidth: true
            spacing: 5
            Repeater {
                model: ["Todos"].concat(root.groups.map(G => G.g))
                delegate: Chip {
                    id: grpChip
                    required property string modelData
                    readonly property bool current: root.group === modelData
                    implicitHeight: 28
                    padX: 11
                    color: current ? Theme.surface2 : hovered ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
                    border.width: 1
                    border.color: current ? Theme.accent : Theme.line
                    onClicked: root.group = modelData
                    Label { text: Tr.t(grpChip.modelData); font.pixelSize: Theme.fontSize - 2; font.weight: Font.DemiBold; color: grpChip.current ? Theme.accent : Theme.dim }
                }
            }
        }

        // Lista en dos columnas
        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: cols.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            RowLayout {
                id: cols
                width: flick.width
                spacing: 24

                Repeater {
                    model: root.columns
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.alignment: Qt.AlignTop
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        spacing: 10
                        Repeater { model: parent.modelData; delegate: GroupBlock {} }
                    }
                }
            }

            Label {
                anchors.centerIn: parent
                visible: root.matches === 0 && root.total > 0
                text: Tr.f("Ningún atajo coincide con «%1»", root.query)
                muted: true
            }
        }

        RowLayout {
            Label { text: Tr.t("Tab cambia de grupo · ↑↓ desplaza · Esc cierra"); mono: true; muted: true; font.pixelSize: Theme.fontSize - 4; Layout.fillWidth: true }
            Label { text: Tr.t("fuente: hyprctl binds"); mono: true; muted: true; font.pixelSize: Theme.fontSize - 4 }
        }
    }
}
