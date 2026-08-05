local OverlayLogic = NivUI.OverlayLogic

local function CL(growth, wrap, perLine, iconSize, spacing)
    return OverlayLogic.ComputeContainerLayout({
        growth = growth or "RIGHT",
        wrap = wrap or "DOWN",
        perLine = perLine or 3,
        iconSize = iconSize or 10,
        spacing = spacing or 2,
    })
end

return {

["ComputeContainerLayout: RIGHT/DOWN yields Horizontal Right Down TOPLEFT"] = function()
    local cl = CL("RIGHT", "DOWN")
    assertEquals(cl.axis, "Horizontal", "axis")
    assertEquals(cl.horizontal, "Right", "horizontal")
    assertEquals(cl.vertical, "Down", "vertical")
    assertEquals(cl.anchorPoint, "TOPLEFT", "anchorPoint")
end,

["ComputeContainerLayout: LEFT/UP yields Horizontal Left Up BOTTOMRIGHT"] = function()
    local cl = CL("LEFT", "UP")
    assertEquals(cl.axis, "Horizontal", "axis")
    assertEquals(cl.horizontal, "Left", "horizontal")
    assertEquals(cl.vertical, "Up", "vertical")
    assertEquals(cl.anchorPoint, "BOTTOMRIGHT", "anchorPoint")
end,

["ComputeContainerLayout: UP/RIGHT yields Vertical Right Up BOTTOMLEFT"] = function()
    local cl = CL("UP", "RIGHT")
    assertEquals(cl.axis, "Vertical", "axis")
    assertEquals(cl.horizontal, "Right", "horizontal")
    assertEquals(cl.vertical, "Up", "vertical")
    assertEquals(cl.anchorPoint, "BOTTOMLEFT", "anchorPoint")
end,

["ComputeContainerLayout: DOWN/LEFT yields Vertical Left Down TOPRIGHT"] = function()
    local cl = CL("DOWN", "LEFT")
    assertEquals(cl.axis, "Vertical", "axis")
    assertEquals(cl.horizontal, "Left", "horizontal")
    assertEquals(cl.vertical, "Down", "vertical")
    assertEquals(cl.anchorPoint, "TOPRIGHT", "anchorPoint")
end,

["ComputeContainerLayout: unknown growth falls back to RIGHT"] = function()
    local cl = CL("GARBAGE", nil)
    assertEquals(cl.axis, "Horizontal", "axis")
    assertEquals(cl.anchorPoint, "TOPLEFT", "anchorPoint")
end,

["ComputeContainerLayout: maximumLineSize = perLine*icon + (perLine-1)*spacing"] = function()
    local cl = CL("RIGHT", "DOWN", 4, 20, 3)
    assertEquals(cl.maximumLineSize, 4 * 20 + 3 * 3, "maximumLineSize")
end,

["ComputeContainerLayout: single icon line size equals icon size"] = function()
    local cl = CL("RIGHT", "DOWN", 1, 30, 5)
    assertEquals(cl.maximumLineSize, 30, "maximumLineSize")
end,

["ComputeContainerLayout matches ComputeGridLayout origin corner for all 8 combos"] = function()
    local combos = {
        { "RIGHT", "DOWN" }, { "RIGHT", "UP" },
        { "LEFT", "DOWN" }, { "LEFT", "UP" },
        { "UP", "RIGHT" }, { "UP", "LEFT" },
        { "DOWN", "RIGHT" }, { "DOWN", "LEFT" },
    }
    for _, combo in ipairs(combos) do
        local grid = OverlayLogic.ComputeGridLayout({
            growth = combo[1], wrap = combo[2], perLine = 3, maxIcons = 5, iconSize = 10, spacing = 2,
        })
        local cl = CL(combo[1], combo[2])
        assertEquals(cl.anchorPoint, grid.anchor,
            combo[1] .. "/" .. combo[2] .. " anchorPoint mismatch")
    end
end,

["TranslateContainerAnchor: CENTER to TOPLEFT shifts by half-icon"] = function()
    local anchor = { point = "CENTER", relativeTo = "healthBar", relativePoint = "TOPLEFT", x = 0, y = 4 }
    local result = OverlayLogic.TranslateContainerAnchor(anchor, "TOPLEFT", 20)
    assertEquals(result.point, "TOPLEFT", "point")
    assertEquals(result.relativeTo, "healthBar", "relativeTo")
    assertEquals(result.relativePoint, "TOPLEFT", "relativePoint")
    assertEquals(result.x, -10, "x")
    assertEquals(result.y, 14, "y")
end,

["TranslateContainerAnchor: TOPLEFT to TOPLEFT is zero delta"] = function()
    local anchor = { point = "TOPLEFT", relativeTo = "frame", relativePoint = "TOPLEFT", x = 5, y = -3 }
    local result = OverlayLogic.TranslateContainerAnchor(anchor, "TOPLEFT", 20)
    assertEquals(result.point, "TOPLEFT", "point")
    assertEquals(result.x, 5, "x unchanged")
    assertEquals(result.y, -3, "y unchanged")
end,

["TranslateContainerAnchor: BOTTOMRIGHT origin shifts correctly"] = function()
    local anchor = { point = "TOPLEFT", relativeTo = "frame", relativePoint = "TOPRIGHT", x = 2, y = 0 }
    local result = OverlayLogic.TranslateContainerAnchor(anchor, "BOTTOMRIGHT", 16)
    assertEquals(result.point, "BOTTOMRIGHT", "point")
    assertEquals(result.x, 2 + 16, "x")
    assertEquals(result.y, 0 - 16, "y")
end,

["TranslateContainerAnchor: nil point defaults to CENTER"] = function()
    local anchor = { relativeTo = "frame", x = 0, y = 0 }
    local result = OverlayLogic.TranslateContainerAnchor(anchor, "TOPLEFT", 10)
    assertEquals(result.point, "TOPLEFT", "point")
    assertEquals(result.relativePoint, "CENTER", "relativePoint defaults to input point")
    assertEquals(result.x, -5, "x")
    assertEquals(result.y, 5, "y")
end,

["BuildContainerGroupSpecs: empty allow/block yields one unrestricted group"] = function()
    local specs = OverlayLogic.BuildContainerGroupSpecs({
        prefix = "HELPFUL", allowTokens = {}, blockTokens = {},
        allowSpellMaps = {}, blockSpellMaps = {},
    })
    assertEquals(#specs, 1, "count")
    assertEquals(specs[1].filterString, "HELPFUL", "filterString")
    assertNil(specs[1].includeSpellIDs, "no includes")
    assertNil(specs[1].excludeSpellIDs, "no excludes")
end,

["BuildContainerGroupSpecs: block tokens append !TOKEN to base"] = function()
    local specs = OverlayLogic.BuildContainerGroupSpecs({
        prefix = "HARMFUL", allowTokens = { "RAID" }, blockTokens = { "PLAYER", "CANCELABLE" },
        allowSpellMaps = {}, blockSpellMaps = {},
    })
    assertEquals(#specs, 1, "one allow-builtin group")
    assertEquals(specs[1].filterString, "HARMFUL|!PLAYER|!CANCELABLE|RAID", "filterString")
end,

["BuildContainerGroupSpecs: each allow-builtin gets its own group"] = function()
    local specs = OverlayLogic.BuildContainerGroupSpecs({
        prefix = "HELPFUL", allowTokens = { "RAID", "PLAYER" }, blockTokens = {},
        allowSpellMaps = {}, blockSpellMaps = {},
    })
    assertEquals(#specs, 2, "count")
    assertEquals(specs[1].filterString, "HELPFUL|RAID", "first")
    assertEquals(specs[2].filterString, "HELPFUL|PLAYER", "second")
end,

["BuildContainerGroupSpecs: allow-spells produce one group with includeSpellIDs"] = function()
    local spells1 = { [774] = true, [8936] = true }
    local spells2 = { [61295] = true }
    local specs = OverlayLogic.BuildContainerGroupSpecs({
        prefix = "HELPFUL", allowTokens = {}, blockTokens = {},
        allowSpellMaps = { spells1, spells2 }, blockSpellMaps = {},
    })
    assertEquals(#specs, 1, "one spell group")
    assertTrue(specs[1].includeSpellIDs[774], "774")
    assertTrue(specs[1].includeSpellIDs[8936], "8936")
    assertTrue(specs[1].includeSpellIDs[61295], "61295")
end,

["BuildContainerGroupSpecs: block-spells populate excludeSpellIDs"] = function()
    local blockSpells = { [12345] = true }
    local specs = OverlayLogic.BuildContainerGroupSpecs({
        prefix = "HELPFUL", allowTokens = { "RAID" }, blockTokens = {},
        allowSpellMaps = {}, blockSpellMaps = { blockSpells },
    })
    assertTrue(specs[1].excludeSpellIDs[12345], "exclude on builtin group")
end,

["BuildContainerGroupSpecs: mixed builtins and spells produce N+1 groups"] = function()
    local spells = { [774] = true }
    local specs = OverlayLogic.BuildContainerGroupSpecs({
        prefix = "HELPFUL", allowTokens = { "RAID", "PLAYER" }, blockTokens = {},
        allowSpellMaps = { spells }, blockSpellMaps = {},
    })
    assertEquals(#specs, 3, "2 builtin + 1 spell")
    assertTrue(specs[3].includeSpellIDs[774], "spell group is last")
end,

}
