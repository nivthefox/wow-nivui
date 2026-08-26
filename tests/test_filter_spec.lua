local NivUI, assertions = ...
local assertTrue = assertions.isTrue
local assertEquals = assertions.equals
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
            allowMissingRaidBuffs = false,
        })
    end,

    ["nil prefix yields empty container inputs"] = function()
        assertTableEquals(Filters:BuildContainerInputs({ allow = { PLAYER = true } }, nil), {
            prefix = nil,
            allowTokens = {},
            blockTokens = {},
            allowSpellMaps = {},
            blockSpellMaps = {},
            allowMissingRaidBuffs = false,
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

    ["Missing Raid Buffs is an Allow-only derived standard filter"] = function()
        local entry = Filters.BUILTIN[#Filters.BUILTIN]

        assertEquals(entry.token, "MISSING_RAID_BUFFS")
        assertEquals(entry.label, "Missing Raid Buffs")
        assertTrue(entry.allowOnly)
        assertTrue(entry.derived)
    end,

    ["Missing Raid Buffs is separated from Blizzard filter tokens"] = function()
        local inputs = Filters:BuildContainerInputs({
            allow = { MISSING_RAID_BUFFS = true, PLAYER = true },
            block = { MISSING_RAID_BUFFS = true, RAID = true },
        }, "HELPFUL")

        assertTableEquals(inputs.allowTokens, { "PLAYER" })
        assertTableEquals(inputs.blockTokens, { "RAID" })
        assertTrue(inputs.allowMissingRaidBuffs)
    end,
}
