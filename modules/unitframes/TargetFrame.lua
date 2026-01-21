NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local TargetFrameModule = {}
NivUI.UnitFrames.TargetFrame = TargetFrameModule

local customFrame = nil
local currentStyle = nil
local blizzardHidden = false
local pendingHide = false

local UPDATE_INTERVAL = 0.1
local timeSinceLastUpdate = 0

local function SafeNumber(value, fallback)
    return NivUI.WidgetFactories.SafeNumber(value, fallback)
end

local function GetClassColor(unit)
    return NivUI.WidgetFactories.GetClassColor(unit)
end

local function GetPowerColor(unit)
    return NivUI.WidgetFactories.GetPowerColor(unit)
end

local function UpdateHealthBar()
    if not customFrame or not customFrame.widgets.healthBar then return end
    local widget = customFrame.widgets.healthBar
    local config = currentStyle.healthBar

    local maxHealth = UnitHealthMax("target") or 1
    local health = UnitHealth("target")

    widget:SetMinMaxValues(0, maxHealth)
    widget:SetValue(health)

    local r, g, b, a = 0.2, 0.8, 0.2, 1
    local bgR, bgG, bgB, bgA = config.backgroundColor.r, config.backgroundColor.g, config.backgroundColor.b, config.backgroundColor.a or 0.8

    if config.colorMode == "class" then
        r, g, b = GetClassColor("target")
    elseif config.colorMode == "class_inverted" then
        r, g, b, a = config.customColor.r, config.customColor.g, config.customColor.b, config.customColor.a or 1
        bgR, bgG, bgB = GetClassColor("target")
    elseif config.colorMode == "custom" then
        r, g, b, a = config.customColor.r, config.customColor.g, config.customColor.b, config.customColor.a or 1
    elseif config.colorMode == "reaction" then
        local reaction = UnitReaction("target", "player")
        if reaction then
            local color = FACTION_BAR_COLORS[reaction]
            if color then
                r, g, b = color.r, color.g, color.b
            end
        end
    end

    widget.bg:SetVertexColor(bgR, bgG, bgB, bgA)
    widget:SetStatusBarColor(r, g, b, a)
end

local function UpdatePowerBar()
    if not customFrame or not customFrame.widgets.powerBar then return end
    local widget = customFrame.widgets.powerBar
    local config = currentStyle.powerBar

    local powerType = UnitPowerType("target")
    local maxPower = UnitPowerMax("target", powerType) or 1
    local power = UnitPower("target", powerType)

    widget:SetMinMaxValues(0, maxPower)
    widget:SetValue(power)

    local r, g, b, a = 0.2, 0.2, 0.8, 1
    if config.colorMode == "power" then
        r, g, b = GetPowerColor("target")
    elseif config.colorMode == "class" then
        r, g, b = GetClassColor("target")
    elseif config.colorMode == "custom" then
        r, g, b, a = config.customColor.r, config.customColor.g, config.customColor.b, config.customColor.a or 1
    end
    widget:SetStatusBarColor(r, g, b, a)
end

local function UpdateHealthText()
    if not customFrame or not customFrame.widgets.healthText then return end
    local widget = customFrame.widgets.healthText
    local config = currentStyle.healthText

    local health = UnitHealth("target")
    local maxHealth = UnitHealthMax("target")
    local pct = UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100
        and UnitHealthPercent("target", true, CurveConstants.ScaleTo100) or nil

    local abbrev = AbbreviateLargeNumbers or AbbreviateNumbers or tostring
    local healthStr = abbrev(health)
    local maxHealthStr = abbrev(maxHealth)

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

    local powerType = UnitPowerType("target")
    local power = UnitPower("target", powerType)
    local maxPower = UnitPowerMax("target", powerType)
    local pct = UnitPowerPercent and CurveConstants and CurveConstants.ScaleTo100
        and UnitPowerPercent("target", powerType, false, CurveConstants.ScaleTo100) or nil

    local abbrev = AbbreviateLargeNumbers or AbbreviateNumbers or tostring
    local powerStr = abbrev(power)
    local maxPowerStr = abbrev(maxPower)

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
            widget:SetUnit("target")
        end
    elseif config.mode == "2D" then
        if widget.texture then
            SetPortraitTexture(widget.texture, "target")
        end
    elseif config.mode == "class" then
        if widget.texture then
            local _, class = UnitClass("target")
            if class then
                local coords = CLASS_ICON_TCOORDS[class]
                if coords then
                    widget.texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                    widget.texture:SetTexCoord(unpack(coords))
                end
            end
        end
    end
end

local function UpdateStatusIndicators()
    if not customFrame or not customFrame.widgets.statusIndicators then return end
    local widget = customFrame.widgets.statusIndicators
    local config = currentStyle.statusIndicators

    if widget.combat then
        if config.showCombat and UnitAffectingCombat("target") then
            widget.combat:SetAlpha(1)
            widget.combat:Show()
        else
            widget.combat:Hide()
        end
    end
end

local function UpdateCastbar()
    if not customFrame or not customFrame.widgets.castbar then return end
    local widget = customFrame.widgets.castbar
    local config = currentStyle.castbar

    local duration = UnitCastingDuration("target")
    local isChanneling = false

    if not duration or duration:IsZero() then
        duration = UnitChannelDuration("target")
        isChanneling = true
    end

    if duration and not duration:IsZero() then
        local direction = isChanneling and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime
        widget:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, direction)

        local name = UnitCastingInfo("target")
        if not name then
            name = UnitChannelInfo("target")
        end

        if widget.spellName and config.showSpellName then
            widget.spellName:SetText(name or "")
        end

        if widget.timer and config.showTimer then
            widget.timer:SetFormattedText("%.1fs", duration:GetRemainingDuration())
        end

        local notInterruptible = select(8, UnitCastingInfo("target"))
        if notInterruptible == nil then
            notInterruptible = select(7, UnitChannelInfo("target"))
        end

        if notInterruptible then
            local color = config.nonInterruptibleColor
            widget:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
        else
            local color = config.castingColor
            widget:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
        end

        widget:Show()
    else
        widget:Hide()
    end
end

local function UpdateNameText()
    if not customFrame or not customFrame.widgets.nameText then return end
    local widget = customFrame.widgets.nameText
    local config = currentStyle.nameText

    local name = UnitName("target") or "Target"
    if config.truncateLength and #name > config.truncateLength then
        name = name:sub(1, config.truncateLength) .. "..."
    end
    widget.text:SetText(name)

    -- Update color in case class changed (new target)
    if config.colorByClass then
        local r, g, b = GetClassColor("target")
        widget.text:SetTextColor(r, g, b, config.customColor and config.customColor.a or 1)
    end
end

local function UpdateLevelText()
    if not customFrame or not customFrame.widgets.levelText then return end
    local widget = customFrame.widgets.levelText
    local config = currentStyle.levelText

    local level = UnitLevel("target")
    local text = level == -1 and "??" or tostring(level)
    widget.text:SetText(text)

    if config.colorByDifficulty then
        local color = GetCreatureDifficultyColor(level)
        if color then
            widget.text:SetTextColor(color.r, color.g, color.b)
        end
    end
end

local function UpdateAllWidgets()
    UpdateHealthBar()
    UpdateHealthText()
    UpdatePowerBar()
    UpdatePowerText()
    UpdatePortrait()
    UpdateNameText()
    UpdateLevelText()
    UpdateStatusIndicators()
    UpdateCastbar()
end

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

local function SoftHideBlizzardTargetFrame()
    if not TargetFrame then return end

    if InCombatLockdown and InCombatLockdown() then
        pendingHide = true
        return
    end

    pendingHide = false

    if TargetFrame.UnregisterAllEvents then
        TargetFrame:UnregisterAllEvents()
    end
    if TargetFrame.EnableMouse then
        TargetFrame:EnableMouse(false)
    end
    if TargetFrame.SetMouseClickEnabled then
        TargetFrame:SetMouseClickEnabled(false)
    end
    if TargetFrame.SetMouseMotionEnabled then
        TargetFrame:SetMouseMotionEnabled(false)
    end

    if TargetFrame.SetHitRectInsets then
        TargetFrame:SetHitRectInsets(10000, 10000, 10000, 10000)
    end

    HideRegions(TargetFrame)

    KillVisual(TargetFrame.TargetFrameContainer)
    KillVisual(TargetFrame.TargetFrameContent)
    KillVisual(TargetFrame.healthbar)
    KillVisual(TargetFrame.manabar)

    if TargetFrame.auraPools then
        TargetFrame.auraPools:ReleaseAll()
        if not TargetFrame.NivUI_AurasDisabled then
            TargetFrame.NivUI_AurasDisabled = true
            TargetFrame.UpdateAuras = function() end
        end
    end

    local children = { TargetFrame:GetChildren() }
    for _, child in ipairs(children) do
        local name = child:GetName()
        if name and name:find("^TargetFrame") then
            KillVisual(child)
        end
    end

    for _, child in ipairs(children) do
        if not child:GetName() then
            KillVisual(child)
        end
    end

    blizzardHidden = true

    if not TargetFrame.NivUI_SoftHideHooked then
        TargetFrame.NivUI_SoftHideHooked = true
        TargetFrame:HookScript("OnShow", function()
            if blizzardHidden then
                SoftHideBlizzardTargetFrame()
            end
        end)
    end
end

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
        print("NivUI TargetFrame: No style found for", styleName)
        return
    end

    currentStyle = style

    local WF = NivUI.WidgetFactories
    if not WF then
        print("NivUI TargetFrame: Widget factories not loaded")
        return
    end

    local frameConfig = style.frame or {}
    local frameWidth = frameConfig.width or 200
    local frameHeight = frameConfig.height or 60

    customFrame = CreateFrame("Button", "NivUI_TargetFrame", UIParent, "SecureUnitButtonTemplate")
    customFrame:SetSize(frameWidth, frameHeight)
    if frameConfig.strata then customFrame:SetFrameStrata(frameConfig.strata) end
    if frameConfig.frameLevel then customFrame:SetFrameLevel(frameConfig.frameLevel) end

    customFrame:SetAttribute("unit", "target")
    customFrame:SetAttribute("type1", "target")
    customFrame:SetAttribute("type2", "togglemenu")
    customFrame:RegisterForClicks("AnyUp")

    customFrame:SetPoint("TOPLEFT", TargetFrame, "TOPLEFT", 24, 0)

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

    customFrame.widgets = {}

    for _, widgetType in ipairs(NivUI.UnitFrames.WIDGET_ORDER) do
        if widgetType ~= "frame" then
            local config = style[widgetType]
            if config and config.enabled and WF[widgetType] then
                local success, widget = pcall(WF[widgetType], customFrame, config, style, "target")
                if success and widget then
                    customFrame.widgets[widgetType] = widget
                elseif not success then
                    print("NivUI TargetFrame: Error creating", widgetType, "-", widget)
                end
            end
        end
    end

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

    customFrame:RegisterUnitEvent("UNIT_MAXHEALTH", "target")
    customFrame:RegisterUnitEvent("UNIT_MAXPOWER", "target")
    customFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", "target")
    customFrame:RegisterUnitEvent("UNIT_MODEL_CHANGED", "target")
    customFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", "target")
    customFrame:RegisterUnitEvent("UNIT_LEVEL", "target")
    customFrame:RegisterUnitEvent("UNIT_FACTION", "target")
    customFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    customFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    customFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", "target")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "target")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "target")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "target")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "target")
    customFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "target")

    customFrame:SetScript("OnEvent", function(self, event, unit)
        if event == "PLAYER_TARGET_CHANGED" then
            if UnitExists("target") then
                self:Show()
                UpdateAllWidgets()
            else
                self:Hide()
            end
        elseif event == "UNIT_MAXHEALTH" then
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
        elseif event == "UNIT_FACTION" then
            UpdateHealthBar()
            UpdateNameText()
        elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
            UpdateStatusIndicators()
        elseif event:find("SPELLCAST") then
            UpdateCastbar()
        end
    end)

    customFrame:SetScript("OnUpdate", function(self, elapsed)
        if not NivUI:IsRealTimeUpdates("target") then
            timeSinceLastUpdate = timeSinceLastUpdate + elapsed
            if timeSinceLastUpdate < UPDATE_INTERVAL then return end
            timeSinceLastUpdate = 0
        end

        UpdateHealthBar()
        UpdateHealthText()
        UpdatePowerBar()
        UpdatePowerText()
    end)

    if UnitExists("target") then
        customFrame:Show()
        UpdateAllWidgets()
    else
        customFrame:Hide()
    end
end

local function EnableTargetFrame()
    local styleName = NivUI:GetAssignment("target")
    BuildCustomFrame(styleName)
    SoftHideBlizzardTargetFrame()
end

local function DisableTargetFrame()
    DestroyCustomFrame()
    ReloadUI()
end

local function RefreshTargetFrame()
    if NivUI:IsFrameEnabled("target") then
        EnableTargetFrame()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        if NivUI:IsFrameEnabled("target") then
            EnableTargetFrame()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingHide then
            SoftHideBlizzardTargetFrame()
        end
    end
end)

NivUI:RegisterCallback("FrameEnabledChanged", function(data)
    if data.frameType == "target" then
        if data.enabled then
            EnableTargetFrame()
        else
            DisableTargetFrame()
        end
    end
end)

NivUI:RegisterCallback("AssignmentChanged", function(data)
    if data.frameType == "target" and NivUI:IsFrameEnabled("target") then
        RefreshTargetFrame()
    end
end)

NivUI:RegisterCallback("StyleChanged", function(data)
    if NivUI:IsFrameEnabled("target") then
        local assignedStyle = NivUI:GetAssignment("target")
        if data.styleName == assignedStyle then
            RefreshTargetFrame()
        end
    end
end)
