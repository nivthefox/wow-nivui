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

function WF.healthBar(parent, config, _style, unit)
    unit = unit or "player"
    local frame = CreateFrame("StatusBar", nil, parent)
    frame:SetSize(config.size.width, config.size.height)
    if config.strata then frame:SetFrameStrata(config.strata) end
    if config.frameLevel then frame:SetFrameLevel(config.frameLevel) end

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

    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    if issecretvalue(maxHealth) or (maxHealth and maxHealth > 0) then
        frame:SetMinMaxValues(0, maxHealth)
        frame:SetValue(health)
    else
        frame:SetMinMaxValues(0, 100000)
        frame:SetValue(71000)
    end

    if config.showAbsorb then
        local absorbBar = CreateFrame("StatusBar", nil, frame)
        absorbBar:SetAllPoints(frame)
        absorbBar:SetFrameLevel((config.frameLevel or 2) + 1)
        absorbBar:SetStatusBarTexture(texturePath)
        absorbBar:SetOrientation(config.orientation or "HORIZONTAL")
        absorbBar:SetReverseFill(true)

        local ac = config.absorbColor or { r = 0.8, g = 0.8, b = 0.2, a = 0.5 }
        absorbBar:SetStatusBarColor(ac.r, ac.g, ac.b, ac.a or 0.5)

        absorbBar:SetMinMaxValues(0, maxHealth or 100000)
        absorbBar:SetValue(0)

        frame.absorbBar = absorbBar
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
    if issecretvalue(maxPower) or (maxPower and maxPower > 0) then
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

    local pct = nil
    if UnitHealthPercent then
        local ok, result = pcall(UnitHealthPercent, unit)
        if ok and result then
            pct = result
        end
    end

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

    local pct = nil
    if UnitPowerPercent then
        local ok, result = pcall(UnitPowerPercent, unit, powerType)
        if ok and result then
            pct = result
        end
    end

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
    frame.filter = (widgetType == "buffs") and "HELPFUL" or "HARMFUL"

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

        icon.duration = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        icon.duration:SetPoint("BOTTOM", 0, -2)

        icon.stacks = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        icon.stacks:SetPoint("BOTTOMRIGHT", 0, 0)

        icon.border = icon:CreateTexture(nil, "OVERLAY")
        icon.border:SetPoint("TOPLEFT", -1, 1)
        icon.border:SetPoint("BOTTOMRIGHT", 1, -1)
        icon.border:SetColorTexture(0, 1, 0, 1)
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
            if config.showDuration then
                icon.duration:SetText(math.random(5, 30) .. "s")
            else
                icon.duration:SetText("")
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
