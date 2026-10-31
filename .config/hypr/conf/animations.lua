--------------------
---- ANIMATIONS ----
--------------------

-- https://wiki.hypr.land/configuring/core/animations/
-- Idea: las cosas entran con un muelle (un pelín de rebote) y salen rápido y sin rebote,
-- como en macOS / Material You. Velocidad en décimas de segundo (más alto = más lento).

-- Curvas
hl.curve("emphasized",      { type = "bezier", points = { {0.05, 0.7}, {0.1, 1}    } }) -- entrada: arranca rápido, frena suave
hl.curve("emphasizedAccel", { type = "bezier", points = { {0.3, 0},    {0.8, 0.15} } }) -- salida: acelera hacia fuera
hl.curve("easeOutQuint",    { type = "bezier", points = { {0.23, 1},   {0.32, 1}   } })
hl.curve("easeInOutCubic",  { type = "bezier", points = { {0.65, 0.05},{0.36, 1}   } })
hl.curve("quick",           { type = "bezier", points = { {0.15, 0},   {0.1, 1}    } })
hl.curve("linear",          { type = "bezier", points = { {0, 0},      {1, 1}      } })

-- Muelles (amortiguamiento crítico ≈ 2·√(stiffness·mass); por debajo, rebota un poco)
hl.curve("soft",   { type = "spring", mass = 1, stiffness = 210, damping = 23 }) -- abrir ventanas: leve rebote
hl.curve("snappy", { type = "spring", mass = 1, stiffness = 320, damping = 34 }) -- mover/redimensionar: firme

hl.animation({ leaf = "global",           enabled = true, speed = 8,   bezier = "default" })

-- Ventanas
hl.animation({ leaf = "windows",          enabled = true, speed = 5,   spring = "snappy" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 5,   spring = "soft",            style = "popin 80%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 2.2, bezier = "emphasizedAccel", style = "popin 88%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 5,   spring = "snappy" })

-- Bordes: cambio de color suave al enfocar
hl.animation({ leaf = "border",           enabled = true, speed = 4,   bezier = "easeOutQuint" })

-- Fundidos (opacidad, sombra, atenuado)
hl.animation({ leaf = "fade",             enabled = true, speed = 3,   bezier = "quick" })
hl.animation({ leaf = "fadeIn",           enabled = true, speed = 2.5, bezier = "emphasized" })
hl.animation({ leaf = "fadeOut",          enabled = true, speed = 2,   bezier = "emphasizedAccel" })

-- Capas (rofi, dock, notificaciones…): crecen un poco al aparecer
hl.animation({ leaf = "layers",           enabled = true, speed = 3.5, bezier = "emphasized" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 3.5, bezier = "emphasized",      style = "popin 92%" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 1.8, bezier = "emphasizedAccel", style = "popin 95%" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 2.5, bezier = "emphasized" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 1.6, bezier = "emphasizedAccel" })

-- Workspaces: deslizan con un ligero fundido; el especial cae desde arriba
hl.animation({ leaf = "workspaces",       enabled = true, speed = 4,   bezier = "emphasized",      style = "slidefade 12%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4,   bezier = "emphasized",      style = "slidefadevert 15%" })

hl.animation({ leaf = "zoomFactor",       enabled = true, speed = 6,   bezier = "quick" })

-- Degradado del borde activo (colores de matugen) girando despacio: una vuelta cada ~10 s (el máximo que admite speed).
-- Obliga a redibujar el borde continuamente; si notas consumo de GPU, pon enabled = false.
hl.animation({ leaf = "borderangle",      enabled = true, speed = 100, bezier = "linear",          style = "loop" })
