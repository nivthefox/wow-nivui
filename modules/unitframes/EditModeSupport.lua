NivUI = NivUI or {}
NivUI.EditMode = {}

local editModeActive = false
local selectionFrames = {}
local forceShownFrames = {}

function NivUI.EditMode:IsActive()
    return editModeActive
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

function NivUI.EditMode:CreateSelectionFrame(frameType, customFrame)
    if selectionFrames[frameType] then
        selectionFrames[frameType]:SetParent(customFrame)
        selectionFrames[frameType]:SetAllPoints(customFrame)
        selectionFrames[frameType].customFrame = customFrame
        return selectionFrames[frameType]
    end

    local selection = CreateFrame("Frame", "NivUI_" .. frameType .. "_Selection",
        customFrame, "BackdropTemplate")

    selection:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 2,
    })
    selection:SetBackdropBorderColor(0.3, 0.6, 1, 1)

    selection:SetAllPoints(customFrame)
    selection:SetFrameStrata("HIGH")
    selection:SetFrameLevel(1000)
    selection:EnableMouse(true)
    selection:RegisterForDrag("LeftButton")
    selection:Hide()

    selection.frameType = frameType
    selection.customFrame = customFrame

    selection:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        self.customFrame:SetMovable(true)
        self.customFrame:StartMoving()
    end)

    selection:SetScript("OnDragStop", function(self)
        self.customFrame:StopMovingOrSizing()
        self.customFrame:SetMovable(false)
        NivUI.EditMode:SavePosition(self.frameType, self.customFrame)
    end)

    selection:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.5, 0.8, 1, 1)
    end)

    selection:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.3, 0.6, 1, 1)
    end)

    selectionFrames[frameType] = selection
    return selection
end

function NivUI.EditMode:ShowSelection(frameType)
    local selection = selectionFrames[frameType]
    if selection and selection.customFrame and selection.customFrame:IsShown() then
        selection:Show()
    end
end

function NivUI.EditMode:HideSelection(frameType)
    local selection = selectionFrames[frameType]
    if selection then
        selection:Hide()
    end
end

function NivUI.EditMode:ShowAllSelections()
    for frameType, selection in pairs(selectionFrames) do
        if selection.customFrame then
            if not selection.customFrame:IsShown() then
                selection.customFrame:Show()
                forceShownFrames[frameType] = true
            end
            selection:Show()
        end
    end
end

function NivUI.EditMode:HideAllSelections()
    for frameType, selection in pairs(selectionFrames) do
        selection:Hide()
        if forceShownFrames[frameType] and selection.customFrame then
            selection.customFrame:Hide()
            forceShownFrames[frameType] = nil
        end
    end
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
