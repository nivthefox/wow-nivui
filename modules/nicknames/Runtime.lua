local _, NivUI = ...

local Nicknames = NivUI.Nicknames
local NameRefresh = NivUI.UnitFrames.Runtime.NameRefresh

NivUI:RegisterProfileApplyCallback("nicknames", function()
    Nicknames:RepairProfile(NivUI:GetActiveProfile())
    NameRefresh.RefreshAll()
end)

NivUI:RegisterCallback("NicknamesChanged", function(data)
    if data and data.identity then
        NameRefresh.RefreshIdentity(data.identity)
    end
end)
