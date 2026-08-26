local NivUI, assertions = ...
local assertEquals = assertions.equals
local assertFalse = assertions.isFalse
local assertNotNil = assertions.isNotNil
local assertTrue = assertions.isTrue

local function contains(list, expected)
    for _, value in ipairs(list) do
        if value == expected then
            return true
        end
    end
    return false
end

return {
    ["threat text is a disabled style widget by default"] = function()
        local config = NivUI.UnitFrames.DEFAULT_STYLE.threatText

        assertNotNil(config, "threat text defaults")
        assertFalse(config.enabled, "default enabled state")
        assertEquals(config.width, 60, "default width")
        assertEquals(config.colorMode, "threat", "default color mode")
        assertTrue(config.invertForTanks, "default tank inversion")
        assertEquals(config.safeColor.r, 1, "default safe red")
        assertEquals(config.safeColor.g, 1, "default safe green")
        assertEquals(config.safeColor.b, 1, "default safe blue")
        assertEquals(config.warningColor.r, 1, "default warning red")
        assertEquals(config.warningColor.g, 0.5, "default warning green")
        assertEquals(config.warningColor.b, 0, "default warning blue")
        assertEquals(config.dangerColor.r, 1, "default danger red")
        assertEquals(config.dangerColor.g, 0, "default danger green")
        assertEquals(config.dangerColor.b, 0, "default danger blue")
        assertEquals(NivUI.UnitFrames.WIDGET_NAMES.threatText, "Threat Lead", "display name")
        assertTrue(contains(NivUI.UnitFrames.WIDGET_ORDER, "threatText"), "widget order")
    end,

    ["threat text exposes text and anchor controls"] = function()
        local tabs = NivUI.UnitFrames.WidgetConfigs.threatText
        local keys = {}

        assertNotNil(tabs, "threat text settings")
        for _, tab in ipairs(tabs) do
            for _, entry in ipairs(tab.entries) do
                keys[entry.key] = true
            end
        end

        for _, key in ipairs({
            "enabled",
            "width",
            "font",
            "fontSize",
            "fontOutline",
            "alignment",
            "anchor.relativeTo",
            "anchor.point",
            "anchor.relativePoint",
            "anchor.x",
            "anchor.y",
            "strata",
            "frameLevel",
            "colorMode",
            "color",
            "invertForTanks",
            "safeColor",
            "warningColor",
            "dangerColor",
        }) do
            assertTrue(keys[key], key .. " setting")
        end

        assertNotNil(NivUI.UnitFrames.THREAT_TEXT_COLOR_MODES, "threat color modes")
    end,
}
