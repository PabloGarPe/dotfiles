-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/configuring/core/config-options/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,

        -- Los colores de los bordes salen del wallpaper: conf/colors.lua (matugen)

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/configuring/extra/tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 0.98,
        inactive_opacity = 0.92,

        -- Sombra amplia y suave; el color (tintado con el wallpaper) está en conf/colors.lua
        shadow = {
            enabled      = true,
            range        = 24,
            render_power = 2,
            offset       = "0 6",
            scale        = 1.0,
            color        = 0x66000000,
            color_inactive = 0x33000000,
        },

        blur = {
            enabled   = true,
            size      = 8,
            passes    = 3,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})
