#!/usr/bin/env bash
# Night light helper for Hyprland (supports Hyprland Lua, hyprsunset, and wlsunset)
ACTION="${1:-toggle}"
SHADER="$HOME/.config/hypr/shaders/nightlight.frag"

is_enabled() {
    if pgrep -x hyprsunset >/dev/null 2>&1 || pgrep -x wlsunset >/dev/null 2>&1; then
        return 0
    fi
    local current
    current=$(hyprctl getoption decoration:screen_shader -j 2>/dev/null | grep -o '"str": *"[^"]*"' | head -n1 | cut -d'"' -f4)
    if [[ -n "$current" && "$current" != "[[EMPTY]]" && "$current" != "none" && "$current" != "" ]]; then
        return 0
    fi
    return 1
}

enable_nightlight() {
    if command -v hyprsunset >/dev/null 2>&1; then
        if ! pgrep -x hyprsunset >/dev/null 2>&1; then
            hyprsunset -t 4000 >/dev/null 2>&1 &
        else
            hyprctl hyprsunset temperature 4000 >/dev/null 2>&1
        fi
        return 0
    fi
    if command -v wlsunset >/dev/null 2>&1; then
        if ! pgrep -x wlsunset >/dev/null 2>&1; then
            wlsunset -t 4000 -T 6500 >/dev/null 2>&1 &
        fi
        return 0
    fi
    # Hyprland Lua config
    hyprctl eval "hl.config({ decoration = { screen_shader = '$SHADER' } })" >/dev/null 2>&1 || \
    hyprctl keyword decoration:screen_shader "$SHADER" >/dev/null 2>&1
}

disable_nightlight() {
    if pgrep -x hyprsunset >/dev/null 2>&1; then
        hyprctl hyprsunset identity >/dev/null 2>&1 || pkill -x hyprsunset >/dev/null 2>&1
    fi
    pkill -x wlsunset >/dev/null 2>&1
    # Hyprland Lua config
    hyprctl eval "hl.config({ decoration = { screen_shader = '' } })" >/dev/null 2>&1 || \
    hyprctl keyword decoration:screen_shader "[[EMPTY]]" >/dev/null 2>&1
}

case "$ACTION" in
    on|enable)
        enable_nightlight
        ;;
    off|disable)
        disable_nightlight
        ;;
    toggle)
        if is_enabled; then
            disable_nightlight
        else
            enable_nightlight
        fi
        ;;
    status)
        if is_enabled; then
            echo "on"
        else
            echo "off"
        fi
        ;;
    *)
        echo "Usage: $0 {on|off|toggle|status}"
        exit 1
        ;;
esac
