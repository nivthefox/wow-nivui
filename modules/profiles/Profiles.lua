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
    if NivUI.ProfileDB and NivUI.ProfileDB.profiles then
        for name in pairs(NivUI.ProfileDB.profiles) do
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
    return NivUI.ProfileDB
        and NivUI.ProfileDB.profiles
        and NivUI.ProfileDB.profiles[name] ~= nil
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
        source = NivUI.DeepCopy(NivUI.ProfileDB.profiles[copyFrom])
    end

    NivUI.ProfileDB.profiles[name] = source
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
    NivUI_DB = NivUI.ProfileDB.profiles[name]

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
    for _ in pairs(NivUI.ProfileDB.profiles) do
        count = count + 1
    end
    if count <= 1 then
        return false, "Cannot delete the last profile"
    end

    if NivUI_CurrentProfile == name then
        self:SwitchProfile("Default")
    end

    NivUI.ProfileDB.profiles[name] = nil
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

    NivUI.ProfileDB.profiles[name] = {}

    if name == NivUI_CurrentProfile then
        NivUI_DB = NivUI.ProfileDB.profiles[name]
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

    NivUI.ProfileDB.profiles[toName] = NivUI.DeepCopy(NivUI.ProfileDB.profiles[fromName])
    print("|cff00ff00NivUI:|r Copied '" .. fromName .. "' to '" .. toName .. "'")
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
        payload = NivUI.DeepCopy(NivUI_DB),
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

    NivUI.ProfileDB.profiles[name] = NivUI.DeepCopy(payload)
    print("|cff00ff00NivUI:|r Imported profile '" .. name .. "'")
    return true
end

