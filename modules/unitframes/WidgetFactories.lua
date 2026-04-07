NivUI = NivUI or {}
NivUI.WidgetFactories = {}

function NivUI.WidgetFactories.GetClassColor(unit)
    local _, class = UnitClass(unit or "player")
    if class then
        local color = RAID_CLASS_COLORS[class]
        if color then
            return color.r, color.g, color.b
        end
    end
    return 1, 1, 1
end

function NivUI.WidgetFactories.GetPowerColor(unit)
    local powerType = UnitPowerType(unit or "player")
    local color = PowerBarColor[powerType]
    if color then
        return color.r, color.g, color.b
    end
    return 0.2, 0.2, 0.8
end

local WF = NivUI.WidgetFactories

--- Atlas mapping for the temp max health loss bar's "blizzardAtlas" mode.
--- Frame types missing from this table fall back to the healthBarTexture mode.
--- TargetFrame swaps between normal and MinusMob variants at runtime based on
--- target classification — see UpdateMaxHealthLossDisplay in UnitFrameBase.
local TEMP_MAX_HP_LOSS_ATLASES = {
    player       = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-TempHPLoss",
    party        = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-TempHPLoss",
    target       = "UI-HUD-UnitFrame-Target-PortraitOn-Bar-TempHPLoss",
    focus        = "UI-HUD-UnitFrame-Target-PortraitOn-Bar-TempHPLoss",
    targettarget = "UI-HUD-UnitFrame-Target-MinusMob-PortraitOn-Bar-TempHPLoss",
    pet          = "UI-HUD-UnitFrame-Target-MinusMob-PortraitOn-Bar-TempHPLoss",
}

local TEMP_MAX_HP_LOSS_TARGET_MINUS_MOB =
    "UI-HUD-UnitFrame-Target-MinusMob-PortraitOn-Bar-TempHPLoss"

--- Returns the atlas name for a given frame type, or nil if no atlas is
--- defined and the lostMaxBar should fall back to the healthBarTexture mode.
--- Exposed so the per-update path can re-resolve atlases (TargetFrame's
--- classification swap).
--- @param frameType string|nil Frame type token (player, target, party, …)
--- @return string|nil atlasName
function WF.GetTempMaxHealthLossAtlas(frameType)
    if not frameType then return nil end
    return TEMP_MAX_HP_LOSS_ATLASES[frameType]
end

function WF.GetTempMaxHealthLossTargetMinusMobAtlas()
    return TEMP_MAX_HP_LOSS_TARGET_MINUS_MOB
end

--- Creates and returns a configured UnitHealPredictionCalculator if the API
--- is available on this client. The calculator owns its mode state, so this
--- helper applies every mode the health bar relies on.
local function CreateHealthCalculator()
    if not CreateUnitHealPredictionCalculator then return nil end
    local calc = CreateUnitHealPredictionCalculator()
    calc:SetMaximumHealthMode(Enum.UnitMaximumHealthMode.Default)
    calc:SetDamageAbsorbClampMode(Enum.UnitDamageAbsorbClampMode.MaximumHealth)
    calc:SetHealAbsorbClampMode(Enum.UnitHealAbsorbClampMode.MaximumHealth)
    calc:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.Total)
    calc:SetIncomingHealClampMode(Enum.UnitIncomingHealClampMode.MissingHealth)
    calc:SetIncomingHealOverflowPercent(0)
    return calc
end

--- Builds an overlay StatusBar parented to the HP bar. Anchoring is left to
--- the per-update functions because heal absorbs anchor to the HP bar's left
--- edge, damage absorbs anchor to the right edge, and heal prediction anchors
--- to the live health fill texture's right edge.
--- @param hpBar StatusBar The parent health bar
--- @param texturePath string The status bar texture path
--- @param color table { r, g, b, a }
--- @param frameLevel number Absolute frame level (already offset)
--- @return StatusBar overlay
local function CreateOverlayBar(hpBar, texturePath, color, frameLevel)
    local bar = CreateFrame("StatusBar", nil, hpBar)
    bar:SetStatusBarTexture(texturePath)
    bar:SetOrientation("HORIZONTAL")
    bar:SetFrameLevel(frameLevel)
    bar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
    bar:Hide()
    return bar
end

--- Builds a thin glow texture anchored to one edge of the HP bar. Visibility
--- is driven later by the calculator's `clamped` flag, which is a plain Lua
--- boolean and safe to test.
--- @param hpBar StatusBar The parent health bar
--- @param edge string "LEFT" or "RIGHT"
--- @param color table { r, g, b, a }
--- @param width number Pixel width of the glow
--- @param frameLevel number Absolute frame level
--- @return Frame glow A frame holding the glow texture
local function CreateOverflowGlow(hpBar, edge, color, width, frameLevel)
    local glow = CreateFrame("Frame", nil, hpBar)
    glow:SetFrameLevel(frameLevel)
    glow:SetWidth(width)
    if edge == "LEFT" then
        glow:SetPoint("TOPLEFT", hpBar, "TOPLEFT", 0, 0)
        glow:SetPoint("BOTTOMLEFT", hpBar, "BOTTOMLEFT", 0, 0)
    else
        glow:SetPoint("TOPRIGHT", hpBar, "TOPRIGHT", 0, 0)
        glow:SetPoint("BOTTOMRIGHT", hpBar, "BOTTOMRIGHT", 0, 0)
    end
    local tex = glow:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\Buttons\\WHITE8x8")
    tex:SetVertexColor(color.r, color.g, color.b, color.a or 1)
    tex:SetAllPoints(glow)
    glow.texture = tex
    glow:Hide()
    return glow
end

function WF.healthBar(parent, config, _style, unit, options)
    unit = unit or "player"
    options = options or {}
    local frame = CreateFrame("StatusBar", nil, parent)
    frame:SetSize(config.size.width, config.size.height)
    if config.strata then frame:SetFrameStrata(config.strata) end
    if config.frameLevel then frame:SetFrameLevel(config.frameLevel) end

    -- Original pixel width is the reference used by the max HP loss display
    -- to compute the shrunken HP bar width. Captured here at construction so
    -- the per-update path can restore it without re-reading config.
    frame.originalHpBarWidth = config.size.width

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.bg:SetAllPoints(frame)

    local texturePath = NivUI:GetTexturePath(config.texture)
    frame:SetStatusBarTexture(texturePath)
    frame:SetOrientation(config.orientation or "HORIZONTAL")
    frame:SetReverseFill(config.reverseFill or false)

    local r, g, b, a = 0.2, 0.8, 0.2, 1
    local bgR, bgG, bgB, bgA = config.backgroundColor.r, config.backgroundColor.g, config.backgroundColor.b, config.backgroundColor.a or 0.8

    if config.colorMode == "class" then
        r, g, b = WF.GetClassColor(unit)
    elseif config.colorMode == "class_inverted" then
        r, g, b, a = config.customColor.r, config.customColor.g, config.customColor.b, config.customColor.a or 1
        bgR, bgG, bgB = WF.GetClassColor(unit)
    elseif config.colorMode == "custom" then
        r, g, b, a = config.customColor.r, config.customColor.g, config.customColor.b, config.customColor.a or 1
    end

    frame.bg:SetVertexColor(bgR, bgG, bgB, bgA)
    frame:SetStatusBarColor(r, g, b, a)

    local maxHealth = UnitHealthMax(unit)
    if maxHealth and (issecretvalue(maxHealth) or maxHealth > 0) then
        frame:SetMinMaxValues(0, maxHealth)
        frame:SetValue(UnitHealth(unit))
    else
        frame:SetMinMaxValues(0, 100000)
        frame:SetValue(71000)
    end

    -- Calculator + frame type are stored on the bar so the per-update path
    -- in UnitFrameBase can reach them without piping through state.
    frame.calculator = CreateHealthCalculator()
    frame.frameType = options.frameType
    frame.texturePath = texturePath

    local baseLevel = frame:GetFrameLevel()

    -- Lost max bar — sibling to the HP bar in the parent's coordinate space,
    -- anchored to the HP bar's TOPLEFT/BOTTOMLEFT, fixed at the original
    -- width. As the HP bar shrinks via SetWidth, this bar continues to
    -- occupy the original area and reverse-fills its right portion to show
    -- the lost max region. Frame level is one below the HP bar so the HP
    -- bar paints over it where they overlap.
    do
        local lostMaxBar = CreateFrame("StatusBar", nil, parent)
        lostMaxBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        lostMaxBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        lostMaxBar:SetWidth(frame.originalHpBarWidth)
        lostMaxBar:SetFrameStrata(frame:GetFrameStrata())
        lostMaxBar:SetFrameLevel(math.max(0, baseLevel - 1))
        lostMaxBar:SetMinMaxValues(0, 1)
        lostMaxBar:SetValue(0)
        lostMaxBar:SetReverseFill(true)
        lostMaxBar:Hide()
        -- Texture is applied in the per-update path so style changes and
        -- TargetFrame's runtime classification swap reach it without a rebuild.
        frame.lostMaxBar = lostMaxBar
    end

    -- Heal absorb overlay — left edge, forward fill, frame level above the HP bar.
    do
        local color = config.healAbsorbColor or { r = 0.4, g = 0.1, b = 0.1, a = 0.85 }
        local offset = config.healAbsorbFrameLevelOffset or 3
        local bar = CreateOverlayBar(frame, texturePath, color, baseLevel + offset)
        frame.healAbsorbBar = bar

        local glowColor = config.healAbsorbOverflowGlowColor or { r = 1.0, g = 0.2, b = 0.2, a = 0.8 }
        local glowWidth = config.healAbsorbOverflowGlowWidth or 3
        frame.healAbsorbOverflowGlow = CreateOverflowGlow(frame, "LEFT", glowColor, glowWidth, baseLevel + offset + 1)
    end

    -- Damage absorb overlay — right edge, reverse fill, replaces the legacy
    -- absorbBar field entirely. The new bar lives on the calculator pipeline.
    do
        local color = config.absorbColor or { r = 0.8, g = 0.8, b = 0.2, a = 0.5 }
        local offset = config.damageAbsorbFrameLevelOffset or 2
        local bar = CreateOverlayBar(frame, texturePath, color, baseLevel + offset)
        bar:SetReverseFill(true)
        frame.damageAbsorbBar = bar

        local glowColor = config.damageAbsorbOverflowGlowColor or { r = 1.0, g = 0.8, b = 0.2, a = 0.8 }
        local glowWidth = config.damageAbsorbOverflowGlowWidth or 3
        frame.damageAbsorbOverflowGlow = CreateOverflowGlow(frame, "RIGHT", glowColor, glowWidth, baseLevel + offset + 1)
    end

    -- Heal prediction overlay — left edge anchors to the live health fill
    -- texture's right edge in the per-update path. Forward fill.
    do
        local color = config.healPredictionColor or { r = 0.4, g = 1.0, b = 0.4, a = 0.5 }
        local offset = config.healPredictionFrameLevelOffset or 1
        local bar = CreateOverlayBar(frame, texturePath, color, baseLevel + offset)
        frame.healPredictionBar = bar
    end

    frame.widgetType = "healthBar"
    return frame
end

function WF.powerBar(parent, config, _style, unit)
    unit = unit or "player"
    local frame = CreateFrame("StatusBar", nil, parent)
    frame:SetSize(config.size.width, config.size.height)
    if config.strata then frame:SetFrameStrata(config.strata) end
    if config.frameLevel then frame:SetFrameLevel(config.frameLevel) end

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.bg:SetAllPoints(frame)
    local bgColor = config.backgroundColor
    frame.bg:SetVertexColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)

    local texturePath = NivUI:GetTexturePath(config.texture)
    frame:SetStatusBarTexture(texturePath)
    frame:SetOrientation(config.orientation or "HORIZONTAL")
    frame:SetReverseFill(config.reverseFill or false)

    local r, g, b, a = 0.2, 0.2, 0.8, 1
    if config.colorMode == "power" then
        r, g, b = WF.GetPowerColor(unit)
    elseif config.colorMode == "class" then
        r, g, b = WF.GetClassColor(unit)
    elseif config.colorMode == "custom" then
        r, g, b, a = config.customColor.r, config.customColor.g, config.customColor.b, config.customColor.a or 1
    end
    frame:SetStatusBarColor(r, g, b, a)

    local powerType = UnitPowerType(unit)
    local power = UnitPower(unit, powerType)
    local maxPower = UnitPowerMax(unit, powerType)
    if maxPower and (issecretvalue(maxPower) or maxPower > 0) then
        frame:SetMinMaxValues(0, maxPower)
        frame:SetValue(power)
    else
        frame:SetMinMaxValues(0, 100)
        frame:SetValue(80)
    end

    frame.widgetType = "powerBar"
    return frame
end

function WF.portrait(parent, config, _style, unit)
    unit = unit or "player"
    local frame

    if config.mode == "3D" then
        frame = CreateFrame("PlayerModel", nil, parent)
        frame:SetSize(config.size.width, config.size.height)
        frame:SetUnit(unit)
        frame:SetPortraitZoom(1)
    elseif config.mode == "class" then
        frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(config.size.width, config.size.height)
        frame.texture = frame:CreateTexture(nil, "ARTWORK")
        frame.texture:SetAllPoints()

        local _, class = UnitClass(unit)
        if class then
            local coords = CLASS_ICON_TCOORDS[class]
            if coords then
                frame.texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                frame.texture:SetTexCoord(unpack(coords))
            end
        end
    else
        frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(config.size.width, config.size.height)
        frame.texture = frame:CreateTexture(nil, "ARTWORK")
        frame.texture:SetAllPoints()
        SetPortraitTexture(frame.texture, unit)
    end

    if config.strata then frame:SetFrameStrata(config.strata) end
    if config.frameLevel then frame:SetFrameLevel(config.frameLevel) end

    if config.borderWidth > 0 then
        frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.border:SetPoint("TOPLEFT", -config.borderWidth, config.borderWidth)
        frame.border:SetPoint("BOTTOMRIGHT", config.borderWidth, -config.borderWidth)
        frame.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = config.borderWidth,
        })
        local bc = config.borderColor
        frame.border:SetBackdropBorderColor(bc.r, bc.g, bc.b, bc.a or 1)
    end

    if config.shape == "circle" then
        local mask = frame:CreateMaskTexture()
        mask:SetAllPoints()
        mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        if frame.texture then
            frame.texture:AddMaskTexture(mask)
        elseif frame.SetMask then
            frame:SetMask("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
        end
    end

    frame.widgetType = "portrait"
    return frame
end

local function CreateTextWidget(parent, config, textValue, widgetType, unit)
    unit = unit or "player"
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(200, config.fontSize + 4)
    if config.strata then frame:SetFrameStrata(config.strata) end
    if config.frameLevel then frame:SetFrameLevel(config.frameLevel) end

    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetAllPoints(frame)
    local fontPath = NivUI:GetFontPath(config.font)
    frame.text:SetFont(fontPath, config.fontSize, config.fontOutline or "")

    local alignment = config.alignment or "CENTER"
    frame.text:SetJustifyH(alignment)
    frame.text:SetJustifyV("MIDDLE")
    frame.text:SetText(textValue)

    local color = config.color or config.customColor or { r = 1, g = 1, b = 1, a = 1 }
    if config.colorByClass then
        local r, g, b = WF.GetClassColor(unit)
        frame.text:SetTextColor(r, g, b, color.a or 1)
    else
        frame.text:SetTextColor(color.r, color.g, color.b, color.a or 1)
    end

    frame.widgetType = widgetType
    return frame
end

function WF.nameText(parent, config, _style, unit)
    unit = unit or "player"
    local name = UnitName(unit) or "Player"
    if not issecretvalue(name) and config.truncateLength and #name > config.truncateLength then
        name = name:sub(1, config.truncateLength)
    end
    return CreateTextWidget(parent, config, name, "nameText", unit)
end

function WF.levelText(parent, config, _style, unit)
    unit = unit or "player"
    local level = UnitLevel(unit)
    local text = level == -1 and "??" or tostring(level)
    local frame = CreateTextWidget(parent, config, text, "levelText", unit)

    if config.colorByDifficulty then
        local color = GetQuestDifficultyColor(level)
        if color then
            frame.text:SetTextColor(color.r, color.g, color.b)
        end
    end

    return frame
end

function WF.healthText(parent, config, _style, unit)
    unit = unit or "player"
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    local text = ""

    local pct = UnitHealthPercent and UnitHealthPercent(unit) or nil

    local abbrev = AbbreviateLargeNumbers or AbbreviateNumbers or tostring
    local healthStr = health ~= nil and abbrev(health) or "71000"
    local maxHealthStr = maxHealth ~= nil and abbrev(maxHealth) or "100000"

    if config.format == "current" then
        text = healthStr
    elseif config.format == "percent" then
        text = pct and string.format("%.0f%%", pct) or "71%"
    elseif config.format == "current_percent" then
        text = pct and string.format("%s (%.0f%%)", healthStr, pct) or "71000 (71%)"
    elseif config.format == "current_max" then
        text = healthStr .. " / " .. maxHealthStr
    elseif config.format == "deficit" then
        if issecretvalue(health) then
            text = ""
        else
            local deficit = (maxHealth or 0) - (health or 0)
            if deficit > 0 then
                text = "-" .. abbrev(deficit)
            else
                text = ""
            end
        end
    end

    return CreateTextWidget(parent, config, text, "healthText", unit)
end

function WF.powerText(parent, config, _style, unit)
    unit = unit or "player"
    local powerType = UnitPowerType(unit)
    local power = UnitPower(unit, powerType)
    local maxPower = UnitPowerMax(unit, powerType)
    local text = ""

    local pct = UnitPowerPercent and UnitPowerPercent(unit, powerType) or nil

    local abbrev = AbbreviateLargeNumbers or AbbreviateNumbers or tostring
    local powerStr = power ~= nil and abbrev(power) or "80"
    local maxPowerStr = maxPower ~= nil and abbrev(maxPower) or "100"

    if config.format == "current" then
        text = powerStr
    elseif config.format == "percent" then
        text = pct and string.format("%.0f%%", pct) or "80%"
    elseif config.format == "current_percent" then
        text = pct and string.format("%s (%.0f%%)", powerStr, pct) or "80 (80%)"
    elseif config.format == "current_max" then
        text = powerStr .. " / " .. maxPowerStr
    end

    return CreateTextWidget(parent, config, text, "powerText", unit)
end

function WF.statusIndicators(parent, config, _style, _unit, options)
    options = options or {}
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(config.iconSize * 2, config.iconSize)
    if config.strata then frame:SetFrameStrata(config.strata) end
    if config.frameLevel then frame:SetFrameLevel(config.frameLevel) end

    frame.combat = frame:CreateTexture(nil, "OVERLAY")
    frame.combat:SetSize(config.iconSize, config.iconSize)
    frame.combat:SetPoint("LEFT")
    frame.combat:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    frame.combat:SetTexCoord(0.5, 1, 0, 0.5)

    frame.resting = frame:CreateTexture(nil, "OVERLAY")
    frame.resting:SetSize(config.iconSize, config.iconSize)
    frame.resting:SetPoint("LEFT", frame.combat, "RIGHT", 2, 0)
    frame.resting:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    frame.resting:SetTexCoord(0, 0.5, 0, 0.5)

    if options.forPreview then
        frame.combat:SetAlpha(0.3)
        frame.resting:SetAlpha(0.3)
    else
        frame.combat:Hide()
        frame.resting:Hide()
    end

    frame.widgetType = "statusIndicators"
    return frame
end

function WF.statusText(parent, config, _style, _unit, options)
    options = options or {}
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(100, 20)
    if config.strata then frame:SetFrameStrata(config.strata) end
    if config.frameLevel then frame:SetFrameLevel(config.frameLevel) end

    frame.text = frame:CreateFontString(nil, "OVERLAY", config.font or "GameFontNormalLarge")
    frame.text:SetAllPoints()
    frame.text:SetText("")

    if options.forPreview then
        frame.text:SetText("AFK")
        if config.color and config.color.afk then
            frame.text:SetTextColor(config.color.afk.r, config.color.afk.g, config.color.afk.b)
        end
    end

    frame.widgetType = "statusText"
    return frame
end

function WF.leaderIcon(parent, config, _style, unit, options)
    options = options or {}
    unit = unit or "player"
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(config.size, config.size)
    if config.strata then frame:SetFrameStrata(config.strata) end
    if config.frameLevel then frame:SetFrameLevel(config.frameLevel) end

    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetAllPoints()
    frame.icon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")

    local isLeader = UnitIsGroupLeader(unit)
    local isAssist = UnitIsGroupAssistant and UnitIsGroupAssistant(unit)
    if isLeader or isAssist then
        if isAssist and not isLeader then
            frame.icon:SetTexture("Interface\\GroupFrame\\UI-Group-AssistantIcon")
        end
    elseif options.forPreview then
        frame.icon:SetAlpha(0.3)
    else
        frame:Hide()
    end

    frame.widgetType = "leaderIcon"
    return frame
end

function WF.raidMarker(parent, config, _style, unit, options)
    options = options or {}
    unit = unit or "player"
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(config.size, config.size)
    if config.strata then frame:SetFrameStrata(config.strata) end
    if config.frameLevel then frame:SetFrameLevel(config.frameLevel) end

    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetAllPoints()
    frame.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")

    local index = GetRaidTargetIndex(unit)
    if index then
        SetRaidTargetIconTexture(frame.icon, index)
    elseif options.forPreview then
        SetRaidTargetIconTexture(frame.icon, 8)
        frame.icon:SetAlpha(0.3)
    else
        frame:Hide()
    end

    frame.widgetType = "raidMarker"
    return frame
end

function WF.roleIcon(parent, config, _style, unit, options)
    options = options or {}
    unit = unit or "player"
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(config.size, config.size)
    if config.strata then frame:SetFrameStrata(config.strata) end
    if config.frameLevel then frame:SetFrameLevel(config.frameLevel) end

    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetAllPoints()

    local role = UnitGroupRolesAssigned(unit)
    if role and role ~= "NONE" and GetMicroIconForRole then
        local atlas = GetMicroIconForRole(role)
        if atlas then
            frame.icon:SetAtlas(atlas)
        end
    elseif options.forPreview then
        if GetMicroIconForRole then
            frame.icon:SetAtlas(GetMicroIconForRole("TANK"))
        end
        frame.icon:SetAlpha(0.3)
    else
        frame:Hide()
    end

    frame.widgetType = "roleIcon"
    return frame
end

function WF.castbar(parent, config, _style, _unit)
    local frame = CreateFrame("StatusBar", nil, parent)
    frame:SetSize(config.size.width, config.size.height)
    if config.strata then frame:SetFrameStrata(config.strata) end
    if config.frameLevel then frame:SetFrameLevel(config.frameLevel) end

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.bg:SetAllPoints(frame)
    local bgColor = config.backgroundColor
    frame.bg:SetVertexColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)

    local texturePath = NivUI:GetTexturePath(config.texture)
    frame:SetStatusBarTexture(texturePath)
    frame:SetMinMaxValues(0, 1)

    frame:SetOrientation(config.orientation or "HORIZONTAL")
    frame:SetReverseFill(config.reverseFill or false)

    frame:SetValue(0.6)

    local color = config.castingColor
    frame:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)

    if config.showIcon then
        frame.icon = frame:CreateTexture(nil, "ARTWORK")
        frame.icon:SetSize(config.size.height, config.size.height)
        frame.icon:SetPoint("RIGHT", frame, "LEFT", -2, 0)
        frame.icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
    end

    if config.showSpellName then
        frame.spellName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.spellName:SetPoint("LEFT", 4, 0)
        frame.spellName:SetText("Lightning Bolt")
    end

    if config.showTimer then
        frame.timer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.timer:SetPoint("RIGHT", -4, 0)
        frame.timer:SetText("1.2s")
    end

    frame.StagePoints = {}
    frame.StagePips = {}
    frame.StageTiers = {}
    frame.NumStages = 0
    frame.CurrSpellStage = -1

    function frame:AddStages(numStages, unit, totalDurationMS)
        self:ClearStages()

        self.NumStages = numStages + 1  -- +1 for hold phase
        self.CurrSpellStage = -1

        local barWidth = self:GetWidth()
        local barHeight = self:GetHeight()
        local sumDuration = 0

        for i = 1, self.NumStages - 1 do
            local stageDuration = GetUnitEmpowerStageDuration(unit, i - 1)
            if stageDuration and not issecretvalue(stageDuration) and stageDuration > 0 then
                sumDuration = sumDuration + stageDuration
                self.StagePoints[i] = sumDuration

                local offset = (sumDuration / totalDurationMS) * barWidth

                local pip = self.StagePips[i]
                if not pip then
                    pip = self:CreateTexture(nil, "OVERLAY")
                    pip:SetTexture("Interface\\Buttons\\WHITE8x8")
                    pip:SetVertexColor(1, 1, 1, 0.8)
                    pip:SetSize(2, barHeight)
                    self.StagePips[i] = pip
                end
                pip:ClearAllPoints()
                pip:SetPoint("CENTER", self, "LEFT", offset, 0)
                pip:Show()

                local tier = self.StageTiers[i]
                if not tier then
                    tier = CreateFrame("Frame", nil, self)
                    tier.Normal = tier:CreateTexture(nil, "ARTWORK", nil, 1)
                    tier.Normal:SetAllPoints()
                    tier.Normal:SetTexture("Interface\\Buttons\\WHITE8x8")
                    tier.Disabled = tier:CreateTexture(nil, "ARTWORK", nil, 0)
                    tier.Disabled:SetAllPoints()
                    tier.Disabled:SetTexture("Interface\\Buttons\\WHITE8x8")
                    tier.Disabled:SetVertexColor(0.3, 0.3, 0.3, 0.6)
                    tier.Glow = tier:CreateTexture(nil, "OVERLAY")
                    tier.Glow:SetAllPoints()
                    tier.Glow:SetTexture("Interface\\Buttons\\WHITE8x8")
                    tier.Glow:SetBlendMode("ADD")
                    tier.Glow:SetAlpha(0)
                    self.StageTiers[i] = tier
                end

                local prevOffset = i > 1 and ((self.StagePoints[i - 1] / totalDurationMS) * barWidth) or 0
                tier:SetPoint("TOPLEFT", self, "TOPLEFT", prevOffset, 0)
                tier:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", offset, 0)

                local r, g, b = self:GetStatusBarColor()
                tier.Normal:SetVertexColor(r, g, b, 1)

                tier.Normal:Hide()
                tier.Disabled:Show()
                tier:Show()
            end
        end
    end

    function frame:ClearStages()
        for _, pip in pairs(self.StagePips) do
            pip:Hide()
        end
        for _, tier in pairs(self.StageTiers) do
            tier:Hide()
        end
        self.NumStages = 0
        self.CurrSpellStage = -1
        wipe(self.StagePoints)
    end

    function frame:UpdateStage(elapsedSec)
        if self.NumStages <= 0 then return end

        local elapsedMS = elapsedSec * 1000
        local maxStage = 0

        for i = 1, self.NumStages - 1 do
            if self.StagePoints[i] and elapsedMS > self.StagePoints[i] then
                maxStage = i
            else
                break
            end
        end

        if maxStage > self.CurrSpellStage and maxStage > 0 then
            self.CurrSpellStage = maxStage

            local tier = self.StageTiers[maxStage]
            if tier then
                tier.Normal:Show()
                tier.Disabled:Hide()

                tier.Glow:SetAlpha(1)
                C_Timer.After(0.1, function()
                    if tier.Glow then
                        tier.Glow:SetAlpha(0)
                    end
                end)
            end
        end
    end

    frame.widgetType = "castbar"
    return frame
end

--- Dispel type index → Blizzard color object mapping.
--- Used to build the step-curve for C_UnitAuras.GetAuraDispelTypeColor().
local _debuffColorByIndex = {
    [0] = _G.DEBUFF_TYPE_NONE_COLOR,
    [1] = _G.DEBUFF_TYPE_MAGIC_COLOR,
    [2] = _G.DEBUFF_TYPE_CURSE_COLOR,
    [3] = _G.DEBUFF_TYPE_DISEASE_COLOR,
    [4] = _G.DEBUFF_TYPE_POISON_COLOR,
    [5] = _G.DEBUFF_TYPE_BLEED_COLOR,
}

--- Step-curve for GetAuraDispelTypeColor(). Built once at load time, reused for every call.
--- Returns nil if C_CurveUtil is unavailable (older clients, PTR changes).
local _debuffColorCurve
do
    local ok, curve = pcall(function()
        if not C_CurveUtil or not C_CurveUtil.CreateColorCurve then return nil end
        if not Enum or not Enum.LuaCurveType or not Enum.LuaCurveType.Step then return nil end
        local c = C_CurveUtil.CreateColorCurve()
        c:SetType(Enum.LuaCurveType.Step)
        for idx, col in pairs(_debuffColorByIndex) do
            if col then c:AddPoint(idx, col) end
        end
        return c
    end)
    _debuffColorCurve = ok and curve or nil
end

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.DebuffColorCurve = _debuffColorCurve

local function CreateAuraWidget(parent, config, widgetType, unit, options)
    options = options or {}
    local forPreview = options.forPreview
    local frame = CreateFrame("Frame", nil, parent)
    if config.strata then frame:SetFrameStrata(config.strata) end
    if config.frameLevel then frame:SetFrameLevel(config.frameLevel) end

    local iconSize = config.iconSize
    local spacing = config.spacing
    local perRow = config.perRow
    local maxIcons = config.maxIcons

    local totalWidth = (iconSize + spacing) * math.min(maxIcons, perRow) - spacing
    local rows = math.ceil(maxIcons / perRow)
    local totalHeight = (iconSize + spacing) * rows - spacing

    frame:SetSize(totalWidth, totalHeight)
    frame.icons = {}
    frame.config = config
    frame.unit = unit
    frame.filter = (widgetType == "buffs") and "HELPFUL"
        or (widgetType == "importantDebuffs") and "HARMFUL|RAID"
        or "HARMFUL"

    local iconAnchor = (config.growth == "LEFT") and "TOPRIGHT" or "TOPLEFT"

    for i = 1, maxIcons do
        local icon = CreateFrame("Frame", nil, frame)
        icon:SetSize(iconSize, iconSize)

        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow

        local xOffset = (config.growth == "LEFT") and -col or col
        xOffset = xOffset * (iconSize + spacing)
        local yOffset = -row * (iconSize + spacing)

        icon:SetPoint(iconAnchor, frame, iconAnchor, xOffset, yOffset)

        icon.texture = icon:CreateTexture(nil, "ARTWORK")
        icon.texture:SetAllPoints()

        icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
        icon.cooldown:SetAllPoints()
        icon.cooldown:SetDrawEdge(false)
        icon.cooldown:SetHideCountdownNumbers(not config.showDuration)

        icon.stacks = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        icon.stacks:SetPoint("BOTTOMRIGHT", 0, 0)

        icon.border = icon:CreateTexture(nil, "OVERLAY")
        icon.border:SetPoint("TOPLEFT", -1, 1)
        icon.border:SetPoint("BOTTOMRIGHT", 1, -1)
        icon.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
        icon.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)
        icon.border:Hide()

        if not forPreview then
            icon:Hide()
        end

        table.insert(frame.icons, icon)
    end

    frame.widgetType = widgetType
    return frame
end

local TEST_BUFFS = {
    "Interface\\Icons\\Spell_Holy_WordFortitude",
    "Interface\\Icons\\Spell_Nature_Regeneration",
    "Interface\\Icons\\Spell_Holy_ArcaneIntellect",
    "Interface\\Icons\\Ability_Warrior_BattleShout",
}

local TEST_DEBUFFS = {
    "Interface\\Icons\\Spell_Shadow_CurseOfTounAA",
    "Interface\\Icons\\Spell_Shadow_UnholyFrenzy",
}

local function PopulateTestAuras(frame, testAuras)
    local config = frame.config
    for i, icon in ipairs(frame.icons) do
        if i <= #testAuras then
            icon.texture:SetTexture(testAuras[i])
            if config.showDuration and icon.cooldown then
                local fakeDuration = math.random(10, 60)
                icon.cooldown:SetCooldown(GetTime(), fakeDuration)
            elseif icon.cooldown then
                icon.cooldown:SetCooldown(0, 0)
            end
            if config.showStacks and math.random() > 0.5 then
                icon.stacks:SetText(math.random(2, 5))
            else
                icon.stacks:SetText("")
            end
            icon:Show()
        else
            icon:Hide()
        end
    end
end

function WF.buffs(parent, config, _style, unit, options)
    local frame = CreateAuraWidget(parent, config, "buffs", unit, options)
    if options and options.forPreview then
        PopulateTestAuras(frame, TEST_BUFFS)
    end
    return frame
end

function WF.debuffs(parent, config, _style, unit, options)
    local frame = CreateAuraWidget(parent, config, "debuffs", unit, options)
    if options and options.forPreview then
        PopulateTestAuras(frame, TEST_DEBUFFS)
    end
    return frame
end

function WF.importantDebuffs(parent, config, _style, unit, options)
    local frame = CreateAuraWidget(parent, config, "importantDebuffs", unit, options)
    if options and options.forPreview then
        PopulateTestAuras(frame, TEST_DEBUFFS)
    end
    return frame
end
