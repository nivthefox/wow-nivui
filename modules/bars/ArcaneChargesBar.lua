local _, NivUI = ...

local function IsAvailable()
    local _, class = UnitClass("player")
    return class == "MAGE" and GetSpecialization() == 1
end

NivUI:RegisterClassBar("arcaneCharges", {
    displayName = "Arcane Charges Bar",
    tabName = "Arcane",
    sortOrder = 7,
    globalRef = "ArcaneChargesBar",
    isAvailable = IsAvailable,

    defaults = {
        point = "CENTER",
        x = 0,
        y = -400,
        width = 160,
        height = 20,
        spacing = 2,
        visibility = "combat",
        emptyColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 },
        filledColor = { r = 0.1, g = 0.5, b = 0.9, a = 1.0 },
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
        { type = "header", text = "Size" },
        { type = "widthSlider", min = 60, max = 400 },
        { type = "heightSlider" },
        { type = "intervalSlider" },
    },

    createModule = function()
        return NivUI.SegmentedBarBase.CreateModule({
            barType = "arcaneCharges",
            powerType = Enum.PowerType.ArcaneCharges,
            frameName = "NivUIArcaneChargesBar",
            globalRef = "ArcaneChargesBar",
            defaultY = -400,
            checkResourceAvailable = IsAvailable,
            supportsPartialFill = false,
        })
    end,
})
