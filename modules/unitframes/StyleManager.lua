NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

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

    NivUI_DB.unitFrameStyles[name] = DeepCopy(data)

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

function NivUI:GetStyleWithDefaults(name)
    local style = self:GetStyle(name)
    if not style then
        return DeepCopy(NivUI.UnitFrames.DEFAULT_STYLE)
    end

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
