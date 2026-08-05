--- Roster identity cache. In 12.1, UnitClass, UnitGroupRolesAssigned, and
--- leader/assist flags return secret values when a unit's identity is secret;
--- secrets throw on comparison and table indexing. Accessors read live and fall
--- back to values snapshotted out of combat. Units the cache has never seen
--- (target, focus, mid-combat joiners) resolve nil and render default.
NivUI = NivUI or {}
NivUI.Roster = {}

local Roster = NivUI.Roster
local cache = {}

local GROUP_TOKENS = { "player" }
for i = 1, 4 do GROUP_TOKENS[#GROUP_TOKENS + 1] = "party" .. i end
for i = 1, 40 do GROUP_TOKENS[#GROUP_TOKENS + 1] = "raid" .. i end

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

--- Secret reads keep the prior snapshot rather than clearing it, so roster
--- events that fire mid-combat cannot wipe the cache the fallback depends on.
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
    for _, unit in ipairs(GROUP_TOKENS) do
        SnapshotUnit(unit)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:RegisterEvent("PARTY_LEADER_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", Snapshot)
