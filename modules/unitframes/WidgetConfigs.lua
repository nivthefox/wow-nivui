NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

NivUI.UnitFrames.WidgetConfigs = {
    frame = {
        {
            label = "General",
            entries = {
                { kind = "slider", key = "width", label = "Width", min = 1, max = 800, step = 1 },
                { kind = "slider", key = "height", label = "Height", min = 1, max = 800, step = 1 },
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

    healthBar = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "slider", key = "size.width", label = "Width", min = 1, max = 800, step = 1 },
                { kind = "slider", key = "size.height", label = "Height", min = 1, max = 800, step = 1 },
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
                { kind = "colorPicker", key = "customColor", label = "Custom Color", hasAlpha = true, showIf = { key = "colorMode", value = "custom" } },
                { kind = "colorPicker", key = "customColor", label = "Foreground Color", hasAlpha = true, showIf = { key = "colorMode", value = "class_inverted" } },
                { kind = "colorPicker", key = "gradientStart", label = "Gradient Start", hasAlpha = true, showIf = { key = "colorMode", value = "health" } },
                { kind = "colorPicker", key = "gradientEnd", label = "Gradient End", hasAlpha = true, showIf = { key = "colorMode", value = "health" } },
                { kind = "colorPicker", key = "backgroundColor", label = "Background", hasAlpha = true, hideIf = { key = "colorMode", value = "class_inverted" } },
            },
        },
        {
            label = "Damage Absorbs",
            entries = {
                { kind = "checkbox", key = "showDamageAbsorb", label = "Show Damage Absorbs" },
                { kind = "colorPicker", key = "absorbColor", label = "Absorb Color", hasAlpha = true, showIf = { key = "showDamageAbsorb", value = true } },
                { kind = "slider", key = "damageAbsorbFrameLevelOffset", label = "Layer Offset", min = 0, max = 10, step = 1, showIf = { key = "showDamageAbsorb", value = true } },
                { kind = "checkbox", key = "showDamageAbsorbOverflowGlow", label = "Show Overflow Glow", showIf = { key = "showDamageAbsorb", value = true } },
                { kind = "colorPicker", key = "damageAbsorbOverflowGlowColor", label = "Glow Color", hasAlpha = true, showIf = { key = "showDamageAbsorb", value = true } },
                { kind = "slider", key = "damageAbsorbOverflowGlowWidth", label = "Glow Width", min = 1, max = 10, step = 1, showIf = { key = "showDamageAbsorb", value = true } },
            },
        },
        {
            label = "Heal Absorbs",
            entries = {
                { kind = "checkbox", key = "showHealAbsorb", label = "Show Heal Absorbs" },
                { kind = "colorPicker", key = "healAbsorbColor", label = "Heal Absorb Color", hasAlpha = true, showIf = { key = "showHealAbsorb", value = true } },
                { kind = "slider", key = "healAbsorbFrameLevelOffset", label = "Layer Offset", min = 0, max = 10, step = 1, showIf = { key = "showHealAbsorb", value = true } },
                { kind = "checkbox", key = "showHealAbsorbOverflowGlow", label = "Show Overflow Glow", showIf = { key = "showHealAbsorb", value = true } },
                { kind = "colorPicker", key = "healAbsorbOverflowGlowColor", label = "Glow Color", hasAlpha = true, showIf = { key = "showHealAbsorb", value = true } },
                { kind = "slider", key = "healAbsorbOverflowGlowWidth", label = "Glow Width", min = 1, max = 10, step = 1, showIf = { key = "showHealAbsorb", value = true } },
            },
        },
        {
            label = "Heal Prediction",
            entries = {
                { kind = "checkbox", key = "showHealPrediction", label = "Show Incoming Heals" },
                { kind = "colorPicker", key = "healPredictionColor", label = "Prediction Color", hasAlpha = true, showIf = { key = "showHealPrediction", value = true } },
                { kind = "dropdown", key = "healPredictionSource", label = "Heal Source", options = "HEAL_PREDICTION_SOURCES", showIf = { key = "showHealPrediction", value = true } },
                { kind = "slider", key = "healPredictionFrameLevelOffset", label = "Layer Offset", min = 0, max = 10, step = 1, showIf = { key = "showHealPrediction", value = true } },
            },
        },
        {
            label = "Max HP Loss",
            entries = {
                { kind = "checkbox", key = "showTempMaxHealthLoss", label = "Show Max HP Loss" },
                { kind = "dropdown", key = "tempMaxHealthLossTextureSource", label = "Texture Source", options = "TEMP_MAX_HEALTH_LOSS_TEXTURE_SOURCES", showIf = { key = "showTempMaxHealthLoss", value = true } },
                { kind = "colorPicker", key = "tempMaxHealthLossColor", label = "Tint Color", hasAlpha = true, showIf = { key = "showTempMaxHealthLoss", value = true } },
            },
        },
    },

    powerBar = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "dropdown", key = "visibility", label = "Show For", options = "POWER_VISIBILITY" },
                { kind = "slider", key = "size.width", label = "Width", min = 1, max = 800, step = 1 },
                { kind = "slider", key = "size.height", label = "Height", min = 1, max = 800, step = 1 },
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
                { kind = "colorPicker", key = "customColor", label = "Custom Color", hasAlpha = true, showIf = { key = "colorMode", value = "custom" } },
                { kind = "colorPicker", key = "backgroundColor", label = "Background", hasAlpha = true },
            },
        },
    },

    portrait = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "slider", key = "size.width", label = "Width", min = 1, max = 800, step = 1 },
                { kind = "slider", key = "size.height", label = "Height", min = 1, max = 800, step = 1 },
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
                { kind = "colorPicker", key = "customColor", label = "Custom Color", hasAlpha = true, showIf = { key = "colorByClass", value = false } },
            },
        },
        {
            label = "Options",
            entries = {
                { kind = "slider", key = "truncateLength", label = "Max Characters", min = 5, max = 40, step = 1 },
            },
        },
    },

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
                { kind = "colorPicker", key = "customColor", label = "Custom Color", hasAlpha = true, showIf = { key = "colorByDifficulty", value = false } },
            },
        },
    },

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
                { kind = "colorPicker", key = "color", label = "Color", hasAlpha = true },
            },
        },
    },

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
                { kind = "colorPicker", key = "color", label = "Color", hasAlpha = true },
            },
        },
    },

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
            },
        },
    },

    statusText = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
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
            label = "Status Types",
            entries = {
                { kind = "checkbox", key = "showDead", label = "Show Dead" },
                { kind = "checkbox", key = "showGhost", label = "Show Ghost" },
                { kind = "checkbox", key = "showAFK", label = "Show AFK" },
                { kind = "checkbox", key = "showDND", label = "Show DND" },
                { kind = "checkbox", key = "showOffline", label = "Show Offline" },
            },
        },
    },

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

    roleIcon = {
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

    castbar = {
        {
            label = "General",
            entries = {
                { kind = "checkbox", key = "enabled", label = "Enabled" },
                { kind = "slider", key = "size.width", label = "Width", min = 1, max = 800, step = 1 },
                { kind = "slider", key = "size.height", label = "Height", min = 1, max = 800, step = 1 },
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
                { kind = "colorPicker", key = "castingColor", label = "Casting", hasAlpha = true },
                { kind = "colorPicker", key = "channelingColor", label = "Channeling", hasAlpha = true },
                { kind = "colorPicker", key = "interruptibleColor", label = "Interruptible", hasAlpha = true },
                { kind = "colorPicker", key = "nonInterruptibleColor", label = "Non-Interruptible", hasAlpha = true },
            },
        },
    },

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
                { kind = "dropdown", key = "dispelIndicator", label = "Dispel Indicator", options = "DISPEL_INDICATOR" },
            },
        },
    },

    importantDebuffs = {
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
                { kind = "slider", key = "perRow", label = "Icons Per Row", min = 1, max = 8, step = 1 },
                { kind = "slider", key = "maxIcons", label = "Max Icons", min = 1, max = 10, step = 1 },
                { kind = "dropdown", key = "growth", label = "Growth Direction", options = "AURA_GROWTH" },
            },
        },
        {
            label = "Display",
            entries = {
                { kind = "checkbox", key = "showDuration", label = "Show Duration" },
                { kind = "checkbox", key = "showStacks", label = "Show Stacks" },
            },
        },
        {
            label = "Dispellable",
            entries = {
                { kind = "dropdown", key = "dispelIndicator", label = "Dispel Indicator", options = "DISPEL_INDICATOR" },
            },
        },
    },
}

NivUI.UnitFrames.FONT_OUTLINES = {
    { value = "", name = "None" },
    { value = "OUTLINE", name = "Outline" },
    { value = "THICKOUTLINE", name = "Thick Outline" },
    { value = "MONOCHROME", name = "Monochrome" },
}

function NivUI.UnitFrames:GetOptionList(optionName, context)
    if optionName == "WIDGET_PARENTS" then
        local excludeWidget = context and context.widgetType or nil
        return self:GetWidgetParentOptions(excludeWidget)
    end

    local lists = {
        HEALTH_COLOR_MODES = self.HEALTH_COLOR_MODES,
        POWER_COLOR_MODES = self.POWER_COLOR_MODES,
        POWER_VISIBILITY = self.POWER_VISIBILITY,
        PORTRAIT_MODES = self.PORTRAIT_MODES,
        PORTRAIT_SHAPES = self.PORTRAIT_SHAPES,
        TEXT_FORMATS = self.TEXT_FORMATS,
        AURA_GROWTH = self.AURA_GROWTH,
        DISPEL_INDICATOR = self.DISPEL_INDICATOR,
        BAR_ORIENTATIONS = self.BAR_ORIENTATIONS,
        FONT_OUTLINES = self.FONT_OUTLINES,
        ANCHOR_POINTS = self.ANCHOR_POINTS,
        TEXT_ALIGNMENTS = self.TEXT_ALIGNMENTS,
        FRAME_STRATA = self.FRAME_STRATA,
        HEAL_PREDICTION_SOURCES = self.HEAL_PREDICTION_SOURCES,
        TEMP_MAX_HEALTH_LOSS_TEXTURE_SOURCES = self.TEMP_MAX_HEALTH_LOSS_TEXTURE_SOURCES,
    }
    return lists[optionName] or {}
end
