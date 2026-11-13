hl.config({
    input = {
        kb_layout  = "us",
        follow_mouse = 1,
        sensitivity  = 0,
        repeat_rate  = 35,
        repeat_delay = 250,
        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
            tap_to_click         = true,
            scroll_factor        = 0.5,
        },
    },
    cursor = {
        hide_on_key_press = true,
    },
})

-- 3-finger horizontal swipe: switch workspace
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
