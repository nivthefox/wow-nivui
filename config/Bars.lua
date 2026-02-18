NivUI = NivUI or {}
NivUI.Config = NivUI.Config or {}
NivUI.Config.Bars = {}

local FRAME_WIDTH = 680
local SIDEBAR_WIDTH = 100
local SECTION_SPACING = 20
local TAB_HEIGHT = 24

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

--- Auto-wires apply functions for config sections based on globalRef
--- @param sections table The sections array from the registration config
--- @param globalRef string The global reference name (e.g., "ChiBar")
local function AutoWireSections(sections, globalRef)
    for _, section in ipairs(sections) do
        -- Wire applyFunc if not already set
        if not section.applyFunc and not section.applySetting then
            if section.type == "visibility" then
                section.applyFunc = function()
                    local fn = NivUI[globalRef .. "_UpdateVisibility"]
                    if fn then fn() end
                end
            elseif section.type == "emptyColor" or section.type == "filledColor" then
                section.applyFunc = function()
                    local fn = NivUI[globalRef .. "_ApplyColors"]
                    if fn then fn() end
                end
            elseif section.type == "borderColor" then
                section.applyFunc = function()
                    local fn = NivUI[globalRef .. "_ApplyBorder"]
                    if fn then fn() end
                end
            elseif section.type == "lockedCheckbox" then
                section.applyFunc = function()
                    local fn = NivUI[globalRef .. "_ApplyLockState"]
                    if fn then fn() end
                end
            elseif section.type == "widthSlider" or section.type == "heightSlider" then
                section.applyFunc = function()
                    local fn = NivUI[globalRef .. "_LoadPosition"]
                    if fn then fn() end
                end
            end
        end

        -- Auto-wire rebuildFunc for sliders that affect segments
        if not section.rebuildFunc then
            if section.type == "spacingSlider" or section.type == "widthSlider" or section.type == "heightSlider" then
                section.rebuildFunc = function()
                    local frame = NivUI[globalRef]
                    if frame and frame.RebuildSegments then
                        frame:RebuildSegments()
                    end
                end
            end
        end
    end
end

--- Sets up the Class Bars tab with subtabs for each bar type.
--- @param ContentArea Frame The content area frame
--- @param Components table The Components table from ConfigFrame
--- @return Frame container The tab container
--- @return table results Table keyed by barType for OnBarMoved
function NivUI.Config.Bars.SetupTab(ContentArea, Components)
    local container = CreateFrame("Frame", nil, ContentArea)
    container:SetAllPoints()
    container:Hide()

    local allTabs = {}
    local results = {}
    local currentSubTab = 1

    local function SelectSubTab(index)
        for i, tabData in ipairs(allTabs) do
            if i == index then
                PanelTemplates_SelectTab(tabData.tab)
                tabData.container:Show()
            else
                PanelTemplates_DeselectTab(tabData.tab)
                tabData.container:Hide()
            end
        end
        currentSubTab = index
    end

    local function LayoutTabs()
        local containerWidth = container:GetWidth()
        if containerWidth == 0 then
            containerWidth = 600
        end

        local x, y = 0, 0
        local numRows = 1

        for _, tabData in ipairs(allTabs) do
            local tabWidth = tabData.tab:GetWidth()

            if x + tabWidth > containerWidth and x > 0 then
                x = 0
                y = y - TAB_HEIGHT
                numRows = numRows + 1
            end

            tabData.tab:ClearAllPoints()
            tabData.tab:SetPoint("TOPLEFT", container, "TOPLEFT", x, y)
            x = x + tabWidth
        end

        local contentOffset = -(numRows * TAB_HEIGHT) - 10
        for _, tabData in ipairs(allTabs) do
            tabData.container:ClearAllPoints()
            tabData.container:SetPoint("TOPLEFT", 0, contentOffset)
            tabData.container:SetPoint("BOTTOMRIGHT", 0, 0)
        end
    end

    local tabIndex = 0
    for _, regConfig in ipairs(NivUI:GetRegisteredClassBars()) do
        tabIndex = tabIndex + 1

        -- Deep copy sections to avoid mutating the registration
        local sections = {}
        for _, section in ipairs(regConfig.configSections) do
            local copy = {}
            for k, v in pairs(section) do
                copy[k] = v
            end
            table.insert(sections, copy)
        end

        -- Auto-wire apply functions
        AutoWireSections(sections, regConfig.globalRef)

        local barConfig = {
            barType = regConfig.barType,
            displayName = regConfig.displayName,
            dbKey = regConfig.dbKey,
            defaults = regConfig.defaults,
            contentHeight = regConfig.contentHeight or 500,
            sections = sections,
        }

        local result = NivUI.Config.Bars.BuildClassBarConfig(container, barConfig, Components)
        results[regConfig.barType] = result

        local tab = Components.GetTab(container, regConfig.tabName or regConfig.displayName)
        local idx = tabIndex
        tab:SetScript("OnClick", function() SelectSubTab(idx) end)

        table.insert(allTabs, {
            tab = tab,
            container = result.container,
        })
    end

    container:SetScript("OnSizeChanged", function()
        LayoutTabs()
    end)

    container:SetScript("OnShow", function()
        LayoutTabs()
        SelectSubTab(currentSubTab)
    end)

    return container, results
end

--- Sets up the OnBarMoved callback for updating sliders when bars are moved.
--- @param results table The results table from SetupTab
function NivUI.Config.Bars.SetupOnBarMoved(results)
    NivUI.OnBarMoved = function()
        for barType, regConfig in pairs(NivUI.classBarRegistry) do
            local db = NivUI.current[regConfig.dbKey] or {}
            local defaults = regConfig.defaults
            local result = results[barType]
            if result then
                if result.widthSlider then
                    result.widthSlider:SetValue(db.width or defaults.width)
                end
                if result.heightSlider then
                    result.heightSlider:SetValue(db.height or defaults.height)
                end
            end
        end
    end
end
