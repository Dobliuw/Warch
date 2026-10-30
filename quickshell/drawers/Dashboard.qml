import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.bar
import qs.services

// Dashboard (clic en el logo): Inicio, Rendimiento, Pentest y Estudio.
Drawer {
    id: root

    contentWidth: Math.min(880, modelData.width - Theme.corner * 2 - 24)
    contentHeight: Math.min(470, modelData.height - Theme.barHeight - 30)
    shown: Ui.open === "dashboard"
    onCloseRequested: Ui.close()

    property int tab: 0
    readonly property var tabs: [
        { name: Tr.t("Inicio"), icon: 0xF02DC },
        { name: Tr.t("Rendimiento"), icon: 0xF04C5 },
        { name: "Pentest", icon: 0xF04FE },
        { name: Tr.t("Estudio"), icon: 0xF14F7 }
    ]
    readonly property string targetDir: Store.target ? Theme.pentestDir + "/" + (Store.target.name || Store.target.ip) : ""

    function notify(title, body) { Quickshell.execDetached(["notify-send", "-a", "warch", title, body]); }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    onOpened: tabRepeater.itemAt(root.tab)?.forceActiveFocus()

    ColumnLayout {
        anchors { fill: parent; margins: 18; topMargin: 8 }
        // Teclado: 1–4 cambian de pestaña; Tab/flechas recorren; Enter activa
        Keys.onPressed: event => {
            const n = event.key - Qt.Key_1;
            if (n >= 0 && n < root.tabs.length && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
                root.tab = n;
                tabRepeater.itemAt(n).forceActiveFocus();
                event.accepted = true;
            }
        }
        spacing: 14

        // ---------- Pestañas ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                id: tabRepeater
                model: root.tabs
                delegate: Item {
                    id: t
                    required property var modelData
                    required property int index
                    readonly property bool on: root.tab === index
                    Layout.fillWidth: true
                    implicitHeight: 54

                    Column {
                        anchors.centerIn: parent
                        spacing: 3
                        Icon { anchors.horizontalCenter: parent.horizontalCenter; code: t.modelData.icon; size: 18; color: t.on ? Theme.accent : tArea.containsMouse ? Theme.fg : Theme.dim }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: t.modelData.name; font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold; color: t.on ? Theme.accent : tArea.containsMouse ? Theme.fg : Theme.dim }
                    }
                    Rectangle {
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                        width: t.on ? parent.width * 0.4 : 0; height: 3; radius: 1.5
                        color: Theme.accent
                        Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
                    }
                    MouseArea { id: tArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.tab = t.index }

                    activeFocusOnTab: true
                    readonly property int radius: 10
                    function go(i) { root.tab = (i + root.tabs.length) % root.tabs.length; tabRepeater.itemAt(root.tab).forceActiveFocus(); }
                    function enter() { root.tab = t.index; const n = nextItemInFocusChain(true); if (n) n.forceActiveFocus(); }
                    Keys.onLeftPressed: go(t.index - 1)
                    Keys.onRightPressed: go(t.index + 1)
                    Keys.onReturnPressed: enter()
                    Keys.onEnterPressed: enter()
                    Keys.onSpacePressed: enter()
                    Keys.onDownPressed: enter()
                    FocusRing {}
                }
            }
        }
        Rectangle { Layout.fillWidth: true; Layout.topMargin: -14; implicitHeight: 1; color: Theme.line }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.tab

            // ================= Inicio =================
            GridLayout {
                columns: 3
                rowSpacing: 10
                columnSpacing: 10

                Tile {
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 330
                    RowLayout {
                        spacing: 16
                        Image {
                            source: Qt.resolvedUrl("../assets/w_logo.svg")
                            sourceSize.height: 150
                            Layout.preferredHeight: 76
                            Layout.preferredWidth: 76 * 805 / 655
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }
                        GridLayout {
                            columns: 2
                            rowSpacing: 4
                            columnSpacing: 10
                            Label { text: "os"; mono: true; color: Theme.accent }   Label { text: "Arch Linux · " + Sys.kernel }
                            Label { text: "wm"; mono: true; color: Theme.accent }   Label { text: "Hyprland" }
                            Label { text: "up"; mono: true; color: Theme.accent }   Label { text: Sys.fmtUptime() }
                            Label { text: "pkg"; mono: true; color: Theme.accent }  Label { text: Sys.updates < 0 ? "…" : Tr.f("%1 actualizaciones", Sys.updates) }
                        }
                    }
                }

                Tile {
                    title: Tr.t("ahora")
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 270
                    Label { text: Qt.formatDateTime(clock.date, "HH:mm"); font.pixelSize: 48; font.weight: Font.ExtraBold; font.features: { "tnum": 1 } }
                    Label { text: Qt.locale().toString(clock.date, Tr.fmtLongDate); muted: true }
                }

                Tile {
                    Layout.rowSpan: 2
                    Layout.fillHeight: true; Layout.preferredWidth: 224
                    spacing: 10

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 120; implicitHeight: 120

                        ClippingRectangle {
                            id: disc
                            anchors.fill: parent
                            radius: width / 2
                            color: Theme.surface2
                            RotationAnimator on rotation {
                                from: 0; to: 360; duration: 12000; loops: Animation.Infinite
                                running: Media.player?.isPlaying ?? false
                            }
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: "#5b4f8e" }
                                    GradientStop { position: 0.5; color: Theme.accent }
                                    GradientStop { position: 1; color: Theme.accent2 }
                                }
                            }
                            Image {
                                anchors.fill: parent
                                source: Media.player?.trackArtUrl ?? ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                        }
                        Rectangle { anchors.centerIn: parent; width: 22; height: 22; radius: 11; color: Theme.base }
                    }
                    Label { text: Media.title || Tr.t("Sin música"); font.weight: Font.Bold; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
                    Label { text: Media.artist; muted: true; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true; visible: text !== "" }
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        Chip { padX: 7; onClicked: Media.player?.previous(); Icon { code: 0xF04AE; size: 17 } }
                        Chip { padX: 7; active: true; onClicked: Media.player?.togglePlaying(); Icon { code: Media.player?.isPlaying ? 0xF03E4 : 0xF040A; color: Theme.accent; size: 17 } }
                        Chip { padX: 7; onClicked: Media.player?.next(); Icon { code: 0xF04AD; size: 17 } }
                    }
                }

                Tile {
                    title: "TO-DOsh · en foco"
                    Layout.columnSpan: 2
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Label {
                        text: Todo.focus?.task?.title ?? Tr.t("Ninguna tarea en foco")
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: Font.Bold
                        muted: !Todo.focus
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Label {
                        visible: !!Todo.focus
                        text: Tr.f("%1 · sesión %2 · total %3", Todo.focus?.task?.project ?? "", Todo.fmtDuration(Todo.focus?.session_seconds), Todo.fmtDuration(Todo.focus?.total_seconds))
                        muted: true
                    }
                }
            }

            // ================= Rendimiento =================
            RowLayout {
                spacing: 10
                Item { Layout.fillWidth: true }
                Gauge {
                    ratio: Sys.gpuTemp / 100; color: Theme.accent
                    value: Sys.gpuTemp + "°"; label: "GPU"; sub: Tr.f("%1%\nuso", Sys.gpuUtil)
                }
                Item { Layout.fillWidth: true }
                Gauge {
                    implicitWidth: 210; implicitHeight: 210
                    ratio: Sys.cpuTemp / 100; color: Theme.accent2
                    value: Sys.cpuTemp + "°"; label: "CPU"; sub: Tr.f("%1%\nuso", Sys.cpu)
                }
                Item { Layout.fillWidth: true }
                Gauge {
                    ratio: Sys.ramTotalG ? Sys.ramUsedG / Sys.ramTotalG : 0; color: Theme.ok
                    value: Sys.ramUsedG.toFixed(1) + "G"; label: Tr.f("RAM de %1G", Math.round(Sys.ramTotalG))
                    sub: Tr.f("%1G\ndisco", Math.round(Sys.diskUsedG))
                }
                Item { Layout.fillWidth: true }
            }

            // ================= Pentest =================
            RowLayout {
                spacing: 10

                Tile {
                    title: Tr.t("objetivo")
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1

                    Label {
                        visible: !Store.target
                        text: Tr.t("Sin objetivo. Fíjalo con:\nwarch target set <ip> <nombre>")
                        muted: true
                        mono: true
                    }
                    Label { visible: !!Store.target; text: Store.target?.ip ?? ""; mono: true; font.pixelSize: 30; font.weight: Font.DemiBold }
                    Label { visible: !!Store.target; text: (Store.target?.name ?? "") + (Store.target?.name ? ".htb" : ""); font.weight: Font.DemiBold; font.pixelSize: Theme.fontSize + 2 }
                    Label {
                        visible: !!Store.target
                        text: Tr.f("desde hace %1", Todo.fmtDuration(Pomo.now - (Store.target?.since ?? Pomo.now)))
                        muted: true
                    }
                    Item { Layout.fillHeight: true }
                    RowLayout {
                        spacing: 8
                        Rectangle { implicitWidth: 8; implicitHeight: 8; radius: 4; color: Sys.tun0 ? Theme.ok : Theme.bad }
                        Label { text: Sys.tun0 ? "LHOST " + Sys.tun0 + " (" + Sys.tunName + ")" : Sys.nordUp ? Tr.f("solo NordVPN (nordlynx %1): sin LHOST", Sys.nordIp) : Tr.t("sin VPN de laboratorio"); mono: true; muted: !Sys.tun0 }
                    }
                }

                Tile {
                    title: Tr.t("acciones")
                    Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1.2

                    GridLayout {
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 6
                        Layout.fillWidth: true

                        Repeater {
                            model: [
                                { icon: 0xF018F, text: Tr.t("Copiar LHOST"), needs: "tun0" },
                                { icon: 0xF070D, text: "nc -lvnp 4444", needs: "" },
                                { icon: 0xF048B, text: "http.server :8000", needs: "" },
                                { icon: 0xF03EB, text: Tr.t("Añadir a /etc/hosts"), needs: "target" },
                                { icon: 0xF0257, text: Tr.t("Crear carpeta"), needs: "target" },
                                { icon: 0xF082E, text: Tr.t("Abrir nota"), needs: "target" }
                            ]
                            delegate: Chip {
                                id: a
                                required property var modelData
                                required property int index
                                readonly property bool enabled_: modelData.needs === "" || (modelData.needs === "tun0" ? !!Sys.tun0 : !!Store.target)
                                Layout.fillWidth: true
                                implicitHeight: 42
                                color: hovered && enabled_ ? Theme.surface2 : Qt.rgba(1, 1, 1, 0.035)
                                opacity: enabled_ ? 1 : 0.4
                                onClicked: if (enabled_) root.action(index)
                                Icon { code: a.modelData.icon; size: 16; color: a.hovered ? Theme.accent : Theme.fg }
                                Label { text: a.modelData.text; Layout.fillWidth: true }
                            }
                        }
                    }
                    Label {
                        text: Store.target ? Tr.f("carpeta: %1", root.targetDir.replace(Quickshell.env("HOME"), "~")) : ""
                        mono: true; muted: true; font.pixelSize: Theme.fontSize - 3
                    }
                }
            }

            // ================= Estudio =================
            RowLayout {
                spacing: 10

                Tile {
                    title: "pomodoro " + Pomo.focusMin + "/" + Pomo.breakMin
                    Layout.fillHeight: true; Layout.preferredWidth: 280

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 170; implicitHeight: 170
                        Canvas {
                            id: pring
                            anchors.fill: parent
                            property real p: Pomo.progress
                            onPChanged: requestPaint()
                            onPaint: {
                                const c = getContext("2d"), r = width / 2 - 7;
                                c.reset(); c.lineWidth = 10; c.lineCap = "round";
                                c.strokeStyle = Theme.surface2; c.beginPath(); c.arc(width / 2, height / 2, r, 0, Math.PI * 2); c.stroke();
                                c.strokeStyle = Pomo.inFocus ? Theme.accent2 : Theme.ok;
                                c.beginPath(); c.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p); c.stroke();
                            }
                        }
                        Column {
                            anchors.centerIn: parent
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: Pomo.label; mono: true; font.pixelSize: 30; font.weight: Font.DemiBold }
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: Pomo.running ? Tr.f("%1 · sesión %2", Tr.t(Pomo.phase), Pomo.session) : Tr.t("detenido"); muted: true }
                        }
                    }
                    Chip {
                        Layout.alignment: Qt.AlignHCenter
                        active: true
                        padX: 16
                        onClicked: Store.run(["pomo", Pomo.running ? "stop" : "start"])
                        Icon { code: Pomo.running ? 0xF04DB : 0xF040A; size: 16; color: Theme.accent2 }
                        Label { text: Pomo.running ? Tr.t("Detener") : Tr.t("Empezar"); color: Theme.accent2; font.weight: Font.DemiBold }
                    }
                }

                Tile {
                    title: Tr.f("tareas · %1 abiertas", Todo.tasks.length)
                    Layout.fillWidth: true; Layout.fillHeight: true

                    Repeater {
                        model: Todo.tasks.slice(0, 7)
                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 38
                            radius: 9
                            color: rowArea.containsMouse ? Theme.surface2 : "transparent"
                            MouseArea { id: rowArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Todo.focusOn(row.modelData.id) }
                            // Teclado: Enter enfoca la tarea, Ctrl+Enter la marca como hecha
                            activeFocusOnTab: true
                            function move(forward) { const n = nextItemInFocusChain(forward); if (n) n.forceActiveFocus(); }
                            function act(event) { (event.modifiers & Qt.ControlModifier) ? Todo.done(row.modelData.id) : Todo.focusOn(row.modelData.id); }
                            Keys.onReturnPressed: event => act(event)
                            Keys.onEnterPressed: event => act(event)
                            Keys.onDownPressed: move(true)
                            Keys.onUpPressed: move(false)
                            FocusRing {}
                            RowLayout {
                                anchors { fill: parent; leftMargin: 8; rightMargin: 10 }
                                spacing: 10
                                Rectangle {
                                    implicitWidth: 16; implicitHeight: 16; radius: 8
                                    color: doneArea.containsMouse ? Theme.ok : "transparent"
                                    border.width: 2
                                    border.color: doneArea.containsMouse ? Theme.ok : row.modelData.status === "IN_PROGRESS" ? Theme.accent2 : Theme.dim
                                    MouseArea { id: doneArea; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Todo.done(row.modelData.id) }
                                }
                                Label { text: row.modelData.title; elide: Text.ElideRight; Layout.fillWidth: true; font.weight: Todo.focus?.task?.id === row.modelData.id ? Font.Bold : Font.Normal }
                                Label { text: row.modelData.status === "IN_PROGRESS" ? Tr.t("en curso") : row.modelData.priority; mono: true; muted: true; font.pixelSize: Theme.fontSize - 3 }
                            }
                        }
                    }
                }
            }
        }
    }

    function action(i) {
        const t = Store.target, dir = targetDir, host = t ? (t.name || "target") + ".htb" : "";
        switch (i) {
        case 0:
            Quickshell.execDetached(["wl-copy", Sys.tun0]);
            notify(Tr.t("LHOST copiada"), Sys.tun0);
            break;
        case 1:
            Quickshell.execDetached(["kitty", "--title", "nc 4444", "-e", "nc", "-lvnp", "4444"]);
            break;
        case 2:
            Quickshell.execDetached(["sh", "-c", "d='" + (dir ? dir + "/content" : "") + "'; [ -d \"$d\" ] || d=\"$HOME\"; exec kitty --title 'http.server 8000' -d \"$d\" -e python -m http.server 8000"]);
            break;
        case 3:
            Quickshell.execDetached(["kitty", "--title", "/etc/hosts", "-e", "sh", "-c", "echo '" + t.ip + " " + host + "' | sudo tee -a /etc/hosts && echo && echo '" + Tr.t("Listo.") + "'; read -r -p '" + Tr.t("Enter para cerrar") + "' _"]);
            break;
        case 4:
            Quickshell.execDetached(["mkdir", "-p", dir + "/nmap", dir + "/content", dir + "/exploits"]);
            notify(Tr.t("Carpeta creada"), dir.replace(Quickshell.env("HOME"), "~") + "/{nmap,content,exploits}");
            break;
        case 5:
            Quickshell.execDetached(["xdg-open", "obsidian://open?vault=" + encodeURIComponent(Theme.obsidianVault) + "&file=" + encodeURIComponent(t.name || t.ip)]);
            break;
        }
    }
}
