NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local MAX_BOSS_FRAMES = 5

local UpdateAllMemberFrames

local state = {
    enabled = false,
    previewMode = false,
    container = nil,
    memberFrames = {},  -- Keyed by unit ID: "boss1", "boss2", etc.
    memberStates = {},  -- State objects for each member frame
    styleName = nil,
}

local function GetBossUnits()
    local units = {}
    for i = 1, MAX_BOSS_FRAMES do
        table.insert(units, "boss" .. i)
    end
    return units
end

local function ShouldShowBossFrames()
    if state.previewMode then
        return true
    end

    -- Show if any boss exists
    for i = 1, MAX_BOSS_FRAMES do
        if UnitExists("boss" .. i) then
            return true
        end
    end

    return false
end

local function ShouldShowUnit(unit)
    if state.previewMode then
        return true
    end

    return UnitExists(unit)
end

local function LayoutMemberFrames()
    if not state.container then return end

    local orientation = NivUI:GetBossOrientation()
    local growth = NivUI:GetBossGrowthDirection()
    local spacing = NivUI:GetBossSpacing()
    local units = GetBossUnits()

    local style = NivUI:GetStyleWithDefaults(state.styleName)
    local frameWidth = style.frame.width or 200
    local frameHeight = style.frame.height or 60

    local xOffset, yOffset = 0, 0
    local xStep, yStep = 0, 0

    if orientation == "VERTICAL" then
        if growth == "DOWN" then
            yStep = -(frameHeight + spacing)
        else  -- UP
            yStep = frameHeight + spacing
        end
    else  -- HORIZONTAL
        if growth == "RIGHT" then
            xStep = frameWidth + spacing
        else  -- LEFT
            xStep = -(frameWidth + spacing)
        end
    end

    local visibleIndex = 0
    for _, unit in ipairs(units) do
        local frame = state.memberFrames[unit]
        if frame then
            if ShouldShowUnit(unit) then
                frame:ClearAllPoints()
                frame:SetPoint("TOPLEFT", state.container, "TOPLEFT", xOffset, yOffset)
                frame:Show()

                visibleIndex = visibleIndex + 1
                xOffset = xOffset + xStep
                yOffset = yOffset + yStep
            else
                frame:Hide()
            end
        end
    end

    local totalFrames = visibleIndex
    if totalFrames > 0 then
        local containerWidth, containerHeight

        if orientation == "VERTICAL" then
            containerWidth = frameWidth
            containerHeight = totalFrames * frameHeight + (totalFrames - 1) * spacing
        else
            containerWidth = totalFrames * frameWidth + (totalFrames - 1) * spacing
            containerHeight = frameHeight
        end

        state.container:SetSize(containerWidth, containerHeight)
    end
end

local function CreateMemberFrame(unit)
    local style = NivUI:GetStyleWithDefaults(state.styleName)
    if not style then return nil end

    local frameConfig = style.frame or {}
    local frameWidth = frameConfig.width or 200
    local frameHeight = frameConfig.height or 60

    local frameName = "NivUI_BossFrame_" .. unit
    local frame = CreateFrame("Button", frameName, state.container, "SecureUnitButtonTemplate")
    frame:SetSize(frameWidth, frameHeight)

    if frameConfig.strata then frame:SetFrameStrata(frameConfig.strata) end
    if frameConfig.frameLevel then frame:SetFrameLevel(frameConfig.frameLevel) end

    frame:SetAttribute("unit", unit)
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "togglemenu")
    frame:RegisterForClicks("AnyUp")

    if frameConfig.showBorder then
        frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.border:SetAllPoints()
        local borderSize = frameConfig.borderSize or 1
        local borderColor = frameConfig.borderColor or { r = 0, g = 0, b = 0, a = 1 }
        frame.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = borderSize,
        })
        frame.border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    end

    frame.widgets = Base.CreateWidgets(frame, style, unit)
    Base.ApplyAnchors(frame, frame.widgets, style)

    local memberState = {
        unit = unit,
        frameType = "boss",
        defaultName = "Boss",
        customFrame = frame,
        currentStyle = style,
        styleName = state.styleName,
        timeSinceLastUpdate = 0,
        castbarTicking = false,
    }

    state.memberStates[unit] = memberState

    frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    frame:RegisterUnitEvent("UNIT_MAXPOWER", unit)
    frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit)
    frame:RegisterUnitEvent("UNIT_MODEL_CHANGED", unit)
    frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
    frame:RegisterUnitEvent("UNIT_LEVEL", unit)
    frame:RegisterUnitEvent("UNIT_FACTION", unit)
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")

    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", unit)

    frame:SetScript("OnEvent", function(self, event, _eventUnit)
        if event == "UNIT_MAXHEALTH" then
            Base.UpdateHealthBar(memberState)
            Base.UpdateHealthText(memberState)
        elseif event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
            Base.UpdatePowerBar(memberState)
            Base.UpdatePowerText(memberState)
        elseif event == "UNIT_MODEL_CHANGED" then
            Base.UpdatePortrait(memberState)
        elseif event == "UNIT_NAME_UPDATE" then
            Base.UpdateNameText(memberState)
        elseif event == "UNIT_LEVEL" then
            Base.UpdateLevelText(memberState)
        elseif event == "UNIT_FACTION" then
            Base.UpdateHealthBar(memberState)
            Base.UpdateNameText(memberState)
        elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
            Base.UpdateStatusIndicators(memberState)
        elseif event:find("SPELLCAST") then
            Base.UpdateCastbar(memberState)
        end
    end)

    local UPDATE_INTERVAL = 0.1
    frame:SetScript("OnUpdate", function(self, elapsed)
        if not NivUI:IsRealTimeUpdates("boss") then
            memberState.timeSinceLastUpdate = memberState.timeSinceLastUpdate + elapsed
            if memberState.timeSinceLastUpdate < UPDATE_INTERVAL then return end
            memberState.timeSinceLastUpdate = 0
        end

        Base.UpdateHealthBar(memberState)
        Base.UpdateHealthText(memberState)
        Base.UpdatePowerBar(memberState)
        Base.UpdatePowerText(memberState)
        Base.UpdateCastbar(memberState)
    end)

    return frame
end

local function DestroyMemberFrame(unit)
    local frame = state.memberFrames[unit]
    if frame then
        frame:UnregisterAllEvents()
        frame:SetScript("OnUpdate", nil)
        frame:SetScript("OnEvent", nil)
        frame:Hide()
        frame:SetParent(nil)
    end
    state.memberFrames[unit] = nil
    state.memberStates[unit] = nil
end

local function BuildBossFrames()
    for unit in pairs(state.memberFrames) do
        DestroyMemberFrame(unit)
    end

    state.styleName = NivUI:GetAssignment("boss")

    if not state.container then
        state.container = CreateFrame("Frame", "NivUI_BossContainer", UIParent)
        state.container:SetSize(200, 300)  -- Will be resized by layout

        local positionApplied = NivUI.EditMode and NivUI.EditMode:ApplyPosition("boss", state.container)
        if not positionApplied then
            state.container:SetPoint("RIGHT", UIParent, "RIGHT", -100, 0)
        end

        if NivUI.EditMode then
            NivUI.EditMode:CreateSelectionFrame("boss", state.container)
            if NivUI.EditMode:IsActive() then
                NivUI.EditMode:ShowSelection("boss")
            end
        end
    end

    local units = GetBossUnits()
    for _, unit in ipairs(units) do
        local frame = CreateMemberFrame(unit)
        if frame then
            state.memberFrames[unit] = frame
        end
    end

    LayoutMemberFrames()
    UpdateAllMemberFrames()
end

function UpdateAllMemberFrames()
    for unit, memberState in pairs(state.memberStates) do
        if state.memberFrames[unit] and state.memberFrames[unit]:IsShown() then
            Base.UpdateAllWidgets(memberState)
        end
    end
end

local function DestroyBossFrames()
    for unit in pairs(state.memberFrames) do
        DestroyMemberFrame(unit)
    end

    if state.container then
        state.container:Hide()
        state.container:SetParent(nil)
        state.container = nil
    end
end

local function OnInstanceEncounterEngageUnit()
    if not state.enabled then return end

    if ShouldShowBossFrames() then
        if state.container then
            state.container:Show()
        end
        LayoutMemberFrames()
        UpdateAllMemberFrames()
    else
        if state.container then
            state.container:Hide()
        end
    end
end

local function HideBlizzardBossFrames()
    if InCombatLockdown and InCombatLockdown() then
        state.pendingHide = true
        return
    end

    state.pendingHide = false

    if BossTargetFrameContainer then
        BossTargetFrameContainer:UnregisterAllEvents()
        BossTargetFrameContainer:Hide()
        BossTargetFrameContainer:SetScript("OnShow", function(self) self:Hide() end)
    end

    for i = 1, MAX_BOSS_FRAMES do
        local frame = _G["Boss" .. i .. "TargetFrame"]
        if frame then
            Base.KillVisual(frame)
        end
    end

    state.blizzardHidden = true
end

local BossFrame = {}
NivUI.UnitFrames.BossFrame = BossFrame

function BossFrame.Enable()
    state.enabled = true
    BuildBossFrames()
    HideBlizzardBossFrames()

    if ShouldShowBossFrames() then
        state.container:Show()
    else
        state.container:Hide()
    end
end

function BossFrame.Disable()
    state.enabled = false
    DestroyBossFrames()
    ReloadUI()
end

function BossFrame.Refresh()
    if state.enabled then
        BuildBossFrames()
        if ShouldShowBossFrames() then
            state.container:Show()
        else
            state.container:Hide()
        end
    end
end

function BossFrame.SetPreviewMode(enabled)
    state.previewMode = enabled
    if state.enabled then
        LayoutMemberFrames()
        UpdateAllMemberFrames()

        if enabled then
            state.container:Show()
        elseif not ShouldShowBossFrames() then
            state.container:Hide()
        end
    end
end

function BossFrame.GetState()
    return state
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
eventFrame:RegisterEvent("UNIT_TARGETABLE_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if NivUI:IsFrameEnabled("boss") then
            BossFrame.Enable()
        end
    elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT"
        or event == "UNIT_TARGETABLE_CHANGED"
        or event == "ENCOUNTER_START"
        or event == "ENCOUNTER_END"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA" then
        OnInstanceEncounterEngageUnit()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if state.pendingHide then
            HideBlizzardBossFrames()
        end
    end
end)

NivUI:RegisterCallback("FrameEnabledChanged", function(data)
    if data.frameType == "boss" then
        if data.enabled then
            BossFrame.Enable()
        else
            BossFrame.Disable()
        end
    end
end)

NivUI:RegisterCallback("AssignmentChanged", function(data)
    if data.frameType == "boss" and NivUI:IsFrameEnabled("boss") then
        BossFrame.Refresh()
    end
end)

NivUI:RegisterCallback("StyleChanged", function(data)
    if NivUI:IsFrameEnabled("boss") then
        local assignedStyle = NivUI:GetAssignment("boss")
        if data.styleName == assignedStyle then
            BossFrame.Refresh()
        end
    end
end)

NivUI:RegisterCallback("BossSettingsChanged", function(_data)
    if state.enabled then
        LayoutMemberFrames()
    end
end)

NivUI:RegisterCallback("BossPreviewChanged", function(data)
    BossFrame.SetPreviewMode(data.enabled)
end)
