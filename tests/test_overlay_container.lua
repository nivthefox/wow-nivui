local NivUI, assertions = ...
local assertEquals = assertions.equals
local assertNil = assertions.isNil
local assertTrue = assertions.isTrue

local OverlayLogic = NivUI.OverlayLogic

local function ComputeLayout(growth, wrap, perLine, iconSize, spacing)
    return OverlayLogic.ComputeContainerLayout({
        growth = growth or "RIGHT",
        wrap = wrap or "DOWN",
        perLine = perLine or 3,
        iconSize = iconSize or 10,
        spacing = spacing or 2,
    })
end

return {
    ["container layout preserves every grid origin corner"] = function()
        local combinations = {
            { "RIGHT", "DOWN" },
            { "RIGHT", "UP" },
            { "LEFT", "DOWN" },
            { "LEFT", "UP" },
            { "UP", "RIGHT" },
            { "UP", "LEFT" },
            { "DOWN", "RIGHT" },
            { "DOWN", "LEFT" },
        }

        for _, combination in ipairs(combinations) do
            local grid = OverlayLogic.ComputeGridLayout({
                growth = combination[1],
                wrap = combination[2],
                perLine = 3,
                maxIcons = 5,
                iconSize = 10,
                spacing = 2,
            })
            local container = ComputeLayout(combination[1], combination[2])
            assertEquals(container.anchorPoint, grid.anchor,
                combination[1] .. "/" .. combination[2] .. " anchor")
        end
    end,

    ["horizontal container layout translates growth and wrapping"] = function()
        local rightDown = ComputeLayout("RIGHT", "DOWN")
        assertEquals(rightDown.axis, "Horizontal")
        assertEquals(rightDown.horizontal, "Right")
        assertEquals(rightDown.vertical, "Down")
        assertEquals(rightDown.anchorPoint, "TOPLEFT")

        local leftUp = ComputeLayout("LEFT", "UP")
        assertEquals(leftUp.axis, "Horizontal")
        assertEquals(leftUp.horizontal, "Left")
        assertEquals(leftUp.vertical, "Up")
        assertEquals(leftUp.anchorPoint, "BOTTOMRIGHT")
    end,

    ["vertical container layout translates growth and wrapping"] = function()
        local upRight = ComputeLayout("UP", "RIGHT")
        assertEquals(upRight.axis, "Vertical")
        assertEquals(upRight.horizontal, "Right")
        assertEquals(upRight.vertical, "Up")
        assertEquals(upRight.anchorPoint, "BOTTOMLEFT")

        local downLeft = ComputeLayout("DOWN", "LEFT")
        assertEquals(downLeft.axis, "Vertical")
        assertEquals(downLeft.horizontal, "Left")
        assertEquals(downLeft.vertical, "Down")
        assertEquals(downLeft.anchorPoint, "TOPRIGHT")
    end,

    ["container layout calculates the maximum line size"] = function()
        assertEquals(ComputeLayout("RIGHT", "DOWN", 4, 20, 3).maximumLineSize, 89)
        assertEquals(ComputeLayout("RIGHT", "DOWN", 1, 30, 5).maximumLineSize, 30)
    end,

    ["container layout treats unknown growth as right"] = function()
        local layout = ComputeLayout("GARBAGE")
        assertEquals(layout.axis, "Horizontal")
        assertEquals(layout.anchorPoint, "TOPLEFT")
    end,

    ["container anchors translate from configured centers to container origins"] = function()
        local result = OverlayLogic.TranslateContainerAnchor({
            point = "CENTER",
            relativeTo = "healthBar",
            relativePoint = "TOPLEFT",
            x = 0,
            y = 4,
        }, "TOPLEFT", 20)

        assertEquals(result.point, "TOPLEFT")
        assertEquals(result.relativeTo, "healthBar")
        assertEquals(result.relativePoint, "TOPLEFT")
        assertEquals(result.x, -10)
        assertEquals(result.y, 14)
    end,

    ["container anchors preserve matching origins"] = function()
        local result = OverlayLogic.TranslateContainerAnchor({
            point = "TOPLEFT",
            relativeTo = "frame",
            relativePoint = "TOPLEFT",
            x = 5,
            y = -3,
        }, "TOPLEFT", 20)

        assertEquals(result.point, "TOPLEFT")
        assertEquals(result.x, 5)
        assertEquals(result.y, -3)
    end,

    ["container anchors translate to bottom-right origins"] = function()
        local result = OverlayLogic.TranslateContainerAnchor({
            point = "TOPLEFT",
            relativeTo = "frame",
            relativePoint = "TOPRIGHT",
            x = 2,
            y = 0,
        }, "BOTTOMRIGHT", 16)

        assertEquals(result.point, "BOTTOMRIGHT")
        assertEquals(result.x, 18)
        assertEquals(result.y, -16)
    end,

    ["container anchors default missing points to center"] = function()
        local result = OverlayLogic.TranslateContainerAnchor({
            relativeTo = "frame",
            x = 0,
            y = 0,
        }, "TOPLEFT", 10)

        assertEquals(result.point, "TOPLEFT")
        assertEquals(result.relativePoint, "CENTER")
        assertEquals(result.x, -5)
        assertEquals(result.y, 5)
    end,

    ["an empty filter configuration produces one unrestricted group"] = function()
        local groups = OverlayLogic.BuildContainerGroupSpecs({
            prefix = "HELPFUL",
            allowTokens = {},
            blockTokens = {},
            allowSpellMaps = {},
            blockSpellMaps = {},
        })

        assertEquals(#groups, 1)
        assertEquals(groups[1].filterString, "HELPFUL")
        assertNil(groups[1].includeSpellIDs)
        assertNil(groups[1].excludeSpellIDs)
    end,

    ["built-in allow filters produce separate container groups"] = function()
        local groups = OverlayLogic.BuildContainerGroupSpecs({
            prefix = "HELPFUL",
            allowTokens = { "RAID", "PLAYER" },
            blockTokens = { "CANCELABLE" },
            allowSpellMaps = {},
            blockSpellMaps = {},
        })

        assertEquals(#groups, 2)
        assertEquals(groups[1].filterString, "HELPFUL|!CANCELABLE|RAID")
        assertEquals(groups[2].filterString, "HELPFUL|!CANCELABLE|PLAYER")
    end,

    ["spell filters merge into container include and exclude maps"] = function()
        local groups = OverlayLogic.BuildContainerGroupSpecs({
            prefix = "HELPFUL",
            allowTokens = {},
            blockTokens = {},
            allowSpellMaps = {
                { [774] = true, [8936] = true },
                { [61295] = true },
            },
            blockSpellMaps = {
                { [12345] = true },
            },
        })

        assertEquals(#groups, 1)
        assertTrue(groups[1].includeSpellIDs[774])
        assertTrue(groups[1].includeSpellIDs[8936])
        assertTrue(groups[1].includeSpellIDs[61295])
        assertTrue(groups[1].excludeSpellIDs[12345])
    end,

    ["built-in and spell allows produce independent container groups"] = function()
        local groups = OverlayLogic.BuildContainerGroupSpecs({
            prefix = "HARMFUL",
            allowTokens = { "RAID", "PLAYER" },
            blockTokens = {},
            allowSpellMaps = {
                { [774] = true },
            },
            blockSpellMaps = {},
        })

        assertEquals(#groups, 3)
        assertTrue(groups[3].includeSpellIDs[774])
    end,
}
