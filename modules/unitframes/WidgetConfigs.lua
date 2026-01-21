-- NivUI Unit Frames: Widget Configuration Schemas
-- Declarative config definitions for each widget type

NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

-- Configuration schema per widget type
-- Each widget has tabs, each tab has entries
-- Entry kinds: slider, dropdown, checkbox, colorPicker, spacer, header

NivUI.UnitFrames.WidgetConfigs = {
    ----------------------------------------------------------------------------
    -- Frame
    ----------------------------------------------------------------------------
    frame = {
        {
            label = "General",
            entries = {
                { kind = "slider", key = "width", label = "Width", min = 100, max = 400, step = 5 },
                { kind = "slider", key = "height", label = "Height", min = 30, max = 200, step = 5 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
        {
            label = "Border",
            entries = {
                { kind = "checkbox", key = "showBorder", label = "Show Border" },
                { kind = "slider", key = "borderSize", label = "Border Size", min = 1, max = 4, step = 1, showIf = { key = "showBorder", value = true } },
                { kind = "colorPicker", key = "borderColor", label = "Border Color", hasAlpha = true, showIf = { key = "showBorder", value = true } },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Health Bar
    ----------------------------------------------------------------------------
    healthBar = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "slider", key = "size.width", label = "Width", min = 50, max = 400, step = 5 },
                { kind = "slider", key = "size.height", label = "Height", min = 8, max = 60, step = 1 },
                { kind = "dropdown", key = "orientation", label = "Orientation", options = "BAR_ORIENTATIONS" },
                { kind = "checkbox", key = "reverseFill", label = "Reverse Fill" },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
        {
            label = "Appearance",
            entries = {
                { kind = "textureDropdown", key = "texture", label = "Texture" },
                { kind = "dropdown", key = "colorMode", label = "Color Mode", options = "HEALTH_COLOR_MODES" },
                { kind = "colorPicker", key = "customColor", label = "Custom Color", showIf = { key = "colorMode", value = "custom" } },
                { kind = "colorPicker", key = "customColor", label = "Foreground Color", showIf = { key = "colorMode", value = "class_inverted" } },
                { kind = "colorPicker", key = "gradientStart", label = "Gradient Start", showIf = { key = "colorMode", value = "health" } },
                { kind = "colorPicker", key = "gradientEnd", label = "Gradient End", showIf = { key = "colorMode", value = "health" } },
                { kind = "colorPicker", key = "backgroundColor", label = "Background", hasAlpha = true, hideIf = { key = "colorMode", value = "class_inverted" } },
            },
        },
        {
            label = "Absorb",
            entries = {
                { kind = "checkbox", key = "showAbsorb", label = "Show Absorb Overlay" },
                { kind = "colorPicker", key = "absorbColor", label = "Absorb Color", hasAlpha = true },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Power Bar
    ----------------------------------------------------------------------------
    powerBar = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "slider", key = "size.width", label = "Width", min = 50, max = 400, step = 5 },
                { kind = "slider", key = "size.height", label = "Height", min = 4, max = 40, step = 1 },
                { kind = "dropdown", key = "orientation", label = "Orientation", options = "BAR_ORIENTATIONS" },
                { kind = "checkbox", key = "reverseFill", label = "Reverse Fill" },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
        {
            label = "Appearance",
            entries = {
                { kind = "textureDropdown", key = "texture", label = "Texture" },
                { kind = "dropdown", key = "colorMode", label = "Color Mode", options = "POWER_COLOR_MODES" },
                { kind = "colorPicker", key = "customColor", label = "Custom Color", showIf = { key = "colorMode", value = "custom" } },
                { kind = "colorPicker", key = "backgroundColor", label = "Background", hasAlpha = true },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Portrait
    ----------------------------------------------------------------------------
    portrait = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "slider", key = "size.width", label = "Width", min = 16, max = 128, step = 4 },
                { kind = "slider", key = "size.height", label = "Height", min = 16, max = 128, step = 4 },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
        {
            label = "Style",
            entries = {
                { kind = "dropdown", key = "mode", label = "Mode", options = "PORTRAIT_MODES" },
                { kind = "dropdown", key = "shape", label = "Shape", options = "PORTRAIT_SHAPES" },
                { kind = "colorPicker", key = "borderColor", label = "Border Color", hasAlpha = true },
                { kind = "slider", key = "borderWidth", label = "Border Width", min = 0, max = 4, step = 1 },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Name Text
    ----------------------------------------------------------------------------
    nameText = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "fontDropdown", key = "font", label = "Font" },
                { kind = "slider", key = "fontSize", label = "Size", min = 8, max = 24, step = 1 },
                { kind = "dropdown", key = "fontOutline", label = "Outline", options = "FONT_OUTLINES" },
                { kind = "dropdown", key = "alignment", label = "Alignment", options = "TEXT_ALIGNMENTS" },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
        {
            label = "Color",
            entries = {
                { kind = "checkbox", key = "colorByClass", label = "Color by Class" },
                { kind = "colorPicker", key = "customColor", label = "Custom Color", showIf = { key = "colorByClass", value = false } },
            },
        },
        {
            label = "Options",
            entries = {
                { kind = "slider", key = "truncateLength", label = "Max Characters", min = 5, max = 40, step = 1 },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Level Text
    ----------------------------------------------------------------------------
    levelText = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "fontDropdown", key = "font", label = "Font" },
                { kind = "slider", key = "fontSize", label = "Size", min = 8, max = 24, step = 1 },
                { kind = "dropdown", key = "fontOutline", label = "Outline", options = "FONT_OUTLINES" },
                { kind = "dropdown", key = "alignment", label = "Alignment", options = "TEXT_ALIGNMENTS" },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
        {
            label = "Color",
            entries = {
                { kind = "checkbox", key = "colorByDifficulty", label = "Color by Difficulty" },
                { kind = "colorPicker", key = "customColor", label = "Custom Color", showIf = { key = "colorByDifficulty", value = false } },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Health Text
    ----------------------------------------------------------------------------
    healthText = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "fontDropdown", key = "font", label = "Font" },
                { kind = "slider", key = "fontSize", label = "Size", min = 8, max = 24, step = 1 },
                { kind = "dropdown", key = "fontOutline", label = "Outline", options = "FONT_OUTLINES" },
                { kind = "dropdown", key = "alignment", label = "Alignment", options = "TEXT_ALIGNMENTS" },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
        {
            label = "Display",
            entries = {
                { kind = "dropdown", key = "format", label = "Format", options = "TEXT_FORMATS" },
                { kind = "colorPicker", key = "color", label = "Color" },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Power Text
    ----------------------------------------------------------------------------
    powerText = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "fontDropdown", key = "font", label = "Font" },
                { kind = "slider", key = "fontSize", label = "Size", min = 8, max = 24, step = 1 },
                { kind = "dropdown", key = "fontOutline", label = "Outline", options = "FONT_OUTLINES" },
                { kind = "dropdown", key = "alignment", label = "Alignment", options = "TEXT_ALIGNMENTS" },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
        {
            label = "Display",
            entries = {
                { kind = "dropdown", key = "format", label = "Format", options = "TEXT_FORMATS" },
                { kind = "colorPicker", key = "color", label = "Color" },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Status Indicators
    ----------------------------------------------------------------------------
    statusIndicators = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "slider", key = "iconSize", label = "Icon Size", min = 8, max = 32, step = 1 },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
        {
            label = "Indicators",
            entries = {
                { kind = "checkbox", key = "showCombat", label = "Show Combat" },
                { kind = "checkbox", key = "showResting", label = "Show Resting" },
                { kind = "checkbox", key = "showDead", label = "Show Dead" },
                { kind = "checkbox", key = "showGhost", label = "Show Ghost" },
                { kind = "checkbox", key = "showAFK", label = "Show AFK" },
                { kind = "checkbox", key = "showDND", label = "Show DND" },
                { kind = "checkbox", key = "showOffline", label = "Show Offline" },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Leader Icon
    ----------------------------------------------------------------------------
    leaderIcon = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "slider", key = "size", label = "Size", min = 8, max = 32, step = 1 },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Raid Marker
    ----------------------------------------------------------------------------
    raidMarker = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "slider", key = "size", label = "Size", min = 8, max = 48, step = 1 },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Castbar
    ----------------------------------------------------------------------------
    castbar = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "slider", key = "size.width", label = "Width", min = 50, max = 400, step = 5 },
                { kind = "slider", key = "size.height", label = "Height", min = 8, max = 40, step = 1 },
                { kind = "dropdown", key = "orientation", label = "Orientation", options = "BAR_ORIENTATIONS" },
                { kind = "checkbox", key = "reverseFill", label = "Reverse Fill" },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
        {
            label = "Appearance",
            entries = {
                { kind = "textureDropdown", key = "texture", label = "Texture" },
                { kind = "colorPicker", key = "backgroundColor", label = "Background", hasAlpha = true },
            },
        },
        {
            label = "Display",
            entries = {
                { kind = "checkbox", key = "showIcon", label = "Show Icon" },
                { kind = "checkbox", key = "showTimer", label = "Show Timer" },
                { kind = "checkbox", key = "showSpellName", label = "Show Spell Name" },
            },
        },
        {
            label = "Colors",
            entries = {
                { kind = "colorPicker", key = "castingColor", label = "Casting" },
                { kind = "colorPicker", key = "channelingColor", label = "Channeling" },
                { kind = "colorPicker", key = "interruptibleColor", label = "Interruptible" },
                { kind = "colorPicker", key = "nonInterruptibleColor", label = "Non-Interruptible" },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Buffs
    ----------------------------------------------------------------------------
    buffs = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "slider", key = "iconSize", label = "Icon Size", min = 12, max = 40, step = 1 },
                { kind = "slider", key = "spacing", label = "Spacing", min = 0, max = 8, step = 1 },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
        {
            label = "Layout",
            entries = {
                { kind = "slider", key = "perRow", label = "Icons Per Row", min = 1, max = 16, step = 1 },
                { kind = "slider", key = "maxIcons", label = "Max Icons", min = 1, max = 40, step = 1 },
                { kind = "dropdown", key = "growth", label = "Growth Direction", options = "AURA_GROWTH" },
            },
        },
        {
            label = "Display",
            entries = {
                { kind = "checkbox", key = "showDuration", label = "Show Duration" },
                { kind = "checkbox", key = "showStacks", label = "Show Stacks" },
                { kind = "checkbox", key = "filterPlayer", label = "Only Player Buffs" },
            },
        },
    },

    ----------------------------------------------------------------------------
    -- Debuffs
    ----------------------------------------------------------------------------
    debuffs = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "slider", key = "iconSize", label = "Icon Size", min = 12, max = 40, step = 1 },
                { kind = "slider", key = "spacing", label = "Spacing", min = 0, max = 8, step = 1 },
                { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS" },
                { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS" },
                { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS" },
                { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1 },
                { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1 },
                { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA" },
                { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1 },
            },
        },
        {
            label = "Layout",
            entries = {
                { kind = "slider", key = "perRow", label = "Icons Per Row", min = 1, max = 16, step = 1 },
                { kind = "slider", key = "maxIcons", label = "Max Icons", min = 1, max = 40, step = 1 },
                { kind = "dropdown", key = "growth", label = "Growth Direction", options = "AURA_GROWTH" },
            },
        },
        {
            label = "Display",
            entries = {
                { kind = "checkbox", key = "showDuration", label = "Show Duration" },
                { kind = "checkbox", key = "showStacks", label = "Show Stacks" },
                { kind = "checkbox", key = "filterPlayer", label = "Only Player Debuffs" },
            },
        },
        {
            label = "Dispellable",
            entries = {
                { kind = "checkbox", key = "highlightDispellable", label = "Highlight Dispellable" },
                { kind = "colorPicker", key = "dispellableColor", label = "Highlight Color", hasAlpha = true },
            },
        },
    },
}

-- Font outline options
NivUI.UnitFrames.FONT_OUTLINES = {
    { value = "", name = "None" },
    { value = "OUTLINE", name = "Outline" },
    { value = "THICKOUTLINE", name = "Thick Outline" },
    { value = "MONOCHROME", name = "Monochrome" },
}

-- Helper to resolve option lists
-- context: optional table with additional info (e.g., { widgetType = "healthBar" })
function NivUI.UnitFrames:GetOptionList(optionName, context)
    -- Handle dynamic option lists
    if optionName == "WIDGET_PARENTS" then
        local excludeWidget = context and context.widgetType or nil
        return self:GetWidgetParentOptions(excludeWidget)
    end

    local lists = {
        HEALTH_COLOR_MODES = self.HEALTH_COLOR_MODES,
        POWER_COLOR_MODES = self.POWER_COLOR_MODES,
        PORTRAIT_MODES = self.PORTRAIT_MODES,
        PORTRAIT_SHAPES = self.PORTRAIT_SHAPES,
        TEXT_FORMATS = self.TEXT_FORMATS,
        AURA_GROWTH = self.AURA_GROWTH,
        BAR_ORIENTATIONS = self.BAR_ORIENTATIONS,
        FONT_OUTLINES = self.FONT_OUTLINES,
        ANCHOR_POINTS = self.ANCHOR_POINTS,
        TEXT_ALIGNMENTS = self.TEXT_ALIGNMENTS,
        FRAME_STRATA = self.FRAME_STRATA,
    }
    return lists[optionName] or {}
end
