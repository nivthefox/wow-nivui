-- NivUI Unit Frames: Style Manager
-- CRUD operations for unit frame styles

NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

-- Deep copy helper (local since NivUI.lua might not be loaded yet)
local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

-- Get a style by name
-- Returns the style data, or nil if not found
function NivUI:GetStyle(name)
    if not NivUI_DB.unitFrameStyles then return nil end
    local style = NivUI_DB.unitFrameStyles[name]
    if not style then return nil end
    return style
end

-- Get all style names as a sorted list
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

-- Check if a style exists
function NivUI:StyleExists(name)
    return NivUI_DB.unitFrameStyles and NivUI_DB.unitFrameStyles[name] ~= nil
end

-- Save a style (create or update)
-- Returns true on success, false with error message on failure
function NivUI:SaveStyle(name, data)
    if not name or name == "" then
        return false, "Style name cannot be empty"
    end

    if not NivUI_DB.unitFrameStyles then
        NivUI_DB.unitFrameStyles = {}
    end

    NivUI_DB.unitFrameStyles[name] = DeepCopy(data)

    -- Trigger event for listeners
    self:TriggerEvent("StyleChanged", { styleName = name })

    return true
end

-- Create a new style from defaults
-- Returns true on success, false with error message on failure
function NivUI:CreateStyle(name)
    if not name or name == "" then
        return false, "Style name cannot be empty"
    end

    if self:StyleExists(name) then
        return false, "Style '" .. name .. "' already exists"
    end

    return self:SaveStyle(name, NivUI.UnitFrames.DEFAULT_STYLE)
end

-- Delete a style
-- Returns true on success, false with error message on failure
function NivUI:DeleteStyle(name)
    if not name or name == "" then
        return false, "Style name cannot be empty"
    end

    if not self:StyleExists(name) then
        return false, "Style '" .. name .. "' does not exist"
    end

    -- Check if this is the last style
    local styleCount = 0
    for _ in pairs(NivUI_DB.unitFrameStyles) do
        styleCount = styleCount + 1
    end

    if styleCount <= 1 then
        return false, "Cannot delete the last style"
    end

    -- Find another style to reassign to
    local fallbackStyle = nil
    for styleName in pairs(NivUI_DB.unitFrameStyles) do
        if styleName ~= name then
            fallbackStyle = styleName
            break
        end
    end

    -- Check if any frame types are using this style
    local inUse = {}
    if NivUI_DB.unitFrameAssignments then
        for frameType, styleName in pairs(NivUI_DB.unitFrameAssignments) do
            if styleName == name then
                table.insert(inUse, frameType)
            end
        end
    end

    -- Reassign frames using this style to fallback
    for _, frameType in ipairs(inUse) do
        NivUI_DB.unitFrameAssignments[frameType] = fallbackStyle
    end

    NivUI_DB.unitFrameStyles[name] = nil

    -- Trigger event for listeners
    self:TriggerEvent("StyleDeleted", { styleName = name, reassigned = inUse, fallback = fallbackStyle })

    return true
end

-- Duplicate a style
-- Returns true on success, false with error message on failure
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

-- Rename a style
-- Returns true on success, false with error message on failure
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

    -- Create new style with same data
    NivUI_DB.unitFrameStyles[newName] = NivUI_DB.unitFrameStyles[oldName]
    NivUI_DB.unitFrameStyles[oldName] = nil

    -- Update any assignments using the old name
    if NivUI_DB.unitFrameAssignments then
        for frameType, styleName in pairs(NivUI_DB.unitFrameAssignments) do
            if styleName == oldName then
                NivUI_DB.unitFrameAssignments[frameType] = newName
            end
        end
    end

    -- Trigger event for listeners
    self:TriggerEvent("StyleRenamed", { oldName = oldName, newName = newName })

    return true
end

-- Get the style assigned to a frame type
function NivUI:GetAssignment(frameType)
    if not NivUI_DB.unitFrameAssignments then
        return "Default"
    end
    return NivUI_DB.unitFrameAssignments[frameType] or "Default"
end

-- Set the style assignment for a frame type
function NivUI:SetAssignment(frameType, styleName)
    if not NivUI_DB.unitFrameAssignments then
        NivUI_DB.unitFrameAssignments = {}
    end

    NivUI_DB.unitFrameAssignments[frameType] = styleName

    -- Trigger event for listeners
    self:TriggerEvent("AssignmentChanged", { frameType = frameType, styleName = styleName })
end

-- Check if a frame type is enabled
function NivUI:IsFrameEnabled(frameType)
    if not NivUI_DB.unitFrameEnabled then
        return false
    end
    return NivUI_DB.unitFrameEnabled[frameType] == true
end

-- Set the enabled state for a frame type
function NivUI:SetFrameEnabled(frameType, enabled)
    if not NivUI_DB.unitFrameEnabled then
        NivUI_DB.unitFrameEnabled = {}
    end

    NivUI_DB.unitFrameEnabled[frameType] = enabled

    -- Trigger event for listeners
    self:TriggerEvent("FrameEnabledChanged", { frameType = frameType, enabled = enabled })
end

-- Check if a frame type uses real-time updates (every frame instead of throttled)
function NivUI:IsRealTimeUpdates(frameType)
    if not NivUI_DB.unitFrameRealTimeUpdates then
        return false
    end
    return NivUI_DB.unitFrameRealTimeUpdates[frameType] == true
end

-- Set whether a frame type uses real-time updates
function NivUI:SetRealTimeUpdates(frameType, enabled)
    if not NivUI_DB.unitFrameRealTimeUpdates then
        NivUI_DB.unitFrameRealTimeUpdates = {}
    end

    NivUI_DB.unitFrameRealTimeUpdates[frameType] = enabled

    -- Trigger event for listeners
    self:TriggerEvent("RealTimeUpdatesChanged", { frameType = frameType, enabled = enabled })
end

-- Get a style with the full default values merged in
-- This ensures any missing keys have defaults
function NivUI:GetStyleWithDefaults(name)
    local style = self:GetStyle(name)
    if not style then
        return DeepCopy(NivUI.UnitFrames.DEFAULT_STYLE)
    end

    -- Merge with defaults (style values take precedence)
    local merged = DeepCopy(NivUI.UnitFrames.DEFAULT_STYLE)

    local function MergeTable(target, source)
        for k, v in pairs(source) do
            if type(v) == "table" and type(target[k]) == "table" then
                MergeTable(target[k], v)
            else
                target[k] = DeepCopy(v)
            end
        end
    end

    MergeTable(merged, style)
    return merged
end

--------------------------------------------------------------------------------
-- Event System
--------------------------------------------------------------------------------

NivUI.eventCallbacks = NivUI.eventCallbacks or {}

-- Register a callback for an event
function NivUI:RegisterCallback(event, callback)
    if not self.eventCallbacks[event] then
        self.eventCallbacks[event] = {}
    end
    table.insert(self.eventCallbacks[event], callback)
end

-- Unregister a callback
function NivUI:UnregisterCallback(event, callback)
    if not self.eventCallbacks[event] then return end
    for i, cb in ipairs(self.eventCallbacks[event]) do
        if cb == callback then
            table.remove(self.eventCallbacks[event], i)
            return
        end
    end
end

-- Trigger an event
function NivUI:TriggerEvent(event, data)
    if not self.eventCallbacks[event] then return end
    for _, callback in ipairs(self.eventCallbacks[event]) do
        callback(data)
    end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

-- Ensure at least one style exists (creates "Default" only if no styles exist)
function NivUI:InitializeDefaultStyle()
    local names = self:GetStyleNames()
    if #names == 0 then
        self:SaveStyle("Default", NivUI.UnitFrames.DEFAULT_STYLE)
    end
end
