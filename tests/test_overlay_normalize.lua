-- tests/test_overlay_normalize.lua
-- Contract tests for NivUI.OverlayLogic.NormalizeOverlay and Overlays:Get.
--
-- NormalizeOverlay(config, defaults) mutates and returns config: it fills any
-- missing keys from defaults (deep-copying table-valued defaults so overlays do
-- not share sub-tables), preserves existing values, and removes the legacy
-- dispelIndicator key. Overlays:Get returns a normalized live record.

local function Normalize(config)
    return NivUI.OverlayLogic.NormalizeOverlay(config, NivUI.Overlays.DEFAULTS)
end

return {
    ["empty table gains all defaults"] = function()
        local config = Normalize({})
        assertEquals(config.displayType, "ICON", "displayType default")
        assertEquals(config.priority, 1, "priority default")
        assertTableEquals(config.color, { r = 1, g = 0, b = 0, a = 1 }, "color default")
        assertEquals(config.targetWidget, "healthBar", "targetWidget default")
        assertEquals(config.borderThickness, 2, "borderThickness default")
    end,

    ["existing values are preserved"] = function()
        local config = Normalize({ priority = 7, displayType = "FRAME" })
        assertEquals(config.priority, 7, "pre-set priority preserved")
        assertEquals(config.displayType, "FRAME", "pre-set displayType preserved")
    end,

    ["dispelIndicator key is removed if present"] = function()
        local config = Normalize({ dispelIndicator = "healthTint" })
        assertNil(config.dispelIndicator, "legacy dispelIndicator must be removed")
    end,

    ["mutates and returns the same table"] = function()
        local input = {}
        local output = Normalize(input)
        assertEquals(output, input, "NormalizeOverlay returns the config it mutated")
    end,

    ["table-valued defaults are deep-copied per config"] = function()
        local a = Normalize({})
        local b = Normalize({})
        a.color.r = 0.5
        assertEquals(b.color.r, 1, "mutating one config's color must not affect another")
        assertEquals(NivUI.Overlays.DEFAULTS.color.r, 1, "mutating a config must not affect DEFAULTS")

        a.duration.color.r = 0.5
        assertEquals(b.duration.color.r, 1,
            "mutating one config's nested duration.color must not affect another")
        assertEquals(NivUI.Overlays.DEFAULTS.duration.color.r, 1,
            "mutating a config's nested duration.color must not affect DEFAULTS")
    end,

    ["Overlays:Get normalizes a legacy-shaped record"] = function()
        NivUI.current.overlays["Legacy"] = { auraType = "HARMFUL", dispelIndicator = "healthTint" }
        local record = NivUI.Overlays:Get("Legacy")
        assertNotNil(record, "legacy record should be retrievable")
        assertEquals(record.auraType, "HARMFUL", "existing auraType preserved")
        assertEquals(record.displayType, "ICON", "legacy record normalized to ICON")
        assertEquals(record.priority, 1, "legacy record gains default priority")
        assertNil(record.dispelIndicator, "legacy dispelIndicator stripped on Get")
        NivUI.current.overlays["Legacy"] = nil
    end,
}
