NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local UpdateAllMemberFrames

local state = {
    enabled = false,
    previewMode = false,
    container = nil,
    memberFrames = {},  -- Keyed by unit ID: "player", "party1", etc.
    memberStates = {},  -- State objects for each member frame
    styleName = nil,
}

local function GetPartyUnits()
    local units = {}
    local includePlayer = NivUI:DoesPartyIncludePlayer()

    if includePlayer then
        table.insert(units, "player")
    end

    for i = 1, 4 do
        table.insert(units, "party" .. i)
    end

    return units
end

local function ShouldShowPartyFrames()
    if state.previewMode then
        return true
    end

    if IsInRaid() then
        return false
    end

    local showWhenSolo = NivUI:DoesPartyShowWhenSolo()
    if showWhenSolo then
        return true
    end

    return IsInGroup()
end

local function ShouldShowUnit(unit)
    if state.previewMode then
        return true
    end

    if unit == "player" then
        return NivUI:DoesPartyIncludePlayer() and ShouldShowPartyFrames()
    end

    return UnitExists(unit)
end

local function LayoutMemberFrames()
    if not state.container then return end

    local orientation = NivUI:GetPartyOrientation()
    local growth = NivUI:GetPartyGrowthDirection()
    local spacing = NivUI:GetPartySpacing()
    local units = GetPartyUnits()

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

    local frameName = "NivUI_PartyFrame_" .. unit
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
        frameType = "party",
        defaultName = unit == "player" and UnitName("player") or "Party Member",
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
        if not NivUI:IsRealTimeUpdates("party") then
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

local function BuildPartyFrames()
    for unit in pairs(state.memberFrames) do
        DestroyMemberFrame(unit)
    end

    state.styleName = NivUI:GetAssignment("party")

    if not state.container then
        state.container = CreateFrame("Frame", "NivUI_PartyContainer", UIParent)
        state.container:SetSize(200, 300)  -- Will be resized by layout

        local positionApplied = NivUI.EditMode and NivUI.EditMode:ApplyPosition("party", state.container)
        if not positionApplied then
            state.container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 20, -200)
        end

        if NivUI.EditMode then
            NivUI.EditMode:CreateSelectionFrame("party", state.container)
            if NivUI.EditMode:IsActive() then
                NivUI.EditMode:ShowSelection("party")
            end
        end
    end

    local units = GetPartyUnits()
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

local function DestroyPartyFrames()
    for unit in pairs(state.memberFrames) do
        DestroyMemberFrame(unit)
    end

    if state.container then
        state.container:Hide()
        state.container:SetParent(nil)
        state.container = nil
    end
end

local function OnGroupRosterUpdate()
    if not state.enabled then return end

    if ShouldShowPartyFrames() then
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

local function HideBlizzardPartyFrames()
    if InCombatLockdown and InCombatLockdown() then
        state.pendingHide = true
        return
    end

    state.pendingHide = false

    if CompactPartyFrame then
        CompactPartyFrame:UnregisterAllEvents()
        CompactPartyFrame:Hide()
        CompactPartyFrame:SetScript("OnShow", function(self) self:Hide() end)
    end

    for i = 1, 4 do
        local frame = _G["PartyMemberFrame" .. i]
        if frame then
            Base.KillVisual(frame)
        end
    end

    state.blizzardHidden = true
end

local PartyFrame = {}
NivUI.UnitFrames.PartyFrame = PartyFrame

function PartyFrame.Enable()
    state.enabled = true
    BuildPartyFrames()
    HideBlizzardPartyFrames()

    if ShouldShowPartyFrames() then
        state.container:Show()
    else
        state.container:Hide()
    end
end

function PartyFrame.Disable()
    state.enabled = false
    DestroyPartyFrames()
    ReloadUI()
end

function PartyFrame.Refresh()
    if state.enabled then
        BuildPartyFrames()
        if ShouldShowPartyFrames() then
            state.container:Show()
        else
            state.container:Hide()
        end
    end
end

function PartyFrame.SetPreviewMode(enabled)
    state.previewMode = enabled
    if state.enabled then
        LayoutMemberFrames()
        UpdateAllMemberFrames()

        if enabled then
            state.container:Show()
        elseif not ShouldShowPartyFrames() then
            state.container:Hide()
        end
    end
end

function PartyFrame.GetState()
    return state
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if NivUI:IsFrameEnabled("party") then
            PartyFrame.Enable()
        end
    elseif event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA" then
        OnGroupRosterUpdate()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if state.pendingHide then
            HideBlizzardPartyFrames()
        end
    end
end)

NivUI:RegisterCallback("FrameEnabledChanged", function(data)
    if data.frameType == "party" then
        if data.enabled then
            PartyFrame.Enable()
        else
            PartyFrame.Disable()
        end
    end
end)

NivUI:RegisterCallback("AssignmentChanged", function(data)
    if data.frameType == "party" and NivUI:IsFrameEnabled("party") then
        PartyFrame.Refresh()
    end
end)

NivUI:RegisterCallback("StyleChanged", function(data)
    if NivUI:IsFrameEnabled("party") then
        local assignedStyle = NivUI:GetAssignment("party")
        if data.styleName == assignedStyle then
            PartyFrame.Refresh()
        end
    end
end)

NivUI:RegisterCallback("PartySettingsChanged", function(data)
    if state.enabled then
        if data.setting == "includePlayer" then
            -- Need to rebuild frames since player frame might be added/removed
            PartyFrame.Refresh()
        elseif data.setting == "spacing" or data.setting == "orientation" or data.setting == "growthDirection" then
            LayoutMemberFrames()
        elseif data.setting == "showWhenSolo" then
            if ShouldShowPartyFrames() then
                state.container:Show()
                LayoutMemberFrames()
                UpdateAllMemberFrames()
            else
                state.container:Hide()
            end
        end
    end
end)

NivUI:RegisterCallback("PartyPreviewChanged", function(data)
    PartyFrame.SetPreviewMode(data.enabled)
end)
