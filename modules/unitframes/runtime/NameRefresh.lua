local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Runtime = NivUI.UnitFrames.Runtime or {}

local NameRefresh = {}
NivUI.UnitFrames.Runtime.NameRefresh = NameRefresh

local registeredStates = setmetatable({}, { __mode = "k" })
local updateNameText

local function IsVisiblePlayerState(state)
    if type(state) ~= "table" or not state.customFrame or not state.customFrame:IsShown() then
        return false
    end
    return NivUI.Nicknames.GetUnitIdentity(state.unit) ~= nil
end

local function RefreshStates(predicate)
    if type(updateNameText) ~= "function" then
        return 0
    end

    local snapshot = NivUI.Nicknames:BeginResolutionPass()
    local refreshed = 0
    for state in pairs(registeredStates) do
        if IsVisiblePlayerState(state) and (not predicate or predicate(state)) then
            updateNameText(state, snapshot)
            refreshed = refreshed + 1
        end
    end
    return refreshed
end

function NameRefresh.RegisterState(state)
    if type(state) ~= "table" then
        return false
    end
    registeredStates[state] = true
    return true
end

function NameRefresh.UnregisterState(state)
    registeredStates[state] = nil
end

function NameRefresh.RefreshAll()
    return RefreshStates()
end

function NameRefresh.RefreshIdentity(identity)
    local normalized = NivUI.Nicknames.NormalizeIdentity(identity)
    if not normalized then
        return 0
    end
    return RefreshStates(function(state)
        return NivUI.Nicknames.GetUnitIdentity(state.unit) == normalized
    end)
end

function NameRefresh.Start(callback, tickerFactory, eventFrameFactory)
    updateNameText = callback
    tickerFactory = tickerFactory or function(tick)
        return C_Timer.NewTicker(1, tick)
    end
    tickerFactory(NameRefresh.RefreshAll)

    eventFrameFactory = eventFrameFactory or CreateFrame
    local eventFrame = eventFrameFactory("Frame")
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", NameRefresh.RefreshAll)
end
