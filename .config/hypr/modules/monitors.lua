-- Laptop panel: 2560x1440, 2x scale. Any other monitor: auto.
hl.monitor({ output = "eDP-1", mode = "2560x1440@60", position = "0x0", scale = 2 })
hl.monitor({ output = "",      mode = "preferred",    position = "auto", scale = "auto" })
