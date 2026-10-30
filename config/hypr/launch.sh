#!/bin/bash
# Autoarranque de warch (lo llama hyprland.lua al iniciar la sesión).
W="$HOME/.local/bin/warch"

# Primera sesión en una máquina nueva: elegir solo qué monitor lleva la barra y cuál el panel
[[ -f "$HOME/.config/warch/monitors.json" ]] || "$W" setup --auto &>/dev/null

awww-daemon &>/dev/null & disown
"$W" wallpaper apply &>/dev/null
"$W" shell start &>/dev/null & disown

# Bloqueo por inactividad (si hypridle está instalado)
command -v hypridle &>/dev/null && hypridle -c "$HOME/.config/hypr/hypridle.conf" &>/dev/null & disown

# NordVPN (si está instalado)
command -v nordvpnd &>/dev/null && ! pgrep -x nordvpnd &>/dev/null && nordvpnd &>/dev/null & disown
