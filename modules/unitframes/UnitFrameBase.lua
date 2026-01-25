NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local UnitFrameBase = {}
NivUI.UnitFrames.Base = UnitFrameBase

local function GetClassColor(unit)
    return NivUI.WidgetFactories.GetClassColor(unit)
end

local function GetPowerColor(unit)
    return NivUI.WidgetFactories.GetPowerColor(unit)
end

function UnitFrameBase.HideRegions(frame)
    if not frame then return end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region then
            region:SetAlpha(0)
            region:Hide()
        end
    end
end

function UnitFrameBase.KillVisual(frame)
    if not frame then return end
    if frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
    if frame.EnableMouse then frame:EnableMouse(false) end
    if frame.SetAlpha then frame:SetAlpha(0) end
    if not InCombatLockdown() then
        if frame.Hide then frame:Hide() end
        if frame.SetScript then
            frame:SetScript("OnShow", function(self)
                self:SetAlpha(0)
                if not InCombatLockdown() then
                    self:Hide()
                end
            end)
            frame:SetScript("OnEnter", nil)
            frame:SetScript("OnLeave", nil)
        end
    end
end

function UnitFrameBase.CreateHideBlizzardFrame(blizzardFrame, options)
    options = options or {}
    local childPrefix = options.childPrefix
    local hasAuras = options.hasAuras
    local extraKills = options.extraKills or {}
    local containerKey = options.containerKey
    local contentKey = options.contentKey

    local function HideBlizzardFrame(state)
        if not blizzardFrame then return end

        if InCombatLockdown and InCombatLockdown() then
            state.pendingHide = true
            return
        end

        state.pendingHide = false

        -- NOTE: Do NOT call UnregisterAllEvents - it breaks Edit Mode
        if blizzardFrame.EnableMouse then
            blizzardFrame:EnableMouse(false)
        end
        if blizzardFrame.SetMouseClickEnabled then
            blizzardFrame:SetMouseClickEnabled(false)
        end
        if blizzardFrame.SetMouseMotionEnabled then
            blizzardFrame:SetMouseMotionEnabled(false)
        end
        if blizzardFrame.SetHitRectInsets then
            blizzardFrame:SetHitRectInsets(10000, 10000, 10000, 10000)
        end

        UnitFrameBase.HideRegions(blizzardFrame)

        if containerKey then
            UnitFrameBase.KillVisual(blizzardFrame[containerKey])
        end
        if contentKey then
            UnitFrameBase.KillVisual(blizzardFrame[contentKey])
        end
        UnitFrameBase.KillVisual(blizzardFrame.healthbar)
        UnitFrameBase.KillVisual(blizzardFrame.manabar)

        for _, key in ipairs(extraKills) do
            UnitFrameBase.KillVisual(blizzardFrame[key])
        end

        if hasAuras and blizzardFrame.auraPools then
            blizzardFrame.auraPools:ReleaseAll()
            if not state.aurasDisabled then
                state.aurasDisabled = true
                blizzardFrame.UpdateAuras = function() end
            end
        end

        if childPrefix then
            local children = { blizzardFrame:GetChildren() }
            for _, child in ipairs(children) do
                local name = child:GetName()
                if name and name:find(childPrefix) then
                    UnitFrameBase.KillVisual(child)
                end
            end
        end

        state.blizzardHidden = true

        if not state.softHideHooked then
            state.softHideHooked = true
            blizzardFrame:HookScript("OnShow", function(self)
                if state.blizzardHidden then
                    self:SetAlpha(0)
                    if not InCombatLockdown() then
                        HideBlizzardFrame(state)
                    end
                end
            end)
        end
    end

    return HideBlizzardFrame
end

function UnitFrameBase.SetSecureVisibility(frame, visible)
    if not frame then return end
    RegisterStateDriver(frame, "visibility", visible and "show" or "hide")
end

function UnitFrameBase.UpdateHealthBar(state)
    if not state.customFrame or not state.customFrame.widgets.healthBar then return end
    local widget = state.customFrame.widgets.healthBar
    local config = state.currentStyle.healthBar
    local unit = state.unit

    local maxHealth = UnitHealthMax(unit)
    local health = UnitHealth(unit)

    widget:SetMinMaxValues(0, maxHealth)
    widget:SetValue(health)

    local r, g, b, a = 0.2, 0.8, 0.2, 1
    local bgR, bgG, bgB, bgA = config.backgroundColor.r, config.backgroundColor.g, config.backgroundColor.b, config.backgroundColor.a or 0.8

    if config.colorMode == "class" then
        r, g, b = GetClassColor(unit)
    elseif config.colorMode == "class_inverted" then
        r, g, b, a = config.customColor.r, config.customColor.g, config.customColor.b, config.customColor.a or 1
        bgR, bgG, bgB = GetClassColor(unit)
    elseif config.colorMode == "custom" then
        r, g, b, a = config.customColor.r, config.customColor.g, config.customColor.b, config.customColor.a or 1
    elseif config.colorMode == "reaction" then
        local reaction = UnitReaction(unit, "player")
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

local function ShouldShowPowerBar(unit, visibility)
    if visibility == "self" then
        return UnitIsUnit(unit, "player")
    elseif visibility == "healers" then
        local role = UnitGroupRolesAssigned(unit)
        return role == "HEALER"
    end
    return true
end

local function IsAnchorChainVisible(widgets, style, widgetType, visited)
    visited = visited or {}
    if visited[widgetType] then return true end
    visited[widgetType] = true

    local config = style[widgetType]
    if not config then return true end

    local anchorTo = config.anchor and config.anchor.relativeTo
    if not anchorTo or anchorTo == "frame" then
        return true
    end

    local anchorWidget = widgets[anchorTo]
    if not anchorWidget then return false end  -- Anchor target doesn't exist (disabled)
    if not anchorWidget:IsShown() then return false end

    return IsAnchorChainVisible(widgets, style, anchorTo, visited)
end

local function CascadeAnchorVisibility(state)
    if not state.customFrame or not state.customFrame.widgets then return end
    local widgets = state.customFrame.widgets
    local style = state.currentStyle

    for widgetType, widget in pairs(widgets) do
        if widget.Hide and widget.Show then
            if not IsAnchorChainVisible(widgets, style, widgetType, nil) then
                widget:Hide()
            end
        end
    end
end

function UnitFrameBase.UpdatePowerBar(state)
    if not state.customFrame or not state.customFrame.widgets.powerBar then return end
    local widget = state.customFrame.widgets.powerBar
    local config = state.currentStyle.powerBar
    local unit = state.unit

    local visibility = config.visibility or "everyone"
    if not ShouldShowPowerBar(unit, visibility) then
        widget:Hide()
        return
    end
    widget:Show()

    local powerType = UnitPowerType(unit)
    local maxPower = UnitPowerMax(unit, powerType)
    local power = UnitPower(unit, powerType)

    widget:SetMinMaxValues(0, maxPower)
    widget:SetValue(power)

    local r, g, b, a = 0.2, 0.2, 0.8, 1
    if config.colorMode == "power" then
        r, g, b = GetPowerColor(unit)
    elseif config.colorMode == "class" then
        r, g, b = GetClassColor(unit)
    elseif config.colorMode == "custom" then
        r, g, b, a = config.customColor.r, config.customColor.g, config.customColor.b, config.customColor.a or 1
    end
    widget:SetStatusBarColor(r, g, b, a)
end

function UnitFrameBase.UpdateHealthText(state)
    if not state.customFrame or not state.customFrame.widgets.healthText then return end
    local widget = state.customFrame.widgets.healthText
    local config = state.currentStyle.healthText
    local unit = state.unit

    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    local abbrev = AbbreviateLargeNumbers or AbbreviateNumbers or tostring
    local healthStr = abbrev(health)
    local maxHealthStr = abbrev(maxHealth)

    if config.format == "percent" then
        local pct = UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100
            and UnitHealthPercent(unit, true, CurveConstants.ScaleTo100) or nil
        if pct then
            widget.text:SetFormattedText("%.0f%%", pct)
        else
            widget.text:SetText(healthStr)
        end
    elseif config.format == "current_percent" then
        local pct = UnitHealthPercent and CurveConstants and CurveConstants.ScaleTo100
            and UnitHealthPercent(unit, true, CurveConstants.ScaleTo100) or nil
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
        if issecretvalue(health) then
            widget.text:SetText("")
        else
            local deficit = maxHealth - health
            if deficit > 0 then
                widget.text:SetText("-" .. abbrev(deficit))
            else
                widget.text:SetText("")
            end
        end
    end
end

function UnitFrameBase.UpdatePowerText(state)
    if not state.customFrame or not state.customFrame.widgets.powerText then return end
    local widget = state.customFrame.widgets.powerText
    local config = state.currentStyle.powerText
    local unit = state.unit

    local powerType = UnitPowerType(unit)
    local power = UnitPower(unit, powerType)
    local maxPower = UnitPowerMax(unit, powerType)
    local abbrev = AbbreviateLargeNumbers or AbbreviateNumbers or tostring
    local powerStr = abbrev(power)
    local maxPowerStr = abbrev(maxPower)

    if config.format == "percent" then
        local pct = UnitPowerPercent and CurveConstants and CurveConstants.ScaleTo100
            and UnitPowerPercent(unit, powerType, false, CurveConstants.ScaleTo100) or nil
        if pct then
            widget.text:SetFormattedText("%.0f%%", pct)
        else
            widget.text:SetText(powerStr)
        end
    elseif config.format == "current_percent" then
        local pct = UnitPowerPercent and CurveConstants and CurveConstants.ScaleTo100
            and UnitPowerPercent(unit, powerType, false, CurveConstants.ScaleTo100) or nil
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

function UnitFrameBase.UpdatePortrait(state)
    if not state.customFrame or not state.customFrame.widgets.portrait then return end
    local widget = state.customFrame.widgets.portrait
    local config = state.currentStyle.portrait
    local unit = state.unit

    if config.mode == "3D" then
        if widget.SetUnit then
            widget:SetUnit(unit)
        end
    elseif config.mode == "2D" then
        if widget.texture then
            SetPortraitTexture(widget.texture, unit)
        end
    elseif config.mode == "class" then
        if widget.texture then
            local _, class = UnitClass(unit)
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

function UnitFrameBase.UpdateStatusIndicators(state)
    if not state.customFrame or not state.customFrame.widgets.statusIndicators then return end
    local widget = state.customFrame.widgets.statusIndicators
    local config = state.currentStyle.statusIndicators
    local unit = state.unit

    if widget.combat then
        if config.showCombat and UnitAffectingCombat(unit) then
            widget.combat:SetAlpha(1)
            widget.combat:Show()
        else
            widget.combat:Hide()
        end
    end
end

function UnitFrameBase.UpdateRaidMarker(state)
    if not state.customFrame or not state.customFrame.widgets.raidMarker then return end
    local widget = state.customFrame.widgets.raidMarker
    local unit = state.unit

    local index = GetRaidTargetIndex(unit)
    if index then
        SetRaidTargetIconTexture(widget.icon, index)
        widget.icon:SetAlpha(1)
        widget:Show()
    else
        widget:Hide()
    end
end

function UnitFrameBase.UpdateLeaderIcon(state)
    if not state.customFrame or not state.customFrame.widgets.leaderIcon then return end
    local widget = state.customFrame.widgets.leaderIcon
    local unit = state.unit

    local isLeader = UnitIsGroupLeader(unit)
    local isAssist = UnitIsGroupAssistant and UnitIsGroupAssistant(unit)

    if isLeader then
        widget.icon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
        widget.icon:SetAlpha(1)
        widget:Show()
    elseif isAssist then
        widget.icon:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
        widget.icon:SetAlpha(1)
        widget:Show()
    else
        widget:Hide()
    end
end

function UnitFrameBase.UpdateRoleIcon(state)
    if not state.customFrame or not state.customFrame.widgets.roleIcon then return end
    local widget = state.customFrame.widgets.roleIcon
    local unit = state.unit

    local role = UnitGroupRolesAssigned(unit)
    if role and role ~= "NONE" and GetMicroIconForRole then
        local atlas = GetMicroIconForRole(role)
        if atlas then
            widget.icon:SetAtlas(atlas)
            widget.icon:SetAlpha(1)
            widget:Show()
            return
        end
    end

    widget:Hide()
end

function UnitFrameBase.UpdateNameText(state)
    if not state.customFrame or not state.customFrame.widgets.nameText then return end
    local widget = state.customFrame.widgets.nameText
    local config = state.currentStyle.nameText
    local unit = state.unit

    local name = UnitName(unit) or state.defaultName or "Unit"
    if not issecretvalue(name) and config.truncateLength and #name > config.truncateLength then
        name = name:sub(1, config.truncateLength)
    end
    widget.text:SetText(name)

    if config.colorByClass then
        local r, g, b = GetClassColor(unit)
        widget.text:SetTextColor(r, g, b, config.customColor and config.customColor.a or 1)
    end
end

function UnitFrameBase.UpdateLevelText(state)
    if not state.customFrame or not state.customFrame.widgets.levelText then return end
    local widget = state.customFrame.widgets.levelText
    local config = state.currentStyle.levelText
    local unit = state.unit

    local level = UnitLevel(unit)
    local text = level == -1 and "??" or tostring(level)
    widget.text:SetText(text)

    if config.colorByDifficulty then
        local color = GetCreatureDifficultyColor and GetCreatureDifficultyColor(level)
            or GetQuestDifficultyColor and GetQuestDifficultyColor(level)
        if color then
            widget.text:SetTextColor(color.r, color.g, color.b)
        end
    end
end

function UnitFrameBase.UpdateCastbar(state)
    if not state.customFrame or not state.customFrame.widgets.castbar then return end
    local widget = state.customFrame.widgets.castbar
    local config = state.currentStyle.castbar
    local unit = state.unit

    local name, _text, texture, startTimeMS, endTimeMS, _isTradeSkill, _castID, notInterruptible, _spellID = UnitCastingInfo(unit)
    local isChanneling = false
    local isEmpowered = false
    local numStages = 0
    local _isEmpoweredFlag

    if not name then
        name, _text, texture, startTimeMS, endTimeMS, _isTradeSkill, notInterruptible, _spellID, _isEmpoweredFlag, numStages = UnitChannelInfo(unit)
        isChanneling = true
        isEmpowered = numStages and numStages > 0
    end

    if not name then
        widget:Hide()
        if state.castbarTicking then
            state.castbarTicking = false
            widget:SetScript("OnUpdate", nil)
        end
        if widget.ClearStages then
            widget:ClearStages()
        end
        return
    end

    if isEmpowered and not issecretvalue(endTimeMS) then
        local holdTime = GetUnitEmpowerHoldAtMaxTime(unit)
        if holdTime and not issecretvalue(holdTime) then
            endTimeMS = endTimeMS + holdTime
        end
    end

    local fillBackward = isChanneling and not isEmpowered

    if issecretvalue(startTimeMS) then
        local duration = isChanneling and UnitChannelDuration(unit) or UnitCastingDuration(unit)
        local direction = fillBackward and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime
        widget:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, direction)

        if widget.timer and config.showTimer then
            if not state.castbarTicking then
                state.castbarTicking = true
                widget:SetScript("OnUpdate", function()
                    widget.timer:SetFormattedText("%.1fs", duration:GetRemainingDuration())
                end)
            end
        elseif state.castbarTicking then
            state.castbarTicking = false
            widget:SetScript("OnUpdate", nil)
        end
    else
        local durationSec = (endTimeMS - startTimeMS) / 1000
        widget:SetMinMaxValues(0, 1)

        if not state.castbarTicking then
            state.castbarTicking = true
            widget:SetScript("OnUpdate", function()
                local elapsed = (GetTime() * 1000 - startTimeMS) / 1000
                local progress = elapsed / durationSec
                widget:SetValue(fillBackward and (1 - progress) or progress)

                if widget.timer and config.showTimer then
                    local remaining = (endTimeMS - GetTime() * 1000) / 1000
                    widget.timer:SetFormattedText("%.1fs", remaining)
                end

                if isEmpowered and widget.UpdateStage then
                    widget:UpdateStage(elapsed)
                end
            end)
        end
    end

    if isEmpowered and widget.AddStages then
        local totalDurationMS = endTimeMS - startTimeMS
        widget:AddStages(numStages, unit, totalDurationMS)
    elseif widget.ClearStages then
        widget:ClearStages()
    end

    if widget.spellName and config.showSpellName then
        widget.spellName:SetText(name or "")
    end

    if widget.icon and config.showIcon then
        widget.icon:SetTexture(texture)
    end

    local cast = config.castingColor
    local nonInt = config.nonInterruptibleColor
    widget:GetStatusBarTexture():SetVertexColorFromBoolean(notInterruptible,
        CreateColor(nonInt.r, nonInt.g, nonInt.b),
        CreateColor(cast.r, cast.g, cast.b))

    widget:Show()
end

function UnitFrameBase.UpdateAllWidgets(state)
    UnitFrameBase.UpdateHealthBar(state)
    UnitFrameBase.UpdateHealthText(state)
    UnitFrameBase.UpdatePowerBar(state)
    UnitFrameBase.UpdatePowerText(state)
    UnitFrameBase.UpdatePortrait(state)
    UnitFrameBase.UpdateNameText(state)
    UnitFrameBase.UpdateLevelText(state)
    UnitFrameBase.UpdateStatusIndicators(state)
    UnitFrameBase.UpdateRaidMarker(state)
    UnitFrameBase.UpdateLeaderIcon(state)
    UnitFrameBase.UpdateRoleIcon(state)
    UnitFrameBase.UpdateCastbar(state)
    CascadeAnchorVisibility(state)
end

function UnitFrameBase.CreateWidgets(parent, style, unit, options)
    options = options or {}
    local WF = NivUI.WidgetFactories
    if not WF then return {} end

    local widgets = {}

    for _, widgetType in ipairs(NivUI.UnitFrames.WIDGET_ORDER) do
        if widgetType ~= "frame" then
            local config = style[widgetType]
            if config and config.enabled and WF[widgetType] then
                local widgetConfig = config
                if options.forPreview then
                    widgetConfig = {}
                    for k, v in pairs(config) do
                        if k ~= "strata" and k ~= "frameLevel" then
                            widgetConfig[k] = v
                        end
                    end
                end

                local success, widget = pcall(WF[widgetType], parent, widgetConfig, style, unit, options)
                if success and widget then
                    widgets[widgetType] = widget
                elseif not success then
                    print("NivUI: Error creating", widgetType, "-", widget)
                end
            end
        end
    end

    return widgets
end

function UnitFrameBase.ApplyAnchors(parent, widgets, style)
    for widgetType, widget in pairs(widgets) do
        local config = style[widgetType]
        local anchor = config and config.anchor
        if anchor then
            widget:ClearAllPoints()

            local anchorTarget
            if anchor.relativeTo == "frame" or anchor.relativeTo == nil then
                anchorTarget = parent
            else
                anchorTarget = widgets[anchor.relativeTo]
                if not anchorTarget then
                    widget:Hide()
                    widget.anchorMissing = true
                end
            end

            if anchorTarget then
                widget:SetPoint(anchor.point, anchorTarget, anchor.relativePoint or anchor.point, anchor.x or 0, anchor.y or 0)
                widget.anchorMissing = nil
            end
        else
            widget:SetPoint("CENTER", parent, "CENTER", 0, 0)
        end
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

function UnitFrameBase.BuildCustomFrame(state)
    local style = NivUI:GetStyleWithDefaults(state.styleName)
    if not style then
        print("NivUI " .. state.frameType .. ": No style found for", state.styleName)
        return
    end

    state.currentStyle = style

    local frameConfig = style.frame or {}
    local frameWidth = frameConfig.width or 200
    local frameHeight = frameConfig.height or 60

    local frameName = "NivUI_" .. state.frameType .. "Frame"
    local customFrame = _G[frameName]
    local isNewFrame = not customFrame

    if isNewFrame then
        customFrame = CreateFrame("Button", frameName, UIParent, "SecureUnitButtonTemplate")
    else
        ClearFrameWidgets(customFrame)
        customFrame:SetParent(UIParent)
    end

    customFrame:SetSize(frameWidth, frameHeight)
    if frameConfig.strata then customFrame:SetFrameStrata(frameConfig.strata) end
    if frameConfig.frameLevel then customFrame:SetFrameLevel(frameConfig.frameLevel) end

    customFrame:SetAttribute("unit", state.unit)
    customFrame:SetAttribute("type1", "target")
    customFrame:SetAttribute("type2", "togglemenu")
    customFrame:RegisterForClicks("AnyUp")

    local positionApplied = NivUI.EditMode and NivUI.EditMode:ApplyPosition(state.frameType, customFrame)

    if not positionApplied then
        local anchorFrame = state.anchorFrame
        if type(anchorFrame) == "function" then
            anchorFrame = anchorFrame()
        end
        if anchorFrame then
            customFrame:SetPoint("TOPLEFT", anchorFrame, "TOPLEFT", state.anchorOffsetX or 0, state.anchorOffsetY or 0)
        else
            customFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end

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

    customFrame.widgets = UnitFrameBase.CreateWidgets(customFrame, style, state.unit)
    UnitFrameBase.ApplyAnchors(customFrame, customFrame.widgets, style)

    state.customFrame = customFrame

    if isNewFrame then
        local visibilityDriver = NivUI:GetVisibilityOverride(state.frameType) or state.visibilityDriver
        state.effectiveVisibilityDriver = visibilityDriver
        if visibilityDriver then
            RegisterStateDriver(customFrame, "visibility", visibilityDriver)
            NivUI.EditMode:RegisterVisibilityDriver(state.frameType, customFrame, visibilityDriver)
            customFrame:HookScript("OnShow", function()
                UnitFrameBase.UpdateAllWidgets(state)
            end)
        end

        customFrame:RegisterUnitEvent("UNIT_MAXHEALTH", state.unit)
        customFrame:RegisterUnitEvent("UNIT_MAXPOWER", state.unit)
        customFrame:RegisterUnitEvent("UNIT_DISPLAYPOWER", state.unit)
        customFrame:RegisterUnitEvent("UNIT_MODEL_CHANGED", state.unit)
        customFrame:RegisterUnitEvent("UNIT_NAME_UPDATE", state.unit)
        customFrame:RegisterUnitEvent("UNIT_LEVEL", state.unit)
        customFrame:RegisterUnitEvent("UNIT_FACTION", state.unit)
        customFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        customFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

        customFrame:RegisterUnitEvent("UNIT_SPELLCAST_START", state.unit)
        customFrame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", state.unit)
        customFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", state.unit)
        customFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", state.unit)
        customFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", state.unit)
        customFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", state.unit)
        customFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", state.unit)
        customFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", state.unit)

        if state.registerEvents then
            state.registerEvents(customFrame)
        end

        customFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        customFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        customFrame:RegisterEvent("ENCOUNTER_START")
        customFrame:RegisterEvent("ENCOUNTER_END")
        customFrame:RegisterEvent("PLAYER_ALIVE")
        customFrame:RegisterEvent("PLAYER_DEAD")
        customFrame:RegisterEvent("PLAYER_UNGHOST")
        customFrame:RegisterEvent("RAID_TARGET_UPDATE")
        customFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        customFrame:RegisterEvent("PARTY_LEADER_CHANGED")
        customFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")

        customFrame:SetScript("OnEvent", function(self, event, eventUnit)
            if event == "UNIT_MAXHEALTH" then
                UnitFrameBase.UpdateHealthBar(state)
                UnitFrameBase.UpdateHealthText(state)
            elseif event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
                UnitFrameBase.UpdatePowerBar(state)
                UnitFrameBase.UpdatePowerText(state)
            elseif event == "UNIT_MODEL_CHANGED" then
                UnitFrameBase.UpdatePortrait(state)
            elseif event == "UNIT_NAME_UPDATE" then
                UnitFrameBase.UpdateNameText(state)
            elseif event == "UNIT_LEVEL" then
                UnitFrameBase.UpdateLevelText(state)
            elseif event == "UNIT_FACTION" then
                UnitFrameBase.UpdateHealthBar(state)
                UnitFrameBase.UpdateNameText(state)
            elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
                UnitFrameBase.UpdateStatusIndicators(state)
            elseif event == "RAID_TARGET_UPDATE" then
                UnitFrameBase.UpdateRaidMarker(state)
            elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" then
                UnitFrameBase.UpdateLeaderIcon(state)
            elseif event == "PLAYER_ROLES_ASSIGNED" then
                UnitFrameBase.UpdateRoleIcon(state)
            elseif event:find("SPELLCAST") then
                UnitFrameBase.UpdateCastbar(state)
            elseif event == "PLAYER_ENTERING_WORLD"
                or event == "ZONE_CHANGED_NEW_AREA"
                or event == "ENCOUNTER_START"
                or event == "ENCOUNTER_END"
                or event == "PLAYER_ALIVE"
                or event == "PLAYER_DEAD"
                or event == "PLAYER_UNGHOST" then
                UnitFrameBase.CheckVisibility(state)
            end

            if state.onEvent then
                state.onEvent(self, event, eventUnit)
            end
        end)

        state.timeSinceLastUpdate = 0
        customFrame:SetScript("OnUpdate", function(self, elapsed)
            UnitFrameBase.CheckVisibility(state)
            if not self:IsShown() then return end

            if state.preUpdate then
                state.preUpdate(state, elapsed)
            end

            if not NivUI:IsRealTimeUpdates(state.frameType) then
                state.timeSinceLastUpdate = state.timeSinceLastUpdate + elapsed
                if state.timeSinceLastUpdate < NivUI.UPDATE_INTERVAL then return end
                state.timeSinceLastUpdate = 0
            end

            UnitFrameBase.UpdateHealthBar(state)
            UnitFrameBase.UpdateHealthText(state)
            UnitFrameBase.UpdatePowerBar(state)
            UnitFrameBase.UpdatePowerText(state)
            UnitFrameBase.UpdateCastbar(state)
        end)

        if NivUI.EditMode then
            NivUI.EditMode:CreateSelectionFrame(state.frameType, customFrame)
            if NivUI.EditMode:IsActive() then
                NivUI.EditMode:ShowSelection(state.frameType)
            end
        end
    end

    UnitFrameBase.CheckVisibility(state)
end

function UnitFrameBase.CheckVisibility(state)
    if not state.customFrame then return end

    if state.effectiveVisibilityDriver then
        if state.customFrame:IsShown() then
            UnitFrameBase.UpdateAllWidgets(state)
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
            UnitFrameBase.UpdateAllWidgets(state)
        end
    else
        if state.customFrame:IsShown() then
            state.customFrame:Hide()
        end
    end
end

function UnitFrameBase.ApplyPendingVisibility(state)
    if state.effectiveVisibilityDriver then return end
    if state.pendingVisibility == nil then return end
    if InCombatLockdown() then return end

    local shouldBeVisible = state.pendingVisibility
    state.pendingVisibility = nil

    if shouldBeVisible then
        if not state.customFrame:IsShown() then
            state.customFrame:Show()
            UnitFrameBase.UpdateAllWidgets(state)
        end
    else
        if state.customFrame:IsShown() then
            state.customFrame:Hide()
        end
    end
end

function UnitFrameBase.DestroyCustomFrame(state)
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

function UnitFrameBase.CreateModule(config)
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
    }

    local module = {}

    function module.Enable()
        state.styleName = NivUI:GetAssignment(state.frameType)
        UnitFrameBase.BuildCustomFrame(state)
        if state.hideBlizzard then
            state.hideBlizzard(state)
        end
    end

    function module.Disable()
        UnitFrameBase.DestroyCustomFrame(state)
        ReloadUI()
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
            UnitFrameBase.ApplyPendingVisibility(state)
        end
    end)

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

    NivUI:RegisterCallback("StyleChanged", function(data)
        if NivUI:IsFrameEnabled(state.frameType) then
            local assignedStyle = NivUI:GetAssignment(state.frameType)
            if data.styleName == assignedStyle then
                module.Refresh()
            end
        end
    end)

    NivUI:RegisterCallback("VisibilityOverrideChanged", function(data)
        if data.frameType == state.frameType and NivUI:IsFrameEnabled(state.frameType) and state.customFrame then
            local newDriver = NivUI:GetVisibilityOverride(state.frameType) or state.visibilityDriver
            state.effectiveVisibilityDriver = newDriver
            if newDriver then
                UnregisterStateDriver(state.customFrame, "visibility")
                RegisterStateDriver(state.customFrame, "visibility", newDriver)
            end
            NivUI.EditMode:RegisterVisibilityDriver(state.frameType, state.customFrame, newDriver)
        end
    end)

    return module
end
