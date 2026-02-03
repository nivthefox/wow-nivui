NivUI:RegisterClassBar("essence", {
    displayName = "Essence Bar",
    tabName = "Essence",
    sortOrder = 3,
    globalRef = "EssenceBar",

    defaults = {
        point = "CENTER",
        x = 0,
        y = -280,
        width = 200,
        height = 20,
        spacing = 2,
        locked = true,
        visibility = "combat",
        emptyColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 },
        filledColor = { r = 0.15, g = 0.75, b = 0.85, a = 1.0 },
        borderColor = { r = 0, g = 0, b = 0, a = 1 },
        updateInterval = 0.05,
    },

    configSections = {
        { type = "enable" },
        { type = "header", text = "General" },
        { type = "visibility" },
        { type = "header", text = "Appearance" },
        { type = "spacingSlider" },
        { type = "emptyColor" },
        { type = "filledColor" },
        { type = "borderColor" },
        { type = "header", text = "Position" },
        { type = "lockedCheckbox" },
        { type = "widthSlider", min = 60, max = 400 },
        { type = "heightSlider" },
        { type = "intervalSlider" },
    },

    createModule = function()
        return NivUI.SegmentedBarBase.CreateModule({
            barType = "essence",
            powerType = Enum.PowerType.Essence,
            frameName = "NivUIEssenceBar",
            globalRef = "EssenceBar",
            defaultY = -280,
            checkResourceAvailable = function()
                local ok, maxPower = pcall(UnitPowerMax, "player", Enum.PowerType.Essence)
                return ok and maxPower and maxPower > 0
            end,
            supportsPartialFill = true,
        })
    end,
})
