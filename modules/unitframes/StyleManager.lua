NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

function NivUI:GetStyle(name)
    if not NivUI_DB.unitFrameStyles then return nil end
    local style = NivUI_DB.unitFrameStyles[name]
    if not style then return nil end
    return style
end

function NivUI:GetStyleNames()
    local names = {}
    if NivUI_DB.unitFrameStyles then
        for name in pairs(NivUI_DB.unitFrameStyles) do
            table.insert(names, name)
        end
    end
    table.sort(names)
    return names
end

function NivUI:StyleExists(name)
    return NivUI_DB.unitFrameStyles and NivUI_DB.unitFrameStyles[name] ~= nil
end

function NivUI:SaveStyle(name, data)
    if not name or name == "" then
        return false, "Style name cannot be empty"
    end

    if not NivUI_DB.unitFrameStyles then
        NivUI_DB.unitFrameStyles = {}
    end

    NivUI_DB.unitFrameStyles[name] = NivUI.DeepCopy(data)

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
    for _ in pairs(NivUI_DB.unitFrameStyles) do
        styleCount = styleCount + 1
    end

    if styleCount <= 1 then
        return false, "Cannot delete the last style"
    end

    local fallbackStyle = nil
    for styleName in pairs(NivUI_DB.unitFrameStyles) do
        if styleName ~= name then
            fallbackStyle = styleName
            break
        end
    end

    local inUse = {}
    if NivUI_DB.unitFrameAssignments then
        for frameType, styleName in pairs(NivUI_DB.unitFrameAssignments) do
            if styleName == name then
                table.insert(inUse, frameType)
            end
        end
    end

    for _, frameType in ipairs(inUse) do
        NivUI_DB.unitFrameAssignments[frameType] = fallbackStyle
    end

    NivUI_DB.unitFrameStyles[name] = nil

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

    NivUI_DB.unitFrameStyles[newName] = NivUI_DB.unitFrameStyles[oldName]
    NivUI_DB.unitFrameStyles[oldName] = nil

    if NivUI_DB.unitFrameAssignments then
        for frameType, styleName in pairs(NivUI_DB.unitFrameAssignments) do
            if styleName == oldName then
                NivUI_DB.unitFrameAssignments[frameType] = newName
            end
        end
    end

    self:TriggerEvent("StyleRenamed", { oldName = oldName, newName = newName })

    return true
end

function NivUI:GetAssignment(frameType)
    if not NivUI_DB.unitFrameAssignments then
        return "Default"
    end
    return NivUI_DB.unitFrameAssignments[frameType] or "Default"
end

function NivUI:SetAssignment(frameType, styleName)
    if not NivUI_DB.unitFrameAssignments then
        NivUI_DB.unitFrameAssignments = {}
    end

    NivUI_DB.unitFrameAssignments[frameType] = styleName

    self:TriggerEvent("AssignmentChanged", { frameType = frameType, styleName = styleName })
end

function NivUI:IsFrameEnabled(frameType)
    if not NivUI_DB.unitFrameEnabled then
        return false
    end
    return NivUI_DB.unitFrameEnabled[frameType] == true
end

function NivUI:SetFrameEnabled(frameType, enabled)
    if not NivUI_DB.unitFrameEnabled then
        NivUI_DB.unitFrameEnabled = {}
    end

    NivUI_DB.unitFrameEnabled[frameType] = enabled

    self:TriggerEvent("FrameEnabledChanged", { frameType = frameType, enabled = enabled })
end

function NivUI:IsRealTimeUpdates(frameType)
    if not NivUI_DB.unitFrameRealTimeUpdates then
        return false
    end
    return NivUI_DB.unitFrameRealTimeUpdates[frameType] == true
end

function NivUI:SetRealTimeUpdates(frameType, enabled)
    if not NivUI_DB.unitFrameRealTimeUpdates then
        NivUI_DB.unitFrameRealTimeUpdates = {}
    end

    NivUI_DB.unitFrameRealTimeUpdates[frameType] = enabled

    self:TriggerEvent("RealTimeUpdatesChanged", { frameType = frameType, enabled = enabled })
end

function NivUI:GetVisibilityOverride(frameType)
    if not NivUI_DB.unitFrameVisibilityOverrides then
        return nil
    end
    local override = NivUI_DB.unitFrameVisibilityOverrides[frameType]
    if override and override ~= "" then
        return override
    end
    return nil
end

function NivUI:SetVisibilityOverride(frameType, driver)
    if not NivUI_DB.unitFrameVisibilityOverrides then
        NivUI_DB.unitFrameVisibilityOverrides = {}
    end

    if driver == "" then
        driver = nil
    end

    NivUI_DB.unitFrameVisibilityOverrides[frameType] = driver

    self:TriggerEvent("VisibilityOverrideChanged", { frameType = frameType, driver = driver })
end

function NivUI:DoesPartyIncludePlayer()
    if NivUI_DB.partyIncludePlayer == nil then
        return true  -- Default to including player
    end
    return NivUI_DB.partyIncludePlayer
end

function NivUI:SetPartyIncludePlayer(enabled)
    NivUI_DB.partyIncludePlayer = enabled

    self:TriggerEvent("PartySettingsChanged", { setting = "includePlayer", enabled = enabled })
end

function NivUI:GetPartySpacing()
    return NivUI_DB.partySpacing or 2
end

local function ValidateSpacing(value, min, max, default)
    if type(value) ~= "number" then return default end
    return math.max(min, math.min(max, value))
end

function NivUI:SetPartySpacing(value)
    NivUI_DB.partySpacing = ValidateSpacing(value, 0, 100, 2)

    self:TriggerEvent("PartySettingsChanged", { setting = "spacing", value = NivUI_DB.partySpacing })
end

function NivUI:GetPartyOrientation()
    return NivUI_DB.partyOrientation or "VERTICAL"
end

function NivUI:SetPartyOrientation(value)
    NivUI_DB.partyOrientation = value

    self:TriggerEvent("PartySettingsChanged", { setting = "orientation", value = value })
end

function NivUI:GetPartyGrowthDirection()
    return NivUI_DB.partyGrowthDirection or "DOWN"
end

function NivUI:SetPartyGrowthDirection(value)
    NivUI_DB.partyGrowthDirection = value

    self:TriggerEvent("PartySettingsChanged", { setting = "growthDirection", value = value })
end

function NivUI:DoesPartyShowWhenSolo()
    if NivUI_DB.partyShowWhenSolo == nil then
        return false
    end
    return NivUI_DB.partyShowWhenSolo
end

function NivUI:SetPartyShowWhenSolo(enabled)
    NivUI_DB.partyShowWhenSolo = enabled

    self:TriggerEvent("PartySettingsChanged", { setting = "showWhenSolo", enabled = enabled })
end

function NivUI:GetPartySortMode()
    return NivUI_DB.partySortMode or "DEFAULT"
end

function NivUI:SetPartySortMode(value)
    NivUI_DB.partySortMode = value

    self:TriggerEvent("PartySettingsChanged", { setting = "sortMode", value = value })
end

local function EnsureRaidSettings(raidSize)
    if not NivUI_DB.raidSettings then
        NivUI_DB.raidSettings = {}
    end
    if not NivUI_DB.raidSettings[raidSize] then
        NivUI_DB.raidSettings[raidSize] = {}
    end
end

function NivUI:GetRaidSpacing(raidSize)
    if not NivUI_DB.raidSettings or not NivUI_DB.raidSettings[raidSize] then
        return 2
    end
    return NivUI_DB.raidSettings[raidSize].spacing or 2
end

function NivUI:SetRaidSpacing(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI_DB.raidSettings[raidSize].spacing = ValidateSpacing(value, 0, 100, 2)

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "spacing", value = NivUI_DB.raidSettings[raidSize].spacing })
end

function NivUI:GetRaidGroupOrientation(raidSize)
    if not NivUI_DB.raidSettings or not NivUI_DB.raidSettings[raidSize] then
        return "VERTICAL"
    end
    return NivUI_DB.raidSettings[raidSize].groupOrientation or "VERTICAL"
end

function NivUI:SetRaidGroupOrientation(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI_DB.raidSettings[raidSize].groupOrientation = value

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "groupOrientation", value = value })
end

function NivUI:GetRaidGroupGrowthDirection(raidSize)
    if not NivUI_DB.raidSettings or not NivUI_DB.raidSettings[raidSize] then
        return "DOWN"
    end
    return NivUI_DB.raidSettings[raidSize].groupGrowthDirection or "DOWN"
end

function NivUI:SetRaidGroupGrowthDirection(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI_DB.raidSettings[raidSize].groupGrowthDirection = value

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "groupGrowthDirection", value = value })
end

function NivUI:GetRaidPlayerGrowthDirection(raidSize)
    if not NivUI_DB.raidSettings or not NivUI_DB.raidSettings[raidSize] then
        return "DOWN"
    end
    return NivUI_DB.raidSettings[raidSize].playerGrowthDirection or "DOWN"
end

function NivUI:SetRaidPlayerGrowthDirection(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI_DB.raidSettings[raidSize].playerGrowthDirection = value

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "playerGrowthDirection", value = value })
end

function NivUI:GetRaidSortMode(raidSize)
    if not NivUI_DB.raidSettings or not NivUI_DB.raidSettings[raidSize] then
        return "GROUP"
    end
    return NivUI_DB.raidSettings[raidSize].sortMode or "GROUP"
end

function NivUI:SetRaidSortMode(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI_DB.raidSettings[raidSize].sortMode = value

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "sortMode", value = value })
end

function NivUI:GetBossSpacing()
    return NivUI_DB.bossSpacing or 2
end

function NivUI:SetBossSpacing(value)
    NivUI_DB.bossSpacing = ValidateSpacing(value, 0, 100, 2)

    self:TriggerEvent("BossSettingsChanged", { setting = "spacing", value = NivUI_DB.bossSpacing })
end

function NivUI:GetBossOrientation()
    return NivUI_DB.bossOrientation or "VERTICAL"
end

function NivUI:SetBossOrientation(value)
    NivUI_DB.bossOrientation = value

    self:TriggerEvent("BossSettingsChanged", { setting = "orientation", value = value })
end

function NivUI:GetBossGrowthDirection()
    return NivUI_DB.bossGrowthDirection or "DOWN"
end

function NivUI:SetBossGrowthDirection(value)
    NivUI_DB.bossGrowthDirection = value

    self:TriggerEvent("BossSettingsChanged", { setting = "growthDirection", value = value })
end

function NivUI:GetArenaSpacing()
    return NivUI_DB.arenaSpacing or 2
end

function NivUI:SetArenaSpacing(value)
    NivUI_DB.arenaSpacing = ValidateSpacing(value, 0, 100, 2)

    self:TriggerEvent("ArenaSettingsChanged", { setting = "spacing", value = NivUI_DB.arenaSpacing })
end

function NivUI:GetArenaOrientation()
    return NivUI_DB.arenaOrientation or "VERTICAL"
end

function NivUI:SetArenaOrientation(value)
    NivUI_DB.arenaOrientation = value

    self:TriggerEvent("ArenaSettingsChanged", { setting = "orientation", value = value })
end

function NivUI:GetArenaGrowthDirection()
    return NivUI_DB.arenaGrowthDirection or "DOWN"
end

function NivUI:SetArenaGrowthDirection(value)
    NivUI_DB.arenaGrowthDirection = value

    self:TriggerEvent("ArenaSettingsChanged", { setting = "growthDirection", value = value })
end

function NivUI:IsFadeOutOfRangeEnabled(frameType)
    if NivUI_DB.unitFrameFadeOutOfRange == nil then
        return false
    end
    return NivUI_DB.unitFrameFadeOutOfRange[frameType] or false
end

function NivUI:SetFadeOutOfRange(frameType, enabled)
    NivUI_DB.unitFrameFadeOutOfRange = NivUI_DB.unitFrameFadeOutOfRange or {}
    NivUI_DB.unitFrameFadeOutOfRange[frameType] = enabled
    self:TriggerEvent("FadeOutOfRangeChanged", { frameType = frameType, enabled = enabled })
end

local function GenerateCustomRaidGroupId()
    return "custom_" .. time() .. "_" .. math.random(1000, 9999)
end

function NivUI:GetCustomRaidGroups()
    return NivUI_DB.customRaidGroups or {}
end

function NivUI:GetCustomRaidGroup(id)
    if not NivUI_DB.customRaidGroups then return nil end
    return NivUI_DB.customRaidGroups[id]
end

function NivUI:CreateCustomRaidGroup(name)
    if not name or name == "" then
        return nil, "Group name cannot be empty"
    end

    if not NivUI_DB.customRaidGroups then
        NivUI_DB.customRaidGroups = {}
    end

    local id = GenerateCustomRaidGroupId()
    local defaultStyleName = self:GetStyleNames()[1] or "Default"

    NivUI_DB.customRaidGroups[id] = {
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

    if not NivUI_DB.customRaidGroups or not NivUI_DB.customRaidGroups[id] then
        return false, "Custom raid group does not exist"
    end

    NivUI_DB.customRaidGroups[id] = NivUI.DeepCopy(data)

    self:TriggerEvent("CustomRaidGroupChanged", { id = id, data = data })

    return true
end

function NivUI:DeleteCustomRaidGroup(id)
    if not id then
        return false, "Invalid group ID"
    end

    if not NivUI_DB.customRaidGroups or not NivUI_DB.customRaidGroups[id] then
        return false, "Custom raid group does not exist"
    end

    local name = NivUI_DB.customRaidGroups[id].name
    NivUI_DB.customRaidGroups[id] = nil

    if NivUI_DB.unitFramePositions then
        NivUI_DB.unitFramePositions["customRaid_" .. id] = nil
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
