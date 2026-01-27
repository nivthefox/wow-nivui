NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local MultiUnitFrameBase = {}
NivUI.UnitFrames.MultiUnitFrameBase = MultiUnitFrameBase

local Base = NivUI.UnitFrames.Base

--- Creates a multi-unit frame module from configuration.
---@param config table Module configuration
---@return table module The created module with Enable, Disable, Refresh, SetPreviewMode, GetState methods
function MultiUnitFrameBase.CreateModule(config)
    local state = {
        enabled = false,
        previewMode = false,
        container = nil,
        memberFrames = {},
        memberStates = {},
        styleName = nil,
        hasVisibilityDriver = false,
        blizzardHidden = false,
        pendingHide = false,
    }

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

    local function UpdateAllMemberFrames()
        for unit, memberState in pairs(state.memberStates) do
            if state.memberFrames[unit] and state.memberFrames[unit]:IsShown() then
                Base.UpdateAllWidgets(memberState)
            end
        end
    end

    local function LayoutMemberFrames()
        if not state.container then return end

        local orientation = config.getOrientation()
        local growth = config.getGrowthDirection()
        local spacing = config.getSpacing()
        local units = config.getUnits()

        local style = NivUI:GetStyleWithDefaults(state.styleName)
        local frameWidth = style.frame.width or 200
        local frameHeight = style.frame.height or 60

        local xOffset, yOffset = 0, 0
        local xStep, yStep = 0, 0

        if orientation == "VERTICAL" then
            if growth == "DOWN" then
                yStep = -(frameHeight + spacing)
            else
                yStep = frameHeight + spacing
            end
        else
            if growth == "RIGHT" then
                xStep = frameWidth + spacing
            else
                xStep = -(frameWidth + spacing)
            end
        end

        local visibleIndex = 0

        if config.memberVisibilityMode == "state_driver" then
            for _, unit in ipairs(units) do
                local frame = state.memberFrames[unit]
                if frame and frame:IsShown() then
                    frame:ClearAllPoints()
                    frame:SetPoint("TOPLEFT", state.container, "TOPLEFT", xOffset, yOffset)

                    visibleIndex = visibleIndex + 1
                    xOffset = xOffset + xStep
                    yOffset = yOffset + yStep
                end
            end
        else
            for _, unit in ipairs(units) do
                local frame = state.memberFrames[unit]
                if frame then
                    local shouldShow = config.shouldShowUnit and config.shouldShowUnit(state, unit)
                    if shouldShow then
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

        local frameName = config.frameNamePrefix .. unit
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
        frame:SetAttribute("type2", config.type2Attribute or "togglemenu")
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

        if config.memberVisibilityMode == "state_driver" then
            local visibilityDriver = ("[@%s,exists] show; hide"):format(unit)
            RegisterStateDriver(frame, "visibility", visibilityDriver)
            frame._visibilityDriver = visibilityDriver
        end

        local defaultName
        if type(config.defaultName) == "function" then
            defaultName = config.defaultName(unit)
        else
            defaultName = config.defaultName or "Unit"
        end

        local memberState = {
            unit = unit,
            frameType = config.frameType,
            defaultName = defaultName,
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
        frame:RegisterUnitEvent("UNIT_FLAGS", unit)
        frame:RegisterUnitEvent("UNIT_CONNECTION", unit)

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
            elseif event == "UNIT_FLAGS" or event == "UNIT_CONNECTION" then
                Base.UpdateStatusText(memberState)
            elseif event:find("SPELLCAST") then
                Base.UpdateCastbar(memberState)
            end
        end)

        frame:SetScript("OnUpdate", function(self, elapsed)
            if not NivUI:IsRealTimeUpdates(config.frameType) then
                memberState.timeSinceLastUpdate = memberState.timeSinceLastUpdate + elapsed
                if memberState.timeSinceLastUpdate < NivUI.UPDATE_INTERVAL then return end
                memberState.timeSinceLastUpdate = 0
            end

            Base.UpdateHealthBar(memberState)
            Base.UpdateHealthText(memberState)
            Base.UpdatePowerBar(memberState)
            Base.UpdatePowerText(memberState)
            Base.UpdateStatusText(memberState)
            Base.UpdateCastbar(memberState)
            Base.UpdateRangeAlpha(memberState)
        end)

        return frame
    end

    local function BuildFrames()
        for unit in pairs(state.memberFrames) do
            DestroyMemberFrame(unit)
        end

        state.styleName = NivUI:GetAssignment(config.frameType)

        if not state.container then
            state.container = CreateFrame("Frame", config.containerName, UIParent)
            state.container:SetSize(200, 300)

            local positionApplied = NivUI.EditMode and NivUI.EditMode:ApplyPosition(config.frameType, state.container)
            if not positionApplied then
                local pos = config.defaultContainerPosition
                state.container:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
            end

            local visibilityOverride = NivUI:GetVisibilityOverride(config.frameType)
            if visibilityOverride and visibilityOverride ~= "" then
                state.hasVisibilityDriver = true
                RegisterStateDriver(state.container, "visibility", visibilityOverride)
                NivUI.EditMode:RegisterVisibilityDriver(config.frameType, state.container, visibilityOverride)
            end

            if NivUI.EditMode then
                NivUI.EditMode:CreateSelectionFrame(config.frameType, state.container)
                if NivUI.EditMode:IsActive() then
                    NivUI.EditMode:ShowSelection(config.frameType)
                end
            end
        end

        local units = config.getUnits()
        for _, unit in ipairs(units) do
            local frame = CreateMemberFrame(unit)
            if frame then
                state.memberFrames[unit] = frame
            end
        end

        LayoutMemberFrames()
        UpdateAllMemberFrames()
    end

    local function DestroyFrames()
        for unit in pairs(state.memberFrames) do
            DestroyMemberFrame(unit)
        end

        if state.container then
            Base.SetSecureVisibility(state.container, false)
            state.container:SetParent(nil)
            state.container = nil
        end
    end

    local function OnContainerEventTriggered()
        if not state.enabled then return end

        if config.memberVisibilityMode == "manual" then
            if state.hasVisibilityDriver then
                LayoutMemberFrames()
                UpdateAllMemberFrames()
            elseif config.shouldShowContainer and config.shouldShowContainer(state) then
                Base.SetSecureVisibility(state.container, true)
                LayoutMemberFrames()
                UpdateAllMemberFrames()
            else
                Base.SetSecureVisibility(state.container, false)
            end
        else
            LayoutMemberFrames()
            UpdateAllMemberFrames()
        end
    end

    local module = {}

    function module.Enable()
        state.enabled = true
        BuildFrames()
        config.hideBlizzardFrames(state)

        if config.memberVisibilityMode == "manual" and not state.hasVisibilityDriver then
            local shouldShow = config.shouldShowContainer and config.shouldShowContainer(state)
            Base.SetSecureVisibility(state.container, shouldShow)
        end
    end

    function module.Disable()
        state.enabled = false
        DestroyFrames()
        NivUI:RequestReload()
    end

    function module.Refresh()
        if state.enabled then
            BuildFrames()
            if config.memberVisibilityMode == "manual" and not state.hasVisibilityDriver then
                local shouldShow = config.shouldShowContainer and config.shouldShowContainer(state)
                Base.SetSecureVisibility(state.container, shouldShow)
            end
        end
    end

    function module.SetPreviewMode(enabled)
        state.previewMode = enabled
        if state.enabled then
            if config.memberVisibilityMode == "state_driver" then
                for _, frame in pairs(state.memberFrames) do
                    if enabled then
                        RegisterStateDriver(frame, "visibility", "show")
                    else
                        RegisterStateDriver(frame, "visibility", frame._visibilityDriver)
                    end
                end
            end

            LayoutMemberFrames()
            UpdateAllMemberFrames()

            if config.memberVisibilityMode == "manual" and not state.hasVisibilityDriver then
                local shouldShow = enabled or (config.shouldShowContainer and config.shouldShowContainer(state))
                Base.SetSecureVisibility(state.container, shouldShow)
            end
        end
    end

    function module.GetState()
        return state
    end

    module.LayoutMemberFrames = LayoutMemberFrames
    module.UpdateAllMemberFrames = UpdateAllMemberFrames

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

    if config.events then
        for _, event in ipairs(config.events) do
            eventFrame:RegisterEvent(event)
        end
    end

    eventFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_LOGIN" then
            if NivUI:IsFrameEnabled(config.frameType) then
                module.Enable()
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            if state.pendingHide then
                config.hideBlizzardFrames(state)
            end
        else
            if config.onContainerEvent then
                config.onContainerEvent(state, event, ...)
            else
                OnContainerEventTriggered()
            end
        end
    end)

    NivUI:RegisterCallback("FrameEnabledChanged", function(data)
        if data.frameType == config.frameType then
            if data.enabled then
                module.Enable()
            else
                module.Disable()
            end
        end
    end)

    NivUI:RegisterCallback("AssignmentChanged", function(data)
        if data.frameType == config.frameType and NivUI:IsFrameEnabled(config.frameType) then
            module.Refresh()
        end
    end)

    NivUI:RegisterCallback("StyleChanged", function(data)
        if NivUI:IsFrameEnabled(config.frameType) then
            local assignedStyle = NivUI:GetAssignment(config.frameType)
            if data.styleName == assignedStyle then
                module.Refresh()
            end
        end
    end)

    NivUI:RegisterCallback("VisibilityOverrideChanged", function(data)
        if data.frameType == config.frameType and state.enabled and state.container then
            if data.driver and data.driver ~= "" then
                state.hasVisibilityDriver = true
                if not NivUI.EditMode:IsActive() then
                    RegisterStateDriver(state.container, "visibility", data.driver)
                end
                NivUI.EditMode:RegisterVisibilityDriver(config.frameType, state.container, data.driver)
            else
                state.hasVisibilityDriver = false
                if not NivUI.EditMode:IsActive() then
                    UnregisterStateDriver(state.container, "visibility")
                end
                NivUI.EditMode:UnregisterVisibilityDriver(config.frameType)
                if config.memberVisibilityMode == "manual" and config.shouldShowContainer then
                    Base.SetSecureVisibility(state.container, config.shouldShowContainer(state))
                end
            end
        end
    end)

    NivUI:RegisterCallback(config.settingsChangedCallback, function(data)
        if state.enabled then
            if config.onSettingsChanged then
                config.onSettingsChanged(state, data)
            else
                LayoutMemberFrames()
            end
        end
    end)

    NivUI:RegisterCallback(config.previewChangedCallback, function(data)
        module.SetPreviewMode(data.enabled)
    end)

    return module
end
