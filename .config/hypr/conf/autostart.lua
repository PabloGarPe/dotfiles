-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/configuring/core/autostart/

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar") -- Barra de menú (el dock lo lanza conf/dock.lua)
    hl.exec_cmd("hyprsunset & disown") -- Brillo por software (centro de control de rofi)
    hl.exec_cmd("qs -d") -- Centro de control (~/.config/quickshell), se abre desde el reloj de waybar
    hl.exec_cmd("waypaper --restore") -- Último fondo (mpvpaper: imágenes y vídeos) + colores (matugen)
end)
