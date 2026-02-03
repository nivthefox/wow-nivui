NivUI:RegisterClassBar("soulShards", {
    displayName = "Soul Shards Bar",
    tabName = "Shards",
    sortOrder = 6,
    globalRef = "SoulShardsBar",

    defaults = {
        point = "CENTER",
        x = 0,
        y = -370,
        width = 200,
        height = 20,
        spacing = 2,
        locked = true,
        visibility = "combat",
        emptyColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 },
        filledColor = { r = 0.58, g = 0.51, b = 0.79, a = 1.0 },
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
            barType = "soulShards",
            powerType = Enum.PowerType.SoulShards,
            frameName = "NivUISoulShardsBar",
            globalRef = "SoulShardsBar",
            defaultY = -370,
            checkResourceAvailable = function()
                local _, class = UnitClass("player")
                return class == "WARLOCK"
            end,
            supportsPartialFill = true,
        })
    end,
})
