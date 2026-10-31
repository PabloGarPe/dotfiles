-------------------------
---- ALT + TAB (MRU) ----
-------------------------
-- Como en Windows: mantén ALT y pulsa TAB para avanzar (SHIFT + TAB retrocede).
-- Al soltar ALT te quedas en la ventana elegida. ESC cancela y vuelve a la original.

local list, idx = {}, 1

local function focus(win)
    hl.dispatch(hl.dsp.focus({ window = "address:" .. win.address }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end

local function step(dir)
    if #list < 2 then return end
    idx = (idx - 1 + dir) % #list + 1
    focus(list[idx])
end

local function start(dir)
    -- Instantánea ordenada de más a menos reciente: al enfocar cambia el historial
    list = {}
    for _, w in ipairs(hl.get_windows()) do
        if w.mapped and not w.hidden and w.workspace and w.workspace.id > 0 then
            table.insert(list, w)
        end
    end
    table.sort(list, function(a, b) return a.focus_history_id < b.focus_history_id end)
    idx = 1
    if #list < 2 then return end
    hl.dispatch(hl.dsp.submap("alttab"))
    step(dir)
end

local function cancel()
    if list[1] then focus(list[1]) end
    hl.dispatch(hl.dsp.submap("reset"))
end

hl.bind("ALT + Tab",         function() start(1) end)
hl.bind("ALT + SHIFT + Tab", function() start(-1) end)

hl.define_submap("alttab", function()
    hl.bind("ALT + Tab",         function() step(1) end,  { repeating = true })
    hl.bind("ALT + SHIFT + Tab", function() step(-1) end, { repeating = true })
    hl.bind("ALT + Escape",      cancel)
    -- Soltar ALT confirma la ventana actual
    hl.bind("ALT + Alt_L", hl.dsp.submap("reset"), { release = true })
    hl.bind("Alt_L",       hl.dsp.submap("reset"), { release = true })
end)
