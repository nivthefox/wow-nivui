local ComboPointsBarModule = NivUI.SegmentedBarBase.CreateModule({
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

NivUI.ComboPointsBarModule = ComboPointsBarModule
