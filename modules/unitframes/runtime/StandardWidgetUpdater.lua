local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Runtime = NivUI.UnitFrames.Runtime or {}

local StandardWidgetUpdater = {}
NivUI.UnitFrames.Runtime.StandardWidgetUpdater = StandardWidgetUpdater
local function GetClassColor(unit)
    return NivUI.WidgetFactories.GetClassColor(unit)
end

local function GetPowerColor(unit)
    return NivUI.WidgetFactories.GetPowerColor(unit)
end

local function GetWidgetConfig(state, widgetName)
    local config = state.currentStyle and state.currentStyle[widgetName]
    if not config then
        return NivUI.UnitFrames.DEFAULT_STYLE[widgetName]
    end
    return config
end
local function ShouldShowPowerBar(unit, visibility)
    if visibility == "self" then
        return UnitIsUnit(unit, "player")
    elseif visibility == "healers" then
        local role = NivUI.Roster:GetRole(unit)
        return role == "HEALER"
    end
    return true
end

local function IsAnchorChainVisible(widgets, style, widgetType, visited)
    visited = visited or {}
    if visited[widgetType] then return true end
    visited[widgetType] = true

    local config = style[widgetType] or (widgets[widgetType] and widgets[widgetType].config)
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

function StandardWidgetUpdater.CascadeAnchorVisibility(state)
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

--- Updates the power bar widget for a unit frame.
--- Handles power values, visibility rules, and color modes (power, class, custom).
--- @param state table The unit frame state table
function StandardWidgetUpdater.UpdatePowerBar(state)
    if not state.customFrame or not state.customFrame.widgets.powerBar then return end
    local widget = state.customFrame.widgets.powerBar
    local config = GetWidgetConfig(state, "powerBar")
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

--- Updates the health text widget for a unit frame.
--- Supports formats: percent, current_percent, current, current_max, deficit.
--- @param state table The unit frame state table
function StandardWidgetUpdater.UpdateHealthText(state)
    if not state.customFrame or not state.customFrame.widgets.healthText then return end
    local widget = state.customFrame.widgets.healthText
    local config = GetWidgetConfig(state, "healthText")
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

--- Updates the power text widget for a unit frame.
--- Supports formats: percent, current_percent, current, current_max.
--- @param state table The unit frame state table
function StandardWidgetUpdater.UpdatePowerText(state)
    if not state.customFrame or not state.customFrame.widgets.powerText then return end
    local widget = state.customFrame.widgets.powerText
    local config = GetWidgetConfig(state, "powerText")
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

--- Updates the portrait widget for a unit frame.
--- Supports modes: 3D (model), 2D (texture), class (class icon).
--- @param state table The unit frame state table
function StandardWidgetUpdater.UpdatePortrait(state)
    if not state.customFrame or not state.customFrame.widgets.portrait then return end
    local widget = state.customFrame.widgets.portrait
    local config = GetWidgetConfig(state, "portrait")
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
            local class = NivUI.Roster:GetClass(unit)
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

--- Updates the status indicator icons (combat, resting) for a unit frame.
--- @param state table The unit frame state table
function StandardWidgetUpdater.UpdateStatusIndicators(state)
    if not state.customFrame or not state.customFrame.widgets.statusIndicators then return end
    local widget = state.customFrame.widgets.statusIndicators
    local config = GetWidgetConfig(state, "statusIndicators")
    local unit = state.unit

    if widget.combat then
        if config.showCombat and UnitAffectingCombat(unit) then
            widget.combat:SetAlpha(1)
            widget.combat:Show()
        else
            widget.combat:Hide()
        end
    end

    if widget.resting then
        if config.showResting and unit == "player" and IsResting() then
            widget.resting:SetAlpha(1)
            widget.resting:Show()
        else
            widget.resting:Hide()
        end
    end
end

--- Updates the status text widget (offline, dead, ghost, AFK, DND) for a unit frame.
--- @param state table The unit frame state table
function StandardWidgetUpdater.UpdateStatusText(state)
    if not state.customFrame or not state.customFrame.widgets.statusText then return end
    local widget = state.customFrame.widgets.statusText
    local config = GetWidgetConfig(state, "statusText")
    local unit = state.unit

    local text = ""
    local color = nil

    if config.showOffline and not UnitIsConnected(unit) then
        text = "OFFLINE"
        color = config.color and config.color.offline
    elseif config.showDead and UnitIsDead(unit) and not UnitIsGhost(unit) then
        text = "DEAD"
        color = config.color and config.color.dead
    elseif config.showGhost and UnitIsGhost(unit) then
        text = "GHOST"
        color = config.color and config.color.ghost
    -- UnitIsAFK/UnitIsDND can return secret booleans (not just during combat).
    -- Guard with issecretvalue() instead of InCombatLockdown().
    elseif config.showAFK and not issecretvalue(UnitIsAFK(unit)) and UnitIsAFK(unit) then
        text = "AFK"
        color = config.color and config.color.afk
    elseif config.showDND and not issecretvalue(UnitIsDND(unit)) and UnitIsDND(unit) then
        text = "DND"
        color = config.color and config.color.dnd
    end

    if text ~= "" then
        widget.text:SetText(text)
        if color then
            widget.text:SetTextColor(color.r, color.g, color.b)
        end
        widget:Show()
    else
        widget.text:SetText("")
        widget:Hide()
    end
end

--- Updates the raid marker icon for a unit frame.
--- @param state table The unit frame state table
function StandardWidgetUpdater.UpdateRaidMarker(state)
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

--- Updates the leader/assistant icon for a unit frame.
--- @param state table The unit frame state table
function StandardWidgetUpdater.UpdateLeaderIcon(state)
    if not state.customFrame or not state.customFrame.widgets.leaderIcon then return end
    local widget = state.customFrame.widgets.leaderIcon
    local unit = state.unit

    local isLeader = NivUI.Roster:IsLeader(unit)
    local isAssist = NivUI.Roster:IsAssist(unit)

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

--- Updates the role icon (tank, healer, DPS) for a unit frame.
--- @param state table The unit frame state table
function StandardWidgetUpdater.UpdateRoleIcon(state)
    if not state.customFrame or not state.customFrame.widgets.roleIcon then return end
    local widget = state.customFrame.widgets.roleIcon
    local unit = state.unit

    local role = NivUI.Roster:GetRole(unit)
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

--- Updates the name text widget for a unit frame.
--- Supports truncation and class coloring.
--- @param state table The unit frame state table
function StandardWidgetUpdater.UpdateNameText(state)
    if not state.customFrame or not state.customFrame.widgets.nameText then return end
    local widget = state.customFrame.widgets.nameText
    local config = GetWidgetConfig(state, "nameText")
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

--- Updates the level text widget for a unit frame.
--- Supports difficulty coloring.
--- @param state table The unit frame state table
function StandardWidgetUpdater.UpdateLevelText(state)
    if not state.customFrame or not state.customFrame.widgets.levelText then return end
    local widget = state.customFrame.widgets.levelText
    local config = GetWidgetConfig(state, "levelText")
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


--- Updates the range-based alpha fading for a unit frame.
--- @param state table The unit frame state table
function StandardWidgetUpdater.UpdateRangeAlpha(state)
    if not state.customFrame or not state.customFrame:IsShown() then return end
    if not NivUI:IsFadeOutOfRangeEnabled(state.frameType) then
        if state.rangeAlphaApplied then
            state.rangeAlphaApplied = nil
            state.customFrame:SetAlpha(1)
        end
        return
    end

    local inRange, checkedRange = NivUI.UnitFrames.RangeCheck.IsInRange(state.unit)
    local outOfRangeAlpha = NivUI:GetOutOfRangeAlpha()
    if checkedRange and not inRange then
        state.customFrame:SetAlpha(outOfRangeAlpha)
    else
        state.customFrame:SetAlpha(1)
    end
    state.rangeAlphaApplied = true
end
