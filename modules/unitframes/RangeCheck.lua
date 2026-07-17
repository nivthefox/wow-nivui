--- Spell-based range checking fallback for when UnitInRange() returns
--- secret booleans in combat (12.0 Midnight taint).
---
--- Adapted from ElvUI's Range element. Uses C_Spell.IsSpellInRange() with
--- class-appropriate friendly spells to determine if a group member is in range.
--- Falls back to CheckInteractDistance() outside of combat when no spell data
--- is available.

NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local RangeCheck = {}
NivUI.UnitFrames.RangeCheck = RangeCheck

local IsSpellInRange = C_Spell.IsSpellInRange
local IsSpellInSpellBook = C_SpellBook.IsSpellInSpellBook

--- Spells used to check friendly range, keyed by class token.
--- Each entry is a table of { [spellID] = true } built at login.
local friendlySpells = {}

--- Raw spell data per class. Values are spell IDs for common friendly-target
--- spells with a range component.
local FRIENDLY_SPELL_DATA = {
    DEATHKNIGHT = { 47541 },  -- Death Coil
    DEMONHUNTER = {},
    DRUID       = { 8936 },   -- Regrowth
    EVOKER      = { 355913 }, -- Emerald Blossom
    HUNTER      = {},
    MAGE        = { 1459 },   -- Arcane Intellect
    MONK        = { 116670 }, -- Vivify
    PALADIN     = { 85673 },  -- Word of Glory
    PRIEST      = { 17 },     -- Power Word: Shield
    ROGUE       = { 36554 },  -- Shadowstep
    SHAMAN      = { 8004 },   -- Healing Surge
    WARLOCK     = { 5697 },   -- Unending Breath
    WARRIOR     = {},
}

--- Builds the active spell list for the player's class, filtering to spells
--- actually in the spellbook. Called at PLAYER_LOGIN and when talents change.
function RangeCheck.UpdateSpellList()
    local _, class = UnitClass("player")
    local data = FRIENDLY_SPELL_DATA[class]
    local spells = {}

    if data then
        for _, spellID in ipairs(data) do
            if IsSpellInSpellBook(spellID, nil, true) then
                spells[spellID] = true
            end
        end
    end

    friendlySpells = spells
end

--- Checks if a unit is in range of any known friendly spell.
--- @param unit string The unit token
--- @return boolean|nil True if in range, false if out of range, nil if no spell could check
local function IsUnitInSpellRange(unit)
    local failed = false
    for spellID in pairs(friendlySpells) do
        local inRange = IsSpellInRange(spellID, unit)
        if inRange then
            return true
        elseif inRange ~= nil then
            failed = true
        end
    end

    if failed then
        return false
    end

    return nil
end

--- Determines if a friendly unit is in range, handling secret boolean values.
--- Uses UnitInRange() first; if the result is tainted, falls back to spell
--- range checking. Outside combat, falls back to CheckInteractDistance().
--- @param unit string The unit token
--- @return boolean inRange Whether the unit should be treated as in range
--- @return boolean checked Whether range was actually checked
function RangeCheck.IsInRange(unit)
    local inRange, checkedRange = UnitInRange(unit)

    if not issecretvalue(checkedRange) and not issecretvalue(inRange) then
        return inRange, checkedRange
    end

    -- UnitInRange returned secret values; fall back to spell range.
    local spellResult = IsUnitInSpellRange(unit)
    if spellResult ~= nil then
        return spellResult, true
    end

    -- No spell data available; try interact distance outside combat.
    if not InCombatLockdown() then
        return CheckInteractDistance(unit, 4), true
    end

    -- No way to check; assume in range.
    return true, false
end

--- Event frame for updating the spell list when talents change.
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:SetScript("OnEvent", function()
    RangeCheck.UpdateSpellList()
end)
