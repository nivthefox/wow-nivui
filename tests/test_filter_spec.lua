local NivUI, assertions = ...
local assertTrue = assertions.isTrue
local assertTableEquals = assertions.tablesEqual

local Filters = NivUI.Filters

return {
    ["nil config yields an empty spec"] = function()
        assertTableEquals(Filters:BuildSpec(nil, "HELPFUL"), {
            allowBuiltin = {},
            blockBuiltin = {},
            allowSpells = {},
            blockSpells = {},
            hasAllow = false,
        })
    end,

    ["nil prefix yields an empty spec"] = function()
        assertTableEquals(Filters:BuildSpec({ allow = { PLAYER = true } }, nil), {
            allowBuiltin = {},
            blockBuiltin = {},
            allowSpells = {},
            blockSpells = {},
            hasAllow = false,
        })
    end,

    ["built-in filters include the aura prefix"] = function()
        local spec = Filters:BuildSpec({
            allow = { PLAYER = true },
            block = { RAID = true },
        }, "HELPFUL")

        assertTableEquals(spec.allowBuiltin, { "HELPFUL|PLAYER" })
        assertTableEquals(spec.blockBuiltin, { "HELPFUL|RAID" })
        assertTrue(spec.hasAllow)
    end,
}
