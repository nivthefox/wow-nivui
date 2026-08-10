local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Runtime = NivUI.UnitFrames.Runtime or {}

local HealthUpdater = {}
NivUI.UnitFrames.Runtime.HealthUpdater = HealthUpdater
local function GetClassColor(unit)
    return NivUI.WidgetFactories.GetClassColor(unit)
end

local function GetWidgetConfig(state, widgetName)
    local config = state.currentStyle and state.currentStyle[widgetName]
    if not config then
        return NivUI.UnitFrames.DEFAULT_STYLE[widgetName]
    end
    return config
end
local DEFAULT_TEMP_MAX_HEALTH_LOSS_COLOR = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 }
local FALLBACK_STATUS_BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local SMALL_TARGET_CLASSIFICATIONS = { minus = true, trivial = true }

local function ResolveLostMaxAtlas(widget, unit, source)
    if source ~= "blizzardAtlas" then
        return nil
    end

    local atlas = NivUI.WidgetFactories.GetTempMaxHealthLossAtlas(widget.frameType)
    if not atlas then
        return nil
    end

    if widget.frameType ~= "target" then
        return atlas
    end

    local classification = UnitClassification and UnitClassification(unit)
    if SMALL_TARGET_CLASSIFICATIONS[classification] then
        return NivUI.WidgetFactories.GetTempMaxHealthLossTargetMinusMobAtlas()
    end
    return atlas
end

local function ApplyLostMaxBarTexture(widget, config, unit)
    local lostMaxBar = widget.lostMaxBar
    if not lostMaxBar then return end

    local color = config.tempMaxHealthLossColor or DEFAULT_TEMP_MAX_HEALTH_LOSS_COLOR
    local atlas = ResolveLostMaxAtlas(widget, unit, config.tempMaxHealthLossTextureSource or "blizzardAtlas")

    if atlas then
        lostMaxBar:SetStatusBarTexture(atlas)
        local barTex = lostMaxBar:GetStatusBarTexture()
        if barTex then barTex:SetVertexColor(1, 1, 1, 1) end
        return
    end

    lostMaxBar:SetStatusBarTexture(widget.texturePath or FALLBACK_STATUS_BAR_TEXTURE)
    local barTex = lostMaxBar:GetStatusBarTexture()
    if barTex then barTex:SetVertexColor(color.r, color.g, color.b, color.a or 1) end
end

local function ClampUnit(value)
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

-- Blizzard's TempMaxHealthLossMixin treats the API value as the LOST fraction
-- (0 = unreduced, 0.3 = 30% lost), even though the wiki names the function
-- ambiguously. The HP bar shrinks to (1 - lostFraction) of the original width.
local function UpdateMaxHealthLossDisplay(widget, config, unit)
    local lostMaxBar = widget.lostMaxBar
    if not lostMaxBar then return end

    local original = widget.originalHpBarWidth or widget:GetWidth()

    if not config.showTempMaxHealthLoss or not GetUnitTotalModifiedMaxHealthPercent then
        widget:SetWidth(original)
        lostMaxBar:Hide()
        return
    end

    local lostPercent = ClampUnit(GetUnitTotalModifiedMaxHealthPercent(unit) or 0)
    if lostPercent <= 0 then
        widget:SetWidth(original)
        lostMaxBar:Hide()
        return
    end

    widget:SetWidth(original * (1 - lostPercent))
    ApplyLostMaxBarTexture(widget, config, unit)
    lostMaxBar:SetWidth(original)
    lostMaxBar:SetValue(lostPercent)
    lostMaxBar:Show()
end

-- The clamped flag is itself a secret boolean and cannot be tested in Lua;
-- SetAlphaFromBoolean is the C-side helper that translates it into alpha.
local function UpdateOverflowGlow(glow, enabled, clamped)
    if not glow then return end
    if not enabled then
        glow:Hide()
        return
    end
    glow:Show()
    glow:SetAlphaFromBoolean(clamped, 1.0, 0.0)
end

local function ReanchorAbsorbBar(bar, widget, anchorPoint)
    local barWidth = widget:GetWidth()
    if bar._lastBarWidth == barWidth then
        return barWidth
    end

    bar:ClearAllPoints()
    if anchorPoint == "LEFT" then
        bar:SetPoint("TOPLEFT", widget, "TOPLEFT", 0, 0)
        bar:SetPoint("BOTTOMLEFT", widget, "BOTTOMLEFT", 0, 0)
    else
        bar:SetPoint("TOPRIGHT", widget, "TOPRIGHT", 0, 0)
        bar:SetPoint("BOTTOMRIGHT", widget, "BOTTOMRIGHT", 0, 0)
    end
    bar:SetWidth(barWidth)
    bar._lastBarWidth = barWidth
    return barWidth
end

local function UpdateHealAbsorbDisplay(widget, config, calculator, maxHP)
    local bar = widget.healAbsorbBar
    if not bar then return end

    local glow = widget.healAbsorbOverflowGlow

    if not config.showHealAbsorb or not calculator then
        bar:Hide()
        if glow then glow:Hide() end
        return
    end

    local barWidth = ReanchorAbsorbBar(bar, widget, "LEFT")
    if not barWidth or barWidth <= 0 then return end

    bar:SetReverseFill(false)
    bar:SetMinMaxValues(0, maxHP)

    local amount, clamped = calculator:GetHealAbsorbs()
    bar:SetValue(amount)
    bar:Show()

    UpdateOverflowGlow(glow, config.showHealAbsorbOverflowGlow, clamped)
end

local function UpdateDamageAbsorbDisplay(widget, config, calculator, maxHP)
    local bar = widget.damageAbsorbBar
    if not bar then return end

    local glow = widget.damageAbsorbOverflowGlow

    if not config.showDamageAbsorb or not calculator then
        bar:Hide()
        if glow then glow:Hide() end
        return
    end

    local barWidth = ReanchorAbsorbBar(bar, widget, "RIGHT")
    if not barWidth or barWidth <= 0 then return end

    bar:SetReverseFill(true)
    bar:SetMinMaxValues(0, maxHP)

    local amount, clamped = calculator:GetDamageAbsorbs()
    bar:SetValue(amount)
    bar:Show()

    UpdateOverflowGlow(glow, config.showDamageAbsorbOverflowGlow, clamped)
end

-- The 12.0 calculator's GetIncomingHeals returns zero regardless of how the
-- prediction is populated, so heal prediction goes through the legacy API
-- the way Blizzard's own UnitFrame.lua does. Overflow past missing health is
-- clipped by the HP bar's SetClipsChildren(true) flag set in the factory.
local function UpdateHealPredictionDisplay(widget, config, unit, maxHP)
    local bar = widget.healPredictionBar
    if not bar then return end

    if not config.showHealPrediction or not UnitGetIncomingHeals then
        bar:Hide()
        return
    end

    local hpTex = widget:GetStatusBarTexture()
    local barWidth = widget:GetWidth()
    if not hpTex or not barWidth or barWidth <= 0 then
        bar:Hide()
        return
    end

    if bar._lastBarWidth ~= barWidth or bar._lastAnchorTex ~= hpTex then
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", hpTex, "TOPRIGHT", 0, 0)
        bar:SetPoint("BOTTOMLEFT", hpTex, "BOTTOMRIGHT", 0, 0)
        bar:SetWidth(barWidth)
        bar._lastBarWidth = barWidth
        bar._lastAnchorTex = hpTex
    end

    bar:SetReverseFill(false)
    bar:SetMinMaxValues(0, maxHP)

    local healSource = (config.healPredictionSource == "self") and "player" or nil
    local incoming = UnitGetIncomingHeals(unit, healSource) or 0
    bar:SetValue(incoming)
    bar:Show()
end

local function InvalidateOverlayAnchors(widget)
    if widget.healAbsorbBar then widget.healAbsorbBar._lastBarWidth = nil end
    if widget.damageAbsorbBar then widget.damageAbsorbBar._lastBarWidth = nil end
    if widget.healPredictionBar then
        widget.healPredictionBar._lastBarWidth = nil
        widget.healPredictionBar._lastAnchorTex = nil
    end
end

local function ResolveHealthBarColors(config, unit)
    local r, g, b, a = 0.2, 0.8, 0.2, 1
    local bg = config.backgroundColor
    local bgR, bgG, bgB, bgA = bg.r, bg.g, bg.b, bg.a or 0.8

    if config.colorMode == "class" then
        r, g, b = GetClassColor(unit)
    elseif config.colorMode == "class_inverted" then
        local cc = config.customColor
        r, g, b, a = cc.r, cc.g, cc.b, cc.a or 1
        bgR, bgG, bgB = GetClassColor(unit)
    elseif config.colorMode == "custom" then
        local cc = config.customColor
        r, g, b, a = cc.r, cc.g, cc.b, cc.a or 1
    elseif config.colorMode == "reaction" then
        local reaction = UnitReaction(unit, "player")
        local color = reaction and FACTION_BAR_COLORS[reaction]
        if color then
            r, g, b = color.r, color.g, color.b
        end
    end

    return r, g, b, a, bgR, bgG, bgB, bgA
end

local function PopulateHealthBarValue(widget, config, calculator, unit, maxHealth)
    widget:SetMinMaxValues(0, maxHealth)

    if not (calculator and UnitGetDetailedHealPrediction) then
        widget:SetValue(UnitHealth(unit))
        return
    end

    local healSource = (config.healPredictionSource == "self") and "player" or nil
    UnitGetDetailedHealPrediction(unit, healSource, calculator)
    widget:SetValue(calculator:GetCurrentHealth())
end

function HealthUpdater.UpdateHealthBar(state)
    if not state.customFrame or not state.customFrame.widgets.healthBar then return end

    local widget = state.customFrame.widgets.healthBar
    local config = GetWidgetConfig(state, "healthBar")
    local unit = state.unit

    local maxHealth = UnitHealthMax(unit)
    if not maxHealth then return end

    local r, g, b, a, bgR, bgG, bgB, bgA = ResolveHealthBarColors(config, unit)
    widget.bg:SetVertexColor(bgR, bgG, bgB, bgA)
    widget:SetStatusBarColor(r, g, b, a)

    PopulateHealthBarValue(widget, config, widget.calculator, unit, maxHealth)

    local widthBefore = widget:GetWidth()
    UpdateMaxHealthLossDisplay(widget, config, unit)
    if widget:GetWidth() ~= widthBefore then
        InvalidateOverlayAnchors(widget)
    end

    UpdateHealAbsorbDisplay(widget, config, widget.calculator, maxHealth)
    UpdateDamageAbsorbDisplay(widget, config, widget.calculator, maxHealth)
    UpdateHealPredictionDisplay(widget, config, unit, maxHealth)
end
