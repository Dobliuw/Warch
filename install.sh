#!/usr/bin/env bash
# warch — instalador. Deja un Arch con Hyprland igual al de la máquina original: barra (Quickshell),
# atajos, temas, wallpapers, bloqueo, VPN y herramientas. Lo propio de cada máquina (monitores,
# teclado, GPU) se genera aparte con `warch setup`, así el resto del repo es idéntico en todos lados.
#
# Uso: ./install.sh [--yes] [--only paso1,paso2]
#   --yes    no pregunta: usa las opciones por defecto
#   --only   corre solo esos pasos: packages, aur, fonts, links, services, todosh, setup
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YES=0
ONLY=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --yes|-y) YES=1 ;;
        --only) ONLY="${2:-}"; shift ;;
        -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

# ---------- mensajes en el idioma del sistema ----------
case "${LC_ALL:-${LC_MESSAGES:-${LANG:-en}}}" in es*) L=es ;; *) L=en ;; esac
t() { if [[ $L == es ]]; then printf '%s' "$1"; else printf '%s' "$2"; fi; }
c_acc=$'\e[38;2;189;181;236m'; c_ok=$'\e[38;2;159;214;180m'; c_bad=$'\e[38;2;240;138;138m'; c_dim=$'\e[2m'; c_0=$'\e[0m'
step() { printf '\n%s━━ %s%s\n' "$c_acc" "$1" "$c_0"; }
ok()   { printf '  %s✓%s %s\n' "$c_ok" "$c_0" "$1"; }
warn() { printf '  %s!%s %s\n' "$c_bad" "$c_0" "$1"; }
info() { printf '  %s%s%s\n' "$c_dim" "$1" "$c_0"; }
ask() {   # ask "pregunta" "default(y/n)" → 0 = sí
    local def="$2" ans
    (( YES )) && [[ $def == y ]] && return 0
    (( YES )) && return 1
    read -rp "  $1 [$( [[ $def == y ]] && echo Y/n || echo y/N )] " ans
    ans="${ans:-$def}"
    [[ $ans =~ ^[yYsS] ]]
}
want() { [[ -z "$ONLY" || ",$ONLY," == *",$1,"* ]]; }

# ---------- comprobaciones ----------
[[ -f /etc/arch-release ]] || { echo "$(t 'warch es para Arch Linux.' 'warch is for Arch Linux.')" >&2; exit 1; }
(( EUID != 0 )) || { echo "$(t 'Ejecútalo como tu usuario, no como root (pide sudo cuando hace falta).' 'Run it as your user, not root (it asks for sudo when needed).')" >&2; exit 1; }
command -v sudo >/dev/null || { echo "sudo is required" >&2; exit 1; }

printf '%s\n' "${c_acc}warch${c_0} · $(t 'instalación' 'install') · $REPO"
NVIDIA=0
lspci 2>/dev/null | grep -qiE '(vga|3d).*nvidia' && NVIDIA=1

# ---------- 1. paquetes del repo oficial ----------
PKGS=(
    # escritorio
    hyprland quickshell qt6-svg qt6-declarative xdg-desktop-portal-hyprland polkit awww hypridle hyprsunset
    # terminal y herramientas
    kitty zsh git curl jq wl-clipboard libnotify grim slurp swappy btop dolphin pacman-contrib
    # audio, brillo, multimedia, bluetooth, batería
    pipewire wireplumber pipewire-pulse pavucontrol playerctl brightnessctl bluez bluez-utils upower
    # VPN de laboratorio, wallpapers y paletas
    openvpn python python-pillow librsvg
    # fuentes e íconos
    ttf-ibm-plex ttf-hack-nerd breeze-icons
)
if want packages; then
    step "$(t 'Paquetes' 'Packages')"
    (( NVIDIA )) && { PKGS+=(nvidia-utils nvidia-settings); info "$(t 'GPU NVIDIA detectada: se agregan nvidia-utils y nvidia-settings (el driver no se toca).' 'NVIDIA GPU detected: adding nvidia-utils and nvidia-settings (the driver itself is left alone).')"; }
    sudo pacman -S --needed --noconfirm "${PKGS[@]}"
    ok "$(t "${#PKGS[@]} paquetes al día" "${#PKGS[@]} packages up to date")"
fi

# ---------- 2. AUR (NordVPN) ----------
if want aur; then
    step "AUR"
    if ask "$(t '¿Instalar NordVPN (nordvpn-bin)?' 'Install NordVPN (nordvpn-bin)?')" y; then
        if ! command -v yay >/dev/null && ! command -v paru >/dev/null; then
            info "$(t 'Instalando yay…' 'Installing yay…')"
            sudo pacman -S --needed --noconfirm base-devel
            tmp="$(mktemp -d)"; git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
            (cd "$tmp/yay-bin" && makepkg -si --noconfirm); rm -rf "$tmp"
        fi
        aur="$(command -v yay || command -v paru)"
        "$aur" -S --needed --noconfirm nordvpn-bin
        sudo systemctl enable --now nordvpnd
        sudo usermod -aG nordvpn "$USER"
        ok "$(t 'NordVPN instalado (cierra sesión una vez para que tome el grupo nordvpn)' 'NordVPN installed (log out once so the nordvpn group applies)')"
    else
        info "$(t 'NordVPN omitido' 'NordVPN skipped')"
    fi
fi

# ---------- 3. fuentes ----------
if want fonts; then
    step "$(t 'Fuentes' 'Fonts')"
    fdir="$HOME/.local/share/fonts"; mkdir -p "$fdir"
    if fc-list | grep -qi manrope; then
        ok "Manrope"
    else
        # El paquete AUR ttf-manrope apunta a una URL caída: se baja de google/fonts
        curl -fsSL -o "$fdir/Manrope-Variable.ttf" 'https://github.com/google/fonts/raw/main/ofl/manrope/Manrope%5Bwght%5D.ttf'
        fc-cache -f "$fdir" >/dev/null
        ok "$(t 'Manrope instalada en ~/.local/share/fonts' 'Manrope installed in ~/.local/share/fonts')"
    fi
fi

# ---------- 4. enlaces de configuración ----------
BACKUP="$HOME/.config/warch/backup/$(date +%Y%m%d-%H%M%S)"
link() {   # link <origen en el repo> <destino>
    local src="$REPO/$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then return; fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        mkdir -p "$BACKUP/$(dirname "${dst#"$HOME"/}")"
        mv "$dst" "$BACKUP/${dst#"$HOME"/}"
    fi
    ln -s "$src" "$dst"
}
if want links; then
    step "$(t 'Configuración' 'Configuration')"
    link config/hypr/hyprland.lua  "$HOME/.config/hypr/hyprland.lua"
    link config/hypr/launch.sh     "$HOME/.config/hypr/launch.sh"
    link config/hypr/hypridle.conf "$HOME/.config/hypr/hypridle.conf"
    link config/hypr/scripts       "$HOME/.config/hypr/scripts"
    link quickshell                "$HOME/.config/quickshell/warch"
    for b in warch warch-wallpaper warch-palette; do link "bin/$b" "$HOME/.local/bin/$b"; done
    if ask "$(t '¿Usar también la configuración de kitty de warch?' 'Also use warch’s kitty config?')" y; then
        link config/kitty "$HOME/.config/kitty"
    fi
    # Biblioteca de wallpapers: se copian (no se enlazan) para que puedas agregar o borrar los tuyos
    mkdir -p "$HOME/.config/warch/wallpapers"
    cp -n "$REPO"/wallpapers/* "$HOME/.config/warch/wallpapers/" 2>/dev/null || true
    [[ -d "$BACKUP" ]] && info "$(t "Lo que había quedó en $BACKUP" "Previous files were moved to $BACKUP")"
    ok "$(t 'Hyprland, Quickshell, CLI warch y kitty enlazados al repo' 'Hyprland, Quickshell, warch CLI and kitty linked to the repo')"
    case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) warn "$(t 'Agrega ~/.local/bin a tu PATH para usar `warch` en la terminal' 'Add ~/.local/bin to your PATH to use `warch` from the terminal')" ;; esac
fi

# ---------- 5. servicios ----------
if want services; then
    step "$(t 'Servicios' 'Services')"
    # Las notificaciones las maneja warch: dunst/mako no deben quedarse con el servicio
    for n in dunst mako swaync; do
        if systemctl --user cat "$n.service" &>/dev/null; then systemctl --user disable --now "$n" &>/dev/null || true; systemctl --user mask "$n" &>/dev/null; info "$n $(t 'desactivado' 'disabled')"; fi
    done
    sudo timedatectl set-ntp true && ok "$(t 'Hora sincronizada por internet (NTP)' 'Clock synced over the internet (NTP)')"
    sudo systemctl enable --now bluetooth &>/dev/null && ok "Bluetooth" || warn "$(t 'No se pudo activar Bluetooth (¿la máquina tiene?)' 'Could not enable Bluetooth (does this machine have it?)')"
    theme="$HOME/.local/state/warch/theme.json"
    [[ -f "$theme" ]] || { mkdir -p "$(dirname "$theme")"; echo '{"scheme":"grafito","mode":"dark","variant":"tonal","opacity":100}' > "$theme"; }
    ok "$(t 'Tema por defecto: Grafito lavanda' 'Default theme: Lavender graphite')"
fi

# ---------- 6. TO-DOsh ----------
if want todosh; then
    step "TO-DOsh"
    if [[ -x /opt/todosh/bin/todosh ]]; then
        ok "$(t 'Ya está en /opt/todosh' 'Already in /opt/todosh')"
    elif ask "$(t '¿Instalar TO-DOsh en /opt/todosh?' 'Install TO-DOsh in /opt/todosh?')" y; then
        sudo install -d -o "$USER" -g "$(id -gn)" /opt/todosh
        git clone --depth 1 https://github.com/Dobliuw/TO-DOsh.git /opt/todosh
        ok "TO-DOsh $(t 'instalado (alias sugerido: alias tdsh=/opt/todosh/bin/todosh)' 'installed (suggested alias: alias tdsh=/opt/todosh/bin/todosh)')"
    fi
fi

# ---------- 7. esta máquina ----------
if want setup; then
    step "$(t 'Esta máquina' 'This machine')"
    if hyprctl version &>/dev/null; then
        info "$(t 'Estás dentro de Hyprland: se toma la disposición actual de monitores.' 'You are inside Hyprland: the current monitor layout is captured.')"
        if (( YES )); then "$HOME/.local/bin/warch" setup --auto; else "$HOME/.local/bin/warch" setup; fi
    else
        "$HOME/.local/bin/warch" setup --auto
        info "$(t 'Al iniciar Hyprland cada monitor usa su modo preferido. Después corre `warch setup` para elegir barra, panel y guardar la disposición.' 'On first Hyprland start every monitor uses its preferred mode. Then run `warch setup` to pick bar/panel monitors and save the layout.')"
    fi
fi

step "$(t 'Listo' 'Done')"
cat <<EOF
  $(t 'Próximos pasos:' 'Next steps:')
  • $(t 'Inicia sesión en Hyprland (o reinícialo) para cargar todo.' 'Log into Hyprland (or restart it) to load everything.')
  • $(t 'Si tus monitores no quedaron bien:' 'If your monitors are not right:') ${c_acc}warch setup${c_0}
  • $(t 'Prueba el bloqueo antes de usarlo:' 'Try the lock screen before relying on it:') ${c_acc}warch lock --test${c_0}
  • $(t 'Perfil de HTB: copia tu .ovpn a' 'HTB profile: copy your .ovpn to') ~/.config/warch/vpn/htb.ovpn
  • $(t 'Atajos:' 'Shortcuts:') ${c_acc}SUPER + K${c_0}
EOF
