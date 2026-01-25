local EssenceBarModule = NivUI.SegmentedBarBase.CreateModule({
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

NivUI.EssenceBarModule = EssenceBarModule
