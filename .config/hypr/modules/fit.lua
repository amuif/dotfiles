-- Keep new floating windows inside the screen.
-- Some apps (e.g. Steam's popups) open floating windows taller than the display
-- (720px logical at 2x scale), so the bottom ends up off-screen. A plain window
-- rule can cap the size but centres using the uncapped size, so do it here:
-- if a new titled floating window doesn't fit, shrink it to the usable area and
-- centre it. Untitled XWayland menus/tooltips are left alone.

local MARGIN = 8

hl.on("window.open", function(w)
    if not w.floating or w.fullscreen ~= 0 or (w.title or "") == "" then
        return
    end

    local m = w.monitor
    if not m then
        return
    end
    local sc = m.scale or 1
    local r = m.reserved or { top = 0, right = 0, bottom = 0, left = 0 }
    local mx, my = m.x or 0, m.y or 0
    local W, H = m.width / sc, m.height / sc

    -- Usable area: monitor minus reserved space (bar/border) minus a small margin
    local left, top = mx + r.left + MARGIN, my + r.top + MARGIN
    local maxW = W - r.left - r.right - MARGIN * 2
    local maxH = H - r.top - r.bottom - MARGIN * 2

    local sw, sh = w.size.x, w.size.y
    local x, y = w.at.x, w.at.y
    local fits = sw <= maxW and sh <= maxH and x >= left - MARGIN and y >= top - MARGIN
        and x + sw <= left + maxW + MARGIN and y + sh <= top + maxH + MARGIN
    if fits then
        return
    end

    local nw, nh = math.min(sw, maxW), math.min(sh, maxH)
    local sel = "address:" .. w.address
    if nw ~= sw or nh ~= sh then
        hl.dispatch(hl.dsp.window.resize({ x = math.floor(nw), y = math.floor(nh), window = sel }))
    end
    hl.dispatch(hl.dsp.window.move({
        x = math.floor(left + (maxW - nw) / 2),
        y = math.floor(top + (maxH - nh) / 2),
        window = sel,
    }))
end)
