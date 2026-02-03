local SoulShardsBarModule = NivUI.SegmentedBarBase.CreateModule({
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

NivUI.SoulShardsBarModule = SoulShardsBarModule
