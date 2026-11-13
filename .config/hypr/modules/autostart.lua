hl.on("hyprland.start", function()
    -- Desktop shell: bar, launcher, notifications, OSD, lock, wallpaper
    hl.exec_cmd("caelestia shell -d")
    -- Auth dialogs
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    -- Clipboard history
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    -- Idle: dim, lock, screen off, suspend
    hl.exec_cmd("hypridle")
    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)
