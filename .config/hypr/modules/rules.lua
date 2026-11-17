---- Layer rules: blur behind the shell and launchers
hl.layer_rule({ name = "blur-caelestia", match = { namespace = "^caelestia-(drawers|border-exclusion)$" }, blur = true, ignore_alpha = 0.55 })
hl.layer_rule({ name = "blur-rofi",      match = { namespace = "^rofi$" },          blur = true, ignore_alpha = 0.4, dim_around = true })
hl.layer_rule({ name = "selection",      match = { namespace = "^(selection|hyprpicker)$" }, no_anim = true })

---- Window rules
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- (Oversized floating windows are shrunk/centred by modules/fit.lua)

-- Small utility windows float, centred
hl.window_rule({
    name  = "float-utils",
    match = { class = "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|blueman-manager|nm-connection-editor|nwg-look|qt6ct|kvantummanager|org\\.kde\\.polkit-kde-authentication-agent-1|xdg-desktop-portal-gtk|swappy|hyprland-run)$" },
    float = true, center = true, size = "60% 60%",
})
hl.window_rule({ name = "float-taskmanager", match = { class = "^taskmanager$" }, float = true, center = true, size = "monitor_w*0.8 monitor_h*0.85" })
hl.window_rule({ name = "float-dialogs", match = { title = "^(Open File|Save File|Save As|Open Folder|File Upload|Choose Files?|Confirm.*)$" }, float = true, center = true })
hl.window_rule({ name = "float-pip",     match = { title = "^(Picture-in-Picture|Picture in picture)$" }, float = true, pin = true, size = "30% 30%", move = "68% 66%", keep_aspect_ratio = true })

-- Media should be fully opaque and not get blurred through
hl.window_rule({
    name  = "opaque-media",
    match = { class = "^(mpv|vlc|imv|org\\.kde\\.gwenview|steam_app_.*|gamescope)$" },
    opacity = "1.0 override 1.0 override", no_blur = true, idle_inhibit = "fullscreen",
})
hl.window_rule({ name = "opaque-browser-video", match = { title = ".*(YouTube|Netflix|Twitch).*" }, opacity = "1.0 override 1.0 override" })
-- Disabled: let hypridle lock even when a window is fullscreen (video wake locks still hold it off)
-- hl.window_rule({ name = "idle-fullscreen",       match = { fullscreen = true }, idle_inhibit = "fullscreen" })

---- Workspace rules: no gaps / borders when a single tiled window
-- (comment these out if you prefer always-floating look)
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
