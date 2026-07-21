-- tests/test_overlay_layout.lua
-- Contract tests for the overlay grid-layout logic and its growth/wrap helpers.
--
-- NivUI.OverlayLogic.ComputeGridLayout({ growth, wrap, perLine, maxIcons,
--   iconSize, spacing }) -> { width, height, anchor, icons = { [i] = { x, y } } }.
-- One origin corner (layout.anchor) for ALL icons; each icon's { x, y } is a
-- signed offset from that corner, with icon 1 always at { 0, 0 }. The container
-- is sized to a SINGLE icon slot (width == height == iconSize): the user's
-- anchor settings position icon 1, which never moves, and the grid flows
-- directionally outward from it. The full-grid footprint is dead as a
-- positioning concept. The function is total over any input (unknown growth
-- behaves as RIGHT; invalid/nil wrap falls to the orientation default).
--
-- Helpers under test:
--   IsVerticalGrowth(growth) -> boolean (nil/unknown -> false)
--   DefaultWrapFor(growth)   -> "RIGHT" if vertical else "DOWN"
--   NormalizeWrap(growth, wrap) -> valid perpendicular member, else default
--   NivUI.UnitFrames:GetWrapOptions(growth) -> adaptive option list

local OverlayLogic = NivUI.OverlayLogic
local UnitFrames = NivUI.UnitFrames

--------------------------------------------------------------------------------
-- Shared fixture: iconSize 10 + spacing 2 -> step 12; perLine 3, maxIcons 5.
-- Container is one icon slot: width == height == iconSize == 10 in every case.
--------------------------------------------------------------------------------

local function Layout(growth, wrap)
    return OverlayLogic.ComputeGridLayout({
        growth = growth,
        wrap = wrap,
        perLine = 3,
        maxIcons = 5,
        iconSize = 10,
        spacing = 2,
    })
end

-- Build the full expected return table for the shared fixture from the
-- single-slot width/height, an anchor, and the five signed icon offsets.
local function Expected(width, height, anchor, offsets)
    local icons = {}
    for i = 1, #offsets do
        icons[i] = { x = offsets[i][1], y = offsets[i][2] }
    end
    return { width = width, height = height, anchor = anchor, icons = icons }
end

return {
    ----------------------------------------------------------------------------
    -- Six spec examples (docs/overlay-growth-directions.html "Examples")
    ----------------------------------------------------------------------------

    ["RIGHT/DOWN fills from TOPLEFT (current behavior)"] = function()
        assertTableEquals(Layout("RIGHT", "DOWN"),
            Expected(10, 10, "TOPLEFT",
                { { 0, 0 }, { 12, 0 }, { 24, 0 }, { 0, -12 }, { 12, -12 } }),
            "RIGHT/DOWN layout")
    end,

    ["RIGHT/UP fills from BOTTOMLEFT"] = function()
        assertTableEquals(Layout("RIGHT", "UP"),
            Expected(10, 10, "BOTTOMLEFT",
                { { 0, 0 }, { 12, 0 }, { 24, 0 }, { 0, 12 }, { 12, 12 } }),
            "RIGHT/UP layout")
    end,

    ["LEFT/DOWN fills from TOPRIGHT"] = function()
        assertTableEquals(Layout("LEFT", "DOWN"),
            Expected(10, 10, "TOPRIGHT",
                { { 0, 0 }, { -12, 0 }, { -24, 0 }, { 0, -12 }, { -12, -12 } }),
            "LEFT/DOWN layout")
    end,

    ["UP/RIGHT fills from BOTTOMLEFT"] = function()
        assertTableEquals(Layout("UP", "RIGHT"),
            Expected(10, 10, "BOTTOMLEFT",
                { { 0, 0 }, { 0, 12 }, { 0, 24 }, { 12, 0 }, { 12, 12 } }),
            "UP/RIGHT layout")
    end,

    ["DOWN/RIGHT fills from TOPLEFT"] = function()
        assertTableEquals(Layout("DOWN", "RIGHT"),
            Expected(10, 10, "TOPLEFT",
                { { 0, 0 }, { 0, -12 }, { 0, -24 }, { 12, 0 }, { 12, -12 } }),
            "DOWN/RIGHT layout")
    end,

    ["DOWN/LEFT fills from TOPRIGHT"] = function()
        assertTableEquals(Layout("DOWN", "LEFT"),
            Expected(10, 10, "TOPRIGHT",
                { { 0, 0 }, { 0, -12 }, { 0, -24 }, { -12, 0 }, { -12, -12 } }),
            "DOWN/LEFT layout")
    end,

    ----------------------------------------------------------------------------
    -- Offset-math continuity with the original CreateAuraWidget implementation.
    -- Production defaults: iconSize 20, spacing 2 (step 22), perLine 8,
    -- maxIcons 16. RIGHT + nil wrap -> TOPLEFT, x = col*22, y = -row*22.
    -- LEFT + nil wrap -> TOPRIGHT, x = -col*22, same y.
    --
    -- These cases pin the relative icon offsets only, NOT pixel-identical
    -- rendering: the container semantics deliberately changed from the
    -- full-grid footprint (174x42) to a single icon slot (20x20) so the user's
    -- anchor settings pin icon 1 directly.
    ----------------------------------------------------------------------------

    ["RIGHT + nil wrap keeps the original implementation's offset math"] = function()
        local layout = OverlayLogic.ComputeGridLayout({
            growth = "RIGHT",
            wrap = nil,
            perLine = 8,
            maxIcons = 16,
            iconSize = 20,
            spacing = 2,
        })
        assertEquals(layout.width, 20, "RIGHT container width = one icon slot")
        assertEquals(layout.height, 20, "RIGHT container height = one icon slot")
        assertEquals(layout.anchor, "TOPLEFT", "RIGHT origin corner")
        for i = 1, 16 do
            local col = (i - 1) % 8
            local row = math.floor((i - 1) / 8)
            assertEquals(layout.icons[i].x, col * 22, "RIGHT offset x for icon " .. i)
            assertEquals(layout.icons[i].y, -row * 22, "RIGHT offset y for icon " .. i)
        end
    end,

    ["LEFT + nil wrap keeps the original implementation's offset math"] = function()
        local layout = OverlayLogic.ComputeGridLayout({
            growth = "LEFT",
            wrap = nil,
            perLine = 8,
            maxIcons = 16,
            iconSize = 20,
            spacing = 2,
        })
        assertEquals(layout.width, 20, "LEFT container width = one icon slot")
        assertEquals(layout.height, 20, "LEFT container height = one icon slot")
        assertEquals(layout.anchor, "TOPRIGHT", "LEFT origin corner")
        for i = 1, 16 do
            local col = (i - 1) % 8
            local row = math.floor((i - 1) / 8)
            assertEquals(layout.icons[i].x, -col * 22, "LEFT offset x for icon " .. i)
            assertEquals(layout.icons[i].y, -row * 22, "LEFT offset y for icon " .. i)
        end
    end,

    ----------------------------------------------------------------------------
    -- Edge cases: unknown growth, invalid wrap, single line, boundary.
    ----------------------------------------------------------------------------

    ["unknown growth with nil wrap renders as RIGHT/DOWN"] = function()
        assertTableEquals(Layout("DIAGONAL", nil), Layout("RIGHT", "DOWN"),
            "unknown growth falls back to RIGHT with default wrap DOWN")
    end,

    ["unknown growth with LEFT wrap renders as RIGHT/DOWN"] = function()
        -- LEFT is not a valid wrap for the effective (horizontal) orientation,
        -- so it falls to the orientation default, matching RIGHT/DOWN exactly.
        assertTableEquals(Layout("DIAGONAL", "LEFT"), Layout("RIGHT", "DOWN"),
            "unknown growth + invalid wrap falls back to RIGHT/DOWN")
    end,

    ["invalid wrap RIGHT + LEFT falls back to RIGHT/DOWN"] = function()
        assertTableEquals(Layout("RIGHT", "LEFT"), Layout("RIGHT", "DOWN"),
            "LEFT is invalid for horizontal growth; wrap resets to DOWN")
    end,

    ["invalid wrap UP + DOWN falls back to UP/RIGHT"] = function()
        assertTableEquals(Layout("UP", "DOWN"), Layout("UP", "RIGHT"),
            "DOWN is invalid for vertical growth; wrap resets to RIGHT")
    end,

    ["single line RIGHT/DOWN is one icon slot with directional offsets"] = function()
        local layout = OverlayLogic.ComputeGridLayout({
            growth = "RIGHT",
            wrap = "DOWN",
            perLine = 3,
            maxIcons = 2,
            iconSize = 10,
            spacing = 2,
        })
        assertEquals(layout.width, 10, "single line width = one icon slot")
        assertEquals(layout.height, 10, "single line height = one icon slot")
        assertTableEquals(layout.icons, { { x = 0, y = 0 }, { x = 12, y = 0 } },
            "single line offsets")
    end,

    ["single line wrap direction is positionally irrelevant"] = function()
        local down = OverlayLogic.ComputeGridLayout({
            growth = "RIGHT", wrap = "DOWN", perLine = 3, maxIcons = 2,
            iconSize = 10, spacing = 2,
        })
        local up = OverlayLogic.ComputeGridLayout({
            growth = "RIGHT", wrap = "UP", perLine = 3, maxIcons = 2,
            iconSize = 10, spacing = 2,
        })
        assertTableEquals(down.icons, up.icons,
            "with a single line, DOWN and UP wrap produce identical offsets")
    end,

    ["maxIcons equals perLine yields one full line"] = function()
        local layout = OverlayLogic.ComputeGridLayout({
            growth = "RIGHT", wrap = "DOWN", perLine = 3, maxIcons = 3,
            iconSize = 10, spacing = 2,
        })
        assertEquals(layout.width, 10, "container width = one icon slot")
        assertEquals(layout.height, 10, "container height = one icon slot")
        assertTableEquals(layout.icons,
            { { x = 0, y = 0 }, { x = 12, y = 0 }, { x = 24, y = 0 } },
            "maxIcons == perLine offsets")
    end,

    ----------------------------------------------------------------------------
    -- IsVerticalGrowth truth table.
    ----------------------------------------------------------------------------

    ["IsVerticalGrowth is true only for UP and DOWN"] = function()
        assertTrue(OverlayLogic.IsVerticalGrowth("UP"), "UP is vertical")
        assertTrue(OverlayLogic.IsVerticalGrowth("DOWN"), "DOWN is vertical")
        assertFalse(OverlayLogic.IsVerticalGrowth("LEFT"), "LEFT is horizontal")
        assertFalse(OverlayLogic.IsVerticalGrowth("RIGHT"), "RIGHT is horizontal")
        assertFalse(OverlayLogic.IsVerticalGrowth(nil), "nil is not vertical")
        assertFalse(OverlayLogic.IsVerticalGrowth("X"), "unknown is not vertical")
    end,

    ----------------------------------------------------------------------------
    -- DefaultWrapFor: RIGHT if vertical else DOWN.
    ----------------------------------------------------------------------------

    ["DefaultWrapFor returns DOWN for horizontal, RIGHT for vertical"] = function()
        assertEquals(OverlayLogic.DefaultWrapFor("RIGHT"), "DOWN", "RIGHT -> DOWN")
        assertEquals(OverlayLogic.DefaultWrapFor("LEFT"), "DOWN", "LEFT -> DOWN")
        assertEquals(OverlayLogic.DefaultWrapFor("UP"), "RIGHT", "UP -> RIGHT")
        assertEquals(OverlayLogic.DefaultWrapFor("DOWN"), "RIGHT", "DOWN -> RIGHT")
        assertEquals(OverlayLogic.DefaultWrapFor(nil), "DOWN", "nil -> DOWN")
    end,

    ----------------------------------------------------------------------------
    -- NormalizeWrap full matrix: valid perpendicular preserved, else default.
    ----------------------------------------------------------------------------

    ["NormalizeWrap preserves valid perpendicular wraps"] = function()
        assertEquals(OverlayLogic.NormalizeWrap("RIGHT", "UP"), "UP", "RIGHT + UP kept")
        assertEquals(OverlayLogic.NormalizeWrap("RIGHT", "DOWN"), "DOWN", "RIGHT + DOWN kept")
        assertEquals(OverlayLogic.NormalizeWrap("DOWN", "LEFT"), "LEFT", "DOWN + LEFT kept")
        assertEquals(OverlayLogic.NormalizeWrap("UP", "RIGHT"), "RIGHT", "UP + RIGHT kept")
    end,

    ["NormalizeWrap resets invalid or missing wraps to the default"] = function()
        assertEquals(OverlayLogic.NormalizeWrap("RIGHT", "LEFT"), "DOWN",
            "LEFT invalid for horizontal -> DOWN")
        assertEquals(OverlayLogic.NormalizeWrap("UP", "DOWN"), "RIGHT",
            "DOWN invalid for vertical -> RIGHT")
        assertEquals(OverlayLogic.NormalizeWrap("RIGHT", nil), "DOWN",
            "missing wrap for horizontal -> DOWN")
        assertEquals(OverlayLogic.NormalizeWrap("UP", nil), "RIGHT",
            "missing wrap for vertical -> RIGHT")
        assertEquals(OverlayLogic.NormalizeWrap("GARBAGE", "LEFT"), "DOWN",
            "unknown growth is horizontal; LEFT invalid -> DOWN")
    end,

    ----------------------------------------------------------------------------
    -- GetWrapOptions: horizontal list for horizontal/unknown/nil growth,
    -- vertical list for vertical growth. Default option first in each.
    ----------------------------------------------------------------------------

    ["GetWrapOptions returns the horizontal pair for RIGHT"] = function()
        assertTableEquals(UnitFrames:GetWrapOptions("RIGHT"),
            { { value = "DOWN", name = "Down" }, { value = "UP", name = "Up" } },
            "RIGHT wrap options")
    end,

    ["GetWrapOptions returns the horizontal pair for LEFT"] = function()
        assertTableEquals(UnitFrames:GetWrapOptions("LEFT"),
            { { value = "DOWN", name = "Down" }, { value = "UP", name = "Up" } },
            "LEFT wrap options")
    end,

    ["GetWrapOptions returns the vertical pair for UP"] = function()
        assertTableEquals(UnitFrames:GetWrapOptions("UP"),
            { { value = "RIGHT", name = "Right" }, { value = "LEFT", name = "Left" } },
            "UP wrap options")
    end,

    ["GetWrapOptions returns the vertical pair for DOWN"] = function()
        assertTableEquals(UnitFrames:GetWrapOptions("DOWN"),
            { { value = "RIGHT", name = "Right" }, { value = "LEFT", name = "Left" } },
            "DOWN wrap options")
    end,

    ["GetWrapOptions returns the horizontal pair for nil growth"] = function()
        assertTableEquals(UnitFrames:GetWrapOptions(nil),
            { { value = "DOWN", name = "Down" }, { value = "UP", name = "Up" } },
            "nil growth wrap options")
    end,

    ["GetWrapOptions returns the horizontal pair for unknown growth"] = function()
        assertTableEquals(UnitFrames:GetWrapOptions("GARBAGE"),
            { { value = "DOWN", name = "Down" }, { value = "UP", name = "Up" } },
            "unknown growth wrap options")
    end,
}
