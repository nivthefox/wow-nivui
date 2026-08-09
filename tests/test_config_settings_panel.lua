local NivUI, assertions = ...
local assertEquals = assertions.equals

local SettingsPanel = NivUI.Config.SettingsPanel

return {
    ["nested settings paths read existing values"] = function()
        local data = { anchor = { offset = { x = 14 } } }

        assertEquals(SettingsPanel.GetValue(data, "anchor.offset.x"), 14, "nested value")
        assertEquals(SettingsPanel.GetValue(data, "anchor.missing.x"), nil, "missing value")
    end,

    ["nested settings paths create intermediate tables"] = function()
        local data = {}

        SettingsPanel.SetValue(data, "anchor.offset.x", 18)

        assertEquals(data.anchor.offset.x, 18, "created nested value")
    end,

    ["nested settings paths replace malformed intermediate values"] = function()
        local data = { anchor = "invalid" }

        SettingsPanel.SetValue(data, "anchor.offset.x", 22)

        assertEquals(data.anchor.offset.x, 22, "repaired nested value")
    end,
}
