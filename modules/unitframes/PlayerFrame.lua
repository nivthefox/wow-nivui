-- NivUI Unit Frames: Player Frame
-- Runtime player unit frame that replaces Blizzard's PlayerFrame

NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local PlayerFrameModule = {}
NivUI.UnitFrames.PlayerFrame = PlayerFrameModule

-- State
local customFrame = nil
local currentStyle = nil
local blizzardHidden = false
local pendingHide = false
local pendingRestore = false

-- Throttle interval for OnUpdate (health/power values are secret in combat, can't compare)
local UPDATE_INTERVAL = 0.1
local timeSinceLastUpdate = 0

-- Helpers from shared factories
local function SafeNumber(value, fallback)
    return NivUI.WidgetFactories.SafeNumber(value, fallback)
end

local function GetClassColor(unit)
    return NivUI.WidgetFactories.GetClassColor(unit)
end

local function GetPowerColor(unit)
    return NivUI.WidgetFactories.GetPowerColor(unit)
end

--------------------------------------------------------------------------------
-- Widget Update Functions
--------------------------------------------------------------------------------

local function UpdateHealthBar()
    if not customFrame or not customFrame.widgets.healthBar then return end
    local widget = customFrame.widgets.healthBar
    local config = currentStyle.healthBar

    local maxHealth = UnitHealthMax("player") or 1
    local health = UnitHealth("player")

    widget:SetMinMaxValues(0, maxHealth)
    widget:SetValue(health)

    local r, g, b = 0.2, 0.8, 0.2
    local bgR, bgG, bgB, bgA = config.backgroundColor.r, config.backgroundColor.g, config.backgroundColor.b, config.backgroundColor.a or 0.8

    if config.colorMode == "class" then
        r, g, b = GetClassColor("player")
    elseif config.colorMode == "class_inverted" then
        r, g, b = config.customColor.r, config.customColor.g, config.customColor.b
        bgR, bgG, bgB = GetClassColor("player")
    elseif config.colorMode == "custom" then
        r, g, b = config.customColor.r, config.customColor.g, config.customColor.b
    end

    widget.bg:SetVertexColor(bgR, bgG, bgB, bgA)
    widget:SetStatusBarColor(r, g, b)
end

local function UpdatePowerBar()
    if not customFrame or not customFrame.widgets.powerBar then return end
    local widget = customFrame.widgets.powerBar
    local config = currentStyle.powerBar

    local powerType = UnitPowerType("player")
    local maxPower = UnitPowerMax("player", powerType) or 1
    local power = UnitPower("player", powerType)

    widget:SetMinMaxValues(0, maxPower)
    widget:SetValue(power)

    local r, g, b = 0.2, 0.2, 0.8
    if config.colorMode == "power" then
        r, g, b = GetPowerColor("player")
    elseif config.colorMode == "class" then
        r, g, b = GetClassColor("player")
    elseif config.colorMode == "custom" then
        r, g, b = config.customColor.r, config.customColor.g, config.customColor.b
    end
    widget:SetStatusBarColor(r, g, b)
end

local function UpdateHealthText()
    if not customFrame or not customFrame.widgets.healthText then return end
    local widget = customFrame.widgets.healthText
    local config = currentStyle.healthText

    local health = UnitHealth("player")
    local maxHealth = UnitHealthMax("player")
    local pct = UnitHealthPercent and UnitHealthPercent("player") or nil

    local abbrev = AbbreviateLargeNumbers or AbbreviateNumbers or tostring
    local healthStr = abbrev(health)
    local maxHealthStr = abbrev(maxHealth)

    -- Use SetFormattedText for formats involving percent (handles secret values)
    if config.format == "percent" then
        if pct then
            widget.text:SetFormattedText("%.0f%%", pct)
        else
            widget.text:SetText(healthStr)
        end
    elseif config.format == "current_percent" then
        if pct then
            widget.text:SetFormattedText("%s (%.0f%%)", healthStr, pct)
        else
            widget.text:SetText(healthStr)
        end
    elseif config.format == "current" then
        widget.text:SetText(healthStr)
    elseif config.format == "current_max" then
        widget.text:SetText(healthStr .. " / " .. maxHealthStr)
    elseif config.format == "deficit" then
        local ok, deficit = pcall(function() return maxHealth - health end)
        if ok and deficit and deficit > 0 then
            widget.text:SetText("-" .. abbrev(deficit))
        else
            widget.text:SetText("")
        end
    end
end

local function UpdatePowerText()
    if not customFrame or not customFrame.widgets.powerText then return end
    local widget = customFrame.widgets.powerText
    local config = currentStyle.powerText

    local powerType = UnitPowerType("player")
    local power = UnitPower("player", powerType)
    local maxPower = UnitPowerMax("player", powerType)
    local pct = UnitPowerPercent and UnitPowerPercent("player", powerType) or nil

    local abbrev = AbbreviateLargeNumbers or AbbreviateNumbers or tostring
    local powerStr = abbrev(power)
    local maxPowerStr = abbrev(maxPower)

    -- Use SetFormattedText for formats involving percent (handles secret values)
    if config.format == "percent" then
        if pct then
            widget.text:SetFormattedText("%.0f%%", pct)
        else
            widget.text:SetText(powerStr)
        end
    elseif config.format == "current_percent" then
        if pct then
            widget.text:SetFormattedText("%s (%.0f%%)", powerStr, pct)
        else
            widget.text:SetText(powerStr)
        end
    elseif config.format == "current" then
        widget.text:SetText(powerStr)
    elseif config.format == "current_max" then
        widget.text:SetText(powerStr .. " / " .. maxPowerStr)
    end
end

local function UpdatePortrait()
    if not customFrame or not customFrame.widgets.portrait then return end
    local widget = customFrame.widgets.portrait
    local config = currentStyle.portrait

    if config.mode == "3D" then
        if widget.SetUnit then
            widget:SetUnit("player")
        end
    elseif config.mode == "2D" then
        if widget.texture then
            SetPortraitTexture(widget.texture, "player")
        end
    end
    -- Class icon doesn't need updating for player
end

local function UpdateStatusIndicators()
    if not customFrame or not customFrame.widgets.statusIndicators then return end
    local widget = customFrame.widgets.statusIndicators
    local config = currentStyle.statusIndicators

    if widget.combat then
        if config.showCombat and UnitAffectingCombat("player") then
            widget.combat:SetAlpha(1)
            widget.combat:Show()
        else
            widget.combat:Hide()
        end
    end
end

local castbarTicking = false

local function UpdateCastbar()
    if not customFrame or not customFrame.widgets.castbar then return end
    local widget = customFrame.widgets.castbar
    local config = currentStyle.castbar

    local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellID = UnitCastingInfo("player")

    if not name then
        name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible, spellID = UnitChannelInfo("player")
    end

    if name then
        local duration = (endTimeMS - startTimeMS) / 1000
        local elapsed = (GetTime() * 1000 - startTimeMS) / 1000
        local progress = elapsed / duration

        widget:SetMinMaxValues(0, 1)
        widget:SetValue(progress)

        if widget.spellName and config.showSpellName then
            widget.spellName:SetText(name)
        end

        if widget.icon and config.showIcon then
            widget.icon:SetTexture(texture)
        end

        if widget.timer and config.showTimer then
            local remaining = duration - elapsed
            widget.timer:SetText(string.format("%.1fs", remaining))
        end

        widget:Show()

        if not castbarTicking then
            castbarTicking = true
            widget:SetScript("OnUpdate", UpdateCastbar)
        end
    else
        widget:Hide()
        if castbarTicking then
            castbarTicking = false
            widget:SetScript("OnUpdate", nil)
        end
    end
end

local function UpdateNameText()
    if not customFrame or not customFrame.widgets.nameText then return end
    local widget = customFrame.widgets.nameText
    local config = currentStyle.nameText

    local name = UnitName("player") or "Player"
    if config.truncateLength and #name > config.truncateLength then
        name = name:sub(1, config.truncateLength) .. "..."
    end
    widget.text:SetText(name)
end

local function UpdateLevelText()
    if not customFrame or not customFrame.widgets.levelText then return end
    local widget = customFrame.widgets.levelText
    local config = currentStyle.levelText

    local level = UnitLevel("player")
    local text = level == -1 and "??" or tostring(level)
    widget.text:SetText(text)

    if config.colorByDifficulty then
        local color = GetQuestDifficultyColor(level)
        if color then
            widget.text:SetTextColor(color.r, color.g, color.b)
        end
    end
end

--------------------------------------------------------------------------------
-- Blizzard Frame Management
--------------------------------------------------------------------------------

local function HideRegions(frame)
    if not frame then return end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region then
            region:SetAlpha(0)
            region:Hide()
        end
    end
end

local function KillVisual(frame)
    if not frame then return end
    if frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
    if frame.EnableMouse then frame:EnableMouse(false) end
    if frame.Hide then frame:Hide() end
    if frame.SetScript then
        frame:SetScript("OnShow", function(self) self:Hide() end)
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
    end
    if frame.SetAlpha then frame:SetAlpha(0) end
end

local function SoftHideBlizzardPlayerFrame()
    if not PlayerFrame then return end

    -- Don't touch protected UI while in combat; retry once we're out.
    if InCombatLockdown and InCombatLockdown() then
        pendingHide = true
        return
    end

    pendingHide = false

    -- Keep PlayerFrame alive as an anchor parent for third-party addons,
    -- but stop Blizzard logic + remove Blizzard visuals.
    if PlayerFrame.UnregisterAllEvents then
        PlayerFrame:UnregisterAllEvents()
    end
    if PlayerFrame.EnableMouse then
        PlayerFrame:EnableMouse(false)
    end
    if PlayerFrame.SetMouseClickEnabled then
        PlayerFrame:SetMouseClickEnabled(false)
    end
    if PlayerFrame.SetMouseMotionEnabled then
        PlayerFrame:SetMouseMotionEnabled(false)
    end

    -- Ensure the (now invisible) PlayerFrame cannot ever be a mouseover/click target.
    if PlayerFrame.SetHitRectInsets then
        PlayerFrame:SetHitRectInsets(10000, 10000, 10000, 10000)
    end

    -- Strip any regions on the root itself.
    HideRegions(PlayerFrame)

    -- Kill the known Blizzard visual containers on the PlayerFrame.
    KillVisual(PlayerFrame.PlayerFrameContainer)
    KillVisual(PlayerFrame.PlayerFrameContent)
    KillVisual(PlayerFrame.healthbar)
    KillVisual(PlayerFrame.manabar)
    KillVisual(PlayerFrame.powerBarAlt)

    -- Kill child frames that start with "PlayerFrame"
    local children = { PlayerFrame:GetChildren() }
    for _, child in ipairs(children) do
        local name = child:GetName()
        if name and name:find("^PlayerFrame") then
            KillVisual(child)
        end
    end

    blizzardHidden = true

    -- Hook OnShow to re-hide if something tries to show it
    if not PlayerFrame.NivUI_SoftHideHooked then
        PlayerFrame.NivUI_SoftHideHooked = true
        PlayerFrame:HookScript("OnShow", function()
            if blizzardHidden then
                SoftHideBlizzardPlayerFrame()
            end
        end)
    end
end

local function RestoreBlizzardPlayerFrame()
    if not PlayerFrame then return end

    -- Don't touch protected UI while in combat; retry once we're out.
    if InCombatLockdown and InCombatLockdown() then
        pendingRestore = true
        return
    end

    pendingRestore = false
    blizzardHidden = false

    -- Re-enable mouse interaction
    if PlayerFrame.EnableMouse then
        PlayerFrame:EnableMouse(true)
    end
    if PlayerFrame.SetMouseClickEnabled then
        PlayerFrame:SetMouseClickEnabled(true)
    end
    if PlayerFrame.SetMouseMotionEnabled then
        PlayerFrame:SetMouseMotionEnabled(true)
    end
    if PlayerFrame.SetHitRectInsets then
        PlayerFrame:SetHitRectInsets(0, 0, 0, 0)
    end

    -- Restore alpha on regions
    local regions = { PlayerFrame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.SetAlpha then
            region:SetAlpha(1)
            region:Show()
        end
    end

    -- Show visual containers
    local function RestoreVisual(frame)
        if not frame then return end
        if frame.SetAlpha then frame:SetAlpha(1) end
        if frame.Show then frame:Show() end
        if frame.SetScript then
            frame:SetScript("OnShow", nil)
        end
    end

    RestoreVisual(PlayerFrame.PlayerFrameContainer)
    RestoreVisual(PlayerFrame.PlayerFrameContent)
    RestoreVisual(PlayerFrame.healthbar)
    RestoreVisual(PlayerFrame.manabar)

    -- Re-register events by calling Blizzard's initialization
    if PlayerFrame_ToPlayerArt then
        PlayerFrame_ToPlayerArt(PlayerFrame)
    end

    -- Show children
    local children = { PlayerFrame:GetChildren() }
    for _, child in ipairs(children) do
        local name = child:GetName()
        if name and name:find("^PlayerFrame") then
            RestoreVisual(child)
        end
    end
end

--------------------------------------------------------------------------------
-- Custom Frame Creation
--------------------------------------------------------------------------------

local function DestroyCustomFrame()
    if customFrame then
        customFrame:UnregisterAllEvents()
        customFrame:SetScript("OnUpdate", nil)
        customFrame:Hide()
        customFrame:SetParent(nil)
        customFrame = nil
    end
    currentStyle = nil
    timeSinceLastUpdate = 0
end

local function BuildCustomFrame(styleName)
    DestroyCustomFrame()

    local style = NivUI:GetStyleWithDefaults(styleName)
    if not style then
        print("NivUI PlayerFrame: No style found for", styleName)
        return
    end

    currentStyle = style

    local WF = NivUI.WidgetFactories
    if not WF then
        print("NivUI PlayerFrame: Widget factories not loaded")
        return
    end

    -- Create container frame
    local frameConfig = style.frame or {}
    local frameWidth = frameConfig.width or 200
    local frameHeight = frameConfig.height or 60

    customFrame = CreateFrame("Frame", "NivUI_PlayerFrame", UIParent)
    customFrame:SetSize(frameWidth, frameHeight)
    if frameConfig.strata then customFrame:SetFrameStrata(frameConfig.strata) end
    if frameConfig.frameLevel then customFrame:SetFrameLevel(frameConfig.frameLevel) end

    -- Anchor TOPLEFT to Blizzard PlayerFrame's TOPLEFT
    customFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 0, 0)

    -- Apply frame border if configured
    if frameConfig.showBorder then
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

    -- Store widgets for later reference
    customFrame.widgets = {}

    -- Pass 1: Create all enabled widgets
    for _, widgetType in ipairs(NivUI.UnitFrames.WIDGET_ORDER) do
        if widgetType ~= "frame" then
            local config = style[widgetType]
            if config and config.enabled and WF[widgetType] then
                local success, widget = pcall(WF[widgetType], customFrame, config, style, "player")
                if success and widget then
                    customFrame.widgets[widgetType] = widget
                elseif not success then
                    print("NivUI PlayerFrame: Error creating", widgetType, "-", widget)
                end
            end
        end
    end

    -- Pass 2: Apply anchors
    for widgetType, widget in pairs(customFrame.widgets) do
        local config = style[widgetType]
        local anchor = config and config.anchor
        if anchor then
            widget:ClearAllPoints()

            local anchorTarget
            if anchor.relativeTo == "frame" or anchor.relativeTo == nil then
                anchorTarget = customFrame
            else
                anchorTarget = customFrame.widgets[anchor.relativeTo]
                if not anchorTarget then
                    anchorTarget = customFrame
                end
            end

            widget:SetPoint(anchor.point, anchorTarget, anchor.relativePoint or anchor.point, anchor.x or 0, anchor.y or 0)
        else
            widget:SetPoint("CENTER", customFrame, "CENTER", 0, 0)
        end
    end

    -- Register for unit events (health/power polled via OnUpdate, but max values via events)
    customFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
    customFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")
    customFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
    customFrame:RegisterUnitEvent("UNIT_MODEL_CHANGED", "player")
    customFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", "player")
    customFrame:RegisterUnitEvent("UNIT_LEVEL", "player")
    customFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    customFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

    -- Castbar events
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "player")

    customFrame:SetScript("OnEvent", function(self, event, unit)
        if event == "UNIT_MAXHEALTH" then
            UpdateHealthBar()
            UpdateHealthText()
        elseif event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
            UpdatePowerBar()
            UpdatePowerText()
        elseif event == "UNIT_MODEL_CHANGED" then
            UpdatePortrait()
        elseif event == "UNIT_NAME_UPDATE" then
            UpdateNameText()
        elseif event == "UNIT_LEVEL" then
            UpdateLevelText()
        elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
            UpdateStatusIndicators()
        elseif event:find("SPELLCAST") then
            UpdateCastbar()
        end
    end)

    -- Updates via OnUpdate (throttled by default, real-time if configured)
    -- Health/power values are secret in combat and can't be compared for change detection
    customFrame:SetScript("OnUpdate", function(self, elapsed)
        if not NivUI:IsRealTimeUpdates("player") then
            timeSinceLastUpdate = timeSinceLastUpdate + elapsed
            if timeSinceLastUpdate < UPDATE_INTERVAL then return end
            timeSinceLastUpdate = 0
        end

        UpdateHealthBar()
        UpdateHealthText()
        UpdatePowerBar()
        UpdatePowerText()
    end)

    customFrame:Show()

    -- Initial update of all widgets
    UpdateHealthBar()
    UpdateHealthText()
    UpdatePowerBar()
    UpdatePowerText()
    UpdateStatusIndicators()
    UpdateCastbar()  -- Hide if not casting
end

--------------------------------------------------------------------------------
-- Enable/Disable Logic
--------------------------------------------------------------------------------

local function EnablePlayerFrame()
    local styleName = NivUI:GetAssignment("player")
    BuildCustomFrame(styleName)
    SoftHideBlizzardPlayerFrame()
end

local function DisablePlayerFrame()
    DestroyCustomFrame()
    RestoreBlizzardPlayerFrame()
end

local function RefreshPlayerFrame()
    if NivUI:IsFrameEnabled("player") then
        EnablePlayerFrame()
    end
end

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Check if player frame should be enabled on login
        if NivUI:IsFrameEnabled("player") then
            EnablePlayerFrame()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Handle pending operations after combat
        if pendingHide then
            SoftHideBlizzardPlayerFrame()
        end
        if pendingRestore then
            RestoreBlizzardPlayerFrame()
        end
    end
end)

-- Listen for enabled state changes
NivUI:RegisterCallback("FrameEnabledChanged", function(data)
    if data.frameType == "player" then
        if data.enabled then
            EnablePlayerFrame()
        else
            DisablePlayerFrame()
        end
    end
end)

-- Listen for style assignment changes
NivUI:RegisterCallback("AssignmentChanged", function(data)
    if data.frameType == "player" and NivUI:IsFrameEnabled("player") then
        RefreshPlayerFrame()
    end
end)

-- Listen for style changes (in case the assigned style is modified)
NivUI:RegisterCallback("StyleChanged", function(data)
    if NivUI:IsFrameEnabled("player") then
        local assignedStyle = NivUI:GetAssignment("player")
        if data.styleName == assignedStyle then
            RefreshPlayerFrame()
        end
    end
end)
