local NivUI, assertions = ...
local assertEquals = assertions.equals
local assertTableEquals = assertions.tablesEqual

local MissingRaidBuffs = NivUI.Filters.MissingRaidBuffs

return {
    ["the six raid buffs have stable provider and display order"] = function()
        local definitions = MissingRaidBuffs.DEFINITIONS

        assertEquals(#definitions, 6)
        assertTableEquals({
            definitions[1].providerClass,
            definitions[2].providerClass,
            definitions[3].providerClass,
            definitions[4].providerClass,
            definitions[5].providerClass,
            definitions[6].providerClass,
        }, { "MAGE", "SHAMAN", "WARRIOR", "PRIEST", "DRUID", "EVOKER" })
        assertTableEquals({
            definitions[1].name,
            definitions[2].name,
            definitions[3].name,
            definitions[4].name,
            definitions[5].name,
            definitions[6].name,
        }, {
            "Arcane Intellect",
            "Skyfury",
            "Battle Shout",
            "Power Word: Fortitude",
            "Mark of the Wild",
            "Blessing of the Bronze",
        })
    end,

    ["each raid buff carries every accepted aura spell ID"] = function()
        local definitions = MissingRaidBuffs.DEFINITIONS

        assertTableEquals(definitions[1].spellIDs, { 1459, 432778 })
        assertTableEquals(definitions[2].spellIDs, { 462854 })
        assertTableEquals(definitions[3].spellIDs, { 6673 })
        assertTableEquals(definitions[4].spellIDs, { 21562 })
        assertTableEquals(definitions[5].spellIDs, { 1126, 432661 })
        assertTableEquals(definitions[6].spellIDs, {
            381732, 381741, 381746, 381748, 381749, 381750, 381751,
            381752, 381753, 381754, 381756, 381757, 381758,
        })
    end,

    ["provider selection returns one ordered definition per available class"] = function()
        local definitions = MissingRaidBuffs:GetDefinitionsForClasses({
            PRIEST = true,
            MAGE = true,
            EVOKER = true,
        })

        assertEquals(#definitions, 3)
        assertEquals(definitions[1].name, "Arcane Intellect")
        assertEquals(definitions[2].name, "Power Word: Fortitude")
        assertEquals(definitions[3].name, "Blessing of the Bronze")
    end,
}
