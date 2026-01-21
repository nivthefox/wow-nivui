-- NivUI Components: Designer
-- Platynator-style interactive preview for unit frame styles

NivUI = NivUI or {}
NivUI.Designer = {}

local PREVIEW_SCALE = 1.0
local SELECTION_COLOR = { r = 0.2, g = 0.6, b = 1, a = 0.8 }
local SNAP_THRESHOLD = 5

--------------------------------------------------------------------------------
-- Widget Factories
--------------------------------------------------------------------------------

local WidgetFactories = {}

-- Helper to safely get a number (handles WoW's "secret" values)
-- WoW's secret values can pass type() == "number" but still fail arithmetic
-- So we use pcall to actually test if the value can be used
local function SafeNumber(value, fallback)
    if value == nil then
        return fallback or 0
    end
    -- Try to perform arithmetic - this catches secret values that claim to be numbers
    local success, result = pcall(function() return value + 0 end)
    if success then
        return result
    end
    return fallback or 0
end

-- Helper to get class color
local function GetClassColor(unit)
    local _, class = UnitClass(unit or "player")
    if class then
        local color = RAID_CLASS_COLORS[class]
        if color then
            return color.r, color.g, color.b
        end
    end
    return 1, 1, 1
end

-- Helper to get power color
local function GetPowerColor(unit)
    local powerType = UnitPowerType(unit or "player")
    local color = PowerBarColor[powerType]
    if color then
        return color.r, color.g, color.b
    end
    return 0.2, 0.2, 0.8
end

-- Health Bar Factory
function WidgetFactories.healthBar(parent, config, style)
    local frame = CreateFrame("StatusBar", nil, parent)
    frame:SetSize(config.size.width, config.size.height)

    -- Background texture (use WHITE8x8 + SetVertexColor like MSUF does)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.bg:SetAllPoints(frame)

    -- Bar texture
    local texturePath = NivUI:GetTexturePath(config.texture)
    frame:SetStatusBarTexture(texturePath)
    frame:SetMinMaxValues(0, 1)

    -- Apply color based on mode
    local r, g, b = 0.2, 0.8, 0.2
    local bgR, bgG, bgB, bgA = config.backgroundColor.r, config.backgroundColor.g, config.backgroundColor.b, config.backgroundColor.a or 0.8

    if config.colorMode == "class" then
        r, g, b = GetClassColor("player")
    elseif config.colorMode == "class_inverted" then
        -- Inverted: foreground uses custom color, background uses class color
        r, g, b = config.customColor.r, config.customColor.g, config.customColor.b
        bgR, bgG, bgB = GetClassColor("player")
    elseif config.colorMode == "custom" then
        r, g, b = config.customColor.r, config.customColor.g, config.customColor.b
    end

    frame.bg:SetVertexColor(bgR, bgG, bgB, bgA)
    frame:SetStatusBarColor(r, g, b)

    -- Set value from live data (handle secret/nil values)
    local health = SafeNumber(UnitHealth("player"), 71000)
    local maxHealth = SafeNumber(UnitHealthMax("player"), 100000)
    if maxHealth > 0 then
        frame:SetValue(health / maxHealth)
    else
        frame:SetValue(0.71)  -- Preview value
    end

    frame.widgetType = "healthBar"
    return frame
end

-- Power Bar Factory
function WidgetFactories.powerBar(parent, config, style)
    local frame = CreateFrame("StatusBar", nil, parent)
    frame:SetSize(config.size.width, config.size.height)

    -- Background texture (use WHITE8x8 + SetVertexColor like MSUF does)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.bg:SetAllPoints(frame)
    local bgColor = config.backgroundColor
    frame.bg:SetVertexColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)

    -- Bar texture
    local texturePath = NivUI:GetTexturePath(config.texture)
    frame:SetStatusBarTexture(texturePath)
    frame:SetMinMaxValues(0, 1)

    -- Apply color based on mode
    local r, g, b = 0.2, 0.2, 0.8
    if config.colorMode == "power" then
        r, g, b = GetPowerColor("player")
    elseif config.colorMode == "class" then
        r, g, b = GetClassColor("player")
    elseif config.colorMode == "custom" then
        r, g, b = config.customColor.r, config.customColor.g, config.customColor.b
    end
    frame:SetStatusBarColor(r, g, b)

    -- Set value from live data (handle secret/nil values)
    local power = SafeNumber(UnitPower("player"), 80)
    local maxPower = SafeNumber(UnitPowerMax("player"), 100)
    if maxPower > 0 then
        frame:SetValue(power / maxPower)
    else
        frame:SetValue(0.8)  -- Preview value
    end

    frame.widgetType = "powerBar"
    return frame
end

-- Portrait Factory
function WidgetFactories.portrait(parent, config, style)
    local frame

    if config.mode == "3D" then
        frame = CreateFrame("PlayerModel", nil, parent)
        frame:SetSize(config.size.width, config.size.height)
        frame:SetUnit("player")
        frame:SetPortraitZoom(1)
    elseif config.mode == "class" then
        frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(config.size.width, config.size.height)
        frame.texture = frame:CreateTexture(nil, "ARTWORK")
        frame.texture:SetAllPoints()

        local _, class = UnitClass("player")
        if class then
            local coords = CLASS_ICON_TCOORDS[class]
            if coords then
                frame.texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                frame.texture:SetTexCoord(unpack(coords))
            end
        end
    else
        -- 2D texture
        frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(config.size.width, config.size.height)
        frame.texture = frame:CreateTexture(nil, "ARTWORK")
        frame.texture:SetAllPoints()
        SetPortraitTexture(frame.texture, "player")
    end

    -- Border
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

    -- Circle mask for circle shape
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

-- Text Factory (generic for name, level, health, power text)
local function CreateTextWidget(parent, config, textValue, widgetType)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(100, config.fontSize + 4)

    frame.text = frame:CreateFontString(nil, "OVERLAY")
    local fontPath = NivUI:GetFontPath(config.font)
    frame.text:SetFont(fontPath, config.fontSize, config.fontOutline or "")
    frame.text:SetPoint("LEFT")
    frame.text:SetText(textValue)

    -- Color
    local color = config.color or config.customColor or { r = 1, g = 1, b = 1 }
    if config.colorByClass then
        local r, g, b = GetClassColor("player")
        frame.text:SetTextColor(r, g, b)
    else
        frame.text:SetTextColor(color.r, color.g, color.b)
    end

    frame.widgetType = widgetType
    return frame
end

function WidgetFactories.nameText(parent, config, style)
    local name = UnitName("player") or "Player"
    if config.truncateLength and #name > config.truncateLength then
        name = name:sub(1, config.truncateLength) .. "..."
    end
    return CreateTextWidget(parent, config, name, "nameText")
end

function WidgetFactories.levelText(parent, config, style)
    local level = UnitLevel("player")
    local text = level == -1 and "??" or tostring(level)
    local frame = CreateTextWidget(parent, config, text, "levelText")

    if config.colorByDifficulty then
        local color = GetQuestDifficultyColor(level)
        if color then
            frame.text:SetTextColor(color.r, color.g, color.b)
        end
    end

    return frame
end

function WidgetFactories.healthText(parent, config, style)
    local health = SafeNumber(UnitHealth("player"), 71000)
    local maxHealth = SafeNumber(UnitHealthMax("player"), 100000)
    local text = ""

    if maxHealth == 0 then maxHealth = 100000 end  -- Fallback

    if config.format == "current" then
        text = AbbreviateNumbers(health)
    elseif config.format == "percent" then
        text = math.floor((health / maxHealth) * 100) .. "%"
    elseif config.format == "current_percent" then
        text = AbbreviateNumbers(health) .. " (" .. math.floor((health / maxHealth) * 100) .. "%)"
    elseif config.format == "current_max" then
        text = AbbreviateNumbers(health) .. " / " .. AbbreviateNumbers(maxHealth)
    elseif config.format == "deficit" then
        local deficit = maxHealth - health
        text = deficit > 0 and "-" .. AbbreviateNumbers(deficit) or ""
    end

    return CreateTextWidget(parent, config, text, "healthText")
end

function WidgetFactories.powerText(parent, config, style)
    local power = SafeNumber(UnitPower("player"), 80)
    local maxPower = SafeNumber(UnitPowerMax("player"), 100)
    local text = ""

    if config.format == "current" then
        text = tostring(power)
    elseif config.format == "percent" then
        text = maxPower > 0 and (math.floor((power / maxPower) * 100) .. "%") or ""
    elseif config.format == "current_percent" then
        text = maxPower > 0 and (power .. " (" .. math.floor((power / maxPower) * 100) .. "%)") or tostring(power)
    elseif config.format == "current_max" then
        text = power .. " / " .. maxPower
    end

    return CreateTextWidget(parent, config, text, "powerText")
end

-- Status Indicators Factory
function WidgetFactories.statusIndicators(parent, config, style)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(config.iconSize * 3, config.iconSize)

    -- Just show combat icon as example in preview
    frame.combat = frame:CreateTexture(nil, "OVERLAY")
    frame.combat:SetSize(config.iconSize, config.iconSize)
    frame.combat:SetPoint("LEFT")
    frame.combat:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    frame.combat:SetTexCoord(0.5, 1, 0, 0.5)

    if UnitAffectingCombat("player") or not config.showCombat then
        frame.combat:Show()
    else
        frame.combat:SetAlpha(0.3)  -- Dim in preview when not in combat
    end

    frame.widgetType = "statusIndicators"
    return frame
end

-- Leader Icon Factory
function WidgetFactories.leaderIcon(parent, config, style)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(config.size, config.size)

    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetAllPoints()
    frame.icon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")

    local isLeader = UnitIsGroupLeader("player")
    if not isLeader then
        frame.icon:SetAlpha(0.3)  -- Dim in preview when not leader
    end

    frame.widgetType = "leaderIcon"
    return frame
end

-- Raid Marker Factory
function WidgetFactories.raidMarker(parent, config, style)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(config.size, config.size)

    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetAllPoints()

    local index = GetRaidTargetIndex("player")
    if index then
        SetRaidTargetIconTexture(frame.icon, index)
    else
        -- Show skull as preview
        SetRaidTargetIconTexture(frame.icon, 8)
        frame.icon:SetAlpha(0.3)
    end

    frame.widgetType = "raidMarker"
    return frame
end

-- Castbar Factory
function WidgetFactories.castbar(parent, config, style)
    local frame = CreateFrame("StatusBar", nil, parent)
    frame:SetSize(config.size.width, config.size.height)

    -- Background texture (use WHITE8x8 + SetVertexColor like MSUF does)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.bg:SetAllPoints(frame)
    local bgColor = config.backgroundColor
    frame.bg:SetVertexColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)

    -- Bar texture
    local texturePath = NivUI:GetTexturePath(config.texture)
    frame:SetStatusBarTexture(texturePath)
    frame:SetMinMaxValues(0, 1)
    frame:SetValue(0.6)  -- Preview value

    local color = config.castingColor
    frame:SetStatusBarColor(color.r, color.g, color.b)

    -- Icon
    if config.showIcon then
        frame.icon = frame:CreateTexture(nil, "ARTWORK")
        frame.icon:SetSize(config.size.height, config.size.height)
        frame.icon:SetPoint("RIGHT", frame, "LEFT", -2, 0)
        frame.icon:SetTexture("Interface\\Icons\\Spell_Nature_Lightning")
    end

    -- Spell name
    if config.showSpellName then
        frame.spellName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.spellName:SetPoint("LEFT", 4, 0)
        frame.spellName:SetText("Lightning Bolt")
    end

    -- Timer
    if config.showTimer then
        frame.timer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.timer:SetPoint("RIGHT", -4, 0)
        frame.timer:SetText("1.2s")
    end

    frame.widgetType = "castbar"
    return frame
end

-- Aura Icon Factory (shared for buffs/debuffs)
local function CreateAuraWidget(parent, config, widgetType, testAuras)
    local frame = CreateFrame("Frame", nil, parent)

    local iconSize = config.iconSize
    local spacing = config.spacing
    local perRow = config.perRow
    local maxIcons = math.min(config.maxIcons, #testAuras)

    local totalWidth = (iconSize + spacing) * math.min(maxIcons, perRow) - spacing
    local rows = math.ceil(maxIcons / perRow)
    local totalHeight = (iconSize + spacing) * rows - spacing

    frame:SetSize(totalWidth, totalHeight)
    frame.icons = {}

    for i = 1, maxIcons do
        local icon = CreateFrame("Frame", nil, frame)
        icon:SetSize(iconSize, iconSize)

        local row = math.floor((i - 1) / perRow)
        local col = (i - 1) % perRow

        local xOffset, yOffset = 0, 0
        if config.growth == "RIGHT" then
            xOffset = col * (iconSize + spacing)
        elseif config.growth == "LEFT" then
            xOffset = -col * (iconSize + spacing)
        end

        if config.growth == "UP" then
            yOffset = row * (iconSize + spacing)
        else
            yOffset = -row * (iconSize + spacing)
        end

        icon:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)

        icon.texture = icon:CreateTexture(nil, "ARTWORK")
        icon.texture:SetAllPoints()
        icon.texture:SetTexture(testAuras[i])

        -- Duration text
        if config.showDuration then
            icon.duration = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            icon.duration:SetPoint("BOTTOM", 0, -2)
            icon.duration:SetText(math.random(5, 30) .. "s")
        end

        -- Stack count
        if config.showStacks and math.random() > 0.5 then
            icon.stacks = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            icon.stacks:SetPoint("BOTTOMRIGHT", 0, 0)
            icon.stacks:SetText(math.random(2, 5))
        end

        table.insert(frame.icons, icon)
    end

    frame.widgetType = widgetType
    return frame
end

function WidgetFactories.buffs(parent, config, style)
    local testBuffs = {
        "Interface\\Icons\\Spell_Holy_WordFortitude",
        "Interface\\Icons\\Spell_Nature_Regeneration",
        "Interface\\Icons\\Spell_Holy_ArcaneIntellect",
        "Interface\\Icons\\Ability_Warrior_BattleShout",
    }
    return CreateAuraWidget(parent, config, "buffs", testBuffs)
end

function WidgetFactories.debuffs(parent, config, style)
    local testDebuffs = {
        "Interface\\Icons\\Spell_Shadow_CurseOfTounAA",
        "Interface\\Icons\\Spell_Shadow_UnholyFrenzy",
    }
    return CreateAuraWidget(parent, config, "debuffs", testDebuffs)
end

--------------------------------------------------------------------------------
-- Designer Frame
--------------------------------------------------------------------------------

-- Create the designer preview area
function NivUI.Designer:Create(parent)
    local container = CreateFrame("Frame", nil, parent)

    -- Preview container (scaled)
    local preview = CreateFrame("Frame", nil, container)
    preview:SetPoint("CENTER")
    preview:SetScale(PREVIEW_SCALE)
    preview:SetSize(200, 60)  -- Default size, will be updated by BuildPreview

    -- Debug border around preview frame (so we can see where it is)
    preview.debugBorder = CreateFrame("Frame", nil, preview, "BackdropTemplate")
    preview.debugBorder:SetAllPoints()
    preview.debugBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    preview.debugBorder:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)

    -- Background for preview area
    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.9)

    container.preview = preview
    container.widgets = {}
    container.selectedWidget = nil

    -- Selection overlay
    container.selectionOverlay = CreateFrame("Frame", nil, container)
    container.selectionOverlay:SetFrameStrata("DIALOG")
    container.selectionOverlay:Hide()

    local selBorder = container.selectionOverlay:CreateTexture(nil, "OVERLAY")
    selBorder:SetAllPoints()
    selBorder:SetColorTexture(SELECTION_COLOR.r, SELECTION_COLOR.g, SELECTION_COLOR.b, SELECTION_COLOR.a)
    container.selectionOverlay.border = selBorder

    local selInner = container.selectionOverlay:CreateTexture(nil, "OVERLAY", nil, 1)
    selInner:SetPoint("TOPLEFT", 2, -2)
    selInner:SetPoint("BOTTOMRIGHT", -2, 2)
    selInner:SetColorTexture(0, 0, 0, 0)
    container.selectionOverlay.inner = selInner

    container.SelectWidget = function(self, widgetType)
        self.selectedWidget = widgetType
        -- Selection overlay disabled - was obscuring the preview
        self.selectionOverlay:Hide()

        if self.onSelectionChanged then
            self.onSelectionChanged(widgetType)
        end
    end

    return container
end

-- Build preview widgets from a style
function NivUI.Designer:BuildPreview(container, styleName)
    -- Clear existing widgets
    for _, widget in pairs(container.widgets) do
        widget:Hide()
        widget:SetParent(nil)
    end
    wipe(container.widgets)

    local style = NivUI:GetStyleWithDefaults(styleName)
    if not style then
        print("NivUI Designer: No style found for", styleName)
        return
    end

    -- Set preview frame size based on style.frame (with fallback for old styles)
    local frameConfig = style.frame or {}
    local frameWidth = frameConfig.width or style.width or 200
    local frameHeight = frameConfig.height or style.height or 60
    container.preview:SetSize(frameWidth, frameHeight)

    -- Apply frame border
    if frameConfig.showBorder then
        local borderSize = frameConfig.borderSize or 1
        local borderColor = frameConfig.borderColor or { r = 0, g = 0, b = 0, a = 1 }
        container.preview.debugBorder:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = borderSize,
        })
        container.preview.debugBorder:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        container.preview.debugBorder:Show()
    else
        container.preview.debugBorder:Hide()
    end

    -- Check if WIDGET_ORDER exists
    if not NivUI.UnitFrames or not NivUI.UnitFrames.WIDGET_ORDER then
        print("NivUI Designer: WIDGET_ORDER not found!")
        return
    end

    -- Create each widget
    local widgetCount = 0
    for _, widgetType in ipairs(NivUI.UnitFrames.WIDGET_ORDER) do
        -- Skip "frame" - it's not a widget, just config for the container
        if widgetType ~= "frame" then
            local config = style[widgetType]
            if config and config.enabled and WidgetFactories[widgetType] then
                local success, widget = pcall(WidgetFactories[widgetType], container.preview, config, style)
                if success and widget then
                    -- Position based on anchor (simplified for preview - just offset from frame)
                    local anchor = config.anchor
                    if anchor then
                        widget:ClearAllPoints()
                        -- For preview, we simplify and anchor to the preview frame
                        widget:SetPoint(anchor.point, container.preview, anchor.relativePoint or anchor.point, anchor.x, anchor.y)
                    else
                        widget:SetPoint("CENTER")
                    end

                    -- Click handler for selection
                    widget:EnableMouse(true)
                    widget:SetScript("OnMouseDown", function()
                        container:SelectWidget(widgetType)
                    end)

                    container.widgets[widgetType] = widget
                    widgetCount = widgetCount + 1
                elseif not success then
                    print("NivUI Designer: Error creating", widgetType, "-", widget)
                end
            end
        end
    end

    if widgetCount == 0 then
        print("NivUI Designer: No widgets created!")
    end
end

-- Refresh preview from live data
function NivUI.Designer:RefreshPreview(container, styleName)
    self:BuildPreview(container, styleName)
    if container.selectedWidget then
        container:SelectWidget(container.selectedWidget)
    end
end
