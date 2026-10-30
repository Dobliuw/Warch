pragma Singleton

import QtQuick
import Quickshell

// Traducciones de la interfaz según el idioma del sistema (LC_MESSAGES / LANG).
// Los textos fuente están en español; `t()` devuelve la traducción y `f()` además reemplaza %1, %2…
// Las descripciones de los atajos de hyprland.lua («Grupo · Texto») también pasan por acá.
Singleton {
    id: root

    readonly property string lang: (Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG") || "en").slice(0, 2)
    readonly property bool es: lang === "es"
    readonly property var dict: es ? ({}) : en

    function t(s) { return dict[s] ?? s; }
    function f(s) {
        let out = t(s);
        for (let i = 1; i < arguments.length; i++) out = out.replace("%" + i, arguments[i]);
        return out;
    }
    // Descripción de atajo «Grupo · Texto» → traducida por partes
    function bind(d) { return d.split(" · ").map(p => t(p)).join(" · "); }

    // Formatos de fecha
    readonly property string fmtBarDate: es ? "ddd d MMM" : "ddd, MMM d"
    readonly property string fmtLongDate: es ? "dddd d 'de' MMMM" : "dddd, MMMM d"
    readonly property string fmtDayNum: es ? "dddd d" : "dddd d"
    readonly property var weekLetters: es ? ["L", "M", "X", "J", "V", "S", "D"] : ["M", "T", "W", "T", "F", "S", "S"]

    readonly property var en: ({
        // Barra
        "sin objetivo": "no target", "sin VPN": "no VPN", "iniciar": "start", "sin tarea enfocada": "no focused task",
        "IP del objetivo": "Target IP", "IP de NordVPN": "NordVPN IP", "%1 copiada": "%1 copied", "LHOST copiada": "LHOST copied",
        "foco": "focus", "descanso": "break", "detenido": "stopped",
        "Enter para cerrar": "Press Enter to close", "Listo.": "Done.",
        // Panel vertical
        "hoy": "today", "TO-DOsh · en foco": "TO-DOsh · in focus", "soltar": "release", "abrir": "open",
        "Ninguna tarea en foco. Haz clic en el título de una tarea para enfocarla.": "No task in focus. Click a task title to focus it.",
        "sesión %1": "session %1", "total %1": "total %1", "Tareas · %1 abiertas": "Tasks · %1 open", "actualizar": "refresh",
        "en curso": "in progress", "bloqueada": "blocked", "Proyectos": "Projects",
        "Notificaciones · %1": "Notifications · %1", "limpiar": "clear", "Sin notificaciones.": "No notifications.",
        "Música · %1": "Music · %1", "Sin título": "Untitled",
        // Dashboard
        "Inicio": "Home", "Rendimiento": "Performance", "Estudio": "Study", "%1 actualizaciones": "%1 updates", "ahora": "now",
        "Sin música": "No music", "Ninguna tarea en foco": "No task in focus", "%1 · sesión %2 · total %3": "%1 · session %2 · total %3",
        "%1%\nuso": "%1%\nusage", "RAM de %1G": "RAM of %1G", "%1G\ndisco": "%1G\ndisk", "objetivo": "target",
        "Sin objetivo. Fíjalo con:\nwarch target set <ip> <nombre>": "No target. Set one with:\nwarch target set <ip> <name>",
        "desde hace %1": "for %1", "solo NordVPN (nordlynx %1): sin LHOST": "NordVPN only (nordlynx %1): no LHOST",
        "sin VPN de laboratorio": "no lab VPN", "acciones": "actions", "Copiar LHOST": "Copy LHOST", "Añadir a /etc/hosts": "Add to /etc/hosts",
        "Crear carpeta": "Create folder", "Abrir nota": "Open note", "carpeta: %1": "folder: %1", "%1 · sesión %2": "%1 · session %2",
        "Detener": "Stop", "Empezar": "Start", "tareas · %1 abiertas": "tasks · %1 open", "Carpeta creada": "Folder created",
        // Ajustes
        "No molestar": "Do not disturb", "Luz nocturna": "Night light", "Micrófono": "Microphone", "apagado": "off", "apagada": "off",
        "servicio detenido": "service stopped", "encendido": "on", "silencio": "silenced", "silenciado": "muted", "activo": "active",
        "SALIDA DE AUDIO": "AUDIO OUTPUT", "Conectando…": "Connecting…", "Conectado": "Connected", "Desconectado": "Disconnected",
        "sin .ovpn": "no .ovpn", "tu IP real es visible": "your real IP is visible", "Desconectar": "Disconnect",
        "Conectar a HTB": "Connect to HTB", "Conexión rápida": "Quick connect", "PAÍSES": "COUNTRIES", "SERVIDOR": "SERVER",
        "Falta ~/.config/warch/vpn/htb.ovpn": "Missing ~/.config/warch/vpn/htb.ovpn", "Copiar LHOST %1": "Copy LHOST %1",
        "NordVPN también está conectada. Si las máquinas no responden, desconéctala.": "NordVPN is also connected. If the machines don't respond, disconnect it.",
        "tecnología: %1": "technology: %1", "Canadá": "Canada", "Estados Unidos": "United States",
        // Lanzador
        "Esquema": "Scheme", "Cambiar la paleta de colores": "Change the color palette", "Cambiar el wallpaper": "Change the wallpaper",
        "Variante": "Variant", "Cambiar la variante del esquema": "Change the scheme variant", "Transparencia": "Transparency",
        "Transparencia de la barra y los paneles": "Bar and panel transparency", "Claro": "Light", "Pasar al modo claro": "Switch to light mode",
        "Oscuro": "Dark", "Pasar al modo oscuro": "Switch to dark mode", "Apagar (ahora %1K)": "Turn off (now %1K)", "Encender": "Turn on",
        "Modo de la barra": "Bar mode", "Sistema, pentest o estudio": "System, pentest or study", "Atajos": "Shortcuts",
        "Abrir el cheat sheet": "Open the cheat sheet", "Bloquear": "Lock", "Bloquear la sesión": "Lock the session",
        "Suspender": "Suspend", "Bloquear y suspender": "Lock and suspend", "Sesión": "Session",
        "Apagar, reiniciar, cerrar sesión…": "Power off, reboot, log out…", "Desde el wallpaper": "From wallpaper",
        "Colores sacados del wallpaper principal": "Colors taken from the main wallpaper", "Tonal": "Tonal",
        "Acentos suaves (por defecto)": "Soft accents (default)", "Vibrante": "Vibrant", "Acentos más saturados": "More saturated accents",
        "Neutral": "Neutral", "Casi sin color": "Almost no color", "Monocromo": "Monochrome", "Solo grises": "Grays only",
        "Sólida": "Solid", "Deja ver el wallpaper": "Shows the wallpaper through", "Modo": "Mode", "Esc vuelve": "Esc goes back",
        "Buscar aplicaciones · escribe > para comandos": "Search apps · type > for commands",
        "Sistema": "System", "Pentest": "Pentest",
        "Grafito lavanda": "Lavender graphite", "Circuito": "Circuit", "Islas": "Islands", "Neón": "Neon", "Bosque": "Forest", "Ámbar": "Amber",
        // Cheat sheet
        "Todos": "All", "Modos": "Modes", "Ventanas": "Windows", "Multimedia": "Media", "Captura": "Screenshot", "Otros": "Other",
        "conflicto": "conflict", "Buscar un atajo: «captura», «workspace», «vpn»…": "Search a shortcut: “screenshot”, “workspace”, “vpn”…",
        "Ningún atajo coincide con «%1»": "No shortcut matches “%1”", "Tab cambia de grupo · ↑↓ desplaza · Esc cierra": "Tab switches group · ↑↓ scrolls · Esc closes",
        "fuente: hyprctl binds": "source: hyprctl binds", "%1 de %2": "%1 of %2", "%1 atajos": "%1 shortcuts",
        "Clic izq": "Left click", "Clic der": "Right click", "Rueda ↓": "Wheel ↓", "Rueda ↑": "Wheel ↑", "Brillo +": "Bright +",
        "Brillo −": "Bright −", "Siguiente": "Next", "Pausa": "Pause", "Anterior": "Previous", "Impr": "Print",
        // Descripciones de atajos (hyprland.lua)
        "Luz nocturna: más cálida": "Night light: warmer", "Luz nocturna: más fría": "Night light: cooler",
        "Monitores (como Windows + P)": "Monitors (like Windows + P)", "Región con swappy": "Region with swappy",
        "Historial de wlsnarf": "wlsnarf history", "Cerrar": "Close", "Salir de Hyprland": "Exit Hyprland", "Archivos (dolphin)": "Files (dolphin)",
        "Flotante / mosaico": "Floating / tiled", "Lanzador (apps y comandos con >)": "Launcher (apps, and commands with >)",
        "Pseudo-mosaico": "Pseudo-tile", "Maximizar": "Maximize", "Pantalla completa": "Fullscreen",
        "Foco a la izquierda": "Focus left", "Foco a la derecha": "Focus right", "Foco arriba": "Focus up", "Foco abajo": "Focus down",
        "Mover a la izquierda": "Move left", "Mover a la derecha": "Move right", "Mover arriba": "Move up", "Mover abajo": "Move down",
        "Ir al workspace": "Go to workspace", "Mover ventana al workspace": "Move window to workspace",
        "Mover ventana al scratchpad": "Move window to scratchpad", "Siguiente (rueda)": "Next (wheel)", "Anterior (rueda)": "Previous (wheel)",
        "Mover con el mouse": "Move with the mouse", "Redimensionar con el mouse": "Resize with the mouse",
        "Subir volumen": "Volume up", "Bajar volumen": "Volume down", "Silenciar": "Mute", "Silenciar micrófono": "Mute microphone",
        "Subir brillo": "Brightness up", "Bajar brillo": "Brightness down", "Siguiente tema": "Next track", "Reproducir / pausa": "Play / pause",
        "Tema anterior": "Previous track", "Vista general de workspaces": "Workspace overview", "Ajustes rápidos y VPN": "Quick settings and VPN",
        "Menú de sesión": "Session menu", "Panel vertical (calendario, TO-DOsh)": "Side panel (calendar, TO-DOsh)",
        "Reiniciar la shell": "Restart the shell", "Atajos (cheat sheet)": "Shortcuts (cheat sheet)",
        "Siguiente (sistema, pentest, estudio)": "Next (system, pentest, study)", "Copiar IP del objetivo": "Copy target IP",
        "Copiar LHOST (tun*)": "Copy LHOST (tun*)", "Empezar / detener pomodoro": "Start / stop pomodoro",
        // Sesión
        "Cerrar sesión": "Log out", "Monitor del sistema": "System monitor", "Hibernar": "Hibernate", "Apagar": "Power off",
        "Reiniciar": "Reboot", "Reiniciar al firmware": "Reboot to firmware",
        "Flechas para moverte, Enter para elegir\nEsc o clic afuera para cancelar": "Arrow keys to move, Enter to select\nEsc or click outside to cancel",
        "Presiona Enter o haz clic otra vez para confirmar": "Press Enter or click again to confirm",
        // Permisos y bloqueo
        "Se necesitan permisos": "Authentication required", "Contraseña": "Password", "Cancelar": "Cancel", "Autorizar": "Authorize",
        "Contraseña de %1": "Password for %1", "Verificando…": "Verifying…", "Vista previa · Esc para salir": "Preview · Esc to exit",
        "Contraseña incorrecta": "Wrong password", "Demasiados intentos": "Too many attempts", "Error de PAM": "PAM error",
        "%1 notificaciones": "%1 notifications", "VPN apagada": "VPN off",
        "Bloqueo en vista previa": "Lock in preview mode",
        "Desbloquea una vez con tu contraseña para activar el bloqueo real. Así nunca quedas afuera.": "Unlock once with your password to enable the real lock. That way you never get locked out.",
        // Wallpapers
        "Aplicado en todos los monitores": "Applied to all monitors", "Aplicado en %1": "Applied to %1", "Buscar wallpaper": "Search wallpaper",
        "←→ elegir · Enter este monitor · Shift+Enter todos · %1 en ~/.config/warch/wallpapers": "←→ choose · Enter this monitor · Shift+Enter all · %1 in ~/.config/warch/wallpapers",
        // Notificaciones de servicios
        "Descanso de %1 min": "%1 min break", "Sesión %1: %2 min de foco": "Session %1: %2 min of focus",
        "VPN de HTB": "HTB VPN", "openvpn terminó con código %1": "openvpn exited with code %1"
    })
}
