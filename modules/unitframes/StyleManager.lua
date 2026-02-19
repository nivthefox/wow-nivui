NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

--- Returns the style configuration for a given name.
--- @param name string The style name to retrieve
--- @return table|nil style The style configuration, or nil if not found
function NivUI:GetStyle(name)
    if not NivUI.current.unitFrameStyles then return nil end
    local style = NivUI.current.unitFrameStyles[name]
    if not style then return nil end
    return style
end

--- Returns a sorted list of all saved style names.
--- @return string[] names The list of style names
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

--- Checks if a style with the given name exists.
--- @param name string The style name to check
--- @return boolean exists Whether the style exists
function NivUI:StyleExists(name)
    return NivUI.current.unitFrameStyles and NivUI.current.unitFrameStyles[name] ~= nil
end

--- Saves a style with the given name, overwriting if it exists.
--- @param name string The style name
--- @param data table The style configuration table
--- @return boolean success Whether the save succeeded
--- @return string|nil errorMessage Error message if save failed
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

--- Creates a new style with default values.
--- @param name string The name for the new style
--- @return boolean success Whether the creation succeeded
--- @return string|nil errorMessage Error message if creation failed
function NivUI:CreateStyle(name)
    if not name or name == "" then
        return false, "Style name cannot be empty"
    end

    if self:StyleExists(name) then
        return false, "Style '" .. name .. "' already exists"
    end

    return self:SaveStyle(name, NivUI.UnitFrames.DEFAULT_STYLE)
end

--- Deletes a style by name.
--- Reassigns any frames using this style to a fallback style.
--- @param name string The style name to delete
--- @return boolean success Whether the deletion succeeded
--- @return string|nil errorMessage Error message if deletion failed
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

--- Duplicates an existing style to a new name.
--- @param fromName string The source style name
--- @param toName string The destination style name
--- @return boolean success Whether the duplication succeeded
--- @return string|nil errorMessage Error message if duplication failed
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

--- Renames a style, updating any frame assignments that reference it.
--- @param oldName string The current style name
--- @param newName string The new style name
--- @return boolean success Whether the rename succeeded
--- @return string|nil errorMessage Error message if rename failed
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

--- Returns the style name assigned to a frame type.
--- @param frameType string The frame type (e.g., "player", "target")
--- @return string styleName The assigned style name, defaults to "Default"
function NivUI:GetAssignment(frameType)
    if not NivUI.current.unitFrameAssignments then
        return "Default"
    end
    return NivUI.current.unitFrameAssignments[frameType] or "Default"
end

--- Assigns a style to a frame type.
--- @param frameType string The frame type (e.g., "player", "target")
--- @param styleName string The style name to assign
function NivUI:SetAssignment(frameType, styleName)
    if not NivUI.current.unitFrameAssignments then
        NivUI.current.unitFrameAssignments = {}
    end

    NivUI.current.unitFrameAssignments[frameType] = styleName

    self:TriggerEvent("AssignmentChanged", { frameType = frameType, styleName = styleName })
end

--- Checks if a frame type is enabled.
--- @param frameType string The frame type to check
--- @return boolean enabled Whether the frame type is enabled
function NivUI:IsFrameEnabled(frameType)
    if not NivUI.current.unitFrameEnabled then
        return false
    end
    return NivUI.current.unitFrameEnabled[frameType] == true
end

--- Enables or disables a frame type.
--- @param frameType string The frame type to configure
--- @param enabled boolean Whether to enable the frame type
function NivUI:SetFrameEnabled(frameType, enabled)
    if not NivUI.current.unitFrameEnabled then
        NivUI.current.unitFrameEnabled = {}
    end

    NivUI.current.unitFrameEnabled[frameType] = enabled

    self:TriggerEvent("FrameEnabledChanged", { frameType = frameType, enabled = enabled })
end

--- Checks if real-time updates are enabled for a frame type.
--- @param frameType string The frame type to check
--- @return boolean enabled Whether real-time updates are enabled
function NivUI:IsRealTimeUpdates(frameType)
    if not NivUI.current.unitFrameRealTimeUpdates then
        return false
    end
    return NivUI.current.unitFrameRealTimeUpdates[frameType] == true
end

--- Enables or disables real-time updates for a frame type.
--- @param frameType string The frame type to configure
--- @param enabled boolean Whether to enable real-time updates
function NivUI:SetRealTimeUpdates(frameType, enabled)
    if not NivUI.current.unitFrameRealTimeUpdates then
        NivUI.current.unitFrameRealTimeUpdates = {}
    end

    NivUI.current.unitFrameRealTimeUpdates[frameType] = enabled

    self:TriggerEvent("RealTimeUpdatesChanged", { frameType = frameType, enabled = enabled })
end

--- Returns the visibility override driver for a frame type.
--- @param frameType string The frame type to check
--- @return string|nil driver The visibility driver string, or nil if no override
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

--- Sets or clears the visibility override driver for a frame type.
--- @param frameType string The frame type to configure
--- @param driver string|nil The visibility driver string, or nil/empty to clear
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

--- Checks if the party frames include the player.
--- @return boolean includePlayer Whether party frames include the player
function NivUI:DoesPartyIncludePlayer()
    if NivUI.current.partyIncludePlayer == nil then
        return true  -- Default to including player
    end
    return NivUI.current.partyIncludePlayer
end

--- Sets whether party frames include the player.
--- @param enabled boolean Whether to include the player in party frames
function NivUI:SetPartyIncludePlayer(enabled)
    NivUI.current.partyIncludePlayer = enabled

    self:TriggerEvent("PartySettingsChanged", { setting = "includePlayer", enabled = enabled })
end

--- Returns the party frame spacing in pixels.
--- @return number spacing The spacing value (0-100), defaults to 2
function NivUI:GetPartySpacing()
    return NivUI.current.partySpacing or 2
end

local function ValidateSpacing(value, min, max, default)
    if type(value) ~= "number" then return default end
    return math.max(min, math.min(max, value))
end

--- Sets the party frame spacing.
--- @param value number The spacing in pixels (clamped to 0-100)
function NivUI:SetPartySpacing(value)
    NivUI.current.partySpacing = ValidateSpacing(value, 0, 100, 2)

    self:TriggerEvent("PartySettingsChanged", { setting = "spacing", value = NivUI.current.partySpacing })
end

--- Returns the party frame orientation.
--- @return string orientation Either "VERTICAL" or "HORIZONTAL"
function NivUI:GetPartyOrientation()
    return NivUI.current.partyOrientation or "VERTICAL"
end

--- Sets the party frame orientation.
--- @param value string Either "VERTICAL" or "HORIZONTAL"
function NivUI:SetPartyOrientation(value)
    NivUI.current.partyOrientation = value

    self:TriggerEvent("PartySettingsChanged", { setting = "orientation", value = value })
end

--- Returns the party frame growth direction.
--- @return string direction Either "DOWN", "UP", "LEFT", or "RIGHT"
function NivUI:GetPartyGrowthDirection()
    return NivUI.current.partyGrowthDirection or "DOWN"
end

--- Sets the party frame growth direction.
--- @param value string Either "DOWN", "UP", "LEFT", or "RIGHT"
function NivUI:SetPartyGrowthDirection(value)
    NivUI.current.partyGrowthDirection = value

    self:TriggerEvent("PartySettingsChanged", { setting = "growthDirection", value = value })
end

--- Checks if party frames are shown when solo.
--- @return boolean showWhenSolo Whether party frames show when solo
function NivUI:DoesPartyShowWhenSolo()
    if NivUI.current.partyShowWhenSolo == nil then
        return false
    end
    return NivUI.current.partyShowWhenSolo
end

--- Sets whether party frames are shown when solo.
--- @param enabled boolean Whether to show party frames when solo
function NivUI:SetPartyShowWhenSolo(enabled)
    NivUI.current.partyShowWhenSolo = enabled

    self:TriggerEvent("PartySettingsChanged", { setting = "showWhenSolo", enabled = enabled })
end

--- Returns the party frame sort mode.
--- @return string sortMode The sort mode (e.g., "DEFAULT", "ROLE", "NAME")
function NivUI:GetPartySortMode()
    return NivUI.current.partySortMode or "DEFAULT"
end

--- Sets the party frame sort mode.
--- @param value string The sort mode (e.g., "DEFAULT", "ROLE", "NAME")
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

--- Returns the raid frame spacing for a given raid size.
--- @param raidSize number The raid size (10, 25, or 40)
--- @return number spacing The spacing value, defaults to 2
function NivUI:GetRaidSpacing(raidSize)
    if not NivUI.current.raidSettings or not NivUI.current.raidSettings[raidSize] then
        return 2
    end
    return NivUI.current.raidSettings[raidSize].spacing or 2
end

--- Sets the raid frame spacing for a given raid size.
--- @param raidSize number The raid size (10, 25, or 40)
--- @param value number The spacing in pixels (clamped to 0-100)
function NivUI:SetRaidSpacing(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI.current.raidSettings[raidSize].spacing = ValidateSpacing(value, 0, 100, 2)

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "spacing", value = NivUI.current.raidSettings[raidSize].spacing })
end

--- Returns the raid group orientation for a given raid size.
--- @param raidSize number The raid size (10, 25, or 40)
--- @return string orientation Either "VERTICAL" or "HORIZONTAL"
function NivUI:GetRaidGroupOrientation(raidSize)
    if not NivUI.current.raidSettings or not NivUI.current.raidSettings[raidSize] then
        return "VERTICAL"
    end
    return NivUI.current.raidSettings[raidSize].groupOrientation or "VERTICAL"
end

--- Sets the raid group orientation for a given raid size.
--- @param raidSize number The raid size (10, 25, or 40)
--- @param value string Either "VERTICAL" or "HORIZONTAL"
function NivUI:SetRaidGroupOrientation(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI.current.raidSettings[raidSize].groupOrientation = value

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "groupOrientation", value = value })
end

--- Returns the raid group growth direction for a given raid size.
--- @param raidSize number The raid size (10, 25, or 40)
--- @return string direction Either "DOWN", "UP", "LEFT", or "RIGHT"
function NivUI:GetRaidGroupGrowthDirection(raidSize)
    if not NivUI.current.raidSettings or not NivUI.current.raidSettings[raidSize] then
        return "DOWN"
    end
    return NivUI.current.raidSettings[raidSize].groupGrowthDirection or "DOWN"
end

--- Sets the raid group growth direction for a given raid size.
--- @param raidSize number The raid size (10, 25, or 40)
--- @param value string Either "DOWN", "UP", "LEFT", or "RIGHT"
function NivUI:SetRaidGroupGrowthDirection(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI.current.raidSettings[raidSize].groupGrowthDirection = value

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "groupGrowthDirection", value = value })
end

--- Returns the raid player growth direction for a given raid size.
--- @param raidSize number The raid size (10, 25, or 40)
--- @return string direction Either "DOWN", "UP", "LEFT", or "RIGHT"
function NivUI:GetRaidPlayerGrowthDirection(raidSize)
    if not NivUI.current.raidSettings or not NivUI.current.raidSettings[raidSize] then
        return "DOWN"
    end
    return NivUI.current.raidSettings[raidSize].playerGrowthDirection or "DOWN"
end

--- Sets the raid player growth direction for a given raid size.
--- @param raidSize number The raid size (10, 25, or 40)
--- @param value string Either "DOWN", "UP", "LEFT", or "RIGHT"
function NivUI:SetRaidPlayerGrowthDirection(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI.current.raidSettings[raidSize].playerGrowthDirection = value

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "playerGrowthDirection", value = value })
end

--- Returns the raid sort mode for a given raid size.
--- @param raidSize number The raid size (10, 25, or 40)
--- @return string sortMode The sort mode (e.g., "GROUP", "ROLE", "NAME")
function NivUI:GetRaidSortMode(raidSize)
    if not NivUI.current.raidSettings or not NivUI.current.raidSettings[raidSize] then
        return "GROUP"
    end
    return NivUI.current.raidSettings[raidSize].sortMode or "GROUP"
end

--- Sets the raid sort mode for a given raid size.
--- @param raidSize number The raid size (10, 25, or 40)
--- @param value string The sort mode (e.g., "GROUP", "ROLE", "NAME")
function NivUI:SetRaidSortMode(raidSize, value)
    EnsureRaidSettings(raidSize)
    NivUI.current.raidSettings[raidSize].sortMode = value

    self:TriggerEvent("RaidSettingsChanged", { raidSize = raidSize, setting = "sortMode", value = value })
end

--- Returns the boss frame spacing in pixels.
--- @return number spacing The spacing value (0-100), defaults to 2
function NivUI:GetBossSpacing()
    return NivUI.current.bossSpacing or 2
end

--- Sets the boss frame spacing.
--- @param value number The spacing in pixels (clamped to 0-100)
function NivUI:SetBossSpacing(value)
    NivUI.current.bossSpacing = ValidateSpacing(value, 0, 100, 2)

    self:TriggerEvent("BossSettingsChanged", { setting = "spacing", value = NivUI.current.bossSpacing })
end

--- Returns the boss frame orientation.
--- @return string orientation Either "VERTICAL" or "HORIZONTAL"
function NivUI:GetBossOrientation()
    return NivUI.current.bossOrientation or "VERTICAL"
end

--- Sets the boss frame orientation.
--- @param value string Either "VERTICAL" or "HORIZONTAL"
function NivUI:SetBossOrientation(value)
    NivUI.current.bossOrientation = value

    self:TriggerEvent("BossSettingsChanged", { setting = "orientation", value = value })
end

--- Returns the boss frame growth direction.
--- @return string direction Either "DOWN", "UP", "LEFT", or "RIGHT"
function NivUI:GetBossGrowthDirection()
    return NivUI.current.bossGrowthDirection or "DOWN"
end

--- Sets the boss frame growth direction.
--- @param value string Either "DOWN", "UP", "LEFT", or "RIGHT"
function NivUI:SetBossGrowthDirection(value)
    NivUI.current.bossGrowthDirection = value

    self:TriggerEvent("BossSettingsChanged", { setting = "growthDirection", value = value })
end

--- Returns the arena frame spacing in pixels.
--- @return number spacing The spacing value (0-100), defaults to 2
function NivUI:GetArenaSpacing()
    return NivUI.current.arenaSpacing or 2
end

--- Sets the arena frame spacing.
--- @param value number The spacing in pixels (clamped to 0-100)
function NivUI:SetArenaSpacing(value)
    NivUI.current.arenaSpacing = ValidateSpacing(value, 0, 100, 2)

    self:TriggerEvent("ArenaSettingsChanged", { setting = "spacing", value = NivUI.current.arenaSpacing })
end

--- Returns the arena frame orientation.
--- @return string orientation Either "VERTICAL" or "HORIZONTAL"
function NivUI:GetArenaOrientation()
    return NivUI.current.arenaOrientation or "VERTICAL"
end

--- Sets the arena frame orientation.
--- @param value string Either "VERTICAL" or "HORIZONTAL"
function NivUI:SetArenaOrientation(value)
    NivUI.current.arenaOrientation = value

    self:TriggerEvent("ArenaSettingsChanged", { setting = "orientation", value = value })
end

--- Returns the arena frame growth direction.
--- @return string direction Either "DOWN", "UP", "LEFT", or "RIGHT"
function NivUI:GetArenaGrowthDirection()
    return NivUI.current.arenaGrowthDirection or "DOWN"
end

--- Sets the arena frame growth direction.
--- @param value string Either "DOWN", "UP", "LEFT", or "RIGHT"
function NivUI:SetArenaGrowthDirection(value)
    NivUI.current.arenaGrowthDirection = value

    self:TriggerEvent("ArenaSettingsChanged", { setting = "growthDirection", value = value })
end

--- Checks if fade-out-of-range is enabled for a frame type.
--- @param frameType string The frame type to check
--- @return boolean enabled Whether fade-out-of-range is enabled
function NivUI:IsFadeOutOfRangeEnabled(frameType)
    if NivUI.current.unitFrameFadeOutOfRange == nil then
        return false
    end
    return NivUI.current.unitFrameFadeOutOfRange[frameType] or false
end

--- Sets whether fade-out-of-range is enabled for a frame type.
--- @param frameType string The frame type to configure
--- @param enabled boolean Whether to enable fade-out-of-range
function NivUI:SetFadeOutOfRange(frameType, enabled)
    NivUI.current.unitFrameFadeOutOfRange = NivUI.current.unitFrameFadeOutOfRange or {}
    NivUI.current.unitFrameFadeOutOfRange[frameType] = enabled
    self:TriggerEvent("FadeOutOfRangeChanged", { frameType = frameType, enabled = enabled })
end

--- Returns the alpha value for out-of-range units.
--- @return number alpha The alpha value (0-1) for out-of-range units
function NivUI:GetOutOfRangeAlpha()
    return NivUI.current.outOfRangeAlpha or 0.3
end

--- Sets the alpha value for out-of-range units.
--- @param alpha number The alpha value (0-1)
function NivUI:SetOutOfRangeAlpha(alpha)
    NivUI.current.outOfRangeAlpha = alpha
    self:TriggerEvent("OutOfRangeAlphaChanged", { alpha = alpha })
end

local function GenerateCustomRaidGroupId()
    return "custom_" .. time() .. "_" .. math.random(1000, 9999)
end

--- Returns all custom raid groups.
--- @return table groups A table of custom raid group configurations keyed by ID
function NivUI:GetCustomRaidGroups()
    return NivUI.current.customRaidGroups or {}
end

--- Returns a specific custom raid group by ID.
--- @param id string The custom raid group ID
--- @return table|nil group The group configuration, or nil if not found
function NivUI:GetCustomRaidGroup(id)
    if not NivUI.current.customRaidGroups then return nil end
    return NivUI.current.customRaidGroups[id]
end

--- Creates a new custom raid group.
--- @param name string The display name for the group
--- @return string|nil id The generated group ID, or nil on failure
--- @return string|nil errorMessage Error message if creation failed
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
        excludePlayer = false,
        styleName = defaultStyleName,
        enabled = true,
    }

    self:TriggerEvent("CustomRaidGroupCreated", { id = id, name = name })

    return id
end

--- Saves changes to an existing custom raid group.
--- @param id string The custom raid group ID
--- @param data table The updated group configuration
--- @return boolean success Whether the save succeeded
--- @return string|nil errorMessage Error message if save failed
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

--- Deletes a custom raid group.
--- @param id string The custom raid group ID to delete
--- @return boolean success Whether the deletion succeeded
--- @return string|nil errorMessage Error message if deletion failed
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

--- Returns a style with defaults merged in for any missing values.
--- @param name string The style name to retrieve
--- @return table style The style with defaults merged
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

--- Initializes the default style if no styles exist.
function NivUI:InitializeDefaultStyle()
    local names = self:GetStyleNames()
    if #names == 0 then
        self:SaveStyle("Default", NivUI.UnitFrames.DEFAULT_STYLE)
    end
end
