local ChiBarModule = NivUI.SegmentedBarBase.CreateModule({
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

NivUI.ChiBarModule = ChiBarModule
