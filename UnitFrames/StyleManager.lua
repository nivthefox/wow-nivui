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

    if name == "Default" then
        return false, "Cannot delete the Default style"
    end

    if not self:StyleExists(name) then
        return false, "Style '" .. name .. "' does not exist"
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

    -- Reassign frames using this style to Default
    for _, frameType in ipairs(inUse) do
        NivUI_DB.unitFrameAssignments[frameType] = "Default"
    end

    NivUI_DB.unitFrameStyles[name] = nil

    -- Trigger event for listeners
    self:TriggerEvent("StyleDeleted", { styleName = name, reassigned = inUse })

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

    if oldName == "Default" then
        return false, "Cannot rename the Default style"
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

-- Ensure Default style exists
function NivUI:InitializeDefaultStyle()
    if not self:StyleExists("Default") then
        self:SaveStyle("Default", NivUI.UnitFrames.DEFAULT_STYLE)
    end
end
