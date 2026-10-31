---------------------
---- KEYBINDINGS ----
---------------------

local programs = require("conf.programs")
local mainMod = programs.mainMod

-- Example binds, see https://wiki.hypr.land/configuring/core/binds/ for more
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(programs.terminal))
local closeWindowBind = hl.bind(mainMod .. " + W", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
-- hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(programs.fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })) -- Toda la pantalla
hl.bind(mainMod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))  -- Maximizar (respeta barra y huecos)
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(programs.menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit")) -- dwindle only (SUPER+J es foco abajo)
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(programs.wallpaper))

-- Direcciones con flechas o con hjkl como en nvim
local directions = {
	{ dir = "left",  keys = { "left",  "H" } },
	{ dir = "down",  keys = { "down",  "J" } },
	{ dir = "up",    keys = { "up",    "K" } },
	{ dir = "right", keys = { "right", "L" } },
}
local grow = "~/.config/hypr/scripts/grow.py"

for _, d in ipairs(directions) do
	for _, key in ipairs(d.keys) do
		-- Move focus with mainMod + arrow keys / hjkl
		hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = d.dir }))
		-- Intercambiar la ventana activa con la vecina con mainMod + ALT
		hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.window.swap({ direction = d.dir }))
		-- Grow the active window towards that side with mainMod + CTRL
		hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.exec_cmd(grow .. " " .. d.dir), { repeating = true })
	end
end

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:magic" })) -- SUPER+SHIFT+S es la captura

-- Capturas de pantalla (zona o ventana) → ~/Pictures/Screenshots + portapapeles
local screenshot = "~/.config/hypr/scripts/screenshot.sh"
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(screenshot))
hl.bind("Print", hl.dsp.exec_cmd(screenshot))

-- Notas rápidas (~/Notes/quick.md): SUPER+SPACE escribir, SUPER+SHIFT+SPACE ver
local notes = "~/.config/hypr/scripts/notes.sh"
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(notes .. " add"))
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.exec_cmd(notes .. " view"))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
-- (el volumen pasa por scripts/volume.sh, que además lo notifica con dunst)
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh up"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh down"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh mute"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh mic"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Apps shortcuts
hl.bind(mainMod .. " + B ", hl.dsp.exec_cmd(programs.browser))
