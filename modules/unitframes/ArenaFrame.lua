NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local MAX_ARENA_FRAMES = 5

local UpdateAllMemberFrames

local state = {
    enabled = false,
    previewMode = false,
    container = nil,
    memberFrames = {},  -- Keyed by unit ID: "arena1", "arena2", etc.
    memberStates = {},  -- State objects for each member frame
    styleName = nil,
}

local function GetArenaUnits()
    local units = {}
    for i = 1, MAX_ARENA_FRAMES do
        table.insert(units, "arena" .. i)
    end
    return units
end

local function ShouldShowArenaFrames()
    if state.previewMode then
        return true
    end

    -- Show if any arena opponent exists
    for i = 1, MAX_ARENA_FRAMES do
        if UnitExists("arena" .. i) then
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

    local orientation = NivUI:GetArenaOrientation()
    local growth = NivUI:GetArenaGrowthDirection()
    local spacing = NivUI:GetArenaSpacing()
    local units = GetArenaUnits()

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

local function ClearFrameWidgets(frame)
    if frame.widgets then
        for _, widget in pairs(frame.widgets) do
            if widget.Hide then widget:Hide() end
            if widget.SetParent then widget:SetParent(nil) end
        end
        wipe(frame.widgets)
    end
    if frame.border then
        frame.border:Hide()
        frame.border:SetParent(nil)
        frame.border = nil
    end
end

local function CreateMemberFrame(unit)
    local style = NivUI:GetStyleWithDefaults(state.styleName)
    if not style then return nil end

    local frameConfig = style.frame or {}
    local frameWidth = frameConfig.width or 200
    local frameHeight = frameConfig.height or 60

    local frameName = "NivUI_ArenaFrame_" .. unit
    local frame = _G[frameName]
    local isNewFrame = not frame

    if isNewFrame then
        frame = CreateFrame("Button", frameName, state.container, "SecureUnitButtonTemplate")
    else
        ClearFrameWidgets(frame)
        frame:SetParent(state.container)
    end

    frame:SetSize(frameWidth, frameHeight)

    if frameConfig.strata then frame:SetFrameStrata(frameConfig.strata) end
    if frameConfig.frameLevel then frame:SetFrameLevel(frameConfig.frameLevel) end

    frame:SetAttribute("unit", unit)
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "focus")
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
        frameType = "arena",
        defaultName = "Arena",
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
        if not NivUI:IsRealTimeUpdates("arena") then
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

local function BuildArenaFrames()
    for unit in pairs(state.memberFrames) do
        DestroyMemberFrame(unit)
    end

    state.styleName = NivUI:GetAssignment("arena")

    if not state.container then
        state.container = CreateFrame("Frame", "NivUI_ArenaContainer", UIParent)
        state.container:SetSize(200, 300)

        local positionApplied = NivUI.EditMode and NivUI.EditMode:ApplyPosition("arena", state.container)
        if not positionApplied then
            state.container:SetPoint("RIGHT", UIParent, "RIGHT", -100, 100)
        end

        local visibilityOverride = NivUI:GetVisibilityOverride("arena")
        if visibilityOverride and visibilityOverride ~= "" then
            state.hasVisibilityDriver = true
            RegisterStateDriver(state.container, "visibility", visibilityOverride)
            NivUI.EditMode:RegisterVisibilityDriver("arena", state.container, visibilityOverride)
        end

        if NivUI.EditMode then
            NivUI.EditMode:CreateSelectionFrame("arena", state.container)
            if NivUI.EditMode:IsActive() then
                NivUI.EditMode:ShowSelection("arena")
            end
        end
    end

    local units = GetArenaUnits()
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

local function DestroyArenaFrames()
    for unit in pairs(state.memberFrames) do
        DestroyMemberFrame(unit)
    end

    if state.container then
        Base.SetSecureVisibility(state.container, false)
        state.container:SetParent(nil)
        state.container = nil
    end
end

local function OnArenaOpponentUpdate()
    if not state.enabled then return end

    if state.hasVisibilityDriver then
        LayoutMemberFrames()
        if state.container and state.container:IsShown() then
            UpdateAllMemberFrames()
        end
    elseif ShouldShowArenaFrames() then
        Base.SetSecureVisibility(state.container, true)
        LayoutMemberFrames()
        UpdateAllMemberFrames()
    else
        Base.SetSecureVisibility(state.container, false)
    end
end

local function HideBlizzardArenaFrames()
    if InCombatLockdown and InCombatLockdown() then
        state.pendingHide = true
        return
    end

    state.pendingHide = false

    if CompactArenaFrame then
        CompactArenaFrame:UnregisterAllEvents()
        CompactArenaFrame:Hide()
        CompactArenaFrame:SetScript("OnShow", function(self) self:Hide() end)
    end

    state.blizzardHidden = true
end

local ArenaFrame = {}
NivUI.UnitFrames.ArenaFrame = ArenaFrame

function ArenaFrame.Enable()
    state.enabled = true
    BuildArenaFrames()
    HideBlizzardArenaFrames()

    if not state.hasVisibilityDriver then
        Base.SetSecureVisibility(state.container, ShouldShowArenaFrames())
    end
end

function ArenaFrame.Disable()
    state.enabled = false
    DestroyArenaFrames()
    ReloadUI()
end

function ArenaFrame.Refresh()
    if state.enabled then
        BuildArenaFrames()
        if not state.hasVisibilityDriver then
            Base.SetSecureVisibility(state.container, ShouldShowArenaFrames())
        end
    end
end

function ArenaFrame.SetPreviewMode(enabled)
    state.previewMode = enabled
    if state.enabled then
        LayoutMemberFrames()
        UpdateAllMemberFrames()

        if not state.hasVisibilityDriver then
            Base.SetSecureVisibility(state.container, enabled or ShouldShowArenaFrames())
        end
    end
end

function ArenaFrame.GetState()
    return state
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")
eventFrame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
eventFrame:RegisterEvent("PVP_MATCH_STATE_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if NivUI:IsFrameEnabled("arena") then
            ArenaFrame.Enable()
        end
    elseif event == "ARENA_OPPONENT_UPDATE"
        or event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS"
        or event == "PVP_MATCH_STATE_CHANGED"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA" then
        OnArenaOpponentUpdate()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if state.pendingHide then
            HideBlizzardArenaFrames()
        end
    end
end)

NivUI:RegisterCallback("FrameEnabledChanged", function(data)
    if data.frameType == "arena" then
        if data.enabled then
            ArenaFrame.Enable()
        else
            ArenaFrame.Disable()
        end
    end
end)

NivUI:RegisterCallback("AssignmentChanged", function(data)
    if data.frameType == "arena" and NivUI:IsFrameEnabled("arena") then
        ArenaFrame.Refresh()
    end
end)

NivUI:RegisterCallback("StyleChanged", function(data)
    if NivUI:IsFrameEnabled("arena") then
        local assignedStyle = NivUI:GetAssignment("arena")
        if data.styleName == assignedStyle then
            ArenaFrame.Refresh()
        end
    end
end)

NivUI:RegisterCallback("ArenaSettingsChanged", function(_data)
    if state.enabled then
        LayoutMemberFrames()
    end
end)

NivUI:RegisterCallback("ArenaPreviewChanged", function(data)
    ArenaFrame.SetPreviewMode(data.enabled)
end)

NivUI:RegisterCallback("VisibilityOverrideChanged", function(data)
    if data.frameType == "arena" and state.enabled and state.container then
        if data.driver and data.driver ~= "" then
            state.hasVisibilityDriver = true
            RegisterStateDriver(state.container, "visibility", data.driver)
            NivUI.EditMode:RegisterVisibilityDriver("arena", state.container, data.driver)
        else
            state.hasVisibilityDriver = false
            UnregisterStateDriver(state.container, "visibility")
            NivUI.EditMode:UnregisterVisibilityDriver("arena")
            Base.SetSecureVisibility(state.container, ShouldShowArenaFrames())
        end
    end
end)
