pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Tokens visuales de warch. La paleta es dinámica: esquema, modo, variante y transparencia salen de
// ~/.local/state/warch/theme.json (lo escribe `warch theme …`) y todo se recalcula en vivo.
Singleton {
    id: root

    // ---------- Ajustes (warch theme) ----------
    property var cfg: ({})
    readonly property string scheme: cfg.scheme ?? "grafito"
    readonly property string mode: cfg.mode ?? "dark"              // "dark" | "light"
    readonly property string variant: cfg.variant ?? "tonal"       // "tonal" | "vibrante" | "neutral" | "mono"
    readonly property real opacity: (cfg.opacity ?? 100) / 100     // transparencia de banda y paneles
    readonly property bool light: mode === "light"

    readonly property var schemes: ({
        grafito:  { name: "Grafito lavanda", base: "#121318", surface: "#1b1c23", surface2: "#272832", fg: "#e7e4dc", dim: "#9293a1", accent: "#bdb5ec", accent2: "#e8c88f" },
        circuito: { name: "Circuito",        base: "#0e1111", surface: "#171a19", surface2: "#222725", fg: "#e7e4dc", dim: "#8f948d", accent: "#a8cfb4", accent2: "#e3b896" },
        islas:    { name: "Islas",           base: "#1b1e26", surface: "#1d2029", surface2: "#282c37", fg: "#ece9f2", dim: "#9a98a8", accent: "#f0bfa8", accent2: "#a9d8c6" },
        neon:     { name: "Neón",            base: "#120f1a", surface: "#1a1624", surface2: "#272035", fg: "#ece6f5", dim: "#9a90ad", accent: "#f27aa8", accent2: "#8fb8ff" },
        bosque:   { name: "Bosque",          base: "#0f1411", surface: "#161c18", surface2: "#212a24", fg: "#e3e8df", dim: "#8d9a8f", accent: "#9fd18b", accent2: "#e0c27a" },
        ambar:    { name: "Ámbar",           base: "#14110d", surface: "#1c1813", surface2: "#29231b", fg: "#efe6d6", dim: "#a19582", accent: "#f0b45e", accent2: "#9ec3d6" }
    })
    readonly property var pal: scheme === "wallpaper" && cfg.custom ? cfg.custom : (schemes[scheme] ?? schemes.grafito)

    // La variante cambia la saturación de los acentos; en modo claro se oscurecen para contrastar
    function vary(c) {
        const col = Qt.color(c);
        let s = col.hslSaturation, l = col.hslLightness;
        if (variant === "vibrante") s = Math.min(1, s * 1.4 + 0.08);
        else if (variant === "neutral") s = s * 0.4;
        else if (variant === "mono") s = 0;
        if (light) l = Math.max(0.3, l - 0.34);
        return Qt.hsla(Math.max(0, col.hslHue), s, l, 1);
    }

    // ---------- Paleta ----------
    readonly property color accent: vary(pal.accent)
    readonly property color accent2: vary(pal.accent2)
    readonly property color base: light ? Qt.tint("#efeee9", Qt.rgba(accent.r, accent.g, accent.b, 0.07)) : pal.base
    readonly property color surface: light ? Qt.tint("#fbfaf7", Qt.rgba(accent.r, accent.g, accent.b, 0.05)) : pal.surface
    readonly property color surface2: light ? Qt.tint("#e3e1db", Qt.rgba(accent.r, accent.g, accent.b, 0.1)) : pal.surface2
    readonly property color fg: light ? "#1d1c22" : pal.fg
    readonly property color dim: light ? "#686774" : pal.dim
    readonly property color ok: light ? "#2e8653" : "#9fd6b4"
    readonly property color bad: light ? "#c0433d" : "#f08a8a"
    readonly property color line: light ? Qt.rgba(0, 0, 0, 0.09) : Qt.rgba(fg.r, fg.g, fg.b, 0.08)
    // Banda y paneles: la superficie con la transparencia elegida
    readonly property color panel: Qt.rgba(surface.r, surface.g, surface.b, opacity)

    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/warch/theme.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { try { root.cfg = JSON.parse(text()); } catch (e) { root.cfg = {}; } }
        onLoadFailed: root.cfg = {}
    }

    // Tipografía
    readonly property string fontUi: "Manrope"
    readonly property string fontMono: "IBM Plex Mono"
    readonly property string fontIcon: "Hack Nerd Font Propo"

    // Medidas (px)
    readonly property int barHeight: 55
    readonly property int marginTop: 9
    readonly property int marginSide: 11
    readonly property int gap: 4
    readonly property int pad: 5
    readonly property int fontSize: 14
    readonly property int iconSize: 19
    readonly property int radius: 13
    readonly property int radiusInner: Math.round(radius * 0.7)
    readonly property int chipHeight: barHeight - 20

    // Animación moderada
    readonly property int anim: 180
    readonly property int drawerAnim: 320

    // Marco (ronda 3): la barra es una banda; los paneles cuelgan de ella con esquinas cóncavas
    readonly property bool frame: true
    readonly property int frameWidth: 0         // grosor del marco en los otros bordes
    readonly property int corner: 18            // radio de las esquinas cóncavas
    readonly property int drawerRadius: 22

    // Pentest
    readonly property string pentestDir: Quickshell.env("HOME") + "/htb"
    readonly property string obsidianVault: "Hacking"
    readonly property var vpnCountries: ["Canada", "United_States", "Argentina"]
}
