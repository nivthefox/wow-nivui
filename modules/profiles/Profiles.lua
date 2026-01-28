NivUI.Profiles = {}

--- Returns the character key for per-character profile selection.
--- Format: "CharacterName-RealmName"
--- @return string
function NivUI.Profiles:GetCharKey()
    return UnitName("player") .. "-" .. GetRealmName()
end

--- Returns the name of the currently active profile.
--- @return string
function NivUI.Profiles:GetCurrentProfileName()
    return NivUI_CurrentProfile or "Default"
end

--- Returns a sorted list of all profile names.
--- @return table
function NivUI.Profiles:GetAllProfiles()
    local names = {}
    if NivUI_DB and NivUI_DB.profiles then
        for name in pairs(NivUI_DB.profiles) do
            table.insert(names, name)
        end
        table.sort(names)
    end
    return names
end

--- Checks if a profile with the given name exists.
--- @param name string
--- @return boolean
function NivUI.Profiles:ProfileExists(name)
    return NivUI_DB
        and NivUI_DB.profiles
        and NivUI_DB.profiles[name] ~= nil
end

--- Creates a new profile with the given name.
--- @param name string The name for the new profile
--- @param copyFrom string|nil Optional profile name to copy settings from
--- @return boolean success
--- @return string|nil errorMessage
function NivUI.Profiles:CreateProfile(name, copyFrom)
    if not name or name == "" then
        return false, "Profile name cannot be empty"
    end

    if self:ProfileExists(name) then
        return false, "Profile '" .. name .. "' already exists"
    end

    local source = {}
    if copyFrom and self:ProfileExists(copyFrom) then
        source = NivUI.DeepCopy(NivUI_DB.profiles[copyFrom])
    end

    NivUI_DB.profiles[name] = source
    print("|cff00ff00NivUI:|r Created profile '" .. name .. "'")
    return true
end

--- Switches to the specified profile.
--- @param name string The profile name to switch to
--- @return boolean success
function NivUI.Profiles:SwitchProfile(name)
    if not self:ProfileExists(name) then
        print("|cffff0000NivUI:|r Profile '" .. name .. "' does not exist")
        return false
    end

    NivUI_CurrentProfile = name
    NivUI.current = NivUI_DB.profiles[name]

    NivUI:InitializeDB()
    NivUI:ApplySettings()

    NivUI:TriggerEvent("ProfileSwitched", { profileName = name })

    print("|cff00ff00NivUI:|r Switched to profile '" .. name .. "'")
    return true
end

--- Deletes the specified profile.
--- @param name string The profile name to delete
--- @return boolean success
--- @return string|nil errorMessage
function NivUI.Profiles:DeleteProfile(name)
    if name == "Default" then
        return false, "Cannot delete the Default profile"
    end

    if not self:ProfileExists(name) then
        return false, "Profile '" .. name .. "' does not exist"
    end

    local count = 0
    for _ in pairs(NivUI_DB.profiles) do
        count = count + 1
    end
    if count <= 1 then
        return false, "Cannot delete the last profile"
    end

    if NivUI_CurrentProfile == name then
        self:SwitchProfile("Default")
    end

    NivUI_DB.profiles[name] = nil
    print("|cff00ff00NivUI:|r Deleted profile '" .. name .. "'")
    return true
end

--- Resets the specified profile to defaults.
--- @param name string|nil The profile name to reset (defaults to current)
--- @return boolean success
--- @return string|nil errorMessage
function NivUI.Profiles:ResetProfile(name)
    name = name or NivUI_CurrentProfile
    if not self:ProfileExists(name) then
        return false, "Profile does not exist"
    end

    NivUI_DB.profiles[name] = {}

    if name == NivUI_CurrentProfile then
        NivUI.current = NivUI_DB.profiles[name]
        NivUI:InitializeDB()
        NivUI:ApplySettings()
    end

    print("|cff00ff00NivUI:|r Reset profile '" .. name .. "' to defaults")
    return true
end

--- Copies a profile to a new name.
--- @param fromName string The source profile name
--- @param toName string The destination profile name
--- @return boolean success
--- @return string|nil errorMessage
function NivUI.Profiles:CopyProfile(fromName, toName)
    if not self:ProfileExists(fromName) then
        return false, "Source profile does not exist"
    end

    if self:ProfileExists(toName) then
        return false, "Destination profile already exists"
    end

    NivUI_DB.profiles[toName] = NivUI.DeepCopy(NivUI_DB.profiles[fromName])
    print("|cff00ff00NivUI:|r Copied '" .. fromName .. "' to '" .. toName .. "'")
    return true
end

--- Renames a profile.
--- @param oldName string The current profile name
--- @param newName string The new profile name
--- @return boolean success
--- @return string|nil errorMessage
function NivUI.Profiles:RenameProfile(oldName, newName)
    if oldName == "Default" then
        return false, "Cannot rename the Default profile"
    end

    if not newName or newName == "" then
        return false, "New name cannot be empty"
    end

    if not self:ProfileExists(oldName) then
        return false, "Profile '" .. oldName .. "' does not exist"
    end

    if self:ProfileExists(newName) then
        return false, "Profile '" .. newName .. "' already exists"
    end

    NivUI_DB.profiles[newName] = NivUI_DB.profiles[oldName]
    NivUI_DB.profiles[oldName] = nil

    if NivUI_CurrentProfile == oldName then
        NivUI_CurrentProfile = newName
        NivUI.current = NivUI_DB.profiles[newName]
    end

    -- Update any spec mappings that reference the old name
    if NivUI_DB.charMeta then
        for _, charData in pairs(NivUI_DB.charMeta) do
            if charData.specProfileMap then
                for specID, profileName in pairs(charData.specProfileMap) do
                    if profileName == oldName then
                        charData.specProfileMap[specID] = newName
                    end
                end
            end
        end
    end

    NivUI:TriggerEvent("ProfileRenamed", { oldName = oldName, newName = newName })
    print("|cff00ff00NivUI:|r Renamed profile '" .. oldName .. "' to '" .. newName .. "'")
    return true
end

--- Encodes a table as a compact string using CBOR + optional compression + base64.
--- Format: "NIVUI:" + base64(compress?(cbor(table)))
--- @param tbl table The table to encode
--- @return string|nil encoded
local function EncodeCompact(tbl)
    local E = C_EncodingUtil

    local ok, bin = pcall(E.SerializeCBOR, tbl)
    if not ok or not bin then
        return nil
    end

    local payload = bin
    if E.CompressString and Enum.CompressionMethod and Enum.CompressionMethod.Deflate then
        local compressOk, compressed = pcall(E.CompressString, bin, Enum.CompressionMethod.Deflate)
        if compressOk and compressed and #compressed < #bin then
            payload = compressed
        end
    end

    local encodeOk, b64 = pcall(E.EncodeBase64, payload)
    if not encodeOk or not b64 then
        return nil
    end

    return "NIVUI:" .. b64
end

--- Decodes a compact string back to a table.
--- Handles "NIVUI:" prefix format (CBOR + optional compression + base64).
--- @param str string The encoded string
--- @return table|nil decoded
local function DecodeCompact(str)
    if not str:match("^NIVUI:") then
        return nil
    end

    local b64 = str:sub(7)
    local E = C_EncodingUtil

    local decodeOk, raw = pcall(E.DecodeBase64, b64)
    if not decodeOk or not raw then
        return nil
    end

    local payload = raw
    if E.DecompressString and Enum.CompressionMethod and Enum.CompressionMethod.Deflate then
        local decompressOk, decompressed = pcall(E.DecompressString, raw, Enum.CompressionMethod.Deflate)
        if decompressOk and decompressed then
            payload = decompressed
        end
    end

    local cborOk, tbl = pcall(E.DeserializeCBOR, payload)
    if not cborOk or type(tbl) ~= "table" then
        return nil
    end

    return tbl
end

--- Exports the current profile as a compact encoded string.
--- @return string
function NivUI.Profiles:ExportCurrentProfile()
    local snapshot = {
        addon = "NivUI",
        version = 1,
        kind = "profile",
        profile = NivUI_CurrentProfile,
        payload = NivUI.DeepCopy(NivUI.current),
    }

    return EncodeCompact(snapshot)
end

--- Exports a unit frame style as a compact encoded string.
--- @param styleName string The style name to export
--- @return string|nil exportString
--- @return string|nil errorMessage
function NivUI.Profiles:ExportStyle(styleName)
    local style = NivUI:GetStyle(styleName)
    if not style then
        return nil, "Style does not exist"
    end

    local snapshot = {
        addon = "NivUI",
        version = 1,
        kind = "style",
        styleName = styleName,
        payload = NivUI.DeepCopy(style),
    }

    return EncodeCompact(snapshot)
end

--- Decodes an import string and returns the payload for creating a new profile.
--- @param str string The import string
--- @return table|nil payload The profile data to create
--- @return string|nil errorMessage
function NivUI.Profiles:DecodeImport(str)
    if not str or str == "" then
        return nil, "Empty import string"
    end

    local data = DecodeCompact(str)
    if not data then
        return nil, "Invalid import format"
    end

    if data.addon ~= "NivUI" then
        return nil, "Not a NivUI export"
    end

    if data.kind ~= "profile" then
        return nil, "Not a profile export"
    end

    return data.payload
end

--- Creates a new profile from imported data.
--- @param name string The name for the new profile
--- @param payload table The profile data
--- @return boolean success
--- @return string|nil errorMessage
function NivUI.Profiles:CreateFromImport(name, payload)
    local success, err = self:CreateProfile(name)
    if not success then
        return false, err
    end

    NivUI_DB.profiles[name] = NivUI.DeepCopy(payload)
    print("|cff00ff00NivUI:|r Imported profile '" .. name .. "'")
    return true
end

---------------------------------------------------------------------
-- Spec-Based Profile Auto-Switch
--
-- Stored in NivUI_DB.charMeta[charKey]:
--   specAutoSwitch  (boolean)
--   specProfileMap  (table: specID -> profileName)
--
-- Combat-safe: defers switch to PLAYER_REGEN_ENABLED if in combat.
---------------------------------------------------------------------

--- Returns the per-character metadata table, creating it if needed.
--- @return table charMeta
local function GetCharMeta()
    NivUI_DB = NivUI_DB or {}
    NivUI_DB.charMeta = NivUI_DB.charMeta or {}

    local charKey = NivUI.Profiles:GetCharKey()
    local char = NivUI_DB.charMeta[charKey]
    if type(char) ~= "table" then
        char = {}
        NivUI_DB.charMeta[charKey] = char
    end

    if char.specAutoSwitch == nil then
        char.specAutoSwitch = false
    end
    if type(char.specProfileMap) ~= "table" then
        char.specProfileMap = {}
    end

    return char
end

--- Returns whether spec-based auto-switch is enabled.
--- @return boolean
function NivUI.Profiles:IsSpecAutoSwitchEnabled()
    local char = GetCharMeta()
    return char.specAutoSwitch == true
end

--- Enables or disables spec-based auto-switch.
--- @param enabled boolean
function NivUI.Profiles:SetSpecAutoSwitchEnabled(enabled)
    local char = GetCharMeta()
    char.specAutoSwitch = (enabled == true)
    if char.specAutoSwitch then
        self:ApplySpecProfileIfEnabled("TOGGLE_ON")
    end
end

--- Returns the profile mapped to a specific spec ID.
--- @param specID number
--- @return string|nil profileName
function NivUI.Profiles:GetSpecProfile(specID)
    if type(specID) ~= "number" then
        return nil
    end
    local char = GetCharMeta()
    local name = char.specProfileMap[specID]
    if type(name) ~= "string" or name == "" then
        return nil
    end
    return name
end

--- Maps a spec ID to a profile name.
--- @param specID number
--- @param profileName string|nil Pass nil or empty to clear the mapping
function NivUI.Profiles:SetSpecProfile(specID, profileName)
    if type(specID) ~= "number" then
        return
    end
    local char = GetCharMeta()

    if type(profileName) ~= "string" or profileName == "" then
        char.specProfileMap[specID] = nil
    else
        char.specProfileMap[specID] = profileName
    end

    if char.specAutoSwitch then
        local cur = self:GetPlayerSpecID()
        if cur == specID then
            self:ApplySpecProfileIfEnabled("MAP_CHANGED")
        end
    end
end

--- Returns the current player's spec ID.
--- @return number|nil specID
function NivUI.Profiles:GetPlayerSpecID()
    if type(GetSpecialization) ~= "function" then
        return nil
    end
    local idx = GetSpecialization()
    if not idx then
        return nil
    end
    local specID = select(1, GetSpecializationInfo(idx))
    if type(specID) ~= "number" then
        return nil
    end
    return specID
end

-- Combat-safe deferral
local pendingSpecSwitch = nil
local specDeferFrame = nil

local function RunAfterCombat(fn)
    if type(fn) ~= "function" then
        return
    end
    if InCombatLockdown() then
        pendingSpecSwitch = fn
        if not specDeferFrame then
            specDeferFrame = CreateFrame("Frame")
            specDeferFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
            specDeferFrame:SetScript("OnEvent", function()
                if pendingSpecSwitch then
                    local pending = pendingSpecSwitch
                    pendingSpecSwitch = nil
                    pending()
                end
            end)
        end
        return
    end
    fn()
end

--- Switches to the profile mapped to the current spec if auto-switch is enabled.
--- Combat-safe: defers the switch until combat ends.
--- @param _reason string Optional reason for logging (unused, for debugging)
function NivUI.Profiles:ApplySpecProfileIfEnabled(_reason)
    if not self:IsSpecAutoSwitchEnabled() then
        return
    end

    local specID = self:GetPlayerSpecID()
    if type(specID) ~= "number" then
        return
    end

    local profileName = self:GetSpecProfile(specID)
    if not profileName then
        return
    end

    if not self:ProfileExists(profileName) then
        return
    end

    if self:GetCurrentProfileName() == profileName then
        return
    end

    RunAfterCombat(function()
        if not self:IsSpecAutoSwitchEnabled() then
            return
        end
        local cur = self:GetPlayerSpecID()
        if cur ~= specID then
            return
        end
        local mapped = self:GetSpecProfile(specID)
        if mapped ~= profileName then
            return
        end
        if self:GetCurrentProfileName() == profileName then
            return
        end
        self:SwitchProfile(profileName)
    end)
end

-- Event frame for spec changes
local specEventFrame = CreateFrame("Frame")
specEventFrame:RegisterEvent("PLAYER_LOGIN")
specEventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
specEventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_SPECIALIZATION_CHANGED" and arg1 and arg1 ~= "player" then
        return
    end
    NivUI.Profiles:ApplySpecProfileIfEnabled(event)
end)

