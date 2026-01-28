NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

function NivUI:GetStyle(name)
    if not NivUI.current.unitFrameStyles then return nil end
    local style = NivUI.current.unitFrameStyles[name]
    if not style then return nil end
    return style
end

function NivUI:GetStyleNames()
    local names = {}
    if NivUI.current.unitFrameStyles then
        for name in pairs(NivUI.current.unitFrameStyles) do
            table.insert(names, name)
        end
    end
    table.sort(names)
    return names
end

function NivUI:StyleExists(name)
    return NivUI.current.unitFrameStyles and NivUI.current.unitFrameStyles[name] ~= nil
end

function NivUI:SaveStyle(name, data)
    if not name or name == "" then
        return false, "Style name cannot be empty"
    end

    if not NivUI.current.unitFrameStyles then
        NivUI.current.unitFrameStyles = {}
    end

    NivUI.current.unitFrameStyles[name] = NivUI.DeepCopy(data)

    self:TriggerEvent("StyleChanged", { styleName = name })

    return true
end

function NivUI:CreateStyle(name)
    if not name or name == "" then
        return false, "Style name cannot be empty"
    end

    if self:StyleExists(name) then
        return false, "Style '" .. name .. "' already exists"
    end

    return self:SaveStyle(name, NivUI.UnitFrames.DEFAULT_STYLE)
end

function NivUI:DeleteStyle(name)
    if not name or name == "" then
        return false, "Style name cannot be empty"
    end

    if not self:StyleExists(name) then
        return false, "Style '" .. name .. "' does not exist"
    end

    local styleCount = 0
    for _ in pairs(NivUI.current.unitFrameStyles) do
        styleCount = styleCount + 1
    end

    if styleCount <= 1 then
        return false, "Cannot delete the last style"
    end

    local fallbackStyle = nil
    for styleName in pairs(NivUI.current.unitFrameStyles) do
        if styleName ~= name then
            fallbackStyle = styleName
            break
        end
    end

    local inUse = {}
    if NivUI.current.unitFrameAssignments then
        for frameType, styleName in pairs(NivUI.current.unitFrameAssignments) do
            if styleName == name then
                table.insert(inUse, frameType)
            end
        end
    end

    for _, frameType in ipairs(inUse) do
        NivUI.current.unitFrameAssignments[frameType] = fallbackStyle
    end

    NivUI.current.unitFrameStyles[name] = nil

    self:TriggerEvent("StyleDeleted", { styleName = name, reassigned = inUse, fallback = fallbackStyle })

    return true
end

function NivUI:DuplicateStyle(fromName, toName)
    if not fromName or fromName == "" then
        return false, "Source style name cannot be empty"
    end

    if not toName or toName == "" then
        return false, "Destination style name cannot be empty"
    end

    if self:StyleExists(toName) then
        return false, "Style '" .. toName .. "' already exists"
    end

    local sourceStyle = self:GetStyle(fromName)
    if not sourceStyle then
        return false, "Source style '" .. fromName .. "' does not exist"
    end

    return self:SaveStyle(toName, sourceStyle)
end

function NivUI:RenameStyle(oldName, newName)
    if not oldName or oldName == "" then
        return false, "Old style name cannot be empty"
    end

    if not newName or newName == "" then
        return false, "New style name cannot be empty"
    end

    if self:StyleExists(newName) then
        return false, "Style '" .. newName .. "' already exists"
    end

    local style = self:GetStyle(oldName)
    if not style then
        return false, "Style '" .. oldName .. "' does not exist"
    end

    NivUI.current.unitFrameStyles[newName] = NivUI.current.unitFrameStyles[oldName]
    NivUI.current.unitFrameStyles[oldName] = nil

    if NivUI.current.unitFrameAssignments then
        for frameType, styleName in pairs(NivUI.current.unitFrameAssignments) do
            if styleName == oldName then
                NivUI.current.unitFrameAssignments[frameType] = newName
            end
        end
    end

    self:TriggerEvent("StyleRenamed", { oldName = oldName, newName = newName })

    return true
end

function NivUI:GetAssignment(frameType)
    if not NivUI.current.unitFrameAssignments then
        return "Default"
    end
    return NivUI.current.unitFrameAssignments[frameType] or "Default"
end

function NivUI:SetAssignment(frameType, styleName)
    if not NivUI.current.unitFrameAssignments then
        NivUI.current.unitFrameAssignments = {}
    end

    NivUI.current.unitFrameAssignments[frameType] = styleName

    self:TriggerEvent("AssignmentChanged", { frameType = frameType, styleName = styleName })
end

function NivUI:IsFrameEnabled(frameType)
    if not NivUI.current.unitFrameEnabled then
        return false
    end
    return NivUI.current.unitFrameEnabled[frameType] == true
end

function NivUI:SetFrameEnabled(frameType, enabled)
    if not NivUI.current.unitFrameEnabled then
        NivUI.current.unitFrameEnabled = {}
    end

    NivUI.current.unitFrameEnabled[frameType] = enabled

    self:TriggerEvent("FrameEnabledChanged", { frameType = frameType, enabled = enabled })
end

function NivUI:IsRealTimeUpdates(frameType)
    if not NivUI.current.unitFrameRealTimeUpdates then
        return false
    end
    return NivUI.current.unitFrameRealTimeUpdates[frameType] == true
end

function NivUI:SetRealTimeUpdates(frameType, enabled)
    if not NivUI.current.unitFrameRealTimeUpdates then
        NivUI.current.unitFrameRealTimeUpdates = {}
    end

    NivUI.current.unitFrameRealTimeUpdates[frameType] = enabled

    self:TriggerEvent("RealTimeUpdatesChanged", { frameType = frameType, enabled = enabled })
end

function NivUI:GetVisibilityOverride(frameType)
    if not NivUI.current.unitFrameVisibilityOverrides then
        return nil
    end
    local override = NivUI.current.unitFrameVisibilityOverrides[frameType]
    if override and override ~= "" then
        return override
    end
    return nil
end

function NivUI:SetVisibilityOverride(frameType, driver)
    if not NivUI.current.unitFrameVisibilityOverrides then
        NivUI.current.unitFrameVisibilityOverrides = {}
    end

    if driver == "" then
        driver = nil
    end

    NivUI.current.unitFrameVisibilityOverrides[frameType] = driver

    self:TriggerEvent("VisibilityOverrideChanged", { frameType = frameType, driver = driver })
end

function NivUI:DoesPartyIncludePlayer()
    if NivUI.current.partyIncludePlayer == nil then
        return true  -- Default to including player
    end
    return NivUI.current.partyIncludePlayer
end

function NivUI:SetPartyIncludePlayer(enabled)
    NivUI.current.partyIncludePlayer = enabled

    self:TriggerEvent("PartySettingsChanged", { setting = "includePlayer", enabled = enabled })
end

function NivUI:GetPartySpacing()
    return NivUI.current.partySpacing or 2
end

local function ValidateSpacing(value, min, max, default)
    if type(value) ~= "number" then return default end
    return math.max(min, math.min(max, value))
end

function NivUI:SetPartySpacing(value)
    NivUI.current.partySpacing = ValidateSpacing(value, 0, 100, 2)

    self:TriggerEvent("PartySettingsChanged", { setting = "spacing", value = NivUI.current.partySpacing })
end

function NivUI:GetPartyOrientation()
    return NivUI.current.partyOrientation or "VERTICAL"
end

function NivUI:SetPartyOrientation(value)
    NivUI.current.partyOrientation = value

    self:TriggerEvent("PartySettingsChanged", { setting = "orientation", value = value })
end

function NivUI:GetPartyGrowthDirection()
    return NivUI.current.partyGrowthDirection or "DOWN"
end

function NivUI:SetPartyGrowthDirection(value)
    NivUI.current.partyGrowthDirection = value

    self:TriggerEvent("PartySettingsChanged", { setting = "growthDirection", value = value })
end

function NivUI:DoesPartyShowWhenSolo()
    if NivUI.current.partyShowWhenSolo == nil then
        return false
    end
    return NivUI.current.partyShowWhenSolo
end

function NivUI:SetPartyShowWhenSolo(enabled)
    NivUI.current.partyShowWhenSolo = enabled

    self:TriggerEvent("PartySettingsChanged", { setting = "showWhenSolo", enabled = enabled })
end

function NivUI:GetPartySortMode()
    return NivUI.current.partySortMode or "DEFAULT"
end

function NivUI:SetPartySortMode(value)
    NivUI.current.partySortMode = value

    self:TriggerEvent("PartySettingsChanged", { setting = "sortMode", value = value })
end

local function EnsureRaidSettings(raidSize)
    if not NivUI.current.raidSettings then
        NivUI.current.raidSettings = {}
    end
    if not NivUI.current.raidSettings[raidSize] then
        NivUI.current.raidSettings[raidSize] = {}
    end
end

function NivUI:GetRaidSpacing(raidSize)
    if not NivUI.current.raidSettings or not NivUI.current.raidSettings[raidSize] then
        return 2
    end
    return NivUI.current.raidSettings[raidSize].spacing or 2
end

function NivUI:SetRaidSpacing(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI.current.raidSettings[raidSize].spacing = ValidateSpacing(value, 0, 100, 2)

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "spacing", value = NivUI.current.raidSettings[raidSize].spacing })
end

function NivUI:GetRaidGroupOrientation(raidSize)
    if not NivUI.current.raidSettings or not NivUI.current.raidSettings[raidSize] then
        return "VERTICAL"
    end
    return NivUI.current.raidSettings[raidSize].groupOrientation or "VERTICAL"
end

function NivUI:SetRaidGroupOrientation(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI.current.raidSettings[raidSize].groupOrientation = value

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "groupOrientation", value = value })
end

function NivUI:GetRaidGroupGrowthDirection(raidSize)
    if not NivUI.current.raidSettings or not NivUI.current.raidSettings[raidSize] then
        return "DOWN"
    end
    return NivUI.current.raidSettings[raidSize].groupGrowthDirection or "DOWN"
end

function NivUI:SetRaidGroupGrowthDirection(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI.current.raidSettings[raidSize].groupGrowthDirection = value

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "groupGrowthDirection", value = value })
end

function NivUI:GetRaidPlayerGrowthDirection(raidSize)
    if not NivUI.current.raidSettings or not NivUI.current.raidSettings[raidSize] then
        return "DOWN"
    end
    return NivUI.current.raidSettings[raidSize].playerGrowthDirection or "DOWN"
end

function NivUI:SetRaidPlayerGrowthDirection(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI.current.raidSettings[raidSize].playerGrowthDirection = value

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "playerGrowthDirection", value = value })
end

function NivUI:GetRaidSortMode(raidSize)
    if not NivUI.current.raidSettings or not NivUI.current.raidSettings[raidSize] then
        return "GROUP"
    end
    return NivUI.current.raidSettings[raidSize].sortMode or "GROUP"
end

function NivUI:SetRaidSortMode(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI.current.raidSettings[raidSize].sortMode = value

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "sortMode", value = value })
end

function NivUI:GetBossSpacing()
    return NivUI.current.bossSpacing or 2
end

function NivUI:SetBossSpacing(value)
    NivUI.current.bossSpacing = ValidateSpacing(value, 0, 100, 2)

    self:TriggerEvent("BossSettingsChanged", { setting = "spacing", value = NivUI.current.bossSpacing })
end

function NivUI:GetBossOrientation()
    return NivUI.current.bossOrientation or "VERTICAL"
end

function NivUI:SetBossOrientation(value)
    NivUI.current.bossOrientation = value

    self:TriggerEvent("BossSettingsChanged", { setting = "orientation", value = value })
end

function NivUI:GetBossGrowthDirection()
    return NivUI.current.bossGrowthDirection or "DOWN"
end

function NivUI:SetBossGrowthDirection(value)
    NivUI.current.bossGrowthDirection = value

    self:TriggerEvent("BossSettingsChanged", { setting = "growthDirection", value = value })
end

function NivUI:GetArenaSpacing()
    return NivUI.current.arenaSpacing or 2
end

function NivUI:SetArenaSpacing(value)
    NivUI.current.arenaSpacing = ValidateSpacing(value, 0, 100, 2)

    self:TriggerEvent("ArenaSettingsChanged", { setting = "spacing", value = NivUI.current.arenaSpacing })
end

function NivUI:GetArenaOrientation()
    return NivUI.current.arenaOrientation or "VERTICAL"
end

function NivUI:SetArenaOrientation(value)
    NivUI.current.arenaOrientation = value

    self:TriggerEvent("ArenaSettingsChanged", { setting = "orientation", value = value })
end

function NivUI:GetArenaGrowthDirection()
    return NivUI.current.arenaGrowthDirection or "DOWN"
end

function NivUI:SetArenaGrowthDirection(value)
    NivUI.current.arenaGrowthDirection = value

    self:TriggerEvent("ArenaSettingsChanged", { setting = "growthDirection", value = value })
end

function NivUI:IsFadeOutOfRangeEnabled(frameType)
    if NivUI.current.unitFrameFadeOutOfRange == nil then
        return false
    end
    return NivUI.current.unitFrameFadeOutOfRange[frameType] or false
end

function NivUI:SetFadeOutOfRange(frameType, enabled)
    NivUI.current.unitFrameFadeOutOfRange = NivUI.current.unitFrameFadeOutOfRange or {}
    NivUI.current.unitFrameFadeOutOfRange[frameType] = enabled
    self:TriggerEvent("FadeOutOfRangeChanged", { frameType = frameType, enabled = enabled })
end

local function GenerateCustomRaidGroupId()
    return "custom_" .. time() .. "_" .. math.random(1000, 9999)
end

function NivUI:GetCustomRaidGroups()
    return NivUI.current.customRaidGroups or {}
end

function NivUI:GetCustomRaidGroup(id)
    if not NivUI.current.customRaidGroups then return nil end
    return NivUI.current.customRaidGroups[id]
end

function NivUI:CreateCustomRaidGroup(name)
    if not name or name == "" then
        return nil, "Group name cannot be empty"
    end

    if not NivUI.current.customRaidGroups then
        NivUI.current.customRaidGroups = {}
    end

    local id = GenerateCustomRaidGroupId()
    local defaultStyleName = self:GetStyleNames()[1] or "Default"

    NivUI.current.customRaidGroups[id] = {
        name = name,
        filterType = "role",
        roles = {
            tank = false,
            healer = false,
            dps = false,
        },
        members = {},
        styleName = defaultStyleName,
        enabled = true,
    }

    self:TriggerEvent("CustomRaidGroupCreated", { id = id, name = name })

    return id
end

function NivUI:SaveCustomRaidGroup(id, data)
    if not id or not data then
        return false, "Invalid parameters"
    end

    if not NivUI.current.customRaidGroups or not NivUI.current.customRaidGroups[id] then
        return false, "Custom raid group does not exist"
    end

    NivUI.current.customRaidGroups[id] = NivUI.DeepCopy(data)

    self:TriggerEvent("CustomRaidGroupChanged", { id = id, data = data })

    return true
end

function NivUI:DeleteCustomRaidGroup(id)
    if not id then
        return false, "Invalid group ID"
    end

    if not NivUI.current.customRaidGroups or not NivUI.current.customRaidGroups[id] then
        return false, "Custom raid group does not exist"
    end

    local name = NivUI.current.customRaidGroups[id].name
    NivUI.current.customRaidGroups[id] = nil

    if NivUI.current.unitFramePositions then
        NivUI.current.unitFramePositions["customRaid_" .. id] = nil
    end

    self:TriggerEvent("CustomRaidGroupDeleted", { id = id, name = name })

    return true
end

function NivUI:GetStyleWithDefaults(name)
    local style = self:GetStyle(name)
    if not style then
        return NivUI.DeepCopy(NivUI.UnitFrames.DEFAULT_STYLE)
    end

    local merged = NivUI.DeepCopy(NivUI.UnitFrames.DEFAULT_STYLE)

    local function MergeTable(target, source)
        for k, v in pairs(source) do
            if type(v) == "table" and type(target[k]) == "table" then
                MergeTable(target[k], v)
            else
                target[k] = NivUI.DeepCopy(v)
            end
        end
    end

    MergeTable(merged, style)
    return merged
end

NivUI.eventCallbacks = NivUI.eventCallbacks or {}

function NivUI:RegisterCallback(event, callback)
    if not self.eventCallbacks[event] then
        self.eventCallbacks[event] = {}
    end
    table.insert(self.eventCallbacks[event], callback)
end

function NivUI:UnregisterCallback(event, callback)
    if not self.eventCallbacks[event] then return end
    for i, cb in ipairs(self.eventCallbacks[event]) do
        if cb == callback then
            table.remove(self.eventCallbacks[event], i)
            return
        end
    end
end

function NivUI:TriggerEvent(event, data)
    if not self.eventCallbacks[event] then return end
    for _, callback in ipairs(self.eventCallbacks[event]) do
        callback(data)
    end
end

function NivUI:InitializeDefaultStyle()
    local names = self:GetStyleNames()
    if #names == 0 then
        self:SaveStyle("Default", NivUI.UnitFrames.DEFAULT_STYLE)
    end
end
