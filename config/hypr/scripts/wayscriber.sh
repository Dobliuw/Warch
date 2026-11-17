#!/usr/bin/env bash
# Pizarra / anotación en pantalla (wayscriber) para warch — alternativa a Epic Pen.
# wayscriber es de instancia única, así que cada modo arranca "en blanco" (sin acumular):
#
#   clean  (SUPER+ALT+A)  Lápiz one-shot (capta los clicks para dibujar): siempre en blanco; Escape borra y cierra.
#   pass   (SUPER+ALT+L)  Transparente / passthrough: entra en blanco (daemon nuevo) y
#                         deja pasar los clicks; otra vez = sale y descarta.
#   draw   (SUPER+ALT+S)  Fija / suelta el trazo mientras estás en passthrough.
#
# Nunca restaura "la sesión pasada": todo corre con --no-resume-session.
set -u
WS=wayscriber

command -v "$WS" >/dev/null || { notify-send "wayscriber no está instalado (yay -S wayscriber-bin)" 2>/dev/null; exit 1; }

# Mata toda instancia y espera a que muera de verdad (si no, --active se defiere al daemon).
kill_all() {
    pkill -x "$WS" 2>/dev/null || true
    for _ in $(seq 1 100); do
        pgrep -x "$WS" >/dev/null || return 0
        sleep 0.02
    done
}

case "${1:-clean}" in
    clean)
        kill_all
        exec "$WS" --active --no-resume-session
        ;;
    pass)
        if pgrep -x "$WS" >/dev/null; then
            kill_all                      # ya estaba en passthrough → salir y descartar
        else
            "$WS" --daemon --no-resume-session &>/dev/null & disown
            for _ in $(seq 1 150); do     # esperar a que el daemon acepte control, luego togglear una vez
                out="$("$WS" --light-toggle 2>&1)"
                [[ "$out" != *"not running"* ]] && break
                sleep 0.02
            done
        fi
        ;;
    draw)
        "$WS" --light-draw-toggle &>/dev/null || true
        ;;
    *)
        echo "uso: wayscriber.sh {clean|pass|draw}" >&2
        exit 2
        ;;
esac
