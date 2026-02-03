NivUI:RegisterClassBar("comboPoints", {
    displayName = "Combo Points Bar",
    tabName = "Combo",
    sortOrder = 4,
    globalRef = "ComboPointsBar",

    defaults = {
        point = "CENTER",
        x = 0,
        y = -310,
        width = 200,
        height = 20,
        spacing = 2,
        locked = true,
        visibility = "combat",
        emptyColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 },
        filledColor = { r = 1.0, g = 0.96, b = 0.41, a = 1.0 },
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
            barType = "comboPoints",
            powerType = Enum.PowerType.ComboPoints,
            frameName = "NivUIComboPointsBar",
            globalRef = "ComboPointsBar",
            defaultY = -310,
            checkResourceAvailable = function()
                local _, class = UnitClass("player")
                if class == "ROGUE" then
                    return true
                end
                if class == "DRUID" then
                    return GetSpecialization() == 2
                end
                return false
            end,
            supportsPartialFill = false,
        })
    end,
})
