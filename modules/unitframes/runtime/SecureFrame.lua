local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Runtime = NivUI.UnitFrames.Runtime or {}

local SecureFrame = {}
NivUI.UnitFrames.Runtime.SecureFrame = SecureFrame
local Lifecycle = NivUI.UnitFrames.Lifecycle
local WidgetTree = NivUI.UnitFrames.Runtime.WidgetTree
local Facade

function SecureFrame.SetFacade(facade)
    Facade = facade
end
--- Creates reversible visibility controls for a Blizzard unit frame.
--- @param blizzardFrame Frame The Blizzard frame to hide
--- @return function hideFunction
--- @return function restoreFunction
function SecureFrame.CreateHideBlizzardFrame(blizzardFrame)
    local function HideBlizzardFrame(state)
        if not blizzardFrame then
            return
        end
        if InCombatLockdown and InCombatLockdown() then
            state.pendingHide = true
            return
        end

        state.pendingHide = false
        RegisterStateDriver(blizzardFrame, "visibility", "hide")
        state.blizzardHidden = true
    end

    local function RestoreBlizzardFrame(state)
        if not blizzardFrame then
            return
        end
        if InCombatLockdown and InCombatLockdown() then
            state.pendingRestore = true
            return
        end

        state.pendingRestore = false
        UnregisterStateDriver(blizzardFrame, "visibility")
        state.blizzardHidden = false
    end

    return HideBlizzardFrame, RestoreBlizzardFrame
end

--- Pending visibility changes to apply when combat ends.
--- @type table<Frame, boolean>
local pendingVisibility = {}

--- Helper frame for deferring secure calls until combat ends.
local combatDeferFrame = CreateFrame("Frame")
combatDeferFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatDeferFrame:SetScript("OnEvent", function()
    for frame, visible in pairs(pendingVisibility) do
        RegisterStateDriver(frame, "visibility", visible and "show" or "hide")
    end
    wipe(pendingVisibility)
end)

--- Sets secure visibility for a frame using a state driver.
--- Defers the call if currently in combat.
--- @param frame Frame|nil The frame to control visibility for
--- @param visible boolean Whether the frame should be visible
function SecureFrame.SetSecureVisibility(frame, visible)
    if not frame then return end
    if InCombatLockdown() then
        pendingVisibility[frame] = visible
        return
    end
    RegisterStateDriver(frame, "visibility", visible and "show" or "hide")
end

local function GetCustomFrame(state)
    local frameName = "NivUI_" .. state.frameType .. "Frame"
    local customFrame = _G[frameName]
    local isNewFrame = not customFrame
    if isNewFrame then
        customFrame = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate")
    else
        WidgetTree.ClearFrameWidgets(customFrame)
        customFrame:SetParent(UIParent)
    end
    return customFrame, isNewFrame
end

local function ConfigureCustomFrame(customFrame, state, frameConfig)
    customFrame:SetSize(frameConfig.width or 200, frameConfig.height or 60)
    if frameConfig.strata then
        customFrame:SetFrameStrata(frameConfig.strata)
    end
    if frameConfig.frameLevel then
        customFrame:SetFrameLevel(frameConfig.frameLevel)
    end

    customFrame:SetAttribute("unit", state.unit)
    customFrame:SetAttribute("type1", "target")
    customFrame:SetAttribute("type2", "togglemenu")
    customFrame:RegisterForClicks("AnyUp")

    customFrame:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetUnit(state.unit)
        GameTooltip:Show()
    end)
    customFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local function ApplyCustomFramePosition(customFrame, state)
    local positionApplied = NivUI.EditMode and NivUI.EditMode:ApplyPosition(state.frameType, customFrame)
    if positionApplied then
        return
    end

    local anchorFrame = state.anchorFrame
    if type(anchorFrame) == "function" then
        anchorFrame = anchorFrame()
    end
    if anchorFrame then
        customFrame:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", state.anchorOffsetX or 0, state.anchorOffsetY or 0)
        return
    end
    customFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

local function CreateCustomFrameBorder(customFrame, frameConfig)
    if not frameConfig.showBorder then
        return
    end

    customFrame.border = CreateFrame("Frame", nil, customFrame, "BackdropTemplate")
    customFrame.border:SetAllPoints()
    local borderSize = frameConfig.borderSize or 1
    local borderColor = frameConfig.borderColor or { r = 0, g = 0, b = 0, a = 1 }
    customFrame.border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = borderSize,
    })
    customFrame.border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
end

local VISIBILITY_EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA",
    "ENCOUNTER_START",
    "ENCOUNTER_END",
    "PLAYER_ALIVE",
    "PLAYER_DEAD",
    "PLAYER_UNGHOST",
    "GROUP_ROSTER_UPDATE",
    "PARTY_LEADER_CHANGED",
    "PLAYER_ROLES_ASSIGNED",
    "PLAYER_UPDATE_RESTING",
    "PLAYER_FLAGS_CHANGED",
}

local function HandleCustomFrameEvent(state, frame, event, eventUnit)
    Facade.HandleEvent(state, event)

    if event == "PLAYER_UPDATE_RESTING" then
        Facade.UpdateStatusIndicators(state)
    elseif event == "PLAYER_FLAGS_CHANGED" then
        Facade.UpdateStatusText(state)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" then
        Facade.UpdateLeaderIcon(state)
    elseif event == "PLAYER_ROLES_ASSIGNED" then
        Facade.UpdateRoleIcon(state)
    elseif event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA"
        or event == "ENCOUNTER_START"
        or event == "ENCOUNTER_END" then
        Facade.CheckVisibility(state)
    elseif event == "PLAYER_ALIVE"
        or event == "PLAYER_DEAD"
        or event == "PLAYER_UNGHOST" then
        Facade.CheckVisibility(state)
        Facade.UpdateStatusText(state)
    end

    if state.onEvent then
        state.onEvent(frame, event, eventUnit)
    end
end

local function UpdateCustomFrame(state, frame, elapsed)
    Facade.CheckVisibility(state)
    if not frame:IsShown() then
        return
    end

    if state.preUpdate then
        state.preUpdate(state, elapsed)
    end

    if not NivUI:IsRealTimeUpdates(state.frameType) then
        state.timeSinceLastUpdate = state.timeSinceLastUpdate + elapsed
        if state.timeSinceLastUpdate < NivUI.UPDATE_INTERVAL then
            return
        end
        state.timeSinceLastUpdate = 0
    end

    Facade.UpdateHealthBar(state)
    Facade.UpdateHealthText(state)
    Facade.UpdatePowerBar(state)
    Facade.UpdatePowerText(state)
    Facade.UpdateCastbar(state)
    Facade.UpdateRangeAlpha(state)
end

local function RegisterCustomFrameEvents(customFrame, state)
    Facade.RegisterStandardEvents(customFrame, state.unit)
    customFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    customFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

    if state.registerEvents then
        state.registerEvents(customFrame)
    end

    for _, event in ipairs(VISIBILITY_EVENTS) do
        customFrame:RegisterEvent(event)
    end

    customFrame:SetScript("OnEvent", function(frame, event, eventUnit)
        HandleCustomFrameEvent(state, frame, event, eventUnit)
    end)
end

local function ConfigureVisibilityDriver(customFrame, state)
    local visibilityDriver = NivUI:GetVisibilityOverride(state.frameType) or state.visibilityDriver
    state.effectiveVisibilityDriver = visibilityDriver
    if not visibilityDriver then
        return
    end

    RegisterStateDriver(customFrame, "visibility", visibilityDriver)
    if NivUI.EditMode then
        NivUI.EditMode:RegisterVisibilityDriver(state.frameType, customFrame, visibilityDriver)
    end
    customFrame:HookScript("OnShow", function()
        Facade.UpdateAllWidgets(state)
    end)
end

local function ConfigureCustomFrameUpdates(customFrame, state)
    state.timeSinceLastUpdate = 0
    customFrame:SetScript("OnUpdate", function(frame, elapsed)
        UpdateCustomFrame(state, frame, elapsed)
    end)
end

local function ConfigureEditMode(customFrame, state)
    if not NivUI.EditMode then
        return
    end

    NivUI.EditMode:CreateSelectionFrame(state.frameType, customFrame)
    if NivUI.EditMode:IsActive() then
        NivUI.EditMode:ShowSelection(state.frameType)
    end
end

local function ConfigureNewCustomFrame(customFrame, state)
    ConfigureVisibilityDriver(customFrame, state)
    RegisterCustomFrameEvents(customFrame, state)
    ConfigureCustomFrameUpdates(customFrame, state)
    ConfigureEditMode(customFrame, state)
end

--- Builds or rebuilds the custom unit frame for a module.
--- @param state table The unit frame state table
function SecureFrame.BuildCustomFrame(state)
    if type(state) ~= "table" then
        return false
    end

    local style = NivUI:GetStyleWithDefaults(state.styleName)
    if not style then
        print("NivUI " .. state.frameType .. ": No style found for", state.styleName)
        return false
    end

    state.currentStyle = style

    local frameConfig = style.frame or {}
    local customFrame, isNewFrame = GetCustomFrame(state)
    ConfigureCustomFrame(customFrame, state, frameConfig)
    ApplyCustomFramePosition(customFrame, state)
    CreateCustomFrameBorder(customFrame, frameConfig)

    customFrame.widgets = Facade.CreateWidgets(customFrame, style, state.unit, { frameType = state.frameType })
    Facade.ApplyAnchors(customFrame, customFrame.widgets, style)

    state.customFrame = customFrame

    if isNewFrame then
        ConfigureNewCustomFrame(customFrame, state)
    end

    Facade.CheckVisibility(state)
    return true
end

--- Checks and updates frame visibility based on visibility driver or shouldShow callback.
--- Queues visibility changes during combat lockdown.
--- @param state table The unit frame state table
function SecureFrame.CheckVisibility(state)
    if not state.customFrame then return end

    if state.effectiveVisibilityDriver then
        if state.customFrame:IsShown() then
            Facade.UpdateAllWidgets(state)
        end
        return
    end

    local shouldBeVisible = not state.shouldShow or state.shouldShow()

    if InCombatLockdown() then
        state.pendingVisibility = shouldBeVisible
        return
    end

    state.pendingVisibility = nil

    if shouldBeVisible then
        if not state.customFrame:IsShown() then
            state.customFrame:Show()
            Facade.UpdateAllWidgets(state)
        end
    else
        if state.customFrame:IsShown() then
            state.customFrame:Hide()
        end
    end
end

--- Applies any pending visibility changes that were queued during combat.
--- Should be called on PLAYER_REGEN_ENABLED.
--- @param state table The unit frame state table
function SecureFrame.ApplyPendingVisibility(state)
    if state.effectiveVisibilityDriver then return end
    if state.pendingVisibility == nil then return end
    if InCombatLockdown() then return end

    local shouldBeVisible = state.pendingVisibility
    state.pendingVisibility = nil

    if shouldBeVisible then
        if not state.customFrame:IsShown() then
            state.customFrame:Show()
            Facade.UpdateAllWidgets(state)
        end
    else
        if state.customFrame:IsShown() then
            state.customFrame:Hide()
        end
    end
end

--- Destroys a custom unit frame, cleaning up events and scripts.
--- @param state table The unit frame state table
function SecureFrame.DestroyCustomFrame(state)
    if state.customFrame then
        state.customFrame:UnregisterAllEvents()
        state.customFrame:SetScript("OnUpdate", nil)
        state.customFrame:Hide()
        state.customFrame:SetParent(nil)
        state.customFrame = nil
    end
    state.currentStyle = nil
    state.timeSinceLastUpdate = 0
    state.castbarTicking = false
end

--- Creates a new unit frame module with the given configuration.
--- Returns a module table with Enable, Disable, Refresh, and GetState functions.
--- @param config table Module configuration with unit, frameType, anchorFrame, etc.
--- @return table module The created module with Enable/Disable/Refresh/GetState functions
function SecureFrame.CreateModule(config)
    if type(config) ~= "table" then
        return nil
    end

    local state = {
        unit = config.unit,
        frameType = config.frameType,
        defaultName = config.defaultName or "Unit",
        anchorFrame = config.anchorFrame,
        anchorOffsetX = config.anchorOffsetX,
        anchorOffsetY = config.anchorOffsetY,
        customFrame = nil,
        currentStyle = nil,
        styleName = nil,
        blizzardHidden = false,
        pendingHide = false,
        timeSinceLastUpdate = 0,
        castbarTicking = false,
        shouldShow = config.shouldShow,
        visibilityDriver = config.visibilityDriver,
        registerEvents = config.registerEvents,
        onEvent = config.onEvent,
        preUpdate = config.preUpdate,
        hideBlizzard = config.hideBlizzard,
        restoreBlizzard = config.restoreBlizzard,
    }

    local module = {}

    function module.Enable()
        state.styleName = NivUI:GetAssignment(state.frameType)
        Facade.BuildCustomFrame(state)
        if state.hideBlizzard then
            state.hideBlizzard(state)
        end
    end

    function module.Disable()
        Facade.DestroyCustomFrame(state)
        if state.restoreBlizzard then
            state.restoreBlizzard(state)
        end
    end

    function module.Refresh()
        if NivUI:IsFrameEnabled(state.frameType) then
            module.Enable()
        end
    end

    function module.GetState()
        return state
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_LOGIN" then
            if NivUI:IsFrameEnabled(state.frameType) then
                module.Enable()
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            if state.pendingHide and state.hideBlizzard then
                state.hideBlizzard(state)
            end
            if state.pendingRestore and state.restoreBlizzard then
                state.restoreBlizzard(state)
            end
            Facade.ApplyPendingVisibility(state)
        end
    end)

    NivUI:RegisterProfileApplyCallback("unitFrame:" .. state.frameType, function()
        if NivUI:IsFrameEnabled(state.frameType) then
            module.Refresh()
            return
        end
        if state.customFrame then
            module.Disable()
        end
    end)

    Lifecycle.Register({
        isEnabled = function()
            return NivUI:IsFrameEnabled(state.frameType)
        end,
        refresh = function()
            module.Refresh()
        end,
        usesStyle = function(styleName)
            return NivUI:GetAssignment(state.frameType) == styleName
        end,
    })

    NivUI:RegisterCallback("FrameEnabledChanged", function(data)
        if data.frameType == state.frameType then
            if data.enabled then
                module.Enable()
            else
                module.Disable()
            end
        end
    end)

    NivUI:RegisterCallback("AssignmentChanged", function(data)
        if data.frameType == state.frameType and NivUI:IsFrameEnabled(state.frameType) then
            module.Refresh()
        end
    end)

    NivUI:RegisterCallback("VisibilityOverrideChanged", function(data)
        if data.frameType == state.frameType and NivUI:IsFrameEnabled(state.frameType) and state.customFrame then
            local newDriver = NivUI:GetVisibilityOverride(state.frameType) or state.visibilityDriver
            state.effectiveVisibilityDriver = newDriver
            if newDriver and not NivUI.EditMode:IsActive() then
                UnregisterStateDriver(state.customFrame, "visibility")
                RegisterStateDriver(state.customFrame, "visibility", newDriver)
            end
            NivUI.EditMode:RegisterVisibilityDriver(state.frameType, state.customFrame, newDriver)
        end
    end)

    return module
end
