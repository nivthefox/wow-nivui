local FRAME_WIDTH = 680
local FRAME_HEIGHT = 650
local ROW_HEIGHT = 32
local SECTION_SPACING = 20
local SIDEBAR_WIDTH = 100

local Components = {}

function Components.GetCheckbox(parent, label, callback)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(ROW_HEIGHT)
    holder:SetPoint("LEFT", 20, 0)
    holder:SetPoint("RIGHT", -20, 0)

    local checkBox = CreateFrame("CheckButton", nil, holder, "SettingsCheckboxTemplate")
    checkBox:SetPoint("LEFT", holder, "CENTER", -15, 0)
    checkBox:SetText(label)
    checkBox:SetNormalFontObject(GameFontHighlight)
    checkBox:GetFontString():SetPoint("RIGHT", holder, "CENTER", -30, 0)
    checkBox:GetFontString():SetPoint("LEFT", holder, 20, 0)
    checkBox:GetFontString():SetJustifyH("RIGHT")

    function holder:SetValue(value)
        checkBox:SetChecked(value)
    end

    function holder:GetValue()
        return checkBox:GetChecked()
    end

    holder:SetScript("OnEnter", function()
        if checkBox.OnEnter then checkBox:OnEnter() end
    end)

    holder:SetScript("OnLeave", function()
        if checkBox.OnLeave then checkBox:OnLeave() end
    end)

    holder:SetScript("OnMouseUp", function()
        checkBox:Click()
    end)

    checkBox:SetScript("OnClick", function()
        if callback then callback(checkBox:GetChecked()) end
    end)

    return holder
end

function Components.GetBasicDropdown(parent, labelText, getItems, isSelectedCallback, onSelectionCallback)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(ROW_HEIGHT)
    frame:SetPoint("LEFT", 20, 0)
    frame:SetPoint("RIGHT", -20, 0)

    local dropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(200)
    dropdown:SetPoint("LEFT", frame, "CENTER", -20, 0)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", 0, 0)
    label:SetPoint("RIGHT", frame, "CENTER", -40, 0)
    label:SetJustifyH("RIGHT")
    label:SetText(labelText)

    dropdown:SetupMenu(function(_, rootDescription)
        local items = getItems()
        for _, item in ipairs(items) do
            rootDescription:CreateRadio(
                item.name,
                function() return isSelectedCallback(item.value) end,
                function() onSelectionCallback(item.value) end
            )
        end
    end)

    function frame:SetValue()
        dropdown:GenerateMenu()
    end

    frame.Label = label
    frame.DropDown = dropdown

    return frame
end

function Components.GetTextureDropdown(parent, labelText, getTextures, getValue, onSelect)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(ROW_HEIGHT)
    frame:SetPoint("LEFT", 20, 0)
    frame:SetPoint("RIGHT", -20, 0)

    local dropdown = CreateFrame("DropdownButton", nil, frame, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(200)
    dropdown:SetPoint("LEFT", frame, "CENTER", -20, 0)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", 0, 0)
    label:SetPoint("RIGHT", frame, "CENTER", -40, 0)
    label:SetJustifyH("RIGHT")
    label:SetText(labelText)

    dropdown:SetupMenu(function(_, rootDescription)
        local textures = getTextures()
        for _, tex in ipairs(textures) do
            local preview
            if tex.path then
                preview = "|T" .. tex.path .. ":16:80|t " .. tex.name
            else
                preview = tex.name
            end
            rootDescription:CreateRadio(
                preview,
                function() return getValue() == tex.value end,
                function() onSelect(tex.value) end
            )
        end
        rootDescription:SetScrollMode(20 * 10)
    end)

    function frame:SetValue()
        dropdown:GenerateMenu()
    end

    frame.Label = label
    frame.DropDown = dropdown

    return frame
end

function Components.GetSliderWithInput(parent, labelText, min, max, step, isDecimal, callback)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(ROW_HEIGHT)
    holder:SetPoint("LEFT", 20, 0)
    holder:SetPoint("RIGHT", -20, 0)

    holder.Label = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    holder.Label:SetJustifyH("RIGHT")
    holder.Label:SetPoint("LEFT", 0, 0)
    holder.Label:SetPoint("RIGHT", holder, "CENTER", -40, 0)
    holder.Label:SetText(labelText)

    local editBox = CreateFrame("EditBox", nil, holder, "InputBoxTemplate")
    editBox:SetSize(50, 20)
    editBox:SetPoint("RIGHT", -5, 0)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(not isDecimal)
    editBox:SetMaxLetters(6)

    holder.Slider = CreateFrame("Slider", nil, holder, "MinimalSliderWithSteppersTemplate")
    holder.Slider:SetPoint("LEFT", holder, "CENTER", -20, 0)
    holder.Slider:SetPoint("RIGHT", editBox, "LEFT", -10, 0)
    holder.Slider:SetHeight(20)

    local numSteps = math.floor((max - min) / step)
    holder.Slider:Init(min, min, max, numSteps, {})

    local updatingFromSlider = false
    local updatingFromInput = false

    holder.Slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if updatingFromInput then return end
        updatingFromSlider = true
        if isDecimal then
            editBox:SetText(string.format("%.2f", value))
        else
            editBox:SetText(tostring(math.floor(value)))
        end
        updatingFromSlider = false
        if callback then callback(value) end
    end)

    local function ApplyInputValue()
        if updatingFromSlider then return end
        local text = editBox:GetText()
        local value = tonumber(text)
        if value then
            value = math.max(min, math.min(max, value))
            updatingFromInput = true
            holder.Slider:SetValue(value)
            updatingFromInput = false
            if callback then callback(value) end
        end
    end

    editBox:SetScript("OnEnterPressed", function(self)
        ApplyInputValue()
        self:ClearFocus()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    editBox:SetScript("OnEditFocusLost", function()
        ApplyInputValue()
    end)

    function holder:GetValue()
        return holder.Slider.Slider:GetValue()
    end

    function holder:SetValue(value)
        updatingFromSlider = true
        holder.Slider:SetValue(value)
        if isDecimal then
            editBox:SetText(string.format("%.2f", value))
        else
            editBox:SetText(tostring(math.floor(value)))
        end
        updatingFromSlider = false
    end

    holder:SetScript("OnMouseWheel", function(_, delta)
        if holder.Slider.Slider:IsEnabled() then
            holder.Slider:SetValue(holder.Slider.Slider:GetValue() + delta * step)
        end
    end)

    holder.EditBox = editBox

    return holder
end

function Components.GetColorPicker(parent, labelText, hasAlpha, callback)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(ROW_HEIGHT)
    holder:SetPoint("LEFT", 20, 0)
    holder:SetPoint("RIGHT", -20, 0)

    local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", 0, 0)
    label:SetPoint("RIGHT", holder, "CENTER", -40, 0)
    label:SetJustifyH("RIGHT")
    label:SetText(labelText)

    local swatch = CreateFrame("Button", nil, holder, "ColorSwatchTemplate")
    swatch:SetPoint("LEFT", holder, "CENTER", -15, 0)

    function holder:SetValue(color)
        swatch.currentColor = CopyTable(color)
        swatch:SetColor(CreateColor(color.r, color.g, color.b))
    end

    swatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    swatch:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            local info = {}
            info.r = swatch.currentColor.r
            info.g = swatch.currentColor.g
            info.b = swatch.currentColor.b
            info.opacity = swatch.currentColor.a
            info.hasOpacity = hasAlpha

            info.swatchFunc = function()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                local a = hasAlpha and ColorPickerFrame:GetColorAlpha() or nil
                swatch.currentColor = { r = r, g = g, b = b, a = a }
                swatch:SetColor(CreateColor(r, g, b))
                if callback then callback(swatch.currentColor) end
            end

            info.cancelFunc = function(previousValues)
                swatch.currentColor = previousValues
                swatch:SetColor(CreateColor(previousValues.r, previousValues.g, previousValues.b))
                if callback then callback(previousValues) end
            end

            info.previousValues = CopyTable(swatch.currentColor)

            ColorPickerFrame:SetupColorPickerAndShow(info)
        else
            swatch.currentColor = { r = 1, g = 1, b = 1, a = hasAlpha and 1 or nil }
            swatch:SetColor(CreateColor(1, 1, 1))
            if callback then callback(swatch.currentColor) end
        end
    end)

    holder:SetScript("OnEnter", function()
        if swatch:GetScript("OnEnter") then swatch:GetScript("OnEnter")(swatch) end
    end)

    holder:SetScript("OnLeave", function()
        if swatch:GetScript("OnLeave") then swatch:GetScript("OnLeave")(swatch) end
    end)

    holder:SetScript("OnMouseUp", function(_, mouseButton)
        swatch:Click(mouseButton)
    end)

    return holder
end

function Components.GetHeader(parent, text)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetPoint("LEFT", 10, 0)
    holder:SetPoint("RIGHT", -10, 0)
    holder:SetHeight(28)

    holder.text = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    holder.text:SetText(text)
    holder.text:SetPoint("LEFT", 10, 0)

    return holder
end

function Components.GetTab(parent, text)
    local tab = CreateFrame("Button", nil, parent, "PanelTopTabButtonTemplate")
    tab:SetText(text)
    tab:SetScript("OnShow", function(self)
        PanelTemplates_TabResize(self, 15, nil, 70)
        PanelTemplates_DeselectTab(self)
    end)
    tab:GetScript("OnShow")(tab)
    return tab
end

function Components.GetSidebarTab(parent, text)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(SIDEBAR_WIDTH - 8, 28)

    btn.selectedBg = btn:CreateTexture(nil, "BACKGROUND")
    btn.selectedBg:SetAllPoints()
    btn.selectedBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    btn.selectedBg:Hide()

    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.text:SetPoint("LEFT", 8, 0)
    btn.text:SetText(text)

    function btn:SetSelected(selected)
        if selected then
            btn.selectedBg:Show()
            btn.text:SetFontObject("GameFontHighlight")
        else
            btn.selectedBg:Hide()
            btn.text:SetFontObject("GameFontNormal")
        end
    end

    return btn
end

local ConfigFrame = CreateFrame("Frame", "NivUIConfigFrame", UIParent, "ButtonFrameTemplate")
ConfigFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
ConfigFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
ConfigFrame:SetToplevel(true)
ConfigFrame:Hide()

ButtonFrameTemplate_HidePortrait(ConfigFrame)
ButtonFrameTemplate_HideButtonBar(ConfigFrame)
ConfigFrame.Inset:Hide()
ConfigFrame:SetTitle("NivUI")

ConfigFrame:SetMovable(true)
ConfigFrame:SetClampedToScreen(true)
ConfigFrame:EnableMouse(true)
ConfigFrame:RegisterForDrag("LeftButton")
ConfigFrame:SetScript("OnDragStart", ConfigFrame.StartMoving)
ConfigFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SetUserPlaced(false)
end)

ConfigFrame:SetScript("OnMouseWheel", function() end)

table.insert(UISpecialFrames, "NivUIConfigFrame")

local Sidebar = CreateFrame("Frame", nil, ConfigFrame)
Sidebar:SetWidth(SIDEBAR_WIDTH)
Sidebar:SetPoint("TOPLEFT", 8, -28)
Sidebar:SetPoint("BOTTOMLEFT", 8, 8)

local sidebarBg = Sidebar:CreateTexture(nil, "BACKGROUND")
sidebarBg:SetAllPoints()
sidebarBg:SetColorTexture(0.05, 0.05, 0.05, 0.8)

local ContentArea = CreateFrame("Frame", nil, ConfigFrame)
ContentArea:SetPoint("TOPLEFT", Sidebar, "TOPRIGHT", 4, 0)
ContentArea:SetPoint("BOTTOMRIGHT", -8, 8)

local sidebarTabs = {}
local sidebarContainers = {}
local currentSidebarTab = 1

local function SelectSidebarTab(index)
    for i, tab in ipairs(sidebarTabs) do
        if i == index then
            tab:SetSelected(true)
            sidebarContainers[i]:Show()
        else
            tab:SetSelected(false)
            sidebarContainers[i]:Hide()
        end
    end
    currentSidebarTab = index
end

--- Section handler dispatch table for BuildClassBarConfig
--- Each handler returns the widget and an optional onShow refresh function
local SectionHandlers = {}

function SectionHandlers.enable(content, section, config)
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

function SectionHandlers.header(content, section, _config)
    return Components.GetHeader(content, section.text), nil
end

function SectionHandlers.visibility(content, section, config)
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

function SectionHandlers.fgTexture(content, section, config)
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

function SectionHandlers.bgTexture(content, section, config)
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

function SectionHandlers.bgColor(content, section, config)
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

function SectionHandlers.borderDropdown(content, section, config)
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

function SectionHandlers.borderColor(content, section, config)
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

function SectionHandlers.color(content, section, config)
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

function SectionHandlers.fontDropdown(content, section, config)
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

function SectionHandlers.fontSizeSlider(content, section, config)
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

function SectionHandlers.fontColor(content, section, config)
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

function SectionHandlers.fontShadow(content, section, config)
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

function SectionHandlers.lockedCheckbox(content, section, config)
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

function SectionHandlers.widthSlider(content, section, config)
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

function SectionHandlers.heightSlider(content, section, config)
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

function SectionHandlers.intervalSlider(content, section, config)
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

function SectionHandlers.spacingSlider(content, section, config)
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

function SectionHandlers.emptyColor(content, section, config)
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

function SectionHandlers.filledColor(content, section, config)
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

--- Configuration table for the Stagger Bar config panel.
--- Uses NivUI:ApplySettings() for most settings since stagger bar uses the shared settings system.
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
--- Uses direct applyFunc callbacks since chi bar has its own update functions.
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
--- Uses direct applyFunc callbacks since essence bar has its own update functions.
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

--- Factory function to build a class bar configuration panel.
--- @param parent Frame The parent frame to attach the config panel to.
--- @param config table Configuration table with the following fields:
---   barType: string - for NivUI:IsClassBarEnabled() / SetClassBarEnabled()
---   displayName: string - for enable checkbox label
---   dbKey: string - NivUI_DB key (e.g., "staggerBar", "chiBar")
---   defaults: table - default values table
---   contentHeight: number - scroll content height
---   sections: table - array of section descriptors
--- @return table { container = Frame, widthSlider = Frame|nil, heightSlider = Frame|nil }
local function BuildClassBarConfig(parent, config)
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
            local widget, onShow, refKey = handler(content, section, config)
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

local staggerResult
local chiResult
local essenceResult
local function SetupClassBarsTabWithSubtabs()
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

    staggerResult = BuildClassBarConfig(container, staggerBarConfig)
    staggerResult.container:SetPoint("TOPLEFT", 0, -42)
    staggerResult.container:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, staggerResult.container)

    local staggerTab = Components.GetTab(container, "Stagger")
    staggerTab:SetPoint("TOPLEFT", 0, 0)
    staggerTab:SetScript("OnClick", function() SelectSubTab(1) end)
    table.insert(subTabs, staggerTab)

    chiResult = BuildClassBarConfig(container, chiBarConfig)
    chiResult.container:SetPoint("TOPLEFT", 0, -42)
    chiResult.container:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, chiResult.container)

    local chiTab = Components.GetTab(container, "Chi")
    chiTab:SetPoint("LEFT", staggerTab, "RIGHT", 0, 0)
    chiTab:SetScript("OnClick", function() SelectSubTab(2) end)
    table.insert(subTabs, chiTab)

    essenceResult = BuildClassBarConfig(container, essenceBarConfig)
    essenceResult.container:SetPoint("TOPLEFT", 0, -42)
    essenceResult.container:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, essenceResult.container)

    local essenceTab = Components.GetTab(container, "Essence")
    essenceTab:SetPoint("LEFT", chiTab, "RIGHT", 0, 0)
    essenceTab:SetScript("OnClick", function() SelectSubTab(3) end)
    table.insert(subTabs, essenceTab)

    container:SetScript("OnShow", function()
        SelectSubTab(currentSubTab)
    end)

    return container
end

local classBarsContainer = SetupClassBarsTabWithSubtabs()
table.insert(sidebarContainers, classBarsContainer)

local classBarsTab = Components.GetSidebarTab(Sidebar, "Class Bars")
classBarsTab:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", 4, -8)
classBarsTab:SetScript("OnClick", function() SelectSidebarTab(1) end)
table.insert(sidebarTabs, classBarsTab)

local unitFramesContainer = NivUI.UnitFrames:SetupConfigTabWithSubtabs(ContentArea, Components)
table.insert(sidebarContainers, unitFramesContainer)

local unitFramesTab = Components.GetSidebarTab(Sidebar, "Unit Frames")
unitFramesTab:SetPoint("TOPLEFT", classBarsTab, "BOTTOMLEFT", 0, -2)
unitFramesTab:SetScript("OnClick", function() SelectSidebarTab(2) end)
table.insert(sidebarTabs, unitFramesTab)

local function CreateTextAreaDialog(name, title, readOnly)
    local dialog = CreateFrame("Frame", name, UIParent, "ButtonFrameTemplate")
    dialog:SetSize(500, 300)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)
    dialog:Hide()

    ButtonFrameTemplate_HidePortrait(dialog)
    ButtonFrameTemplate_HideButtonBar(dialog)
    dialog.Inset:Hide()
    dialog:SetTitle(title)

    dialog:SetMovable(true)
    dialog:SetClampedToScreen(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetUserPlaced(false)
    end)

    table.insert(UISpecialFrames, name)

    local scrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -32, 50)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth() - 20)
    editBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
    scrollFrame:SetScrollChild(editBox)
    dialog.EditBox = editBox

    if readOnly then
        editBox:SetScript("OnChar", function() end)
        editBox:SetScript("OnTextChanged", function(self)
            if self.expectedText and self:GetText() ~= self.expectedText then
                self:SetText(self.expectedText)
                self:HighlightText()
            end
        end)
    end

    return dialog
end

local exportDialog = CreateTextAreaDialog("NivUIExportDialog", "Export Profile", true)

local importDialog = CreateFrame("Frame", "NivUIImportDialog", UIParent, "ButtonFrameTemplate")
do
    local dialog = importDialog
    dialog:SetSize(500, 340)
    dialog:SetPoint("CENTER")
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)
    dialog:Hide()

    ButtonFrameTemplate_HidePortrait(dialog)
    ButtonFrameTemplate_HideButtonBar(dialog)
    dialog.Inset:Hide()
    dialog:SetTitle("Import Profile")

    dialog:SetMovable(true)
    dialog:SetClampedToScreen(true)
    dialog:EnableMouse(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self:SetUserPlaced(false)
    end)

    table.insert(UISpecialFrames, "NivUIImportDialog")

    local nameLabel = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameLabel:SetPoint("TOPLEFT", 12, -30)
    nameLabel:SetText("Profile Name:")

    local nameBox = CreateFrame("EditBox", nil, dialog, "InputBoxTemplate")
    nameBox:SetSize(200, 20)
    nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
    nameBox:SetAutoFocus(false)
    dialog.NameBox = nameBox

    local scrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -55)
    scrollFrame:SetPoint("BOTTOMRIGHT", -32, 50)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scrollFrame:GetWidth() - 20)
    editBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
    scrollFrame:SetScrollChild(editBox)
    dialog.EditBox = editBox

    local acceptBtn = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")
    acceptBtn:SetText("Import")
    acceptBtn:SetWidth(100)
    acceptBtn:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -5, 12)
    acceptBtn:SetScript("OnClick", function()
        local name = nameBox:GetText()
        local text = editBox:GetText()
        if name == "" then
            print("|cffff0000NivUI:|r Please enter a profile name")
            return
        end
        local payload, err = NivUI.Profiles:DecodeImport(text)
        if payload then
            local success, createErr = NivUI.Profiles:CreateFromImport(name, payload)
            if not success then
                print("|cffff0000NivUI:|r " .. createErr)
                return
            end
        else
            print("|cffff0000NivUI:|r " .. err)
            return
        end
        dialog:Hide()
    end)

    local cancelBtn = CreateFrame("Button", nil, dialog, "UIPanelDynamicResizeButtonTemplate")
    cancelBtn:SetText(CANCEL)
    cancelBtn:SetWidth(100)
    cancelBtn:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", 5, 12)
    cancelBtn:SetScript("OnClick", function() dialog:Hide() end)

    dialog:SetScript("OnShow", function()
        nameBox:SetText("")
        editBox:SetText("")
        nameBox:SetFocus()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
    end)
    dialog:SetScript("OnHide", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
    end)
end

local function SetupProfilesTab()
    local container = CreateFrame("Frame", nil, ContentArea)
    container:SetAllPoints()
    container:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 0)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(FRAME_WIDTH - SIDEBAR_WIDTH - 60, 600)
    scrollFrame:SetScrollChild(content)

    local allFrames = {}
    local onShowHandlers = {}

    local function AddFrame(frame, spacing)
        spacing = spacing or 0
        if #allFrames == 0 then
            frame:SetPoint("TOP", content, "TOP", 0, 0)
        else
            frame:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -spacing)
        end
        table.insert(allFrames, frame)
    end

    local profileHeader = Components.GetHeader(content, "Profile Management")
    AddFrame(profileHeader, 0)

    local profileDropdown = Components.GetBasicDropdown(
        content,
        "Current Profile:",
        function()
            local items = {}
            local profiles = NivUI.Profiles:GetAllProfiles()
            for _, name in ipairs(profiles) do
                table.insert(items, { value = name, name = name })
            end
            return items
        end,
        function(value)
            return NivUI.Profiles:GetCurrentProfileName() == value
        end,
        function(value)
            NivUI.Profiles:SwitchProfile(value)
        end
    )
    AddFrame(profileDropdown, 0)

    table.insert(onShowHandlers, function()
        profileDropdown:SetValue()
    end)

    local buttonRow1 = CreateFrame("Frame", nil, content)
    buttonRow1:SetHeight(ROW_HEIGHT)
    buttonRow1:SetPoint("LEFT", 20, 0)
    buttonRow1:SetPoint("RIGHT", -20, 0)
    AddFrame(buttonRow1, SECTION_SPACING)

    local newProfileBtn = CreateFrame("Button", nil, buttonRow1, "UIPanelDynamicResizeButtonTemplate")
    newProfileBtn:SetText("New")
    newProfileBtn:SetWidth(80)
    newProfileBtn:SetPoint("LEFT", buttonRow1, "CENTER", -170, 0)
    newProfileBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_NEW_PROFILE")
    end)

    local copyProfileBtn = CreateFrame("Button", nil, buttonRow1, "UIPanelDynamicResizeButtonTemplate")
    copyProfileBtn:SetText("Copy")
    copyProfileBtn:SetWidth(80)
    copyProfileBtn:SetPoint("LEFT", newProfileBtn, "RIGHT", 5, 0)
    copyProfileBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_COPY_PROFILE")
    end)

    local renameProfileBtn = CreateFrame("Button", nil, buttonRow1, "UIPanelDynamicResizeButtonTemplate")
    renameProfileBtn:SetText("Rename")
    renameProfileBtn:SetWidth(80)
    renameProfileBtn:SetPoint("LEFT", copyProfileBtn, "RIGHT", 5, 0)
    renameProfileBtn:SetScript("OnClick", function()
        local current = NivUI.Profiles:GetCurrentProfileName()
        if current == "Default" then
            print("|cffff0000NivUI:|r Cannot rename the Default profile")
            return
        end
        StaticPopup_Show("NIVUI_RENAME_PROFILE", current)
    end)

    local deleteProfileBtn = CreateFrame("Button", nil, buttonRow1, "UIPanelDynamicResizeButtonTemplate")
    deleteProfileBtn:SetText("Delete")
    deleteProfileBtn:SetWidth(80)
    deleteProfileBtn:SetPoint("LEFT", renameProfileBtn, "RIGHT", 5, 0)
    deleteProfileBtn:SetScript("OnClick", function()
        local current = NivUI.Profiles:GetCurrentProfileName()
        if current == "Default" then
            print("|cffff0000NivUI:|r Cannot delete the Default profile")
            return
        end
        StaticPopup_Show("NIVUI_DELETE_PROFILE", current)
    end)

    local specHeader = Components.GetHeader(content, "Specialization Profiles")
    AddFrame(specHeader, SECTION_SPACING)

    local specDropdowns = {}
    local specDropdownsCreated = false

    local function GetSpecMeta()
        local n = type(GetNumSpecializations) == "function" and GetNumSpecializations() or 0
        local out = {}
        for i = 1, n do
            local specID, specName, _, specIcon = GetSpecializationInfo(i)
            if type(specID) == "number" and type(specName) == "string" then
                out[#out + 1] = { id = specID, name = specName, icon = specIcon }
            end
        end
        return out
    end

    local function UpdateSpecDropdowns()
        local enabled = NivUI.Profiles:IsSpecAutoSwitchEnabled()
        for _, row in ipairs(specDropdowns) do
            row.DropDown:SetEnabled(enabled)
            local specID = row.specID
            local cur = NivUI.Profiles:GetSpecProfile(specID)
            if cur and not NivUI.Profiles:ProfileExists(cur) then
                NivUI.Profiles:SetSpecProfile(specID, nil)
            end
            row:SetValue()
        end
    end

    local specAutoSwitch = Components.GetCheckbox(
        content,
        "Auto-switch by spec",
        function(checked)
            NivUI.Profiles:SetSpecAutoSwitchEnabled(checked)
            UpdateSpecDropdowns()
        end
    )
    AddFrame(specAutoSwitch, 0)

    local exportHeader = Components.GetHeader(content, "Import / Export")

    local function RepositionExportHeader()
        local anchor = specAutoSwitch
        if #specDropdowns > 0 then
            anchor = specDropdowns[#specDropdowns]
        end
        exportHeader:ClearAllPoints()
        exportHeader:SetPoint("LEFT", 10, 0)
        exportHeader:SetPoint("RIGHT", -10, 0)
        exportHeader:SetPoint("TOP", anchor, "BOTTOM", 0, -SECTION_SPACING)
    end

    local function EnsureSpecDropdowns()
        if specDropdownsCreated then
            return
        end
        specDropdownsCreated = true

        local specs = GetSpecMeta()
        for i, spec in ipairs(specs) do
            local specDropdown = Components.GetBasicDropdown(
                content,
                spec.name .. ":",
                function()
                    local items = {}
                    local profiles = NivUI.Profiles:GetAllProfiles()
                    for _, name in ipairs(profiles) do
                        table.insert(items, { value = name, name = name })
                    end
                    return items
                end,
                function(value)
                    local mapped = NivUI.Profiles:GetSpecProfile(spec.id)
                    local effective = mapped or NivUI.Profiles:GetCurrentProfileName()
                    return effective == value
                end,
                function(value)
                    NivUI.Profiles:SetSpecProfile(spec.id, value)
                end
            )
            specDropdown.specID = spec.id
            table.insert(specDropdowns, specDropdown)

            local anchor = (i == 1) and specAutoSwitch or specDropdowns[i - 1]
            specDropdown:SetPoint("TOP", anchor, "BOTTOM", 0, 0)
        end

        RepositionExportHeader()
    end

    table.insert(onShowHandlers, function()
        specAutoSwitch:SetValue(NivUI.Profiles:IsSpecAutoSwitchEnabled())
        EnsureSpecDropdowns()
        UpdateSpecDropdowns()
    end)

    exportHeader:SetPoint("TOP", specAutoSwitch, "BOTTOM", 0, -SECTION_SPACING)

    local buttonRow3 = CreateFrame("Frame", nil, content)
    buttonRow3:SetHeight(ROW_HEIGHT)
    buttonRow3:SetPoint("LEFT", 20, 0)
    buttonRow3:SetPoint("RIGHT", -20, 0)
    buttonRow3:SetPoint("TOP", exportHeader, "BOTTOM", 0, 0)

    local exportProfileBtn = CreateFrame("Button", nil, buttonRow3, "UIPanelDynamicResizeButtonTemplate")
    exportProfileBtn:SetText("Export Profile")
    exportProfileBtn:SetWidth(110)
    exportProfileBtn:SetPoint("LEFT", buttonRow3, "CENTER", -115, 0)
    exportProfileBtn:SetScript("OnClick", function()
        local str = NivUI.Profiles:ExportCurrentProfile()
        exportDialog.EditBox.expectedText = str
        exportDialog.EditBox:SetText(str)
        exportDialog.EditBox:HighlightText()
        exportDialog:Show()
        exportDialog.EditBox:SetFocus()
    end)

    local importProfileBtn = CreateFrame("Button", nil, buttonRow3, "UIPanelDynamicResizeButtonTemplate")
    importProfileBtn:SetText("Import Profile")
    importProfileBtn:SetWidth(110)
    importProfileBtn:SetPoint("LEFT", exportProfileBtn, "RIGHT", 5, 0)
    importProfileBtn:SetScript("OnClick", function()
        importDialog:Show()
    end)

    container:SetScript("OnShow", function()
        for _, onShow in ipairs(onShowHandlers) do
            onShow()
        end
    end)

    return container
end

StaticPopupDialogs["NIVUI_NEW_PROFILE"] = {
    text = "Enter a name for the new profile:",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    editBoxWidth = 200,
    OnAccept = function(self)
        local name = self.EditBox:GetText()
        local success, err = NivUI.Profiles:CreateProfile(name)
        if not success and err then
            print("|cffff0000NivUI:|r " .. err)
        end
    end,
    OnShow = function(self)
        self.EditBox:SetText("")
        self.EditBox:SetFocus()
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local name = parent.EditBox:GetText()
        local success, err = NivUI.Profiles:CreateProfile(name)
        if not success and err then
            print("|cffff0000NivUI:|r " .. err)
        end
        parent:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["NIVUI_COPY_PROFILE"] = {
    text = "Enter a name for the copy:",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    editBoxWidth = 200,
    OnAccept = function(self)
        local name = self.EditBox:GetText()
        local current = NivUI.Profiles:GetCurrentProfileName()
        local success, err = NivUI.Profiles:CopyProfile(current, name)
        if not success and err then
            print("|cffff0000NivUI:|r " .. err)
        end
    end,
    OnShow = function(self)
        self.EditBox:SetText("")
        self.EditBox:SetFocus()
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local name = parent.EditBox:GetText()
        local current = NivUI.Profiles:GetCurrentProfileName()
        local success, err = NivUI.Profiles:CopyProfile(current, name)
        if not success and err then
            print("|cffff0000NivUI:|r " .. err)
        end
        parent:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["NIVUI_RENAME_PROFILE"] = {
    text = "Enter a new name for profile '%s':",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    editBoxWidth = 200,
    OnAccept = function(self, data)
        local newName = self.EditBox:GetText()
        local success, err = NivUI.Profiles:RenameProfile(data, newName)
        if not success and err then
            print("|cffff0000NivUI:|r " .. err)
        end
    end,
    OnShow = function(self, data)
        self.EditBox:SetText(data)
        self.EditBox:HighlightText()
        self.EditBox:SetFocus()
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local newName = parent.EditBox:GetText()
        local success, err = NivUI.Profiles:RenameProfile(parent.data, newName)
        if not success and err then
            print("|cffff0000NivUI:|r " .. err)
        end
        parent:Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["NIVUI_DELETE_PROFILE"] = {
    text = "Are you sure you want to delete the profile '%s'?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        local current = NivUI.Profiles:GetCurrentProfileName()
        local _, err = NivUI.Profiles:DeleteProfile(current)
        if err then
            print("|cffff0000NivUI:|r " .. err)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local profilesContainer = SetupProfilesTab()
table.insert(sidebarContainers, profilesContainer)

local profilesTab = Components.GetSidebarTab(Sidebar, "Profiles")
profilesTab:SetPoint("TOPLEFT", unitFramesTab, "BOTTOMLEFT", 0, -2)
profilesTab:SetScript("OnClick", function() SelectSidebarTab(3) end)
table.insert(sidebarTabs, profilesTab)

ConfigFrame:SetScript("OnShow", function()
    SelectSidebarTab(currentSidebarTab)
end)

NivUI.OnBarMoved = function()
    local staggerDb = NivUI.current.staggerBar
    local staggerDefaults = NivUI.staggerBarDefaults
    if staggerResult and staggerResult.widthSlider then
        staggerResult.widthSlider:SetValue(staggerDb.width or staggerDefaults.width)
    end
    if staggerResult and staggerResult.heightSlider then
        staggerResult.heightSlider:SetValue(staggerDb.height or staggerDefaults.height)
    end

    local chiDb = NivUI.current.chiBar or {}
    local chiDefaults = NivUI.chiBarDefaults
    if chiResult and chiResult.widthSlider then
        chiResult.widthSlider:SetValue(chiDb.width or chiDefaults.width)
    end
    if chiResult and chiResult.heightSlider then
        chiResult.heightSlider:SetValue(chiDb.height or chiDefaults.height)
    end

    local essenceDb = NivUI.current.essenceBar or {}
    local essenceDefaults = NivUI.essenceBarDefaults
    if essenceResult and essenceResult.widthSlider then
        essenceResult.widthSlider:SetValue(essenceDb.width or essenceDefaults.width)
    end
    if essenceResult and essenceResult.heightSlider then
        essenceResult.heightSlider:SetValue(essenceDb.height or essenceDefaults.height)
    end
end

NivUI.staggerBarConfig = staggerBarConfig
NivUI.chiBarConfig = chiBarConfig
NivUI.essenceBarConfig = essenceBarConfig
NivUI.BuildClassBarConfig = BuildClassBarConfig
NivUI.Components = Components
NivUI.ConfigFrame = ConfigFrame
