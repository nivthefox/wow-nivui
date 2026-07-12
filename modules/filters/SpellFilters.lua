--- Aura filtering model: Blizzard's built-in filter modifiers plus user-defined
--- custom spell lists. Each aura widget independently toggles Allow/Block per filter.
--- Custom lists are profile-scoped under NivUI.current.customFilters.
NivUI = NivUI or {}
NivUI.Filters = NivUI.Filters or {}

local Filters = NivUI.Filters

--- Built-in Blizzard aura filter modifiers (12.x), in display order.
Filters.BUILTIN = {
    { token = "PLAYER", label = "Player" },
    { token = "RAID", label = "Raid" },
    { token = "RAID_IN_COMBAT", label = "Raid In Combat" },
    { token = "RAID_PLAYER_DISPELLABLE", label = "Raid Player Dispellable" },
    { token = "BIG_DEFENSIVE", label = "Big Defensive" },
    { token = "EXTERNAL_DEFENSIVE", label = "External Defensive" },
    { token = "CROWD_CONTROL", label = "Crowd Control" },
    { token = "CANCELABLE", label = "Cancelable" },
    { token = "NOT_CANCELABLE", label = "Not Cancelable" },
}

local BUILTIN_TOKENS = {}
for _, entry in ipairs(Filters.BUILTIN) do
    BUILTIN_TOKENS[entry.token] = true
end

local function GetStore()
    local profile = NivUI.current
    if not profile then return nil end
    profile.customFilters = profile.customFilters or {}
    return profile.customFilters
end

--- @return table Sorted array of custom filter names
function Filters:GetCustomNames()
    local store = GetStore()
    local names = {}
    if store then
        for name in pairs(store) do
            names[#names + 1] = name
        end
        table.sort(names)
    end
    return names
end

--- @return boolean, string|nil True on success; false, error message otherwise
function Filters:CreateCustom(name)
    name = type(name) == "string" and strtrim(name) or ""
    if name == "" then
        return false, "Name cannot be empty"
    end
    if BUILTIN_TOKENS[name] then
        return false, "That name is reserved"
    end
    local store = GetStore()
    if not store then
        return false, "No active profile"
    end
    if store[name] then
        return false, "A filter named '" .. name .. "' already exists"
    end
    store[name] = { spells = {} }
    NivUI:TriggerEvent("CustomFiltersChanged", { name = name })
    return true
end

function Filters:DeleteCustom(name)
    local store = GetStore()
    if store and store[name] then
        store[name] = nil
        NivUI:TriggerEvent("CustomFiltersChanged", { name = name, deleted = true })
    end
end

--- @return table The spellID -> saved name table for a custom filter (empty if missing)
function Filters:GetCustomSpells(name)
    local store = GetStore()
    local filter = store and store[name]
    return filter and filter.spells or {}
end

--- Resolves user input (a spellID or name) to spell data.
--- @return number|nil spellID, string|nil name, number|string|nil icon
function Filters:ResolveSpell(input)
    if type(input) ~= "string" then input = tostring(input or "") end
    input = strtrim(input)
    if input == "" then return nil end
    if not C_Spell or not C_Spell.GetSpellInfo then return nil end

    local info = C_Spell.GetSpellInfo(tonumber(input) or input)
    if not info or not info.spellID then return nil end
    return info.spellID, info.name, info.iconID
end

--- Adds a spell (by ID or name) to a custom filter.
--- @return number|nil spellID, string message (name on success, error on failure)
function Filters:AddSpell(name, input)
    local store = GetStore()
    local filter = store and store[name]
    if not filter then
        return nil, "Unknown filter"
    end
    local spellID, spellName = self:ResolveSpell(input)
    if not spellID then
        return nil, "No spell found for '" .. tostring(input) .. "'"
    end
    filter.spells[spellID] = spellName or true
    NivUI:TriggerEvent("CustomFiltersChanged", { name = name })
    return spellID, spellName or ("Spell " .. spellID)
end

function Filters:RemoveSpell(name, spellID)
    local spells = self:GetCustomSpells(name)
    if spells[spellID] ~= nil then
        spells[spellID] = nil
        NivUI:TriggerEvent("CustomFiltersChanged", { name = name })
    end
end

--- @return string name, number|string|nil icon
function Filters:GetDisplay(spellID, savedName)
    local name, icon
    if C_Spell then
        if C_Spell.GetSpellName then name = C_Spell.GetSpellName(spellID) end
        if C_Spell.GetSpellTexture then icon = C_Spell.GetSpellTexture(spellID) end
    end
    if not name then
        name = (type(savedName) == "string" and savedName) or ("Spell " .. tostring(spellID))
    end
    return name, icon
end

--- @return table Sorted array of { spellID, name, icon } for a custom filter
function Filters:GetSortedSpells(name)
    local spells = self:GetCustomSpells(name)
    local entries = {}
    for spellID, savedName in pairs(spells) do
        local displayName, icon = self:GetDisplay(spellID, savedName)
        entries[#entries + 1] = { spellID = spellID, name = displayName, icon = icon }
    end
    table.sort(entries, function(a, b)
        return (a.name or "") < (b.name or "")
    end)
    return entries
end

--- Resolves a widget's allow/block config into concrete matching sets for CollectAuras.
--- @param config table The aura widget config (with .allow / .block key sets)
--- @param prefix string "HELPFUL" or "HARMFUL"
--- @return table Spec with allowBuiltin/blockBuiltin filter strings, allowSpells/blockSpells sets, hasAllow flag
function Filters:BuildSpec(config, prefix)
    local spec = { allowBuiltin = {}, blockBuiltin = {}, allowSpells = {}, blockSpells = {} }
    local allow, block = config.allow, config.block

    for _, entry in ipairs(self.BUILTIN) do
        if allow and allow[entry.token] then
            spec.allowBuiltin[#spec.allowBuiltin + 1] = prefix .. "|" .. entry.token
        end
        if block and block[entry.token] then
            spec.blockBuiltin[#spec.blockBuiltin + 1] = prefix .. "|" .. entry.token
        end
    end

    local store = GetStore()
    if store then
        for name, filter in pairs(store) do
            if allow and allow[name] then
                spec.allowSpells[#spec.allowSpells + 1] = filter.spells
            end
            if block and block[name] then
                spec.blockSpells[#spec.blockSpells + 1] = filter.spells
            end
        end
    end

    spec.hasAllow = #spec.allowBuiltin > 0 or #spec.allowSpells > 0
    return spec
end
