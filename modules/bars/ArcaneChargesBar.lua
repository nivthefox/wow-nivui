local ArcaneChargesBarModule = NivUI.SegmentedBarBase.CreateModule({
    barType = "arcaneCharges",
    powerType = Enum.PowerType.ArcaneCharges,
    frameName = "NivUIArcaneChargesBar",
    globalRef = "ArcaneChargesBar",
    defaultY = -400,
    checkResourceAvailable = function()
        local _, class = UnitClass("player")
        if class ~= "MAGE" then
            return false
        end
        return GetSpecialization() == 1
    end,
    supportsPartialFill = false,
})

NivUI.ArcaneChargesBarModule = ArcaneChargesBarModule
