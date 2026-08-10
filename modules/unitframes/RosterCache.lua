local _, NivUI = ...

NivUI.Roster = {}

local Roster = NivUI.Roster
local cache = {}
local groupUnits = { "player" }

for index = 1, 4 do
    groupUnits[#groupUnits + 1] = "party" .. index
end
for index = 1, 40 do
    groupUnits[#groupUnits + 1] = "raid" .. index
end

local function LiveOrCached(unit, key, value)
    if not issecretvalue(value) and value ~= nil then
        return value
    end
    local entry = cache[unit]
    return entry and entry[key]
end

function Roster:GetClass(unit)
    local _, class = UnitClass(unit)
    return LiveOrCached(unit, "class", class)
end

function Roster:GetRole(unit)
    return LiveOrCached(unit, "role", UnitGroupRolesAssigned(unit))
end

function Roster:IsLeader(unit)
    return LiveOrCached(unit, "isLeader", UnitIsGroupLeader(unit))
end

function Roster:IsAssist(unit)
    local isAssist = UnitIsGroupAssistant and UnitIsGroupAssistant(unit)
    return LiveOrCached(unit, "isAssist", isAssist)
end

local function WriteIfReadable(entry, key, value)
    if not issecretvalue(value) and value ~= nil then
        entry[key] = value
    end
end

local function SnapshotUnit(unit)
    if not UnitExists(unit) then
        cache[unit] = nil
        return
    end

    local entry = cache[unit] or {}
    local _, class = UnitClass(unit)
    WriteIfReadable(entry, "class", class)
    WriteIfReadable(entry, "role", UnitGroupRolesAssigned(unit))
    WriteIfReadable(entry, "isLeader", UnitIsGroupLeader(unit))
    if UnitIsGroupAssistant then
        WriteIfReadable(entry, "isAssist", UnitIsGroupAssistant(unit))
    end
    cache[unit] = entry
end

local function Snapshot()
    for _, unit in ipairs(groupUnits) do
        SnapshotUnit(unit)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
eventFrame:RegisterEvent("PARTY_LEADER_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", Snapshot)
