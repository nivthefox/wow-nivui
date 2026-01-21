-- NivUI Unit Frames: Default Style Schema
-- Defines the complete structure for a unit frame style

NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

-- Generate parent options for anchor dropdown
-- excludeWidget: the widget type to exclude from the list (the one being edited)
function NivUI.UnitFrames:GetWidgetParentOptions(excludeWidget)
    local options = {
        { value = "frame", name = "Frame" },
    }
    for _, widgetType in ipairs(self.WIDGET_ORDER) do
        if widgetType ~= "frame" and widgetType ~= excludeWidget then
            local name = self.WIDGET_NAMES[widgetType] or widgetType
            table.insert(options, { value = widgetType, name = name })
        end
    end
    return options
end

-- Anchor point options (dropdown-compatible format)
NivUI.UnitFrames.ANCHOR_POINTS = {
    { value = "TOPLEFT", name = "Top Left" },
    { value = "TOP", name = "Top" },
    { value = "TOPRIGHT", name = "Top Right" },
    { value = "LEFT", name = "Left" },
    { value = "CENTER", name = "Center" },
    { value = "RIGHT", name = "Right" },
    { value = "BOTTOMLEFT", name = "Bottom Left" },
    { value = "BOTTOM", name = "Bottom" },
    { value = "BOTTOMRIGHT", name = "Bottom Right" },
}

-- Frame types that can have styles assigned
NivUI.UnitFrames.FRAME_TYPES = {
    { value = "player", name = "Player" },
    { value = "target", name = "Target" },
    { value = "focus", name = "Focus" },
    { value = "pet", name = "Pet" },
    { value = "party", name = "Party" },
    { value = "boss", name = "Boss" },
    { value = "targettarget", name = "Target of Target" },
}

-- Health bar color modes
NivUI.UnitFrames.HEALTH_COLOR_MODES = {
    { value = "class", name = "Class Color" },
    { value = "class_inverted", name = "Class Color (Inverted)" },
    { value = "health", name = "Health Gradient" },
    { value = "reaction", name = "Reaction" },
    { value = "custom", name = "Custom" },
}

-- Power bar color modes
NivUI.UnitFrames.POWER_COLOR_MODES = {
    { value = "power", name = "Power Type" },
    { value = "class", name = "Class Color" },
    { value = "custom", name = "Custom" },
}

-- Portrait modes
NivUI.UnitFrames.PORTRAIT_MODES = {
    { value = "3D", name = "3D Model" },
    { value = "2D", name = "2D Texture" },
    { value = "class", name = "Class Icon" },
}

-- Portrait shapes
NivUI.UnitFrames.PORTRAIT_SHAPES = {
    { value = "square", name = "Square" },
    { value = "circle", name = "Circle" },
}

-- Text formats for health/power
NivUI.UnitFrames.TEXT_FORMATS = {
    { value = "none", name = "None" },
    { value = "current", name = "Current" },
    { value = "percent", name = "Percent" },
    { value = "current_percent", name = "Current / Percent" },
    { value = "current_max", name = "Current / Max" },
    { value = "deficit", name = "Deficit" },
}

-- Aura growth directions
NivUI.UnitFrames.AURA_GROWTH = {
    { value = "RIGHT", name = "Right" },
    { value = "LEFT", name = "Left" },
    { value = "UP", name = "Up" },
    { value = "DOWN", name = "Down" },
}

-- Bar orientations
NivUI.UnitFrames.BAR_ORIENTATIONS = {
    { value = "HORIZONTAL", name = "Horizontal" },
    { value = "VERTICAL", name = "Vertical" },
}

-- Frame strata options
NivUI.UnitFrames.FRAME_STRATA = {
    { value = "BACKGROUND", name = "Background" },
    { value = "LOW", name = "Low" },
    { value = "MEDIUM", name = "Medium" },
    { value = "HIGH", name = "High" },
    { value = "DIALOG", name = "Dialog" },
    { value = "FULLSCREEN", name = "Fullscreen" },
    { value = "FULLSCREEN_DIALOG", name = "Fullscreen Dialog" },
    { value = "TOOLTIP", name = "Tooltip" },
}

-- Text alignments
NivUI.UnitFrames.TEXT_ALIGNMENTS = {
    { value = "LEFT", name = "Left" },
    { value = "CENTER", name = "Center" },
    { value = "RIGHT", name = "Right" },
}

-- Default anchor configuration
local function DefaultAnchor(point, relativeTo, relativePoint, x, y)
    return {
        point = point or "CENTER",
        relativeTo = relativeTo or "frame",  -- "frame" means parent unit frame
        relativePoint = relativePoint or "CENTER",
        x = x or 0,
        y = y or 0,
    }
end

-- Default style definition
-- This is what a new style starts with
NivUI.UnitFrames.DEFAULT_STYLE = {
    -- Frame settings
    frame = {
        width = 200,
        height = 60,
        strata = "MEDIUM",
        frameLevel = 1,
        showBorder = false,
        borderColor = { r = 0, g = 0, b = 0, a = 1 },
        borderSize = 1,
    },

    -- Health Bar
    healthBar = {
        enabled = true,
        anchor = DefaultAnchor("TOPLEFT", "frame", "TOPLEFT", 0, 0),
        size = { width = 180, height = 24 },
        strata = "MEDIUM",
        frameLevel = 2,
        texture = "Default",
        orientation = "HORIZONTAL",
        reverseFill = false,
        colorMode = "class",
        customColor = { r = 0.2, g = 0.8, b = 0.2 },
        gradientStart = { r = 1, g = 0, b = 0 },
        gradientEnd = { r = 0, g = 1, b = 0 },
        showAbsorb = true,
        absorbColor = { r = 0.8, g = 0.8, b = 0.2, a = 0.5 },
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 },
    },

    -- Power Bar
    powerBar = {
        enabled = true,
        anchor = DefaultAnchor("TOPLEFT", "healthBar", "BOTTOMLEFT", 0, -2),
        size = { width = 180, height = 12 },
        strata = "MEDIUM",
        frameLevel = 2,
        texture = "Default",
        orientation = "HORIZONTAL",
        reverseFill = false,
        colorMode = "power",
        customColor = { r = 0.2, g = 0.2, b = 0.8 },
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 },
    },

    -- Portrait
    portrait = {
        enabled = true,
        anchor = DefaultAnchor("RIGHT", "frame", "LEFT", -4, 0),
        size = { width = 48, height = 48 },
        strata = "MEDIUM",
        frameLevel = 1,
        mode = "3D",
        shape = "square",
        borderColor = { r = 0, g = 0, b = 0, a = 1 },
        borderWidth = 1,
    },

    -- Name Text
    nameText = {
        enabled = true,
        anchor = DefaultAnchor("BOTTOMLEFT", "healthBar", "TOPLEFT", 2, 2),
        strata = "MEDIUM",
        frameLevel = 10,
        font = "Friz Quadrata",
        fontSize = 12,
        fontOutline = "OUTLINE",
        alignment = "LEFT",
        colorByClass = true,
        customColor = { r = 1, g = 1, b = 1 },
        truncateLength = 20,
    },

    -- Level Text
    levelText = {
        enabled = true,
        anchor = DefaultAnchor("BOTTOMRIGHT", "healthBar", "TOPRIGHT", -2, 2),
        strata = "MEDIUM",
        frameLevel = 10,
        font = "Friz Quadrata",
        fontSize = 11,
        fontOutline = "OUTLINE",
        alignment = "RIGHT",
        colorByDifficulty = true,
        customColor = { r = 1, g = 0.82, b = 0 },
    },

    -- Health Text
    healthText = {
        enabled = true,
        anchor = DefaultAnchor("CENTER", "healthBar", "CENTER", 0, 0),
        strata = "MEDIUM",
        frameLevel = 10,
        font = "Friz Quadrata",
        fontSize = 11,
        fontOutline = "OUTLINE",
        alignment = "CENTER",
        format = "current_percent",
        color = { r = 1, g = 1, b = 1 },
    },

    -- Power Text
    powerText = {
        enabled = true,
        anchor = DefaultAnchor("CENTER", "powerBar", "CENTER", 0, 0),
        strata = "MEDIUM",
        frameLevel = 10,
        font = "Friz Quadrata",
        fontSize = 10,
        fontOutline = "OUTLINE",
        alignment = "CENTER",
        format = "current",
        color = { r = 1, g = 1, b = 1 },
    },

    -- Status Indicators
    statusIndicators = {
        enabled = true,
        strata = "MEDIUM",
        frameLevel = 5,
        showCombat = true,
        showResting = true,
        showDead = true,
        showGhost = true,
        showAFK = true,
        showDND = true,
        showOffline = true,
        iconSize = 16,
        anchor = DefaultAnchor("TOPRIGHT", "frame", "TOPRIGHT", 0, 0),
    },

    -- Leader/Assistant Icon
    leaderIcon = {
        enabled = true,
        anchor = DefaultAnchor("TOPLEFT", "frame", "TOPLEFT", -4, 4),
        strata = "MEDIUM",
        frameLevel = 5,
        size = 16,
    },

    -- Raid Marker
    raidMarker = {
        enabled = true,
        anchor = DefaultAnchor("TOP", "frame", "TOP", 0, 8),
        strata = "MEDIUM",
        frameLevel = 5,
        size = 20,
    },

    -- Castbar
    castbar = {
        enabled = true,
        anchor = DefaultAnchor("TOP", "powerBar", "BOTTOM", 0, 0),
        size = { width = 180, height = 16 },
        strata = "MEDIUM",
        frameLevel = 3,
        texture = "Default",
        orientation = "HORIZONTAL",
        reverseFill = false,
        showIcon = true,
        showTimer = true,
        showSpellName = true,
        backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.8 },
        castingColor = { r = 1, g = 0.7, b = 0 },
        channelingColor = { r = 0, g = 0.7, b = 1 },
        interruptibleColor = { r = 0.7, g = 0.7, b = 0.7 },
        nonInterruptibleColor = { r = 0.7, g = 0, b = 0 },
    },

    -- Buffs
    buffs = {
        enabled = true,
        anchor = DefaultAnchor("BOTTOMLEFT", "frame", "TOPLEFT", 0, 4),
        strata = "MEDIUM",
        frameLevel = 5,
        iconSize = 20,
        spacing = 2,
        perRow = 8,
        maxIcons = 16,
        growth = "RIGHT",
        showDuration = true,
        showStacks = true,
        filterPlayer = false,  -- Only show player-cast buffs
    },

    -- Debuffs
    debuffs = {
        enabled = true,
        anchor = DefaultAnchor("BOTTOMLEFT", "buffs", "TOPLEFT", 0, 2),
        strata = "MEDIUM",
        frameLevel = 5,
        iconSize = 22,
        spacing = 2,
        perRow = 8,
        maxIcons = 16,
        growth = "RIGHT",
        showDuration = true,
        showStacks = true,
        highlightDispellable = true,
        dispellableColor = { r = 0, g = 1, b = 0, a = 1 },
        filterPlayer = false,  -- Only show player-cast debuffs
    },
}

-- Widget list for iteration (order matters for UI)
NivUI.UnitFrames.WIDGET_ORDER = {
    "frame",
    "healthBar",
    "powerBar",
    "portrait",
    "nameText",
    "levelText",
    "healthText",
    "powerText",
    "statusIndicators",
    "leaderIcon",
    "raidMarker",
    "castbar",
    "buffs",
    "debuffs",
}

-- Human-readable widget names
NivUI.UnitFrames.WIDGET_NAMES = {
    frame = "Frame",
    healthBar = "Health Bar",
    powerBar = "Power Bar",
    portrait = "Portrait",
    nameText = "Name Text",
    levelText = "Level Text",
    healthText = "Health Text",
    powerText = "Power Text",
    statusIndicators = "Status Indicators",
    leaderIcon = "Leader Icon",
    raidMarker = "Raid Marker",
    castbar = "Castbar",
    buffs = "Buffs",
    debuffs = "Debuffs",
}
