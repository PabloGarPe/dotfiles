----------------------------
---- DOCK AUTO-OCULTABLE ----
----------------------------
-- El dock (~/.config/waybar/dock.jsonc) arranca oculto en cada monitor.
-- Llevar el ratón al borde inferior lo muestra; alejarse de él lo vuelve a ocultar.

local dock = "~/.config/waybar/scripts/dock.sh"
local REVEAL = 2   -- px desde el borde inferior que hacen aparecer el dock
local HIDE   = 80  -- px desde el borde a partir de los cuales se oculta (dock: 58 + 6 de margen)

local visible = {} -- monitor -> true si su dock está visible

local function toggle(mon)
    visible[mon] = not visible[mon] or nil
    hl.exec_cmd(dock .. " toggle " .. mon)
end

-- Al (re)cargar la config todos los docks vuelven a arrancar ocultos, así el estado coincide
hl.exec_cmd(dock .. " restart")

hl.timer(function()
    local pos = hl.get_cursor_pos()
    local mon = hl.get_monitor_at_cursor()
    if not pos or not mon then return end

    local fromBottom = mon.y + mon.height / mon.scale - pos.y

    -- Oculta los docks de otros monitores o si el ratón se ha alejado
    for name in pairs(visible) do
        if name ~= mon.name or fromBottom > HIDE then toggle(name) end
    end

    if not visible[mon.name] and fromBottom <= REVEAL then toggle(mon.name) end
end, { timeout = 100, type = "repeat" })
