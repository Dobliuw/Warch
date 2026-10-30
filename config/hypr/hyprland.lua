-- Hyprland Lua config de warch (repo: config/hypr/hyprland.lua, enlazado en ~/.config/hypr/hyprland.lua).
-- Lo propio de cada máquina (monitores, teclado, GPU) NO está acá: vive en ~/.config/warch/machine.lua,
-- que genera `warch setup`. Así este archivo es el mismo en todas las máquinas.
-- https://wiki.hypr.land/configuring/


------------------
---- MONITORS ---- ################### CUSTOM ########################
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/
-- machine.lua declara los monitores (hl.monitor) y devuelve { kb_layout, nvidia }.
-- Si todavía no existe, cada monitor usa su modo preferido y Hyprland los acomoda solo.

local machine = { kb_layout = "us", nvidia = false }
local machineFile = os.getenv("HOME") .. "/.config/warch/machine.lua"
local mf = io.open(machineFile, "r")
if mf then
    mf:close()
    machine = dofile(machineFile) or machine
else
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
end


---------------------
---- MY PROGRAMS ---- ################### CUSTOM #######################
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "dolphin"
local firefox     = "/usr/bin/firefox &>/dev/null & disown"
local discord     = "/opt/discord/discord &>/dev/null & disown"
local obsidian    = "/usr/bin/obsidian_apprun &>/dev/null & disown"


-------------------
---- AUTOSTART ---- ############### CUSTOM #################
-------------------

-- See https://wiki.hypr.land/configuring/core/autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("hash dbus-update-activation-environment 2>/dev/null && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user start hyprland-session.target")

    hl.exec_cmd("~/.config/hypr/launch.sh")
    hl.exec_cmd("hyprsunset")  -- luz nocturna (antes wl-gammarelay, que no estaba instalado)

    if machine.nvidia then
        hl.exec_cmd("nvidia-settings --load-config-only")
    end
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/configuring/core/environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------------
----  NVIDIA CUSTOM FIXS ---- ################# CUSTOM #######################
-----------------------------

-- Solo en máquinas con GPU NVIDIA (lo detecta `warch setup`)
if machine.nvidia then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("XDG_SESSION_TYPE", "wayland")
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("WLR_NO_HARDWARE_CURSORS", "1")
end


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/configuring/core/advanced-configuration/permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/configuring/core/config-options/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 2,

        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/configuring/extra/tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- See https://wiki.hypr.land/configuring/core/animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- Ref https://wiki.hypr.land/configuring/core/rules/workspace-rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ name = "no-gaps-wtv1", match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ name = "no-gaps-f1",   match = { float = false, workspace = "f[1]" },   border_size = 0, rounding = 0 })

hl.config({
    -- See https://wiki.hypr.land/configuring/layouts/dwindle-layout/ for more
    dwindle = {
        preserve_split = true, -- You probably want this
    },

    -- See https://wiki.hypr.land/configuring/layouts/master-layout/ for more
    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = machine.kb_layout,
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Example per-device config
-- See https://wiki.hypr.land/configuring/core/devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


-------------------------
---- CUSOTM KEYBINDS ---- #################### CUSTOM #########################
-------------------------

local mainMod = "SUPER"

-- Blue Ligth Filter
-- (was "$mainMod N, Up": N is not a modifier, so the old parser ignored it and it
-- also fired together with movefocus up. Moved to SUPER + CTRL to avoid the clash.)
hl.bind(mainMod .. " + CTRL + Up",   hl.dsp.exec_cmd("~/.local/bin/warch night warmer"), { description = "Sistema · Luz nocturna: más cálida" })
hl.bind(mainMod .. " + CTRL + Down", hl.dsp.exec_cmd("~/.local/bin/warch night cooler"), { description = "Sistema · Luz nocturna: más fría" })

-- Win + Shift + P Windows OS functionality (Monitors)
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/monitors_disable.sh"), { description = "Sistema · Monitores (como Windows + P)" })

-- Screenshot
hl.bind("ALT + Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'), { description = "Captura · Región con swappy" })

-- Custom Apps
hl.bind(mainMod .. " + ALT + F", hl.dsp.exec_cmd(firefox), { description = "Apps · Firefox" })
hl.bind(mainMod .. " + ALT + D", hl.dsp.exec_cmd(discord), { description = "Apps · Discord" })
hl.bind(mainMod .. " + ALT + O", hl.dsp.exec_cmd(obsidian), { description = "Apps · Obsidian" })
hl.bind(mainMod .. " + H",       hl.dsp.exec_cmd("~/.config/wlsnarf/wlsnarf_history.sh"), { description = "Apps · Historial de wlsnarf" })

-- Basic keybinds
hl.bind(mainMod .. " + Return",      hl.dsp.exec_cmd(terminal), { description = "Apps · Terminal (kitty)" })
hl.bind(mainMod .. " + Q",           hl.dsp.window.close(), { description = "Ventanas · Cerrar" })
hl.bind(mainMod .. " + SHIFT + Escape", hl.dsp.exit(), { description = "Sesión · Salir de Hyprland" })
hl.bind(mainMod .. " + E",           hl.dsp.exec_cmd(fileManager), { description = "Apps · Archivos (dolphin)" })
hl.bind(mainMod .. " + S",           hl.dsp.window.float({ action = "toggle" }), { description = "Ventanas · Flotante / mosaico" })
hl.bind(mainMod .. " + D",           hl.dsp.exec_cmd("~/.local/bin/warch ui launcher"), { description = "Apps · Lanzador (apps y comandos con >)" })
hl.bind(mainMod .. " + P",           hl.dsp.window.pseudo(), { description = "Ventanas · Pseudo-mosaico" }) -- dwindle
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Ventanas · Maximizar" })  -- toggle maximize
hl.bind(mainMod .. " + SHIFT + F",   hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Ventanas · Pantalla completa" }) -- toggle real fullscreen
-- hl.bind(mainMod .. " + J",        hl.dsp.layout("togglesplit")) -- dwindle

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }), { description = "Ventanas · Foco a la izquierda" })
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), { description = "Ventanas · Foco a la derecha" })
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }), { description = "Ventanas · Foco arriba" })
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }), { description = "Ventanas · Foco abajo" })

-- Move focus windows with mainMod + Shift + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }), { description = "Ventanas · Mover a la izquierda" })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), { description = "Ventanas · Mover a la derecha" })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }), { description = "Ventanas · Mover arriba" })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }), { description = "Ventanas · Mover abajo" })

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
-- (keys 2 and 3 are swapped on purpose, as in the old config)
local workspaceForKey = { [1] = 1, [2] = 3, [3] = 2, [4] = 4, [5] = 5, [6] = 6, [7] = 7, [8] = 8, [9] = 9, [0] = 10 }
for key, ws in pairs(workspaceForKey) do
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = ws }), { description = "Workspaces · Ir al workspace " .. ws })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = ws }), { description = "Workspaces · Mover ventana al workspace " .. ws })
end

-- Example special workspace (scratchpad)
-- (SUPER + Z: antes era SUPER + S y chocaba con flotante/mosaico)
hl.bind(mainMod .. " + Z",         hl.dsp.workspace.toggle_special("magic"), { description = "Workspaces · Scratchpad" })
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Workspaces · Mover ventana al scratchpad" })

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspaces · Siguiente (rueda)" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Workspaces · Anterior (rueda)" })

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { description = "Ventanas · Mover con el mouse", mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { description = "Ventanas · Redimensionar con el mouse", mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { description = "Multimedia · Subir volumen", locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { description = "Multimedia · Bajar volumen", locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { description = "Multimedia · Silenciar", locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { description = "Multimedia · Silenciar micrófono", locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { description = "Multimedia · Subir brillo", locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { description = "Multimedia · Bajar brillo", locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { description = "Multimedia · Siguiente tema", locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { description = "Multimedia · Pausa", locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { description = "Multimedia · Reproducir / pausa", locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { description = "Multimedia · Tema anterior", locked = true })

---------------------
---- WARCH SHELL ---- ################### CUSTOM #######################
---------------------
-- Atajos de la shell de warch (Quickshell). Todos pasan por el CLI `warch`.
-- La descripción de cada uno es la que muestra el cheat sheet ("Grupo · Texto").
local warch = "~/.local/bin/warch"

-- Superficies de la barra
hl.bind("ALT " .. "+ Tab",       hl.dsp.exec_cmd(warch .. " ui overview"),   { description = "warch · Vista general de workspaces" })
hl.bind(mainMod .. " + A",         hl.dsp.exec_cmd(warch .. " ui dashboard"),  { description = "warch · Dashboard" })
hl.bind(mainMod .. " + C",         hl.dsp.exec_cmd(warch .. " ui settings"),   { description = "warch · Ajustes rápidos y VPN" })
hl.bind(mainMod .. " + Escape",    hl.dsp.exec_cmd(warch .. " ui session"),    { description = "warch · Menú de sesión" })
hl.bind(mainMod .. " + grave",     hl.dsp.exec_cmd(warch .. " panel toggle"),  { description = "warch · Panel vertical (calendario, TO-DOsh)" })
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd(warch .. " ui dnd"),        { description = "warch · No molestar" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd(warch .. " shell restart"), { description = "warch · Reiniciar la shell" })
hl.bind(mainMod .. " + K",         hl.dsp.exec_cmd(warch .. " ui cheatsheet"), { description = "warch · Atajos (cheat sheet)" })
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd(warch .. " ui wallpaper"),  { description = "warch · Wallpapers" })

-- Desenfoque detrás de la barra y los paneles (se nota cuando la transparencia es menor a 100%).
-- ignore_alpha evita desenfocar las zonas totalmente transparentes de cada capa.
hl.layer_rule({ name = "warch-blur", match = { namespace = "^warch-(bar|drawer|wallpaper|notifications|panel|polkit|session|overview)$" }, blur = true, ignore_alpha = 0.05 })
hl.bind(mainMod .. " + L",         hl.dsp.exec_cmd(warch .. " lock"),          { description = "Sesión · Bloquear" })

-- Modos
hl.bind(mainMod .. " + M",         hl.dsp.exec_cmd(warch .. " mode next"), { description = "Modos · Siguiente (sistema, pentest, estudio)" })
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd(warch .. " mode prev"), { description = "Modos · Anterior" })

-- Pentest
hl.bind(mainMod .. " + I",         hl.dsp.exec_cmd(warch .. " target ip | wl-copy -n"), { description = "Pentest · Copiar IP del objetivo" })
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd(warch .. " lhost"),                  { description = "Pentest · Copiar LHOST (tun*)" })

-- Estudio
hl.bind(mainMod .. " + T",         hl.dsp.exec_cmd(warch .. " pomo toggle"), { description = "Estudio · Empezar / detener pomodoro" })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/configuring/core/rules/

-- Example windowrule
-- hl.window_rule({ name = "float-kitty", match = { class = "^(kitty)$", title = "^(kitty)$" }, float = true })

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })

-- Fix some dragging issues with XWayland
-- hl.window_rule({
--     name  = "fix-xwayland-drags",
--     match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
--     no_focus = true,
-- })
