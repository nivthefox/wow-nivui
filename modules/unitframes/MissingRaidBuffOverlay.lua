local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}

local MissingRaidBuffOverlay = {}
NivUI.UnitFrames.MissingRaidBuffOverlay = MissingRaidBuffOverlay

local function CreateBorderEdges(frame, thickness, color)
    color = color or {}
    local red = color.r or 1
    local green = color.g or 0
    local blue = color.b or 0
    local alpha = color.a or 1

    local top = frame:CreateTexture(nil, "OVERLAY")
    top:SetColorTexture(red, green, blue, alpha)
    top:SetHeight(thickness)
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

    local bottom = frame:CreateTexture(nil, "OVERLAY")
    bottom:SetColorTexture(red, green, blue, alpha)
    bottom:SetHeight(thickness)
    bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

    local left = frame:CreateTexture(nil, "OVERLAY")
    left:SetColorTexture(red, green, blue, alpha)
    left:SetWidth(thickness)
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)

    local right = frame:CreateTexture(nil, "OVERLAY")
    right:SetColorTexture(red, green, blue, alpha)
    right:SetWidth(thickness)
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
end

local MISSING_RAID_BUFF_PAD = 2
local MISSING_RAID_BUFF_EMPTY_WIDTH = 1

local function GetMissingRaidBuffBadgeTemplate()
    if not C_XMLUtil or not C_XMLUtil.GetTemplateInfo then
        return nil
    end
    if not C_XMLUtil.GetTemplateInfo("DisableUntrustedLayoutScriptsTemplate") then
        return nil
    end
    return "DisableUntrustedLayoutScriptsTemplate"
end

local function BuildSpellIDMap(spellIDs)
    local map = {}
    for _, spellID in ipairs(spellIDs) do
        map[spellID] = true
    end
    return map
end

local function PaintMissingRaidBuffBadge(badge, config, definition)
    if config.displayType == "BORDER" then
        CreateBorderEdges(badge, config.borderThickness or 2, config.color)
        return nil
    end

    local texture = badge:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints(badge)
    if config.displayType == "ICON" then
        texture:SetTexture(C_Spell.GetSpellTexture(definition.iconSpellID))
    else
        local color = config.color or {}
        texture:SetColorTexture(color.r or 1, color.g or 0, color.b or 0, color.a or 1)
    end
    return texture
end

local function CreateMissingRaidBuffCell(parent, config, unit, definition, width, height)
    local window = CreateFrame("Frame", nil, parent)
    window:SetClipsChildren(true)
    window:SetSize(width, height)

    local container = CreateFrame("AuraContainer", nil, window, "CustomAuraContainerTemplate")
    if config.strata then container:SetFrameStrata(config.strata) end
    if config.frameLevel then container:SetFrameLevel(config.frameLevel) end
    container:ClearAllPoints()
    container:SetPoint("TOPRIGHT", window, "TOPLEFT", -MISSING_RAID_BUFF_PAD, 0)
    if container.SetFlowLayoutAnchorPoint then
        container:SetFlowLayoutAnchorPoint("TOPLEFT")
    end
    if container.SetMouseClickEnabled then
        container:SetMouseClickEnabled(false)
    end
    if container.SetMouseMotionEnabled then
        container:SetMouseMotionEnabled(false)
    end
    container:SetUnit(unit)

    local groupKey = "nivmissing"
    container:AddAuraGroup(groupKey, "HELPFUL", {
        maxFrameCount = 1,
        candidateFilters = { includeSpellIDs = BuildSpellIDMap(definition.spellIDs) },
        initializeFrame = function(button)
            button:SetSize(width + MISSING_RAID_BUFF_PAD, height)
        end,
        layout = {
            elementWidth = width + MISSING_RAID_BUFF_PAD,
            elementHeight = height,
        },
    })

    local badge = CreateFrame("Frame", nil, window, GetMissingRaidBuffBadgeTemplate())
    badge:SetSize(width, height)
    badge:SetPoint(
        "TOPLEFT",
        container,
        "TOPLEFT",
        MISSING_RAID_BUFF_PAD + MISSING_RAID_BUFF_EMPTY_WIDTH,
        0)
    local texture = PaintMissingRaidBuffBadge(badge, config, definition)
    badge:Show()
    if container.SetEnabled then
        container:SetEnabled(true)
    end

    return {
        badge = badge,
        container = container,
        definition = definition,
        groupKey = groupKey,
        texture = texture,
        window = window,
    }
end

local function IsReadable(value)
    return not issecretvalue or not issecretvalue(value)
end

local function IsMissingRaidBuffUnitEligible(unit)
    local exists = UnitExists(unit)
    if not IsReadable(exists) or not exists then
        return false
    end

    local dead = UnitIsDeadOrGhost(unit)
    if not IsReadable(dead) or dead then
        return false
    end

    local connected = UnitIsConnected(unit)
    if not IsReadable(connected) or not connected then
        return false
    end

    local canAssist = UnitCanAssist("player", unit)
    if not IsReadable(canAssist) or not canAssist then
        return false
    end

    local rangeCheck = NivUI.UnitFrames.RangeCheck
    if not rangeCheck or not rangeCheck.IsInRange then
        return true
    end
    local inRange, checked = rangeCheck.IsInRange(unit)
    return not checked or inRange
end

local function GetConfiguredTargetSize(config, style)
    if type(style) ~= "table" then
        return nil, nil
    end

    local targetName = config.targetWidget or "healthBar"
    local target = style[targetName]
    if targetName == "frame" then
        target = style.frame
        if type(target) == "table" then
            return target.width, target.height
        end
        return nil, nil
    end
    if type(target) ~= "table" then
        return nil, nil
    end
    if type(target.size) == "table" then
        return target.size.width, target.size.height
    end
    if type(target.size) == "number" then
        return target.size, target.size
    end
    if targetName == "statusIndicators" and type(target.iconSize) == "number" then
        return target.iconSize * 2, target.iconSize
    end
    if targetName == "statusText" then
        return 100, 20
    end
    if targetName == "nameText"
        or targetName == "levelText"
        or targetName == "healthText"
        or targetName == "powerText" then
        return 200, (target.fontSize or 12) + 4
    end
    return nil, nil
end

local function GetMissingRaidBuffSize(config, style)
    local width, height = GetConfiguredTargetSize(config, style)
    if not width or not height then
        return nil, nil
    end
    if config.displayType == "BORDER" then
        local thickness = config.borderThickness or 2
        return width + thickness * 2, height + thickness * 2
    end
    return width, height
end

function MissingRaidBuffOverlay.Create(parent, config, style, unit, groupSpecs, createNormal)
    local root = CreateFrame("Frame", nil, parent)
    root:SetSize(config.iconSize, config.iconSize)
    if config.strata then root:SetFrameStrata(config.strata) end
    if config.frameLevel then root:SetFrameLevel(config.frameLevel) end

    local normal = createNormal(root, config, unit, groupSpecs)
    local transformative = NivUI.OverlayLogic.IsTransformative(config.displayType)
    local configuredWidth, configuredHeight = GetMissingRaidBuffSize(config, style)
    local layout
    if not transformative then
        local reserved = normal and config.maxIcons * #groupSpecs or 0
        layout = NivUI.OverlayLogic.ComputeGridLayout({
            growth = config.growth,
            wrap = config.wrap,
            perLine = config.perRow,
            maxIcons = reserved + #NivUI.Filters.MissingRaidBuffs.DEFINITIONS,
            iconSize = config.iconSize,
            spacing = config.spacing,
        })
    end

    if normal then
        normal:ClearAllPoints()
        if transformative then
            normal:SetAllPoints(root)
        else
            normal:SetPoint(layout.anchor, root, layout.anchor, 0, 0)
        end
    end

    local cells = {}
    local initialWidth = transformative and (configuredWidth or 1000) or config.iconSize
    local initialHeight = transformative and (configuredHeight or 1000) or config.iconSize
    for _, definition in ipairs(NivUI.Filters.MissingRaidBuffs.DEFINITIONS) do
        cells[#cells + 1] = CreateMissingRaidBuffCell(
            root, config, unit, definition, initialWidth, initialHeight)
    end

    local widget = {
        config = config,
        inner = normal and normal.inner or root,
        missingRaidBuffCells = cells,
        normalInner = normal and normal.inner or nil,
        root = root,
        unit = unit,
        missingRaidBuffEligible = true,
    }

    if transformative then
        widget.skipAnchor = true
        if config.displayType == "BORDER" then
            widget.borderTarget = config.targetWidget or "healthBar"
            widget.borderThickness = config.borderThickness or 2
        else
            widget.fillTintTarget = config.targetWidget or "healthBar"
            widget.fillTintTextures = normal and normal.fillTintTextures or {}
        end
    else
        widget.anchorOverride = NivUI.OverlayLogic.TranslateContainerAnchor(
            config.anchor, layout.anchor, config.iconSize)
    end

    local function ApplyCellVisibility(cell)
        if cell.providerAvailable and widget.missingRaidBuffEligible then
            cell.window:Show()
        else
            cell.window:Hide()
        end
    end

    function widget:SetMissingRaidBuffProviders(classes)
        local available = NivUI.Filters.MissingRaidBuffs:GetDefinitionsForClasses(classes)
        local availableByClass = {}
        for index, definition in ipairs(available) do
            availableByClass[definition.providerClass] = index
        end

        local reserved = normal and config.maxIcons * #groupSpecs or 0
        for _, cell in ipairs(cells) do
            local index = availableByClass[cell.definition.providerClass]
            cell.providerAvailable = index ~= nil
            if index and not transformative then
                local position = layout.icons[reserved + index]
                cell.window:ClearAllPoints()
                cell.window:SetPoint(layout.anchor, root, layout.anchor, position.x, position.y)
            end
            ApplyCellVisibility(cell)
        end
    end

    function widget:SetMissingRaidBuffEligible(eligible)
        self.missingRaidBuffEligible = eligible and true or false
        for _, cell in ipairs(cells) do
            ApplyCellVisibility(cell)
        end
    end

    function widget:UpdateMissingRaidBuffSize()
        if not transformative then
            return
        end

        local width = configuredWidth or root:GetWidth()
        local height = configuredHeight or root:GetHeight()
        if not IsReadable(width) or not IsReadable(height) or width <= 0 or height <= 0 then
            return
        end

        for _, cell in ipairs(cells) do
            cell.window:ClearAllPoints()
            cell.window:SetAllPoints(root)
            cell.badge:SetSize(width, height)
            if cell.container.SetAuraGroupLayout then
                pcall(cell.container.SetAuraGroupLayout, cell.container, cell.groupKey, {
                    elementWidth = width + MISSING_RAID_BUFF_PAD,
                    elementHeight = height,
                })
            end
        end
    end

    function widget:ClearAllPoints()
        root:ClearAllPoints()
    end

    function widget:Hide()
        root:Hide()
    end

    function widget:SetAllPoints(target)
        root:SetAllPoints(target)
    end

    function widget:SetPoint(...)
        root:SetPoint(...)
    end

    function widget:SetParent(value)
        root:SetParent(value)
        if value == nil then
            root:UnregisterAllEvents()
            root:SetScript("OnEvent", nil)
            root:SetScript("OnUpdate", nil)
            if normal then
                normal:SetParent(nil)
            end
            for _, cell in ipairs(cells) do
                cell.window:Hide()
                cell.window:SetParent(nil)
            end
            NivUI.UnitFrames.Runtime.MissingRaidBuffProvider.Unregister(self)
        end
    end

    function widget:Show()
        root:Show()
    end

    root:RegisterUnitEvent("UNIT_CONNECTION", unit)
    root:RegisterUnitEvent("UNIT_FACTION", unit)
    root:RegisterUnitEvent("UNIT_FLAGS", unit)
    root:SetScript("OnEvent", function()
        widget:SetMissingRaidBuffEligible(IsMissingRaidBuffUnitEligible(unit))
    end)
    local elapsedSinceEligibilityCheck = 0
    root:SetScript("OnUpdate", function(_, elapsed)
        elapsedSinceEligibilityCheck = elapsedSinceEligibilityCheck + elapsed
        if elapsedSinceEligibilityCheck < 1 then
            return
        end
        elapsedSinceEligibilityCheck = 0
        widget:SetMissingRaidBuffEligible(IsMissingRaidBuffUnitEligible(unit))
    end)

    widget:SetMissingRaidBuffEligible(IsMissingRaidBuffUnitEligible(unit))
    NivUI.UnitFrames.Runtime.MissingRaidBuffProvider.Register(widget)
    return widget
end
