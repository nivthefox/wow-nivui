local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Runtime = NivUI.UnitFrames.Runtime or {}

local MissingRaidBuffProvider = {}
NivUI.UnitFrames.Runtime.MissingRaidBuffProvider = MissingRaidBuffProvider

local widgets = setmetatable({}, { __mode = "k" })

local function AddUnitClass(classes, unit)
    if not UnitExists(unit) then
        return
    end

    local class = NivUI.Roster:GetClass(unit)
    if class then
        classes[class] = true
    end
end

function MissingRaidBuffProvider.CollectProviderClasses()
    local classes = {}
    if IsInRaid() then
        for index = 1, GetNumGroupMembers() do
            AddUnitClass(classes, "raid" .. index)
        end
        return classes
    end

    if not IsInGroup() then
        return classes
    end

    AddUnitClass(classes, "player")
    for index = 1, math.max(0, GetNumGroupMembers() - 1) do
        AddUnitClass(classes, "party" .. index)
    end
    return classes
end

function MissingRaidBuffProvider.RefreshAll()
    local classes = MissingRaidBuffProvider.CollectProviderClasses()
    for widget in pairs(widgets) do
        widget:SetMissingRaidBuffProviders(classes)
    end
end

function MissingRaidBuffProvider.Register(widget)
    if not widget or not widget.SetMissingRaidBuffProviders then
        return
    end

    widgets[widget] = true
    widget:SetMissingRaidBuffProviders(MissingRaidBuffProvider.CollectProviderClasses())
end

function MissingRaidBuffProvider.Unregister(widget)
    widgets[widget] = nil
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", MissingRaidBuffProvider.RefreshAll)
