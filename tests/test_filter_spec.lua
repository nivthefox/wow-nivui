local NivUI, assertions = ...
local assertTrue = assertions.isTrue
local assertTableEquals = assertions.tablesEqual

local Filters = NivUI.Filters

return {
    ["nil config yields empty container inputs"] = function()
        assertTableEquals(Filters:BuildContainerInputs(nil, "HELPFUL"), {
            prefix = "HELPFUL",
            allowTokens = {},
            blockTokens = {},
            allowSpellMaps = {},
            blockSpellMaps = {},
        })
    end,

    ["nil prefix yields empty container inputs"] = function()
        assertTableEquals(Filters:BuildContainerInputs({ allow = { PLAYER = true } }, nil), {
            prefix = nil,
            allowTokens = {},
            blockTokens = {},
            allowSpellMaps = {},
            blockSpellMaps = {},
        })
    end,

    ["built-in filters remain unprefixed container tokens"] = function()
        local inputs = Filters:BuildContainerInputs({
            allow = { PLAYER = true },
            block = { RAID = true },
        }, "HELPFUL")

        assertTableEquals(inputs.allowTokens, { "PLAYER" })
        assertTableEquals(inputs.blockTokens, { "RAID" })
        assertTrue(inputs.prefix == "HELPFUL")
    end,
}
