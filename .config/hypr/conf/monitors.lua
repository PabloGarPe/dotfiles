------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/
-- Regla por defecto para cualquier monitor. Los monitores concretos (DP-1,
-- HDMI-A-1) los define HyprMod en hyprland-gui.lua.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})
