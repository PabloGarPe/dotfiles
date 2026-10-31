-- Configuración de Hyprland: punto de entrada.
-- Cada sección vive en su propio módulo dentro de conf/.
-- Wiki: https://wiki.hypr.land/configuring/

require("conf.monitors")    -- Regla por defecto de monitores
require("conf.env")         -- Variables de entorno y permisos
require("conf.autostart")   -- Programas al iniciar
require("conf.appearance")  -- Huecos, bordes, decoración
pcall(require, "conf.colors") -- Colores del wallpaper (generado por matugen, puede no existir)
require("conf.animations")  -- Curvas y animaciones
require("conf.layouts")     -- dwindle / master / scrolling
require("conf.misc")        -- Misc y capas
require("conf.input")       -- Teclado, ratón, gestos
require("conf.keybinds")    -- Atajos (programas en conf/programs.lua)
require("conf.alttab")      -- ALT + TAB estilo Windows
require("conf.dock")        -- Dock de waybar que aparece con el ratón
require("conf.workspaces")  -- Workspaces por monitor
require("conf.rules")       -- Reglas de ventanas

-- HyprMod managed settings (se carga al final para que sus valores prevalezcan)
require("hyprland-gui")
