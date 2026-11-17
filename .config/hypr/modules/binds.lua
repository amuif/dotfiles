-- Keybinds. SUPER = main modifier.
local M = "SUPER"
local a = _G.apps
local exec = hl.dsp.exec_cmd
local function bind(keys, d, opts) hl.bind(M .. (keys ~= "" and " + " .. keys or ""), d, opts) end
local function shell(name) return hl.dsp.global("caelestia:" .. name) end

---- Apps
bind("Q",         exec(a.terminal))
bind("Return",    exec(a.terminal))
bind("E",         exec(a.fileManager))
bind("B",         exec(a.browser))
bind("T",         exec("Telegram"))

---- Caelestia shell
bind("Space",     shell("launcher"))                        -- app launcher
bind("R",         exec("rofi -show drun"))                  -- rofi launcher
bind("SHIFT + R", exec("rofi -show run"))
bind("TAB",       exec("rofi -show window"))
bind("D",         shell("dashboard"))                       -- dashboard (media, calendar, perf)
bind("SHIFT + T", exec("caelestia shell dashboard open tasks"))      -- dashboard: task list
bind("SHIFT + D", exec("caelestia shell dashboard open screentime")) -- dashboard: screen time
bind("N",         shell("sidebar"))                         -- notifications / quick settings
bind("U",         shell("utilities"))                       -- utilities panel
bind("A",         shell("showall"))
bind("M",         shell("barExpand"))                       -- show bar + extra icons
bind("Z",         shell("toggleBar"))                       -- hide/show the bar
bind("Escape",    shell("session"))                         -- power menu
bind("L",         shell("lock"))                            -- lock screen
bind("SHIFT + V", exec("caelestia clipboard"))              -- clipboard history
bind("period",    exec("caelestia emoji -p"))               -- emoji picker
bind("SHIFT + W", exec("caelestia wallpaper -r"))           -- random wallpaper (re-themes everything)
bind("SHIFT + C", exec("hyprpicker -a"))                    -- colour picker -> clipboard
bind("CTRL + SHIFT + R", exec("caelestia shell -r"))        -- restart shell

---- Task manager (btop, falls back to htop): floating toggle
local taskmgr = "pkill -f '^kitty --class taskmanager' || kitty --class taskmanager -o font_size=9 -e sh -c 'exec $(command -v btop || command -v htop)'"
hl.bind("CTRL + SHIFT + Escape", exec(taskmgr))

---- Screenshots / recording
hl.bind("Print",           shell("screenshotFreeze"))       -- region, edit
hl.bind("SHIFT + Print",   shell("screenshotFreezeClip"))   -- region, clipboard only
bind("SHIFT + S",          shell("screenshotFreezeClip"))
hl.bind("CTRL + Print",    exec("caelestia screenshot"))    -- full screen
bind("ALT + R",            exec("caelestia record -r"))     -- record region (toggle)

---- Windows
bind("C",         hl.dsp.window.close())
bind("SHIFT + Q", hl.dsp.window.close())
bind("CTRL + SHIFT + Q", hl.dsp.window.kill())
bind("V",         hl.dsp.window.float({ action = "toggle" }))
bind("F",         hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }))
bind("SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
bind("P",         hl.dsp.window.pseudo())
bind("ALT + T",   hl.dsp.layout("togglesplit"))                -- was SUPER+T, now Telegram
bind("O",         hl.dsp.window.pin({ action = "toggle" }))
bind("SHIFT + O", hl.dsp.window.center())
bind("G",         hl.dsp.group.toggle())
bind("ALT + TAB", hl.dsp.window.cycle_next())

-- Focus / move / resize: arrows and vim keys (H J K L)
local dirs = { left = "left", right = "right", up = "up", down = "down", H = "left", J = "down", K = "up" }
for key, dir in pairs(dirs) do
    bind(key,              hl.dsp.focus({ direction = dir }))
    bind("SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end
-- L is lock, so SHIFT+L moves right but focus-right is arrow only
bind("SHIFT + L", hl.dsp.window.move({ direction = "right" }))

local step = 40
local resizes = { left = { -step, 0 }, right = { step, 0 }, up = { 0, -step }, down = { 0, step } }
for key, d in pairs(resizes) do
    bind("CTRL + " .. key, hl.dsp.window.resize({ x = d[1], y = d[2], relative = true }), { repeating = true })
end

-- Mouse
bind("mouse:272", hl.dsp.window.drag(),   { mouse = true })
bind("mouse:273", hl.dsp.window.resize(), { mouse = true })

---- Workspaces
for i = 1, 10 do
    local key = i % 10
    bind(tostring(key),              hl.dsp.focus({ workspace = i }))
    bind("SHIFT + " .. key,          hl.dsp.window.move({ workspace = i }))
    bind("ALT + " .. key,            hl.dsp.window.move({ workspace = i, follow = false }))
end
bind("mouse_down",   hl.dsp.focus({ workspace = "e+1" }))
bind("mouse_up",     hl.dsp.focus({ workspace = "e-1" }))
bind("CTRL + right", hl.dsp.focus({ workspace = "e+1" }))
bind("CTRL + left",  hl.dsp.focus({ workspace = "e-1" }))
bind("grave",        hl.dsp.focus({ workspace = "previous" }))

-- Scratchpad
bind("S",            hl.dsp.workspace.toggle_special("magic"))
bind("ALT + S",      hl.dsp.window.move({ workspace = "special:magic" }))

---- Session
bind("SHIFT + M", exec("hyprctl dispatch 'hl.dsp.exit()'"))

---- Hardware keys (work on lock screen too)
local hw = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), hw)
hl.bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      hw)
hl.bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",   shell("brightnessUp"),   hw)
hl.bind("XF86MonBrightnessDown", shell("brightnessDown"), hw)
hl.bind("XF86AudioNext",  shell("mediaNext"),   { locked = true })
hl.bind("XF86AudioPrev",  shell("mediaPrev"),   { locked = true })
hl.bind("XF86AudioPlay",  shell("mediaToggle"), { locked = true })
hl.bind("XF86AudioPause", shell("mediaToggle"), { locked = true })
