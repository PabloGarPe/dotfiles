----------------------
---- WINDOW RULES ----
----------------------

-- See https://wiki.hypr.land/configuring/core/rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Desenfoque tras waybar (barra de menú y dock translúcidos, estilo macOS)
hl.layer_rule({
    name        = "waybar-blur",
    match       = { namespace = "^(menubar|dock)$" },
    blur        = true,
    blur_popups = true,
    ignore_alpha = 0.1,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Desenfoque tras rofi (tema ~/.config/rofi/themes/aurora.rasi)
hl.layer_rule({
    name         = "rofi-blur",
    match        = { namespace = "^rofi$" },
    blur         = true,
    ignore_alpha = 0.1,
})

-- Centro de control de Quickshell (~/.config/quickshell): blur y sin la animación
-- de capas de Hyprland (el panel ya anima su entrada)
hl.layer_rule({
    name         = "quickshell-blur",
    match        = { namespace = "^quickshell-.*$" },
    blur         = true,
    ignore_alpha = 0.3,
    no_anim      = true,
})

-- Editor de notas rápidas (Alt+e desde SUPER+SHIFT+SPACE): flotante y centrado
hl.window_rule({
    name   = "quick-notes",
    match  = { class = "^quick-notes$" },
    float  = true,
    size   = "900 600",
    center = true,
})

-- Desenfoque tras las notificaciones de dunst (~/.config/dunst/dunstrc)
hl.layer_rule({
    name         = "dunst-blur",
    match        = { namespace = "^notifications$" },
    blur         = true,
    ignore_alpha = 0.1,
})

-- Las notificaciones entran deslizando desde el borde derecho (el resto de capas hace popin)
hl.layer_rule({
    name      = "dunst-slide",
    match     = { namespace = "^notifications$" },
    animation = "slide right",
})

-- Esquinas redondeadas de la pantalla (~/.config/quickshell/ScreenCorners.qml): sin animación
hl.layer_rule({
    name    = "screen-corners",
    match   = { namespace = "^screen-corners$" },
    no_anim = true,
})

-- Fundido al cambiar de fondo (~/.config/quickshell/WallpaperFade.qml): sin animación de capa
hl.layer_rule({
    name    = "wallpaper-fade",
    match   = { namespace = "^wallpaper-fade$" },
    no_anim = true,
})
