local _, NivUI = ...

local Nicknames = {}
NivUI.Nicknames = Nicknames

local MAX_NICKNAME_CHARACTERS = 12
local resolvers = {}
local resolverFailures = {}
local diagnosticSink = function(message)
    print("|cffff0000NivUI:|r " .. message)
end

local function Trim(value)
    return value:match("^%s*(.-)%s*$")
end

local function IsSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value)
end

local function IsContinuationByte(byte)
    return byte and byte >= 0x80 and byte <= 0xBF
end

local function UTF8CharacterLength(value)
    local count = 0
    local index = 1
    local length = #value

    while index <= length do
        local first = value:byte(index)
        local sequenceLength

        if first <= 0x7F then
            sequenceLength = 1
        elseif first >= 0xC2 and first <= 0xDF
            and IsContinuationByte(value:byte(index + 1)) then
            sequenceLength = 2
        elseif first == 0xE0
            and value:byte(index + 1) and value:byte(index + 1) >= 0xA0
            and value:byte(index + 1) <= 0xBF
            and IsContinuationByte(value:byte(index + 2)) then
            sequenceLength = 3
        elseif ((first >= 0xE1 and first <= 0xEC) or (first >= 0xEE and first <= 0xEF))
            and IsContinuationByte(value:byte(index + 1))
            and IsContinuationByte(value:byte(index + 2)) then
            sequenceLength = 3
        elseif first == 0xED
            and value:byte(index + 1) and value:byte(index + 1) >= 0x80
            and value:byte(index + 1) <= 0x9F
            and IsContinuationByte(value:byte(index + 2)) then
            sequenceLength = 3
        elseif first == 0xF0
            and value:byte(index + 1) and value:byte(index + 1) >= 0x90
            and value:byte(index + 1) <= 0xBF
            and IsContinuationByte(value:byte(index + 2))
            and IsContinuationByte(value:byte(index + 3)) then
            sequenceLength = 4
        elseif first >= 0xF1 and first <= 0xF3
            and IsContinuationByte(value:byte(index + 1))
            and IsContinuationByte(value:byte(index + 2))
            and IsContinuationByte(value:byte(index + 3)) then
            sequenceLength = 4
        elseif first == 0xF4
            and value:byte(index + 1) and value:byte(index + 1) >= 0x80
            and value:byte(index + 1) <= 0x8F
            and IsContinuationByte(value:byte(index + 2))
            and IsContinuationByte(value:byte(index + 3)) then
            sequenceLength = 4
        else
            return nil
        end

        count = count + 1
        index = index + sequenceLength
    end

    return count
end

function Nicknames.NormalizeIdentity(identity)
    if IsSecret(identity) or type(identity) ~= "string" then
        return nil, "Identity must use the Character-Realm format"
    end

    local trimmed = Trim(identity)
    local character, realm = trimmed:match("^([^-]+)%-(.+)$")
    if not character or not realm then
        return nil, "Identity must use the Character-Realm format"
    end

    character = Trim(character)
    realm = Trim(realm)
    if character == "" or realm == "" then
        return nil, "Identity must use the Character-Realm format"
    end
    if character:find("[%c|]") or realm:find("[%c|]") then
        return nil, "Identity contains unsupported characters"
    end

    return character:lower() .. "-" .. realm:lower()
end

function Nicknames.ValidateNickname(nickname, allowBlank)
    if IsSecret(nickname) or type(nickname) ~= "string" then
        return nil, "Nickname must be plain text"
    end

    local trimmed = Trim(nickname)
    if trimmed == "" then
        if allowBlank then
            return ""
        end
        return nil, "Nickname cannot be blank"
    end
    if trimmed:find("[%c|]") then
        return nil, "Nickname cannot contain control characters or WoW formatting escapes"
    end

    local characterLength = UTF8CharacterLength(trimmed)
    if not characterLength then
        return nil, "Nickname must contain valid UTF-8 text"
    end
    if characterLength > MAX_NICKNAME_CHARACTERS then
        return nil, "Nickname cannot exceed 12 characters"
    end

    return trimmed
end

function Nicknames.TruncateText(value, maximumCharacters)
    if type(value) ~= "string" or type(maximumCharacters) ~= "number" or maximumCharacters < 0 then
        return value
    end

    local count = 0
    local index = 1
    while index <= #value and count < maximumCharacters do
        local first = value:byte(index)
        local sequenceLength = 1
        if first >= 0xC2 and first <= 0xDF then
            sequenceLength = 2
        elseif first >= 0xE0 and first <= 0xEF then
            sequenceLength = 3
        elseif first >= 0xF0 and first <= 0xF4 then
            sequenceLength = 4
        end
        index = index + sequenceLength
        count = count + 1
    end

    if index > #value then
        return value
    end
    return value:sub(1, index - 1)
end

function Nicknames.GetUnitIdentity(unit)
    if type(UnitIsPlayer) ~= "function" or type(UnitFullName) ~= "function" then
        return nil
    end

    local isPlayer = UnitIsPlayer(unit)
    if IsSecret(isPlayer) or not isPlayer then
        return nil
    end

    local character, realm = UnitFullName(unit)
    if IsSecret(character) or IsSecret(realm) or type(character) ~= "string" or type(realm) ~= "string" then
        return nil
    end

    return Nicknames.NormalizeIdentity(character .. "-" .. realm)
end

function Nicknames:Get(identity, profile)
    local normalized = self.NormalizeIdentity(identity)
    if not normalized then
        return nil
    end

    profile = profile or NivUI:GetActiveProfile()
    if type(profile) ~= "table" or type(profile.nicknames) ~= "table" then
        return nil
    end
    return profile.nicknames[normalized]
end

function Nicknames:Save(identity, nickname, profile)
    local normalized, identityError = self.NormalizeIdentity(identity)
    if not normalized then
        return false, identityError
    end

    local validated, nicknameError = self.ValidateNickname(nickname, true)
    if validated == nil then
        return false, nicknameError
    end

    profile = profile or NivUI:GetActiveProfile()
    if type(profile) ~= "table" then
        return false, "Active profile is unavailable"
    end

    if validated == "" then
        if type(profile.nicknames) == "table" then
            profile.nicknames[normalized] = nil
        end
    else
        if type(profile.nicknames) ~= "table" then
            profile.nicknames = {}
        end
        profile.nicknames[normalized] = validated
    end

    NivUI:TriggerEvent("NicknamesChanged", { identity = normalized, nickname = validated ~= "" and validated or nil })
    return true, nil, normalized
end

function Nicknames:GetEntries(profile)
    profile = profile or NivUI:GetActiveProfile()
    self:RepairProfile(profile)

    local entries = {}
    if type(profile) ~= "table" or type(profile.nicknames) ~= "table" then
        return entries
    end

    for identity, nickname in pairs(profile.nicknames) do
        entries[#entries + 1] = { identity = identity, nickname = nickname }
    end
    table.sort(entries, function(left, right)
        return left.identity < right.identity
    end)
    return entries
end

function Nicknames:RepairProfile(profile)
    if type(profile) ~= "table" then
        return 0
    end
    if profile.nicknames == nil then
        return 0
    end
    if type(profile.nicknames) ~= "table" then
        profile.nicknames = nil
        return 1
    end

    local originalKeys = {}
    for key in pairs(profile.nicknames) do
        originalKeys[#originalKeys + 1] = key
    end
    table.sort(originalKeys, function(left, right)
        return tostring(left) < tostring(right)
    end)

    local repaired = {}
    local changed = 0
    for _, originalKey in ipairs(originalKeys) do
        local normalized = self.NormalizeIdentity(originalKey)
        local nickname = self.ValidateNickname(profile.nicknames[originalKey], false)
        if normalized and nickname and repaired[normalized] == nil then
            repaired[normalized] = nickname
            if normalized ~= originalKey or nickname ~= profile.nicknames[originalKey] then
                changed = changed + 1
            end
        else
            changed = changed + 1
        end
    end

    profile.nicknames = repaired
    return changed
end

function Nicknames:RegisterResolver(resolver)
    if type(resolver) ~= "function" then
        return false
    end
    for _, registered in ipairs(resolvers) do
        if registered == resolver then
            return true
        end
    end
    resolvers[#resolvers + 1] = resolver
    return true
end

function Nicknames:UnregisterResolver(resolver)
    for index, registered in ipairs(resolvers) do
        if registered == resolver then
            table.remove(resolvers, index)
            resolverFailures[resolver] = nil
            return true
        end
    end
    return false
end

function Nicknames:BeginResolutionPass()
    local snapshot = {}
    for index, resolver in ipairs(resolvers) do
        snapshot[index] = resolver
    end
    return snapshot
end

local function ReportResolverFailure(resolver, failure)
    if resolverFailures[resolver] == failure then
        return
    end
    resolverFailures[resolver] = failure
    diagnosticSink("Nickname resolver failed: " .. failure)
end

local function ResolveExternal(identity, snapshot)
    for _, resolver in ipairs(snapshot) do
        local ok, result = pcall(resolver, identity)
        if not ok then
            ReportResolverFailure(resolver, tostring(result))
        elseif IsSecret(result) then
            ReportResolverFailure(resolver, "returned a secret value")
        elseif result == nil then
            resolverFailures[resolver] = nil
        elseif type(result) ~= "string" then
            ReportResolverFailure(resolver, "returned a non-text value")
        else
            local trimmed = Trim(result)
            if trimmed == "" then
                resolverFailures[resolver] = nil
            else
                local validated, validationError = Nicknames.ValidateNickname(result, false)
                if validated then
                    resolverFailures[resolver] = nil
                    return validated
                end
                ReportResolverFailure(resolver, validationError)
            end
        end
    end
    return nil
end

function Nicknames:Resolve(identity, normalName, snapshot, profile)
    local normalized = self.NormalizeIdentity(identity)
    if not normalized then
        return normalName
    end

    local external = ResolveExternal(normalized, snapshot or self:BeginResolutionPass())
    if external then
        return external
    end

    return self:Get(normalized, profile) or normalName
end

function Nicknames:ResolveUnit(unit, normalName, snapshot, profile)
    local identity = self.GetUnitIdentity(unit)
    if not identity then
        return normalName
    end
    return self:Resolve(identity, normalName, snapshot, profile)
end

function Nicknames:SetDiagnosticSink(sink)
    if type(sink) ~= "function" then
        return false
    end
    diagnosticSink = sink
    return true
end

local PublicAPI = {}

function PublicAPI.RegisterResolver(first, second)
    return Nicknames:RegisterResolver(second or first)
end

function PublicAPI.UnregisterResolver(first, second)
    return Nicknames:UnregisterResolver(second or first)
end

_G.NivUI_Nicknames = PublicAPI
