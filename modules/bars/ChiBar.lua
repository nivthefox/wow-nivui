NivUI:RegisterClassBar("chi", {
    displayName = "Chi Bar",
    tabName = "Chi",
    sortOrder = 2,
    globalRef = "ChiBar",

    defaults = {
        point = "CENTER",
        x = 0,
        y = -250,
        width = 200,
        height = 20,
        spacing = 2,
        locked = true,
        visibility = "combat",
        emptyColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 },
        filledColor = { r = 0.0, g = 0.8, b = 0.6, a = 1.0 },
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
            barType = "chi",
            powerType = Enum.PowerType.Chi,
            frameName = "NivUIChiBar",
            globalRef = "ChiBar",
            defaultY = -250,
            checkResourceAvailable = function()
                local _, class = UnitClass("player")
                if class ~= "MONK" then
                    return false
                end
                return GetSpecialization() == 3
            end,
            supportsPartialFill = false,
        })
    end,
})
