-- ~/.config/hypr/hyprland.lua
-- Entry point. Everything lives in ./modules; colours come from Caelestia
-- (regenerated from the wallpaper into ./scheme/current.lua).
-- Original default config: hyprland.lua.orig

local dir = os.getenv("HOME") .. "/.config/hypr/"
package.path = dir .. "?.lua;" .. package.path

-- Load the wallpaper-generated palette. Fallback keeps Hyprland usable if it's missing.
local ok, scheme = pcall(dofile, dir .. "scheme/current.lua")
if not ok or type(scheme) ~= "table" then
    scheme = { primary = "c2c1ff", tertiary = "f5b2e0", surface = "131317", outlineVariant = "47464f" }
end
_G.scheme = scheme

require("modules.vars")
require("modules.monitors")
require("modules.env")
require("modules.autostart")
require("modules.look")
require("modules.input")
require("modules.binds")
require("modules.rules")
