# warch

Mi escritorio de Arch Linux + Hyprland, reproducible. No es una distro: un repo con la configuración
y un instalador que deja cualquier máquina (notebook o PC, con uno, dos o tres monitores) con el mismo
sistema: barra, atajos, temas, wallpapers, bloqueo, VPN y herramientas.

## Instalar en una máquina nueva

```sh
git clone <este repo> ~/warch && cd ~/warch
./install.sh            # pregunta lo opcional (NordVPN, kitty, TO-DOsh)
./install.sh --yes      # todo por defecto, sin preguntas
```

Después: iniciar sesión en Hyprland y, si los monitores no quedaron como querés, `warch setup`.

El instalador es seguro de volver a correr. Lo que ya existía en `~/.config` se mueve a
`~/.config/warch/backup/<fecha>` antes de enlazar. Pasos sueltos: `./install.sh --only links,setup`.

| Paso | Qué hace |
|---|---|
| `packages` | Instala con pacman todo lo de abajo (+ `nvidia-utils` si hay GPU NVIDIA; el driver no se toca) |
| `aur` | NordVPN (`nordvpn-bin`), instalando `yay` si hace falta |
| `fonts` | Manrope desde google/fonts (el paquete del AUR está roto) |
| `links` | Enlaza la config del repo en `~/.config` y el CLI en `~/.local/bin`; copia los wallpapers |
| `services` | Desactiva dunst/mako, activa NTP y Bluetooth, tema por defecto |
| `todosh` | Clona TO-DOsh en `/opt/todosh` |
| `setup` | Genera la configuración propia de la máquina (ver abajo) |

## Qué maneja cada cosa

| Pieza | Herramienta | Dónde se configura |
|---|---|---|
| Gestor de ventanas, atajos | **Hyprland** (config en Lua) | `config/hypr/hyprland.lua` |
| Barra, paneles, lanzador, notificaciones, bloqueo, vista general, cheat sheet, diálogo de permisos | **Quickshell** (QML) | `quickshell/` |
| Lanzador `SUPER + D` (antes wofi) | Quickshell: apps, y con `>` comandos | `quickshell/drawers/Launcher.qml` |
| Notificaciones (antes dunst) | Quickshell | `quickshell/services/Notifs.qml` |
| Wallpapers | **awww** | `warch wallpaper`, biblioteca en `~/.config/warch/wallpapers` |
| Bloqueo por inactividad | **hypridle** → `warch lock` | `config/hypr/hypridle.conf` |
| Luz nocturna | **hyprsunset** | `warch night` |
| VPN | **nordvpn** y **openvpn** (HTB) | panel de ajustes, `~/.config/warch/vpn/htb.ovpn` |
| Terminal | **kitty** | `config/kitty/` |
| Todo lo anterior desde la terminal | **`warch`** (bash) | `bin/warch` |

La interfaz sale en el idioma del sistema (`LANG`): inglés o español (`quickshell/services/Tr.qml`).

## Configuración propia de cada máquina

El repo es igual en todas las máquinas. Lo que cambia vive fuera, en `~/.config/warch/`, y lo genera
`warch setup`:

- `machine.lua` — monitores (modo, posición, rotación, escala), teclado y si hay NVIDIA. Lo carga
  `hyprland.lua`. Sin este archivo, cada monitor usa su modo preferido.
- `monitors.json` — qué monitor lleva la barra (`main`) y cuál el panel oculto (`side`). Si no hay
  monitor vertical, el panel va en el principal.

`warch setup` toma la disposición actual de Hyprland: acomodá los monitores, corré `warch setup` y
queda guardada. En el primer inicio de sesión de una máquina nueva corre solo (`--auto`).

En pantallas chicas la barra se compacta (sin título de ventana y luego sin fecha) y los paneles se
achican al ancho del monitor. En notebooks aparece la batería.

## Atajos principales

`SUPER + K` muestra todos (lee `hyprctl binds`). Los de warch:

| Atajo | Acción |
|---|---|
| `SUPER + D` | Lanzador (`>` para comandos: esquema, wallpaper, variante, transparencia…) |
| `SUPER + A` / `C` | Dashboard / ajustes rápidos y VPN |
| `SUPER + Tab` | Vista general de workspaces |
| `SUPER + W` | Wallpapers |
| `SUPER + Esc` / `L` | Menú de sesión / bloquear |
| ``SUPER + ` `` | Panel lateral (calendario, TO-DOsh, notificaciones) |
| `SUPER + M` | Modo de la barra: sistema → pentest → estudio |
| `SUPER + I` / `SHIFT + I` | Copiar IP del objetivo / LHOST |
| `SUPER + T` | Pomodoro |
| `SUPER + K` | Cheat sheet |

## CLI

```sh
warch setup [--auto]                 # monitores, teclado y GPU de esta máquina
warch theme scheme neon              # grafito, circuito, islas, neon, bosque, ambar, wallpaper
warch theme mode light | variant vibrante | opacity 80
warch wallpaper set img.jpg [DP-2|all]
warch mode pentest                   # sistema | pentest | estudio | next | prev
warch target set 10.10.11.32 box     # objetivo (pasa a modo pentest)
warch pomo start | toggle            # pomodoro 90/20 (modo estudio)
warch lhost                          # copia tu LHOST (IP de tun*)
warch night toggle | warmer | cooler
warch lock [--test]                  # --test: vista previa sin bloquear
warch ui dashboard|settings|launcher|wallpaper|overview|cheatsheet|session
warch shell restart | logs
```

## Estructura

```
install.sh                instalador
bin/warch                 CLI; escribe el estado en ~/.local/state/warch/
bin/warch-wallpaper       genera wallpapers (circuito + logo) a la medida de cada monitor
bin/warch-palette         saca una paleta de colores de una imagen
config/hypr/              hyprland.lua, launch.sh, hypridle.conf, scripts/
config/kitty/             terminal
quickshell/               la shell: bar/, drawers/, overlays/, panel/, lock/, services/
wallpapers/               biblioteca inicial (se copia a ~/.config/warch/wallpapers)
```

## Actualizar

Como la config está enlazada al repo: `git pull` y `warch shell restart` (y `hyprctl reload` si
cambió `hyprland.lua`).

## Notas

- El bloqueo real se activa recién después de desbloquear bien la vista previa (`warch lock --test`)
  una vez, para no quedar afuera si algo falla con el teclado.
- El diálogo de permisos de warch solo aparece para acciones lanzadas desde la interfaz; en la
  terminal, `sudo`, `systemctl` y `pkexec` siguen pidiendo la contraseña en la terminal.
- Para volver a dunst: `systemctl --user unmask dunst`.
