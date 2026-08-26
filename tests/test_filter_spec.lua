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
            mineOnly = false,
        })
    end,

    ["nil prefix yields empty container inputs"] = function()
        assertTableEquals(Filters:BuildContainerInputs({ mineOnly = true }, nil), {
            prefix = nil,
            allowTokens = {},
            blockTokens = {},
            allowSpellMaps = {},
            blockSpellMaps = {},
            allowMissingRaidBuffs = false,
            mineOnly = false,
        })
    end,

    ["Mine Only is separated from built-in container tokens"] = function()
        local inputs = Filters:BuildContainerInputs({
            mineOnly = true,
            allow = { RAID = true },
            block = { RAID = true },
        }, "HELPFUL")

        assertTableEquals(inputs.allowTokens, { "RAID" })
        assertTableEquals(inputs.blockTokens, { "RAID" })
        assertTrue(inputs.prefix == "HELPFUL")
        assertTrue(inputs.mineOnly)
    end,

    ["Player is no longer a built-in matrix filter"] = function()
        for _, entry in ipairs(Filters.BUILTIN) do
            assertTrue(entry.token ~= "PLAYER")
        end
    end,

    ["Player remains reserved as a custom filter name"] = function()
        local success, message = Filters:CreateCustom("PLAYER")

        assertEquals(success, false)
        assertEquals(message, "That name is reserved")
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
            mineOnly = true,
            allow = { MISSING_RAID_BUFFS = true },
            block = { MISSING_RAID_BUFFS = true, RAID = true },
        }, "HELPFUL")

        assertTableEquals(inputs.allowTokens, {})
        assertTableEquals(inputs.blockTokens, { "RAID" })
        assertTrue(inputs.allowMissingRaidBuffs)
        assertTrue(inputs.mineOnly)
    end,
}
