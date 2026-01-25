NivUI = NivUI or {}
NivUI.EditMode = NivUI.EditMode or {}

local editModeActive = false
local selectionFrames = {}
local forceShownFrames = {}
local selectedFrame = nil
local registeredFrames = {}
local visibilityDrivers = {}
local suspendedDrivers = {}

-- Nine-slice layout matching Blizzard's EditModeSystemSelectionLayout
local SelectionLayout = {
    ["TopRightCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = 8, y = 8 },
    ["TopLeftCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = -8, y = 8 },
    ["BottomLeftCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = -8, y = -8 },
    ["BottomRightCorner"] = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = 8, y = -8 },
    ["TopEdge"] = { atlas = "_%s-NineSlice-EdgeTop" },
    ["BottomEdge"] = { atlas = "_%s-NineSlice-EdgeBottom" },
    ["LeftEdge"] = { atlas = "!%s-NineSlice-EdgeLeft" },
    ["RightEdge"] = { atlas = "!%s-NineSlice-EdgeRight" },
    ["Center"] = { atlas = "%s-NineSlice-Center", x = -8, y = 8, x1 = 8, y1 = -8 },
}

local HIGHLIGHT_TEXTURE_KIT = "editmode-actionbar-highlight"
local SELECTED_TEXTURE_KIT = "editmode-actionbar-selected"

function NivUI.EditMode:IsActive()
    return editModeActive
end

function NivUI.EditMode:IsSnapEnabled()
    return EditModeManagerFrame and EditModeManagerFrame:IsSnapEnabled()
end

function NivUI.EditMode:RegisterVisibilityDriver(frameType, frame, driverString)
    if not driverString or driverString == "" then
        visibilityDrivers[frameType] = nil
        return
    end

    visibilityDrivers[frameType] = { frame = frame, driver = driverString }

    if editModeActive then
        UnregisterStateDriver(frame, "visibility")
        suspendedDrivers[frameType] = visibilityDrivers[frameType]
        frame:Show()
        forceShownFrames[frameType] = true
    end
end

function NivUI.EditMode:UnregisterVisibilityDriver(frameType)
    visibilityDrivers[frameType] = nil
    suspendedDrivers[frameType] = nil
end

function NivUI.EditMode:SavePosition(frameType, customFrame)
    NivUI_DB.unitFramePositions = NivUI_DB.unitFramePositions or {}

    local point, relativeTo, relativePoint, offsetX, offsetY = customFrame:GetPoint(1)
    NivUI_DB.unitFramePositions[frameType] = {
        point = point,
        relativeTo = relativeTo and relativeTo:GetName() or "UIParent",
        relativePoint = relativePoint,
        offsetX = offsetX,
        offsetY = offsetY
    }
end

function NivUI.EditMode:ApplyPosition(frameType, customFrame)
    local pos = NivUI_DB.unitFramePositions and NivUI_DB.unitFramePositions[frameType]
    if not pos then return false end

    customFrame:ClearAllPoints()
    customFrame:SetPoint(pos.point, _G[pos.relativeTo] or UIParent,
        pos.relativePoint, pos.offsetX, pos.offsetY)
    return true
end

local function ApplySelectionTexture(selection, textureKit)
    NineSliceUtil.ApplyLayout(selection, SelectionLayout, textureKit)
end

-- Add magnetism-compatible methods to a frame
local function SetupMagnetismMethods(frame, selection)
    -- Returns selection frame sides, adjusted for scale: left, right, bottom, top
    function frame:GetScaledSelectionSides()
        local left, bottom, width, height = selection:GetRect()
        local scale = self:GetScale()
        return left * scale, (left + width) * scale, bottom * scale, (bottom + height) * scale
    end

    -- Returns selection frame center, adjusted for scale: centerX, centerY
    function frame:GetScaledSelectionCenter()
        local centerX, centerY = selection:GetCenter()
        local scale = self:GetScale()
        return centerX * scale, centerY * scale
    end

    -- Returns center, adjusted for scale: centerX, centerY
    function frame:GetScaledCenter()
        local centerX, centerY = self:GetCenter()
        local scale = self:GetScale()
        return centerX * scale, centerY * scale
    end

    -- Safely get scaled selection sides from another frame (may have secret values or be hidden)
    local function SafeGetOtherFrameSides(otherFrame)
        local success, left, right, bottom, top = pcall(function()
            if otherFrame.GetScaledSelectionSides then
                return otherFrame:GetScaledSelectionSides()
            else
                local l, b, w, h = otherFrame:GetRect()
                if not l then return nil end
                local scale = otherFrame:GetScale() or 1
                return l * scale, (l + w) * scale, b * scale, (b + h) * scale
            end
        end)
        if success and left then
            return left, right, bottom, top
        end
        return nil
    end

    function frame:IsToTheLeftOfFrame(systemFrame)
        local _, myRight = self:GetScaledSelectionSides()
        local otherLeft = SafeGetOtherFrameSides(systemFrame)
        if not otherLeft then return false end
        return myRight < otherLeft
    end

    function frame:IsAboveFrame(systemFrame)
        local _, _, myBottom = self:GetScaledSelectionSides()
        local otherLeft, _, _, otherTop = SafeGetOtherFrameSides(systemFrame)
        if not otherLeft then return false end
        return myBottom > otherTop
    end

    function frame:IsVerticallyAlignedWithFrame(systemFrame)
        local _, _, myBottom, myTop = self:GetScaledSelectionSides()
        local otherLeft, _, otherBottom, otherTop = SafeGetOtherFrameSides(systemFrame)
        if not otherLeft then return false end
        return (myTop >= otherBottom) and (myBottom <= otherTop)
    end

    function frame:IsHorizontallyAlignedWithFrame(systemFrame)
        local myLeft, myRight = self:GetScaledSelectionSides()
        local otherLeft, otherRight = SafeGetOtherFrameSides(systemFrame)
        if not otherLeft then return false end
        return (myRight >= otherLeft) and (myLeft <= otherRight)
    end

    -- Determines if this frame can snap to another frame horizontally/vertically
    function frame:GetFrameMagneticEligibility(otherFrame)
        if otherFrame == self then
            return false, false
        end
        -- Use pcall to safely check alignment - other frame may have secret/nil rect values
        local hSuccess, horizontalEligible = pcall(function()
            return self:IsVerticallyAlignedWithFrame(otherFrame)
        end)
        local vSuccess, verticalEligible = pcall(function()
            return self:IsHorizontallyAlignedWithFrame(otherFrame)
        end)
        return hSuccess and horizontalEligible or false, vSuccess and verticalEligible or false
    end

    -- Get combined center offset from another frame
    function frame:GetCombinedCenterOffset(otherFrame)
        local centerX, centerY = self:GetScaledSelectionCenter()
        local frameCenterX, frameCenterY

        local success = pcall(function()
            if otherFrame.GetScaledCenter then
                frameCenterX, frameCenterY = otherFrame:GetScaledCenter()
            else
                frameCenterX, frameCenterY = otherFrame:GetCenter()
            end
        end)

        if not success or not frameCenterX then
            return 0, 0
        end

        local scale = self:GetScale()
        return (centerX - frameCenterX) / scale, (centerY - frameCenterY) / scale
    end

    -- Get selection offset for snapping
    function frame:GetCombinedSelectionOffset(frameInfo, forYOffset)
        local myLeft, myRight, myBottom, myTop = self:GetScaledSelectionSides()
        local otherLeft, otherRight, otherBottom, otherTop

        if frameInfo.frame == UIParent then
            otherLeft = EditModeMagnetismManager.uiParentLeft
            otherRight = EditModeMagnetismManager.uiParentRight
            otherBottom = EditModeMagnetismManager.uiParentBottom
            otherTop = EditModeMagnetismManager.uiParentTop
        else
            local success = pcall(function()
                if frameInfo.frame.GetScaledSelectionSides then
                    otherLeft, otherRight, otherBottom, otherTop = frameInfo.frame:GetScaledSelectionSides()
                else
                    local left, bottom, width, height = frameInfo.frame:GetRect()
                    if left then
                        otherLeft, otherRight, otherBottom, otherTop = left, left + width, bottom, bottom + height
                    end
                end
            end)

            if not success or not otherLeft then
                return 0
            end
        end

        local scale = self:GetScale()
        local point = frameInfo.point
        local relativePoint = frameInfo.relativePoint
        local offset = frameInfo.offset or 0

        if forYOffset then
            local myY = string.find(point, "TOP") and myTop or (string.find(point, "BOTTOM") and myBottom or ((myTop + myBottom) / 2))
            local otherY = string.find(relativePoint, "TOP") and otherTop or (string.find(relativePoint, "BOTTOM") and otherBottom or ((otherTop + otherBottom) / 2))
            return (myY - otherY) / scale + offset
        else
            local myX = string.find(point, "RIGHT") and myRight or (string.find(point, "LEFT") and myLeft or ((myLeft + myRight) / 2))
            local otherX = string.find(relativePoint, "RIGHT") and otherRight or (string.find(relativePoint, "LEFT") and otherLeft or ((otherLeft + otherRight) / 2))
            return (myX - otherX) / scale + offset
        end
    end

    -- Calculate snap offsets
    function frame:GetSnapOffsets(frameInfo)
        local forYOffsetNo = false
        local forYOffsetYes = true
        local offsetX, offsetY

        if frameInfo.isCornerSnap then
            offsetX = self:GetCombinedSelectionOffset(frameInfo, forYOffsetNo)
            offsetY = self:GetCombinedSelectionOffset(frameInfo, forYOffsetYes)
        else
            offsetX, offsetY = self:GetCombinedCenterOffset(frameInfo.frame)
            if frameInfo.isHorizontal then
                offsetX = self:GetCombinedSelectionOffset(frameInfo, forYOffsetNo)
            else
                offsetY = self:GetCombinedSelectionOffset(frameInfo, forYOffsetYes)
            end
        end

        return offsetX, offsetY
    end

    -- Snap to a frame using magnetism info
    function frame:SnapToFrame(frameInfo)
        local offsetX, offsetY = self:GetSnapOffsets(frameInfo)
        self:ClearAllPoints()
        self:SetPoint(frameInfo.point, frameInfo.frame, frameInfo.relativePoint, offsetX, offsetY)
    end
end

-- Register a frame with the magnetism system
function NivUI.EditMode:RegisterFrameForMagnetism(frame)
    if not EditModeMagnetismManager then return end
    if registeredFrames[frame] then return end

    EditModeMagnetismManager:RegisterFrame(frame)
    registeredFrames[frame] = true
end

-- Unregister a frame from the magnetism system
function NivUI.EditMode:UnregisterFrameFromMagnetism(frame)
    if not EditModeMagnetismManager then return end
    if not registeredFrames[frame] then return end

    EditModeMagnetismManager:UnregisterFrame(frame)
    registeredFrames[frame] = nil
end

function NivUI.EditMode:CreateSelectionFrame(frameType, customFrame)
    if selectionFrames[frameType] then
        selectionFrames[frameType]:SetParent(customFrame)
        selectionFrames[frameType]:SetAllPoints(customFrame)
        selectionFrames[frameType].customFrame = customFrame
        SetupMagnetismMethods(customFrame, selectionFrames[frameType])
        return selectionFrames[frameType]
    end

    local selection = CreateFrame("Frame", "NivUI_" .. frameType .. "_Selection",
        customFrame, "NineSliceCodeTemplate")

    selection:SetAllPoints(customFrame)
    selection:SetFrameStrata("MEDIUM")
    selection:SetFrameLevel(1000)
    selection:EnableMouse(true)
    selection:RegisterForDrag("LeftButton")
    selection:Hide()

    selection.frameType = frameType
    selection.customFrame = customFrame
    selection.textureShown = nil
    selection.isDragging = false

    -- Set up magnetism methods on the custom frame
    SetupMagnetismMethods(customFrame, selection)

    -- Store reference for Selection compatibility
    customFrame.Selection = selection

    -- Create mouse-over highlight child frame
    selection.MouseOverHighlight = CreateFrame("Frame", nil, selection, "NineSliceCodeTemplate")
    selection.MouseOverHighlight:SetAllPoints(selection)
    selection.MouseOverHighlight:SetAlpha(0.4)
    selection.MouseOverHighlight:Hide()
    NineSliceUtil.ApplyLayout(selection.MouseOverHighlight, SelectionLayout, HIGHLIGHT_TEXTURE_KIT)
    selection.MouseOverHighlight:SetBlendMode("ADD")

    -- Create label
    selection.Label = selection:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    selection.Label:SetAllPoints(selection)

    -- Use custom group name if this is a custom raid group
    local labelText = frameType
    if frameType:find("^customRaid_") then
        local groupId = frameType:gsub("^customRaid_", "")
        local groupConfig = NivUI:GetCustomRaidGroup(groupId)
        if groupConfig then
            labelText = groupConfig.name
        end
    end
    selection.Label:SetText(labelText)

    selection:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end

        self.customFrame:SetMovable(true)
        self.customFrame:StartMoving()
        self.isDragging = true

        -- Enable snap preview lines
        if EditModeManagerFrame and NivUI.EditMode:IsSnapEnabled() then
            EditModeManagerFrame:SetSnapPreviewFrame(self.customFrame)
        end
    end)

    selection:SetScript("OnDragStop", function(self)
        self.customFrame:StopMovingOrSizing()
        self.customFrame:SetMovable(false)
        self.isDragging = false

        -- Clear snap preview and apply magnetism
        if EditModeManagerFrame then
            EditModeManagerFrame:ClearSnapPreviewFrame()
        end

        if NivUI.EditMode:IsSnapEnabled() and EditModeMagnetismManager then
            EditModeMagnetismManager:ApplyMagnetism(self.customFrame)
        end

        NivUI.EditMode:SavePosition(self.frameType, self.customFrame)
    end)

    selection:SetScript("OnMouseDown", function(self)
        NivUI.EditMode:SelectFrame(self.frameType, self.customFrame)
    end)

    selection:SetScript("OnEnter", function(self)
        self.MouseOverHighlight:Show()
    end)

    selection:SetScript("OnLeave", function(self)
        self.MouseOverHighlight:Hide()
    end)

    selection.IsDragging = function(self)
        return self.isDragging
    end

    selectionFrames[frameType] = selection
    return selection
end

function NivUI.EditMode:ShowHighlighted(frameType)
    local selection = selectionFrames[frameType]
    if not selection then return end

    if selection.textureShown ~= "highlight" then
        ApplySelectionTexture(selection, HIGHLIGHT_TEXTURE_KIT)
        selection.textureShown = "highlight"
    end
    selection.isSelected = false
    selection:Show()
end

function NivUI.EditMode:ShowSelected(frameType)
    local selection = selectionFrames[frameType]
    if not selection then return end

    if selection.textureShown ~= "selected" then
        ApplySelectionTexture(selection, SELECTED_TEXTURE_KIT)
        selection.textureShown = "selected"
    end
    selection.isSelected = true
    selection:Show()
end

function NivUI.EditMode:SelectFrame(frameType, targetFrame)
    -- Deselect previous
    if selectedFrame and selectedFrame ~= frameType then
        self:ShowHighlighted(selectedFrame)
    end

    -- Select new
    selectedFrame = frameType
    self:ShowSelected(frameType)

    -- Show settings dialog if this frame type has settings
    if self:HasSettings(frameType) then
        self:ShowSettingsDialog(frameType, targetFrame)
    end
end

function NivUI.EditMode:ClearSelection()
    if selectedFrame then
        self:ShowHighlighted(selectedFrame)
        selectedFrame = nil
    end
    self:HideSettingsDialog()
end

function NivUI.EditMode:ShowSelection(frameType)
    local selection = selectionFrames[frameType]
    if selection and selection.customFrame and selection.customFrame:IsShown() then
        self:ShowHighlighted(frameType)
    end
end

function NivUI.EditMode:HideSelection(frameType)
    local selection = selectionFrames[frameType]
    if selection then
        selection:Hide()
        selection.textureShown = nil
    end
end

-- Calculate projected container size for group frame types based on settings
-- This allows Edit Mode to show accurate frame sizes even when not in a group
function NivUI.EditMode:GetProjectedContainerSize(frameType)
    local styleName = NivUI:GetAssignment(frameType)
    local style = NivUI:GetStyleWithDefaults(styleName)
    local frameConfig = style and style.frame or {}
    local frameWidth = frameConfig.width or 200
    local frameHeight = frameConfig.height or 60

    if frameType == "party" then
        local memberCount = NivUI:DoesPartyIncludePlayer() and 5 or 4
        local orientation = NivUI:GetPartyOrientation()
        local spacing = NivUI:GetPartySpacing()

        if orientation == "VERTICAL" then
            return frameWidth, memberCount * frameHeight + (memberCount - 1) * spacing
        else
            return memberCount * frameWidth + (memberCount - 1) * spacing, frameHeight
        end

    elseif frameType == "boss" then
        local memberCount = 5
        local orientation = NivUI:GetBossOrientation()
        local spacing = NivUI:GetBossSpacing()

        if orientation == "VERTICAL" then
            return frameWidth, memberCount * frameHeight + (memberCount - 1) * spacing
        else
            return memberCount * frameWidth + (memberCount - 1) * spacing, frameHeight
        end

    elseif frameType == "arena" then
        local memberCount = 5
        local orientation = NivUI:GetArenaOrientation()
        local spacing = NivUI:GetArenaSpacing()

        if orientation == "VERTICAL" then
            return frameWidth, memberCount * frameHeight + (memberCount - 1) * spacing
        else
            return memberCount * frameWidth + (memberCount - 1) * spacing, frameHeight
        end

    elseif frameType == "raid10" or frameType == "raid20" or frameType == "raid40" then
        local maxGroups = frameType == "raid10" and 2 or (frameType == "raid20" and 4 or 8)
        local spacing = NivUI:GetRaidSpacing(frameType)
        local groupOrientation = NivUI:GetRaidGroupOrientation(frameType)
        local playerGrowth = NivUI:GetRaidPlayerGrowthDirection(frameType)

        -- Raid frames typically use smaller dimensions
        frameWidth = frameConfig.width or 80
        frameHeight = frameConfig.height or 40

        -- Calculate group size (5 members per group)
        local groupWidth, groupHeight
        if playerGrowth == "DOWN" or playerGrowth == "UP" then
            groupWidth = frameWidth
            groupHeight = 5 * frameHeight + 4 * spacing
        else
            groupWidth = 5 * frameWidth + 4 * spacing
            groupHeight = frameHeight
        end

        -- Calculate container size based on group arrangement
        if groupOrientation == "VERTICAL" then
            return groupWidth, maxGroups * groupHeight + (maxGroups - 1) * spacing
        else
            return maxGroups * groupWidth + (maxGroups - 1) * spacing, groupHeight
        end

    elseif frameType:find("^customRaid_") then
        -- Custom raid groups - estimate based on a reasonable max member count
        local groupId = frameType:gsub("^customRaid_", "")
        local groupConfig = NivUI:GetCustomRaidGroup(groupId)
        if not groupConfig then return nil, nil end

        styleName = groupConfig.styleName or styleName
        style = NivUI:GetStyleWithDefaults(styleName)
        frameConfig = style and style.frame or {}
        frameWidth = frameConfig.width or 80
        frameHeight = frameConfig.height or 40

        -- Estimate max members: roles can have up to 40 members, member filter uses selection count
        local maxMembers = 10  -- Reasonable default for preview
        if groupConfig.filterType == "member" then
            local memberCount = 0
            for _ in pairs(groupConfig.members) do
                memberCount = memberCount + 1
            end
            maxMembers = math.max(memberCount, 1)
        end

        local spacing = 2
        return frameWidth, maxMembers * frameHeight + (maxMembers - 1) * spacing
    end

    return nil, nil
end

-- Resize group frame containers to reflect projected size for Edit Mode
function NivUI.EditMode:UpdateContainerSizes()
    local groupFrameTypes = {"party", "boss", "arena", "raid10", "raid20", "raid40"}

    for _, frameType in ipairs(groupFrameTypes) do
        local selection = selectionFrames[frameType]
        if selection and selection.customFrame then
            local width, height = self:GetProjectedContainerSize(frameType)
            if width and height then
                selection.customFrame:SetSize(width, height)
            end
        end
    end

    -- Also update custom raid group sizes
    local customGroups = NivUI:GetCustomRaidGroups()
    for groupId in pairs(customGroups) do
        local frameType = "customRaid_" .. groupId
        local selection = selectionFrames[frameType]
        if selection and selection.customFrame then
            local width, height = self:GetProjectedContainerSize(frameType)
            if width and height then
                selection.customFrame:SetSize(width, height)
            end
        end
    end
end

function NivUI.EditMode:ShowAllSelections()
    -- Update UIParent points for magnetism calculations
    if EditModeMagnetismManager and EditModeMagnetismManager.UpdateUIParentPoints then
        EditModeMagnetismManager:UpdateUIParentPoints()
    end

    -- Resize group frame containers to reflect user settings
    self:UpdateContainerSizes()

    for frameType, driverInfo in pairs(visibilityDrivers) do
        UnregisterStateDriver(driverInfo.frame, "visibility")
        suspendedDrivers[frameType] = driverInfo
    end

    for frameType, selection in pairs(selectionFrames) do
        if selection.customFrame then
            if not selection.customFrame:IsShown() then
                selection.customFrame:Show()
                forceShownFrames[frameType] = true
            end
            self:ShowHighlighted(frameType)

            -- Register for magnetism when visible
            self:RegisterFrameForMagnetism(selection.customFrame)
        end
    end
end

function NivUI.EditMode:HideAllSelections()
    selectedFrame = nil
    self:HideSettingsDialog()

    for frameType, selection in pairs(selectionFrames) do
        selection:Hide()
        selection.textureShown = nil

        -- Unregister from magnetism
        if selection.customFrame then
            self:UnregisterFrameFromMagnetism(selection.customFrame)
        end

        if forceShownFrames[frameType] and selection.customFrame then
            selection.customFrame:Hide()
            forceShownFrames[frameType] = nil
        end
    end

    for _, driverInfo in pairs(suspendedDrivers) do
        RegisterStateDriver(driverInfo.frame, "visibility", driverInfo.driver)
    end
    wipe(suspendedDrivers)
end

function NivUI.EditMode:HideBlizzardSelections()
    for _, blizzFrame in ipairs({PlayerFrame, TargetFrame, PetFrame, FocusFrame}) do
        if blizzFrame and blizzFrame.Selection then
            blizzFrame.Selection:Hide()
            if not blizzFrame.Selection.NivUI_Hooked then
                blizzFrame.Selection.NivUI_Hooked = true
                hooksecurefunc(blizzFrame.Selection, "Show", function(self)
                    self:Hide()
                end)
            end
        end
    end
end

local function OnEditModeEnter()
    editModeActive = true
    NivUI.EditMode:HideBlizzardSelections()
    NivUI.EditMode:ShowAllSelections()
end

local function OnEditModeExit()
    editModeActive = false
    NivUI.EditMode:HideAllSelections()
end

EventRegistry:RegisterCallback("EditMode.Enter", OnEditModeEnter, NivUI.EditMode)
EventRegistry:RegisterCallback("EditMode.Exit", OnEditModeExit, NivUI.EditMode)

if EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive() then
    OnEditModeEnter()
end
