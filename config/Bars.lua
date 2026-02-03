NivUI = NivUI or {}
NivUI.Config = NivUI.Config or {}
NivUI.Config.Bars = {}

local FRAME_WIDTH = 680
local SIDEBAR_WIDTH = 100
local SECTION_SPACING = 20

--- Section handler dispatch table for BuildClassBarConfig
--- Each handler returns the widget and an optional onShow refresh function
local SectionHandlers = {}

function SectionHandlers.enable(content, section, config, Components)
    local widget = Components.GetCheckbox(
        content,
        section.label or ("Enable " .. config.displayName),
        function(checked)
            NivUI:SetClassBarEnabled(config.barType, checked)
        end
    )
    local function onShow()
        widget:SetValue(NivUI:IsClassBarEnabled(config.barType))
    end
    return widget, onShow
end

function SectionHandlers.header(content, section, _config, Components)
    return Components.GetHeader(content, section.text), nil
end

function SectionHandlers.visibility(content, section, config, Components)
    local widget
    if section.applySetting then
        widget = Components.GetBasicDropdown(
            content,
            section.label or "Bar Visible:",
            function() return NivUI:GetVisibilityOptions() end,
            function(value) return NivUI:GetSetting("visibility") == value end,
            function(value)
                NivUI.current[config.dbKey].visibility = value
                NivUI:ApplySettings(section.applySetting)
            end
        )
    else
        widget = Components.GetBasicDropdown(
            content,
            section.label or "Bar Visible:",
            function() return NivUI:GetVisibilityOptions() end,
            function(value)
                local db = NivUI.current[config.dbKey] or {}
                return (db.visibility or config.defaults.visibility) == value
            end,
            function(value)
                NivUI.current[config.dbKey] = NivUI.current[config.dbKey] or {}
                NivUI.current[config.dbKey].visibility = value
                if section.applyFunc then section.applyFunc() end
            end
        )
    end
    local function onShow()
        widget:SetValue()
    end
    return widget, onShow
end

function SectionHandlers.fgTexture(content, section, config, Components)
    local widget = Components.GetTextureDropdown(
        content,
        section.label or "Foreground:",
        function() return NivUI:GetBarTextures() end,
        function() return NivUI:GetSetting("foregroundTexture") end,
        function(value)
            NivUI.current[config.dbKey].foregroundTexture = value
            NivUI:ApplySettings(section.applySetting or "barTexture")
        end
    )
    local function onShow()
        widget:SetValue()
    end
    return widget, onShow
end

function SectionHandlers.bgTexture(content, section, config, Components)
    local widget = Components.GetTextureDropdown(
        content,
        section.label or "Background:",
        function() return NivUI:GetBarTextures() end,
        function() return NivUI:GetSetting("backgroundTexture") end,
        function(value)
            NivUI.current[config.dbKey].backgroundTexture = value
            NivUI:ApplySettings(section.applySetting or "background")
        end
    )
    local function onShow()
        widget:SetValue()
    end
    return widget, onShow
end

function SectionHandlers.bgColor(content, section, config, Components)
    local widget = Components.GetColorPicker(
        content,
        section.label or "Background Color:",
        true,
        function(color)
            NivUI.current[config.dbKey].backgroundColor = color
            NivUI:ApplySettings(section.applySetting or "background")
        end
    )
    local function onShow()
        local db = NivUI.current[config.dbKey]
        widget:SetValue(db.backgroundColor or config.defaults.backgroundColor)
    end
    return widget, onShow
end

function SectionHandlers.borderDropdown(content, section, config, Components)
    local widget = Components.GetBasicDropdown(
        content,
        section.label or "Border Style:",
        function() return NivUI:GetBorders() end,
        function(value) return NivUI:GetSetting("borderStyle") == value end,
        function(value)
            NivUI.current[config.dbKey].borderStyle = value
            NivUI:ApplySettings(section.applySetting or "border")
        end
    )
    local function onShow()
        widget:SetValue()
    end
    return widget, onShow
end

function SectionHandlers.borderColor(content, section, config, Components)
    local hasAlpha = section.hasAlpha
    if hasAlpha == nil then hasAlpha = true end

    local widget
    if section.applySetting then
        widget = Components.GetColorPicker(
            content,
            section.label or "Border Color:",
            hasAlpha,
            function(color)
                NivUI.current[config.dbKey].borderColor = color
                NivUI:ApplySettings(section.applySetting)
            end
        )
    else
        widget = Components.GetColorPicker(
            content,
            section.label or "Border Color:",
            hasAlpha,
            function(color)
                NivUI.current[config.dbKey] = NivUI.current[config.dbKey] or {}
                NivUI.current[config.dbKey].borderColor = color
                if section.applyFunc then section.applyFunc() end
            end
        )
    end
    local function onShow()
        local db = NivUI.current[config.dbKey] or {}
        widget:SetValue(db.borderColor or config.defaults.borderColor)
    end
    return widget, onShow
end

function SectionHandlers.color(content, section, config, Components)
    local hasAlpha = section.hasAlpha
    if hasAlpha == nil then hasAlpha = false end

    local widget
    if section.nestedKey then
        widget = Components.GetColorPicker(
            content,
            section.label,
            hasAlpha,
            function(color)
                NivUI.current[config.dbKey][section.nestedKey] = NivUI.current[config.dbKey][section.nestedKey] or {}
                NivUI.current[config.dbKey][section.nestedKey][section.key] = color
                if section.applyFunc then section.applyFunc() end
            end
        )
        local function onShow()
            local db = NivUI.current[config.dbKey]
            local nested = db[section.nestedKey] or config.defaults[section.nestedKey] or {}
            widget:SetValue(nested[section.key])
        end
        return widget, onShow
    else
        if section.applySetting then
            widget = Components.GetColorPicker(
                content,
                section.label,
                hasAlpha,
                function(color)
                    NivUI.current[config.dbKey][section.key] = color
                    NivUI:ApplySettings(section.applySetting)
                end
            )
        else
            widget = Components.GetColorPicker(
                content,
                section.label,
                hasAlpha,
                function(color)
                    NivUI.current[config.dbKey] = NivUI.current[config.dbKey] or {}
                    NivUI.current[config.dbKey][section.key] = color
                    if section.applyFunc then section.applyFunc() end
                end
            )
        end
        local function onShow()
            local db = NivUI.current[config.dbKey] or {}
            widget:SetValue(db[section.key] or config.defaults[section.key])
        end
        return widget, onShow
    end
end

function SectionHandlers.fontDropdown(content, section, config, Components)
    local widget = Components.GetBasicDropdown(
        content,
        section.label or "Font:",
        function() return NivUI:GetFonts() end,
        function(value) return NivUI:GetSetting("font") == value end,
        function(value)
            NivUI.current[config.dbKey].font = value
            NivUI:ApplySettings(section.applySetting or "font")
        end
    )
    local function onShow()
        widget:SetValue()
    end
    return widget, onShow
end

function SectionHandlers.fontSizeSlider(content, section, config, Components)
    local widget = Components.GetSliderWithInput(
        content,
        section.label or "Font Size:",
        section.min or 8,
        section.max or 24,
        section.step or 1,
        false,
        function(value)
            NivUI.current[config.dbKey].fontSize = value
            NivUI:ApplySettings(section.applySetting or "font")
        end
    )
    local function onShow()
        local db = NivUI.current[config.dbKey]
        widget:SetValue(db.fontSize or config.defaults.fontSize)
    end
    return widget, onShow
end

function SectionHandlers.fontColor(content, section, config, Components)
    local widget = Components.GetColorPicker(
        content,
        section.label or "Font Color:",
        false,
        function(color)
            NivUI.current[config.dbKey].fontColor = color
            NivUI:ApplySettings(section.applySetting or "font")
        end
    )
    local function onShow()
        local db = NivUI.current[config.dbKey]
        widget:SetValue(db.fontColor or config.defaults.fontColor)
    end
    return widget, onShow
end

function SectionHandlers.fontShadow(content, section, config, Components)
    local widget = Components.GetCheckbox(
        content,
        section.label or "Text Shadow",
        function(checked)
            NivUI.current[config.dbKey].fontShadow = checked
            NivUI:ApplySettings(section.applySetting or "font")
        end
    )
    local function onShow()
        local db = NivUI.current[config.dbKey]
        local shadow = db.fontShadow
        if shadow == nil then shadow = config.defaults.fontShadow end
        widget:SetValue(shadow)
    end
    return widget, onShow
end

function SectionHandlers.lockedCheckbox(content, section, config, Components)
    local widget
    if section.applySetting then
        widget = Components.GetCheckbox(
            content,
            section.label or "Locked",
            function(checked)
                NivUI.current[config.dbKey].locked = checked
                NivUI:ApplySettings(section.applySetting)
            end
        )
    else
        widget = Components.GetCheckbox(
            content,
            section.label or "Locked",
            function(checked)
                NivUI.current[config.dbKey] = NivUI.current[config.dbKey] or {}
                NivUI.current[config.dbKey].locked = checked
                if section.applyFunc then section.applyFunc() end
            end
        )
    end
    local function onShow()
        local db = NivUI.current[config.dbKey] or {}
        widget:SetValue(db.locked or false)
    end
    return widget, onShow
end

function SectionHandlers.widthSlider(content, section, config, Components)
    local widget
    if section.applySetting then
        widget = Components.GetSliderWithInput(
            content,
            section.label or "Width:",
            section.min or 100,
            section.max or 600,
            section.step or 10,
            false,
            function(value)
                NivUI.current[config.dbKey].width = value
                NivUI:ApplySettings(section.applySetting)
            end
        )
    else
        widget = Components.GetSliderWithInput(
            content,
            section.label or "Width:",
            section.min or 100,
            section.max or 600,
            section.step or 10,
            false,
            function(value)
                NivUI.current[config.dbKey] = NivUI.current[config.dbKey] or {}
                NivUI.current[config.dbKey].width = value
                if section.applyFunc then section.applyFunc() end
                if section.rebuildFunc then section.rebuildFunc() end
            end
        )
    end
    local function onShow()
        local db = NivUI.current[config.dbKey] or {}
        widget:SetValue(db.width or config.defaults.width)
    end
    return widget, onShow, "widthSlider"
end

function SectionHandlers.heightSlider(content, section, config, Components)
    local widget
    if section.applySetting then
        widget = Components.GetSliderWithInput(
            content,
            section.label or "Height:",
            section.min or 5,
            section.max or 60,
            section.step or 1,
            false,
            function(value)
                NivUI.current[config.dbKey].height = value
                NivUI:ApplySettings(section.applySetting)
            end
        )
    else
        widget = Components.GetSliderWithInput(
            content,
            section.label or "Height:",
            section.min or 5,
            section.max or 60,
            section.step or 1,
            false,
            function(value)
                NivUI.current[config.dbKey] = NivUI.current[config.dbKey] or {}
                NivUI.current[config.dbKey].height = value
                if section.applyFunc then section.applyFunc() end
                if section.rebuildFunc then section.rebuildFunc() end
            end
        )
    end
    local function onShow()
        local db = NivUI.current[config.dbKey] or {}
        widget:SetValue(db.height or config.defaults.height)
    end
    return widget, onShow, "heightSlider"
end

function SectionHandlers.intervalSlider(content, section, config, Components)
    local widget
    if section.applySetting then
        widget = Components.GetSliderWithInput(
            content,
            section.label or "Update Interval:",
            section.min or 0.05,
            section.max or 1.0,
            section.step or 0.05,
            true,
            function(value)
                NivUI.current[config.dbKey].updateInterval = value
                NivUI:ApplySettings(section.applySetting)
            end
        )
    else
        widget = Components.GetSliderWithInput(
            content,
            section.label or "Update Interval:",
            section.min or 0.05,
            section.max or 1.0,
            section.step or 0.05,
            true,
            function(value)
                NivUI.current[config.dbKey] = NivUI.current[config.dbKey] or {}
                NivUI.current[config.dbKey].updateInterval = value
            end
        )
    end
    local function onShow()
        local db = NivUI.current[config.dbKey] or {}
        widget:SetValue(db.updateInterval or config.defaults.updateInterval)
    end
    return widget, onShow
end

function SectionHandlers.spacingSlider(content, section, config, Components)
    local widget = Components.GetSliderWithInput(
        content,
        section.label or "Segment Spacing:",
        section.min or 0,
        section.max or 10,
        section.step or 1,
        false,
        function(value)
            NivUI.current[config.dbKey] = NivUI.current[config.dbKey] or {}
            NivUI.current[config.dbKey].spacing = value
            if section.rebuildFunc then section.rebuildFunc() end
        end
    )
    local function onShow()
        local db = NivUI.current[config.dbKey] or {}
        widget:SetValue(db.spacing or config.defaults.spacing)
    end
    return widget, onShow
end

function SectionHandlers.emptyColor(content, section, config, Components)
    local widget = Components.GetColorPicker(
        content,
        section.label or "Empty Color:",
        true,
        function(color)
            NivUI.current[config.dbKey] = NivUI.current[config.dbKey] or {}
            NivUI.current[config.dbKey].emptyColor = color
            if section.applyFunc then section.applyFunc() end
        end
    )
    local function onShow()
        local db = NivUI.current[config.dbKey] or {}
        widget:SetValue(db.emptyColor or config.defaults.emptyColor)
    end
    return widget, onShow
end

function SectionHandlers.filledColor(content, section, config, Components)
    local widget = Components.GetColorPicker(
        content,
        section.label or "Filled Color:",
        true,
        function(color)
            NivUI.current[config.dbKey] = NivUI.current[config.dbKey] or {}
            NivUI.current[config.dbKey].filledColor = color
            if section.applyFunc then section.applyFunc() end
        end
    )
    local function onShow()
        local db = NivUI.current[config.dbKey] or {}
        widget:SetValue(db.filledColor or config.defaults.filledColor)
    end
    return widget, onShow
end

NivUI.Config.Bars.SectionHandlers = SectionHandlers

--- Configuration table for the Stagger Bar config panel.
local staggerBarConfig = {
    barType = "stagger",
    displayName = "Stagger Bar",
    dbKey = "staggerBar",
    defaults = NivUI.staggerBarDefaults,
    contentHeight = 900,
    sections = {
        { type = "enable" },
        { type = "header", text = "General" },
        { type = "visibility", applySetting = "visibility" },
        { type = "header", text = "Appearance" },
        { type = "fgTexture", applySetting = "barTexture" },
        { type = "bgTexture", applySetting = "background" },
        { type = "bgColor", applySetting = "background" },
        { type = "borderDropdown", applySetting = "border" },
        { type = "borderColor", applySetting = "border" },
        { type = "header", text = "Stagger Colors" },
        { type = "color", nestedKey = "colors", key = "light", label = "Light:" },
        { type = "color", nestedKey = "colors", key = "moderate", label = "Moderate:" },
        { type = "color", nestedKey = "colors", key = "heavy", label = "Heavy:" },
        { type = "color", nestedKey = "colors", key = "extreme", label = "Extreme:" },
        { type = "header", text = "Text" },
        { type = "fontDropdown", applySetting = "font" },
        { type = "fontSizeSlider", applySetting = "font" },
        { type = "fontColor", applySetting = "font" },
        { type = "fontShadow", applySetting = "font" },
        { type = "header", text = "Position" },
        { type = "lockedCheckbox", applySetting = "locked" },
        { type = "widthSlider", applySetting = "position" },
        { type = "heightSlider", applySetting = "position" },
        { type = "intervalSlider" },
    },
}

--- Configuration table for the Chi Bar config panel.
local chiBarConfig = {
    barType = "chi",
    displayName = "Chi Bar",
    dbKey = "chiBar",
    defaults = NivUI.chiBarDefaults,
    contentHeight = 500,
    sections = {
        { type = "enable" },
        { type = "header", text = "General" },
        { type = "visibility", applyFunc = function() NivUI.ChiBar_UpdateVisibility() end },
        { type = "header", text = "Appearance" },
        { type = "spacingSlider", rebuildFunc = function() if NivUI.ChiBar then NivUI.ChiBar:RebuildSegments() end end },
        { type = "emptyColor", applyFunc = function() NivUI.ChiBar_ApplyColors() end },
        { type = "filledColor", applyFunc = function() NivUI.ChiBar_ApplyColors() end },
        { type = "borderColor", applyFunc = function() NivUI.ChiBar_ApplyBorder() end },
        { type = "header", text = "Position" },
        { type = "lockedCheckbox", applyFunc = function() NivUI.ChiBar_ApplyLockState() end },
        { type = "widthSlider", min = 60, max = 400, applyFunc = function() NivUI.ChiBar_LoadPosition() end, rebuildFunc = function() if NivUI.ChiBar then NivUI.ChiBar:RebuildSegments() end end },
        { type = "heightSlider", applyFunc = function() NivUI.ChiBar_LoadPosition() end, rebuildFunc = function() if NivUI.ChiBar then NivUI.ChiBar:RebuildSegments() end end },
        { type = "intervalSlider" },
    },
}

--- Configuration table for the Essence Bar config panel.
local essenceBarConfig = {
    barType = "essence",
    displayName = "Essence Bar",
    dbKey = "essenceBar",
    defaults = NivUI.essenceBarDefaults,
    contentHeight = 500,
    sections = {
        { type = "enable" },
        { type = "header", text = "General" },
        { type = "visibility", applyFunc = function() NivUI.EssenceBar_UpdateVisibility() end },
        { type = "header", text = "Appearance" },
        { type = "spacingSlider", rebuildFunc = function() if NivUI.EssenceBar then NivUI.EssenceBar:RebuildSegments() end end },
        { type = "emptyColor", applyFunc = function() NivUI.EssenceBar_ApplyColors() end },
        { type = "filledColor", applyFunc = function() NivUI.EssenceBar_ApplyColors() end },
        { type = "borderColor", applyFunc = function() NivUI.EssenceBar_ApplyBorder() end },
        { type = "header", text = "Position" },
        { type = "lockedCheckbox", applyFunc = function() NivUI.EssenceBar_ApplyLockState() end },
        { type = "widthSlider", min = 60, max = 400, applyFunc = function() NivUI.EssenceBar_LoadPosition() end, rebuildFunc = function() if NivUI.EssenceBar then NivUI.EssenceBar:RebuildSegments() end end },
        { type = "heightSlider", applyFunc = function() NivUI.EssenceBar_LoadPosition() end, rebuildFunc = function() if NivUI.EssenceBar then NivUI.EssenceBar:RebuildSegments() end end },
        { type = "intervalSlider" },
    },
}

--- Configuration table for the Combo Points Bar config panel.
local comboPointsBarConfig = {
    barType = "comboPoints",
    displayName = "Combo Points Bar",
    dbKey = "comboPointsBar",
    defaults = NivUI.comboPointsBarDefaults,
    contentHeight = 500,
    sections = {
        { type = "enable" },
        { type = "header", text = "General" },
        { type = "visibility", applyFunc = function() NivUI.ComboPointsBar_UpdateVisibility() end },
        { type = "header", text = "Appearance" },
        { type = "spacingSlider", rebuildFunc = function() if NivUI.ComboPointsBar then NivUI.ComboPointsBar:RebuildSegments() end end },
        { type = "emptyColor", applyFunc = function() NivUI.ComboPointsBar_ApplyColors() end },
        { type = "filledColor", applyFunc = function() NivUI.ComboPointsBar_ApplyColors() end },
        { type = "borderColor", applyFunc = function() NivUI.ComboPointsBar_ApplyBorder() end },
        { type = "header", text = "Position" },
        { type = "lockedCheckbox", applyFunc = function() NivUI.ComboPointsBar_ApplyLockState() end },
        { type = "widthSlider", min = 60, max = 400, applyFunc = function() NivUI.ComboPointsBar_LoadPosition() end, rebuildFunc = function() if NivUI.ComboPointsBar then NivUI.ComboPointsBar:RebuildSegments() end end },
        { type = "heightSlider", applyFunc = function() NivUI.ComboPointsBar_LoadPosition() end, rebuildFunc = function() if NivUI.ComboPointsBar then NivUI.ComboPointsBar:RebuildSegments() end end },
        { type = "intervalSlider" },
    },
}

--- Configuration table for the Holy Power Bar config panel.
local holyPowerBarConfig = {
    barType = "holyPower",
    displayName = "Holy Power Bar",
    dbKey = "holyPowerBar",
    defaults = NivUI.holyPowerBarDefaults,
    contentHeight = 500,
    sections = {
        { type = "enable" },
        { type = "header", text = "General" },
        { type = "visibility", applyFunc = function() NivUI.HolyPowerBar_UpdateVisibility() end },
        { type = "header", text = "Appearance" },
        { type = "spacingSlider", rebuildFunc = function() if NivUI.HolyPowerBar then NivUI.HolyPowerBar:RebuildSegments() end end },
        { type = "emptyColor", applyFunc = function() NivUI.HolyPowerBar_ApplyColors() end },
        { type = "filledColor", applyFunc = function() NivUI.HolyPowerBar_ApplyColors() end },
        { type = "borderColor", applyFunc = function() NivUI.HolyPowerBar_ApplyBorder() end },
        { type = "header", text = "Position" },
        { type = "lockedCheckbox", applyFunc = function() NivUI.HolyPowerBar_ApplyLockState() end },
        { type = "widthSlider", min = 60, max = 400, applyFunc = function() NivUI.HolyPowerBar_LoadPosition() end, rebuildFunc = function() if NivUI.HolyPowerBar then NivUI.HolyPowerBar:RebuildSegments() end end },
        { type = "heightSlider", applyFunc = function() NivUI.HolyPowerBar_LoadPosition() end, rebuildFunc = function() if NivUI.HolyPowerBar then NivUI.HolyPowerBar:RebuildSegments() end end },
        { type = "intervalSlider" },
    },
}

--- Configuration table for the Soul Shards Bar config panel.
local soulShardsBarConfig = {
    barType = "soulShards",
    displayName = "Soul Shards Bar",
    dbKey = "soulShardsBar",
    defaults = NivUI.soulShardsBarDefaults,
    contentHeight = 500,
    sections = {
        { type = "enable" },
        { type = "header", text = "General" },
        { type = "visibility", applyFunc = function() NivUI.SoulShardsBar_UpdateVisibility() end },
        { type = "header", text = "Appearance" },
        { type = "spacingSlider", rebuildFunc = function() if NivUI.SoulShardsBar then NivUI.SoulShardsBar:RebuildSegments() end end },
        { type = "emptyColor", applyFunc = function() NivUI.SoulShardsBar_ApplyColors() end },
        { type = "filledColor", applyFunc = function() NivUI.SoulShardsBar_ApplyColors() end },
        { type = "borderColor", applyFunc = function() NivUI.SoulShardsBar_ApplyBorder() end },
        { type = "header", text = "Position" },
        { type = "lockedCheckbox", applyFunc = function() NivUI.SoulShardsBar_ApplyLockState() end },
        { type = "widthSlider", min = 60, max = 400, applyFunc = function() NivUI.SoulShardsBar_LoadPosition() end, rebuildFunc = function() if NivUI.SoulShardsBar then NivUI.SoulShardsBar:RebuildSegments() end end },
        { type = "heightSlider", applyFunc = function() NivUI.SoulShardsBar_LoadPosition() end, rebuildFunc = function() if NivUI.SoulShardsBar then NivUI.SoulShardsBar:RebuildSegments() end end },
        { type = "intervalSlider" },
    },
}

--- Configuration table for the Arcane Charges Bar config panel.
local arcaneChargesBarConfig = {
    barType = "arcaneCharges",
    displayName = "Arcane Charges Bar",
    dbKey = "arcaneChargesBar",
    defaults = NivUI.arcaneChargesBarDefaults,
    contentHeight = 500,
    sections = {
        { type = "enable" },
        { type = "header", text = "General" },
        { type = "visibility", applyFunc = function() NivUI.ArcaneChargesBar_UpdateVisibility() end },
        { type = "header", text = "Appearance" },
        { type = "spacingSlider", rebuildFunc = function() if NivUI.ArcaneChargesBar then NivUI.ArcaneChargesBar:RebuildSegments() end end },
        { type = "emptyColor", applyFunc = function() NivUI.ArcaneChargesBar_ApplyColors() end },
        { type = "filledColor", applyFunc = function() NivUI.ArcaneChargesBar_ApplyColors() end },
        { type = "borderColor", applyFunc = function() NivUI.ArcaneChargesBar_ApplyBorder() end },
        { type = "header", text = "Position" },
        { type = "lockedCheckbox", applyFunc = function() NivUI.ArcaneChargesBar_ApplyLockState() end },
        { type = "widthSlider", min = 60, max = 400, applyFunc = function() NivUI.ArcaneChargesBar_LoadPosition() end, rebuildFunc = function() if NivUI.ArcaneChargesBar then NivUI.ArcaneChargesBar:RebuildSegments() end end },
        { type = "heightSlider", applyFunc = function() NivUI.ArcaneChargesBar_LoadPosition() end, rebuildFunc = function() if NivUI.ArcaneChargesBar then NivUI.ArcaneChargesBar:RebuildSegments() end end },
        { type = "intervalSlider" },
    },
}

--- Configuration table for the Rune Bar config panel.
local runeBarConfig = {
    barType = "rune",
    displayName = "Rune Bar",
    dbKey = "runeBar",
    defaults = NivUI.runeBarDefaults,
    contentHeight = 500,
    sections = {
        { type = "enable" },
        { type = "header", text = "General" },
        { type = "visibility", applyFunc = function() NivUI.RuneBar_UpdateVisibility() end },
        { type = "header", text = "Appearance" },
        { type = "spacingSlider", rebuildFunc = function() if NivUI.RuneBar then NivUI.RuneBar:RebuildSegments() end end },
        { type = "emptyColor", applyFunc = function() NivUI.RuneBar_ApplyColors() end },
        { type = "filledColor", applyFunc = function() NivUI.RuneBar_ApplyColors() end },
        { type = "borderColor", applyFunc = function() NivUI.RuneBar_ApplyBorder() end },
        { type = "header", text = "Position" },
        { type = "lockedCheckbox", applyFunc = function() NivUI.RuneBar_ApplyLockState() end },
        { type = "widthSlider", min = 120, max = 480, applyFunc = function() NivUI.RuneBar_LoadPosition() end, rebuildFunc = function() if NivUI.RuneBar then NivUI.RuneBar:RebuildSegments() end end },
        { type = "heightSlider", applyFunc = function() NivUI.RuneBar_LoadPosition() end, rebuildFunc = function() if NivUI.RuneBar then NivUI.RuneBar:RebuildSegments() end end },
        { type = "intervalSlider" },
    },
}

NivUI.Config.Bars.staggerBarConfig = staggerBarConfig
NivUI.Config.Bars.chiBarConfig = chiBarConfig
NivUI.Config.Bars.essenceBarConfig = essenceBarConfig
NivUI.Config.Bars.comboPointsBarConfig = comboPointsBarConfig
NivUI.Config.Bars.holyPowerBarConfig = holyPowerBarConfig
NivUI.Config.Bars.soulShardsBarConfig = soulShardsBarConfig
NivUI.Config.Bars.arcaneChargesBarConfig = arcaneChargesBarConfig
NivUI.Config.Bars.runeBarConfig = runeBarConfig

--- Factory function to build a class bar configuration panel.
--- @param parent Frame The parent frame to attach the config panel to.
--- @param config table Configuration table
--- @param Components table The Components table from ConfigFrame
--- @return table { container = Frame, widthSlider = Frame|nil, heightSlider = Frame|nil }
function NivUI.Config.Bars.BuildClassBarConfig(parent, config, Components)
    local container = CreateFrame("Frame", nil, parent)
    container:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 0)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(FRAME_WIDTH - SIDEBAR_WIDTH - 60, config.contentHeight or 500)
    scrollFrame:SetScrollChild(content)

    local allFrames = {}

    local function AddFrame(frame, spacing)
        spacing = spacing or 0
        if #allFrames == 0 then
            frame:SetPoint("TOP", content, "TOP", 0, 0)
        else
            frame:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -spacing)
        end
        table.insert(allFrames, frame)
    end

    local refs = {}
    local onShowHandlers = {}

    for _, section in ipairs(config.sections) do
        local handler = SectionHandlers[section.type]
        if handler then
            local widget, onShow, refKey = handler(content, section, config, Components)
            if widget then
                local spacing = section.spacing
                if spacing == nil and section.type == "header" then
                    spacing = SECTION_SPACING
                end
                AddFrame(widget, spacing or 0)
            end
            if onShow then
                table.insert(onShowHandlers, onShow)
            end
            if refKey then
                refs[refKey] = widget
            end
        end
    end

    container:SetScript("OnShow", function()
        for _, onShow in ipairs(onShowHandlers) do
            onShow()
        end
    end)

    return {
        container = container,
        widthSlider = refs.widthSlider,
        heightSlider = refs.heightSlider,
    }
end

--- Sets up the Class Bars tab with subtabs for each bar type.
--- @param ContentArea Frame The content area frame
--- @param Components table The Components table from ConfigFrame
--- @return Frame container The tab container
--- @return table results Table with stagger, chi, essence results for OnBarMoved
function NivUI.Config.Bars.SetupTab(ContentArea, Components)
    local container = CreateFrame("Frame", nil, ContentArea)
    container:SetAllPoints()
    container:Hide()

    local subTabs = {}
    local subTabContainers = {}
    local currentSubTab = 1

    local function SelectSubTab(index)
        for i, tab in ipairs(subTabs) do
            if i == index then
                PanelTemplates_SelectTab(tab)
                subTabContainers[i]:Show()
            else
                PanelTemplates_DeselectTab(tab)
                subTabContainers[i]:Hide()
            end
        end
        currentSubTab = index
    end

    local staggerResult = NivUI.Config.Bars.BuildClassBarConfig(container, staggerBarConfig, Components)
    staggerResult.container:SetPoint("TOPLEFT", 0, -42)
    staggerResult.container:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, staggerResult.container)

    local staggerTab = Components.GetTab(container, "Stagger")
    staggerTab:SetPoint("TOPLEFT", 0, 0)
    staggerTab:SetScript("OnClick", function() SelectSubTab(1) end)
    table.insert(subTabs, staggerTab)

    local chiResult = NivUI.Config.Bars.BuildClassBarConfig(container, chiBarConfig, Components)
    chiResult.container:SetPoint("TOPLEFT", 0, -42)
    chiResult.container:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, chiResult.container)

    local chiTab = Components.GetTab(container, "Chi")
    chiTab:SetPoint("LEFT", staggerTab, "RIGHT", 0, 0)
    chiTab:SetScript("OnClick", function() SelectSubTab(2) end)
    table.insert(subTabs, chiTab)

    local essenceResult = NivUI.Config.Bars.BuildClassBarConfig(container, essenceBarConfig, Components)
    essenceResult.container:SetPoint("TOPLEFT", 0, -42)
    essenceResult.container:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, essenceResult.container)

    local essenceTab = Components.GetTab(container, "Essence")
    essenceTab:SetPoint("LEFT", chiTab, "RIGHT", 0, 0)
    essenceTab:SetScript("OnClick", function() SelectSubTab(3) end)
    table.insert(subTabs, essenceTab)

    local comboPointsResult = NivUI.Config.Bars.BuildClassBarConfig(container, comboPointsBarConfig, Components)
    comboPointsResult.container:SetPoint("TOPLEFT", 0, -42)
    comboPointsResult.container:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, comboPointsResult.container)

    local comboPointsTab = Components.GetTab(container, "Combo")
    comboPointsTab:SetPoint("LEFT", essenceTab, "RIGHT", 0, 0)
    comboPointsTab:SetScript("OnClick", function() SelectSubTab(4) end)
    table.insert(subTabs, comboPointsTab)

    local holyPowerResult = NivUI.Config.Bars.BuildClassBarConfig(container, holyPowerBarConfig, Components)
    holyPowerResult.container:SetPoint("TOPLEFT", 0, -42)
    holyPowerResult.container:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, holyPowerResult.container)

    local holyPowerTab = Components.GetTab(container, "Holy")
    holyPowerTab:SetPoint("LEFT", comboPointsTab, "RIGHT", 0, 0)
    holyPowerTab:SetScript("OnClick", function() SelectSubTab(5) end)
    table.insert(subTabs, holyPowerTab)

    local soulShardsResult = NivUI.Config.Bars.BuildClassBarConfig(container, soulShardsBarConfig, Components)
    soulShardsResult.container:SetPoint("TOPLEFT", 0, -42)
    soulShardsResult.container:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, soulShardsResult.container)

    local soulShardsTab = Components.GetTab(container, "Shards")
    soulShardsTab:SetPoint("LEFT", holyPowerTab, "RIGHT", 0, 0)
    soulShardsTab:SetScript("OnClick", function() SelectSubTab(6) end)
    table.insert(subTabs, soulShardsTab)

    local arcaneChargesResult = NivUI.Config.Bars.BuildClassBarConfig(container, arcaneChargesBarConfig, Components)
    arcaneChargesResult.container:SetPoint("TOPLEFT", 0, -42)
    arcaneChargesResult.container:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, arcaneChargesResult.container)

    local arcaneChargesTab = Components.GetTab(container, "Arcane")
    arcaneChargesTab:SetPoint("LEFT", soulShardsTab, "RIGHT", 0, 0)
    arcaneChargesTab:SetScript("OnClick", function() SelectSubTab(7) end)
    table.insert(subTabs, arcaneChargesTab)

    local runeResult = NivUI.Config.Bars.BuildClassBarConfig(container, runeBarConfig, Components)
    runeResult.container:SetPoint("TOPLEFT", 0, -42)
    runeResult.container:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, runeResult.container)

    local runeTab = Components.GetTab(container, "Runes")
    runeTab:SetPoint("LEFT", arcaneChargesTab, "RIGHT", 0, 0)
    runeTab:SetScript("OnClick", function() SelectSubTab(8) end)
    table.insert(subTabs, runeTab)

    container:SetScript("OnShow", function()
        SelectSubTab(currentSubTab)
    end)

    return container, {
        stagger = staggerResult,
        chi = chiResult,
        essence = essenceResult,
        comboPoints = comboPointsResult,
        holyPower = holyPowerResult,
        soulShards = soulShardsResult,
        arcaneCharges = arcaneChargesResult,
        rune = runeResult,
    }
end

--- Sets up the OnBarMoved callback for updating sliders when bars are moved.
--- @param results table The results table from SetupTab
function NivUI.Config.Bars.SetupOnBarMoved(results)
    NivUI.OnBarMoved = function()
        local staggerDb = NivUI.current.staggerBar
        local staggerDefaults = NivUI.staggerBarDefaults
        if results.stagger and results.stagger.widthSlider then
            results.stagger.widthSlider:SetValue(staggerDb.width or staggerDefaults.width)
        end
        if results.stagger and results.stagger.heightSlider then
            results.stagger.heightSlider:SetValue(staggerDb.height or staggerDefaults.height)
        end

        local chiDb = NivUI.current.chiBar or {}
        local chiDefaults = NivUI.chiBarDefaults
        if results.chi and results.chi.widthSlider then
            results.chi.widthSlider:SetValue(chiDb.width or chiDefaults.width)
        end
        if results.chi and results.chi.heightSlider then
            results.chi.heightSlider:SetValue(chiDb.height or chiDefaults.height)
        end

        local essenceDb = NivUI.current.essenceBar or {}
        local essenceDefaults = NivUI.essenceBarDefaults
        if results.essence and results.essence.widthSlider then
            results.essence.widthSlider:SetValue(essenceDb.width or essenceDefaults.width)
        end
        if results.essence and results.essence.heightSlider then
            results.essence.heightSlider:SetValue(essenceDb.height or essenceDefaults.height)
        end

        local comboPointsDb = NivUI.current.comboPointsBar or {}
        local comboPointsDefaults = NivUI.comboPointsBarDefaults
        if results.comboPoints and results.comboPoints.widthSlider then
            results.comboPoints.widthSlider:SetValue(comboPointsDb.width or comboPointsDefaults.width)
        end
        if results.comboPoints and results.comboPoints.heightSlider then
            results.comboPoints.heightSlider:SetValue(comboPointsDb.height or comboPointsDefaults.height)
        end

        local holyPowerDb = NivUI.current.holyPowerBar or {}
        local holyPowerDefaults = NivUI.holyPowerBarDefaults
        if results.holyPower and results.holyPower.widthSlider then
            results.holyPower.widthSlider:SetValue(holyPowerDb.width or holyPowerDefaults.width)
        end
        if results.holyPower and results.holyPower.heightSlider then
            results.holyPower.heightSlider:SetValue(holyPowerDb.height or holyPowerDefaults.height)
        end

        local soulShardsDb = NivUI.current.soulShardsBar or {}
        local soulShardsDefaults = NivUI.soulShardsBarDefaults
        if results.soulShards and results.soulShards.widthSlider then
            results.soulShards.widthSlider:SetValue(soulShardsDb.width or soulShardsDefaults.width)
        end
        if results.soulShards and results.soulShards.heightSlider then
            results.soulShards.heightSlider:SetValue(soulShardsDb.height or soulShardsDefaults.height)
        end

        local arcaneChargesDb = NivUI.current.arcaneChargesBar or {}
        local arcaneChargesDefaults = NivUI.arcaneChargesBarDefaults
        if results.arcaneCharges and results.arcaneCharges.widthSlider then
            results.arcaneCharges.widthSlider:SetValue(arcaneChargesDb.width or arcaneChargesDefaults.width)
        end
        if results.arcaneCharges and results.arcaneCharges.heightSlider then
            results.arcaneCharges.heightSlider:SetValue(arcaneChargesDb.height or arcaneChargesDefaults.height)
        end

        local runeDb = NivUI.current.runeBar or {}
        local runeDefaults = NivUI.runeBarDefaults
        if results.rune and results.rune.widthSlider then
            results.rune.widthSlider:SetValue(runeDb.width or runeDefaults.width)
        end
        if results.rune and results.rune.heightSlider then
            results.rune.heightSlider:SetValue(runeDb.height or runeDefaults.height)
        end
    end
end
