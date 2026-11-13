-- Floating & glassy, tuned for Intel UHD 620 (blur kept to 2 passes).
local c = _G.scheme
local function rgba(hex, a) return "rgba(" .. hex .. (a or "ff") .. ")" end

hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 6,
        border_size = 2,
        col = {
            active_border   = { colors = { rgba(c.primary, "ee"), rgba(c.tertiary, "ee") }, angle = 45 },
            inactive_border = rgba(c.outlineVariant, "88"),
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 16,
        rounding_power = 2.5,

        active_opacity     = 0.94,
        inactive_opacity   = 0.86,
        fullscreen_opacity = 1.0,

        dim_inactive = true,
        dim_strength = 0.05,

        shadow = {
            enabled      = true,
            range        = 20,
            render_power = 3,
            offset       = "0 4",
            color        = 0x55000000,
        },

        blur = {
            enabled           = true,
            size              = 6,
            passes            = 2,
            new_optimizations = true,
            xray              = false,
            noise             = 0.02,
            contrast          = 1.0,
            brightness        = 1.0,
            vibrancy          = 0.2,
            popups            = true,
        },
    },

    animations = { enabled = true },

    dwindle = { preserve_split = true, smart_split = false },
    master  = { new_status = "master" },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        animate_manual_resizes = true,
        focus_on_activate = true,
    },

    layers = {
        allow_new_top_layers_over_existing_fullscreen = true,
    },
})

-- Curves
hl.curve("emphasized", { type = "bezier", points = { {0.05, 0.7}, {0.1, 1} } })
hl.curve("emphAccel",  { type = "bezier", points = { {0.3, 0},    {0.8, 0.15} } })
hl.curve("standard",   { type = "bezier", points = { {0.2, 0},    {0, 1} } })
hl.curve("linear",     { type = "bezier", points = { {0, 0},      {1, 1} } })
hl.curve("bouncy",     { type = "spring", mass = 1, stiffness = 220, damping = 20 })
hl.curve("soft",       { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })

-- Animations
hl.animation({ leaf = "global",       enabled = true, speed = 8,   bezier = "standard" })
hl.animation({ leaf = "windows",      enabled = true, speed = 5,   spring = "soft" })
hl.animation({ leaf = "windowsIn",    enabled = true, speed = 4.5, spring = "bouncy",    style = "popin 85%" })
hl.animation({ leaf = "windowsOut",   enabled = true, speed = 2,   bezier = "emphAccel", style = "popin 85%" })
hl.animation({ leaf = "windowsMove",  enabled = true, speed = 5,   spring = "soft" })
hl.animation({ leaf = "border",       enabled = true, speed = 6,   bezier = "standard" })
hl.animation({ leaf = "borderangle",  enabled = true, speed = 60,  bezier = "linear",    style = "loop" })
hl.animation({ leaf = "fade",         enabled = true, speed = 3,   bezier = "standard" })
hl.animation({ leaf = "layers",       enabled = true, speed = 4,   bezier = "emphasized" })
hl.animation({ leaf = "layersIn",     enabled = true, speed = 4,   bezier = "emphasized", style = "fade" })
hl.animation({ leaf = "layersOut",    enabled = true, speed = 2,   bezier = "emphAccel",  style = "fade" })
hl.animation({ leaf = "workspaces",   enabled = true, speed = 5,   bezier = "emphasized", style = "slidefade 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "emphasized", style = "slidevert" })
