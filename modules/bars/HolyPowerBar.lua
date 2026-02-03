local HolyPowerBarModule = NivUI.SegmentedBarBase.CreateModule({
    barType = "holyPower",
    powerType = Enum.PowerType.HolyPower,
    frameName = "NivUIHolyPowerBar",
    globalRef = "HolyPowerBar",
    defaultY = -340,
    checkResourceAvailable = function()
        local _, class = UnitClass("player")
        return class == "PALADIN"
    end,
    supportsPartialFill = false,
})

NivUI.HolyPowerBarModule = HolyPowerBarModule
