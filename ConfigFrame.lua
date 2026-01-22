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

-- Create a texture dropdown with preview
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
            -- Build preview: |Tpath:height:width|t name
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

-- Create a slider with +/- steppers AND an input box
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

    -- Input box on the right
    local editBox = CreateFrame("EditBox", nil, holder, "InputBoxTemplate")
    editBox:SetSize(50, 20)
    editBox:SetPoint("RIGHT", -5, 0)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(not isDecimal)
    editBox:SetMaxLetters(6)

    -- Slider in the middle
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

-- Create a color picker
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
            -- Right click resets to white
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

-- Create a section header
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

-- Create a top tab button (for sub-tabs)
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

-- Create a sidebar tab button (for left-side navigation)
function Components.GetSidebarTab(parent, text)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(SIDEBAR_WIDTH - 8, 28)

    -- Background (shown when selected)
    btn.selectedBg = btn:CreateTexture(nil, "BACKGROUND")
    btn.selectedBg:SetAllPoints()
    btn.selectedBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    btn.selectedBg:Hide()

    -- Highlight
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)

    -- Text
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

--------------------------------------------------------------------------------
-- Main Config Frame
--------------------------------------------------------------------------------

local ConfigFrame = CreateFrame("Frame", "NivUIConfigFrame", UIParent, "ButtonFrameTemplate")
ConfigFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
ConfigFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
ConfigFrame:SetToplevel(true)
ConfigFrame:Hide()

-- Customize ButtonFrameTemplate
ButtonFrameTemplate_HidePortrait(ConfigFrame)
ButtonFrameTemplate_HideButtonBar(ConfigFrame)
ConfigFrame.Inset:Hide()
ConfigFrame:SetTitle("NivUI")

-- Make movable
ConfigFrame:SetMovable(true)
ConfigFrame:SetClampedToScreen(true)
ConfigFrame:EnableMouse(true)
ConfigFrame:RegisterForDrag("LeftButton")
ConfigFrame:SetScript("OnDragStart", ConfigFrame.StartMoving)
ConfigFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SetUserPlaced(false)
end)

-- Prevent mouse wheel from scrolling parent
ConfigFrame:SetScript("OnMouseWheel", function() end)

-- Add to special frames so Escape closes it
table.insert(UISpecialFrames, "NivUIConfigFrame")

--------------------------------------------------------------------------------
-- Sidebar Tab System
--------------------------------------------------------------------------------

-- Sidebar container
local Sidebar = CreateFrame("Frame", nil, ConfigFrame)
Sidebar:SetWidth(SIDEBAR_WIDTH)
Sidebar:SetPoint("TOPLEFT", 8, -28)
Sidebar:SetPoint("BOTTOMLEFT", 8, 8)

-- Sidebar background
local sidebarBg = Sidebar:CreateTexture(nil, "BACKGROUND")
sidebarBg:SetAllPoints()
sidebarBg:SetColorTexture(0.05, 0.05, 0.05, 0.8)

-- Content area (right of sidebar)
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

--------------------------------------------------------------------------------
-- Class Bars Tab
--------------------------------------------------------------------------------

-- Creates the Stagger Bar settings content (used as a subtab)
local function SetupStaggerBarContent(parent)
    local container = CreateFrame("Frame", nil, parent)
    container:Hide()

    -- ScrollFrame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 0)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(FRAME_WIDTH - SIDEBAR_WIDTH - 60, 900)
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

    ----------------------------------------------------------------------------
    -- General Section
    ----------------------------------------------------------------------------
    local generalHeader = Components.GetHeader(content, "General")
    AddFrame(generalHeader)

    local visibilityDropdown = Components.GetBasicDropdown(
        content,
        "Bar Visible:",
        function() return NivUI:GetVisibilityOptions() end,
        function(value) return NivUI:GetSetting("visibility") == value end,
        function(value)
            NivUI_DB.staggerBar.visibility = value
            NivUI:ApplySettings("visibility")
        end
    )
    AddFrame(visibilityDropdown)

    ----------------------------------------------------------------------------
    -- Appearance Section
    ----------------------------------------------------------------------------
    local appearanceHeader = Components.GetHeader(content, "Appearance")
    AddFrame(appearanceHeader, SECTION_SPACING)

    local fgTextureDropdown = Components.GetTextureDropdown(
        content,
        "Foreground:",
        function() return NivUI:GetBarTextures() end,
        function() return NivUI:GetSetting("foregroundTexture") end,
        function(value)
            NivUI_DB.staggerBar.foregroundTexture = value
            NivUI:ApplySettings("barTexture")
        end
    )
    AddFrame(fgTextureDropdown)

    local bgTextureDropdown = Components.GetTextureDropdown(
        content,
        "Background:",
        function() return NivUI:GetBarTextures() end,
        function() return NivUI:GetSetting("backgroundTexture") end,
        function(value)
            NivUI_DB.staggerBar.backgroundTexture = value
            NivUI:ApplySettings("background")
        end
    )
    AddFrame(bgTextureDropdown)

    local bgColorPicker = Components.GetColorPicker(
        content,
        "Background Color:",
        true,
        function(color)
            NivUI_DB.staggerBar.backgroundColor = color
            NivUI:ApplySettings("background")
        end
    )
    AddFrame(bgColorPicker)

    local borderDropdown = Components.GetBasicDropdown(
        content,
        "Border Style:",
        function() return NivUI:GetBorders() end,
        function(value) return NivUI:GetSetting("borderStyle") == value end,
        function(value)
            NivUI_DB.staggerBar.borderStyle = value
            NivUI:ApplySettings("border")
        end
    )
    AddFrame(borderDropdown)

    local borderColorPicker = Components.GetColorPicker(
        content,
        "Border Color:",
        true,
        function(color)
            NivUI_DB.staggerBar.borderColor = color
            NivUI:ApplySettings("border")
        end
    )
    AddFrame(borderColorPicker)

    ----------------------------------------------------------------------------
    -- Stagger Colors Section
    ----------------------------------------------------------------------------
    local colorsHeader = Components.GetHeader(content, "Stagger Colors")
    AddFrame(colorsHeader, SECTION_SPACING)

    local lightColorPicker = Components.GetColorPicker(
        content,
        "Light:",
        false,
        function(color)
            NivUI_DB.staggerBar.colors = NivUI_DB.staggerBar.colors or {}
            NivUI_DB.staggerBar.colors.light = color
        end
    )
    AddFrame(lightColorPicker)

    local moderateColorPicker = Components.GetColorPicker(
        content,
        "Moderate:",
        false,
        function(color)
            NivUI_DB.staggerBar.colors = NivUI_DB.staggerBar.colors or {}
            NivUI_DB.staggerBar.colors.moderate = color
        end
    )
    AddFrame(moderateColorPicker)

    local heavyColorPicker = Components.GetColorPicker(
        content,
        "Heavy:",
        false,
        function(color)
            NivUI_DB.staggerBar.colors = NivUI_DB.staggerBar.colors or {}
            NivUI_DB.staggerBar.colors.heavy = color
        end
    )
    AddFrame(heavyColorPicker)

    local extremeColorPicker = Components.GetColorPicker(
        content,
        "Extreme:",
        false,
        function(color)
            NivUI_DB.staggerBar.colors = NivUI_DB.staggerBar.colors or {}
            NivUI_DB.staggerBar.colors.extreme = color
        end
    )
    AddFrame(extremeColorPicker)

    ----------------------------------------------------------------------------
    -- Text Section
    ----------------------------------------------------------------------------
    local textHeader = Components.GetHeader(content, "Text")
    AddFrame(textHeader, SECTION_SPACING)

    local fontDropdown = Components.GetBasicDropdown(
        content,
        "Font:",
        function() return NivUI:GetFonts() end,
        function(value) return NivUI:GetSetting("font") == value end,
        function(value)
            NivUI_DB.staggerBar.font = value
            NivUI:ApplySettings("font")
        end
    )
    AddFrame(fontDropdown)

    local fontSizeSlider = Components.GetSliderWithInput(
        content,
        "Font Size:",
        8, 24, 1, false,
        function(value)
            NivUI_DB.staggerBar.fontSize = value
            NivUI:ApplySettings("font")
        end
    )
    AddFrame(fontSizeSlider)

    local fontColorPicker = Components.GetColorPicker(
        content,
        "Font Color:",
        false,
        function(color)
            NivUI_DB.staggerBar.fontColor = color
            NivUI:ApplySettings("font")
        end
    )
    AddFrame(fontColorPicker)

    local fontShadowCheck = Components.GetCheckbox(
        content,
        "Text Shadow",
        function(checked)
            NivUI_DB.staggerBar.fontShadow = checked
            NivUI:ApplySettings("font")
        end
    )
    AddFrame(fontShadowCheck)

    ----------------------------------------------------------------------------
    -- Position Section
    ----------------------------------------------------------------------------
    local positionHeader = Components.GetHeader(content, "Position")
    AddFrame(positionHeader, SECTION_SPACING)

    local lockedCheck = Components.GetCheckbox(
        content,
        "Locked",
        function(checked)
            NivUI_DB.staggerBar.locked = checked
            NivUI:ApplySettings("locked")
        end
    )
    AddFrame(lockedCheck)

    local widthSlider = Components.GetSliderWithInput(
        content,
        "Width:",
        100, 600, 10, false,
        function(value)
            NivUI_DB.staggerBar.width = value
            NivUI:ApplySettings("position")
        end
    )
    AddFrame(widthSlider)

    local heightSlider = Components.GetSliderWithInput(
        content,
        "Height:",
        5, 60, 1, false,
        function(value)
            NivUI_DB.staggerBar.height = value
            NivUI:ApplySettings("position")
        end
    )
    AddFrame(heightSlider)

    local intervalSlider = Components.GetSliderWithInput(
        content,
        "Update Interval:",
        0.05, 1.0, 0.05, true,
        function(value)
            NivUI_DB.staggerBar.updateInterval = value
        end
    )
    AddFrame(intervalSlider)

    ----------------------------------------------------------------------------
    -- Refresh on show
    ----------------------------------------------------------------------------
    container:SetScript("OnShow", function()
        local db = NivUI_DB.staggerBar
        local defaults = NivUI.defaults

        -- General
        visibilityDropdown:SetValue()

        -- Appearance
        fgTextureDropdown:SetValue()
        bgTextureDropdown:SetValue()
        bgColorPicker:SetValue(db.backgroundColor or defaults.backgroundColor)
        borderDropdown:SetValue()
        borderColorPicker:SetValue(db.borderColor or defaults.borderColor)

        -- Stagger Colors
        local colors = db.colors or defaults.colors
        lightColorPicker:SetValue(colors.light)
        moderateColorPicker:SetValue(colors.moderate)
        heavyColorPicker:SetValue(colors.heavy)
        extremeColorPicker:SetValue(colors.extreme)

        -- Text
        fontDropdown:SetValue()
        fontSizeSlider:SetValue(db.fontSize or defaults.fontSize)
        fontColorPicker:SetValue(db.fontColor or defaults.fontColor)
        local shadow = db.fontShadow
        if shadow == nil then shadow = defaults.fontShadow end
        fontShadowCheck:SetValue(shadow)

        -- Position
        lockedCheck:SetValue(db.locked or false)
        widthSlider:SetValue(db.width or defaults.width)
        heightSlider:SetValue(db.height or defaults.height)
        intervalSlider:SetValue(db.updateInterval or defaults.updateInterval)
    end)

    -- Store references for external updates
    container.widthSlider = widthSlider
    container.heightSlider = heightSlider

    return container
end

-- Creates the Chi Bar settings content (used as a subtab)
local function SetupChiBarContent(parent)
    local container = CreateFrame("Frame", nil, parent)
    container:Hide()

    -- ScrollFrame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 0)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(FRAME_WIDTH - SIDEBAR_WIDTH - 60, 500)
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

    local chiDefaults = NivUI.ChiBar and NivUI.ChiBar.defaults or {
        visibility = "combat",
        spacing = 2,
        width = 200,
        height = 20,
        locked = true,
        emptyColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 },
        filledColor = { r = 0.0, g = 0.8, b = 0.6, a = 1.0 },
        borderColor = { r = 0, g = 0, b = 0, a = 1 },
        updateInterval = 0.05,
    }

    ----------------------------------------------------------------------------
    -- General Section
    ----------------------------------------------------------------------------
    local generalHeader = Components.GetHeader(content, "General")
    AddFrame(generalHeader)

    local visibilityDropdown = Components.GetBasicDropdown(
        content,
        "Bar Visible:",
        function() return NivUI:GetVisibilityOptions() end,
        function(value)
            local db = NivUI_DB.chiBar or {}
            return (db.visibility or chiDefaults.visibility) == value
        end,
        function(value)
            NivUI_DB.chiBar = NivUI_DB.chiBar or {}
            NivUI_DB.chiBar.visibility = value
            if NivUI.ChiBar and NivUI.ChiBar.UpdateVisibility then
                NivUI.ChiBar.UpdateVisibility()
            end
        end
    )
    AddFrame(visibilityDropdown)

    ----------------------------------------------------------------------------
    -- Appearance Section
    ----------------------------------------------------------------------------
    local appearanceHeader = Components.GetHeader(content, "Appearance")
    AddFrame(appearanceHeader, SECTION_SPACING)

    local spacingSlider = Components.GetSliderWithInput(
        content,
        "Segment Spacing:",
        0, 10, 1, false,
        function(value)
            NivUI_DB.chiBar = NivUI_DB.chiBar or {}
            NivUI_DB.chiBar.spacing = value
            if NivUI.ChiBar and NivUI.ChiBar.RebuildSegments then
                NivUI.ChiBar:RebuildSegments()
            end
        end
    )
    AddFrame(spacingSlider)

    local emptyColorPicker = Components.GetColorPicker(
        content,
        "Empty Color:",
        true,
        function(color)
            NivUI_DB.chiBar = NivUI_DB.chiBar or {}
            NivUI_DB.chiBar.emptyColor = color
            if NivUI.ChiBar and NivUI.ChiBar.ApplyColors then
                NivUI.ChiBar.ApplyColors()
            end
        end
    )
    AddFrame(emptyColorPicker)

    local filledColorPicker = Components.GetColorPicker(
        content,
        "Filled Color:",
        true,
        function(color)
            NivUI_DB.chiBar = NivUI_DB.chiBar or {}
            NivUI_DB.chiBar.filledColor = color
            if NivUI.ChiBar and NivUI.ChiBar.ApplyColors then
                NivUI.ChiBar.ApplyColors()
            end
        end
    )
    AddFrame(filledColorPicker)

    local borderColorPicker = Components.GetColorPicker(
        content,
        "Border Color:",
        true,
        function(color)
            NivUI_DB.chiBar = NivUI_DB.chiBar or {}
            NivUI_DB.chiBar.borderColor = color
            if NivUI.ChiBar and NivUI.ChiBar.ApplyBorder then
                NivUI.ChiBar.ApplyBorder()
            end
        end
    )
    AddFrame(borderColorPicker)

    ----------------------------------------------------------------------------
    -- Position Section
    ----------------------------------------------------------------------------
    local positionHeader = Components.GetHeader(content, "Position")
    AddFrame(positionHeader, SECTION_SPACING)

    local lockedCheck = Components.GetCheckbox(
        content,
        "Locked",
        function(checked)
            NivUI_DB.chiBar = NivUI_DB.chiBar or {}
            NivUI_DB.chiBar.locked = checked
            if NivUI.ChiBar and NivUI.ChiBar.ApplyLockState then
                NivUI.ChiBar.ApplyLockState()
            end
        end
    )
    AddFrame(lockedCheck)

    local widthSlider = Components.GetSliderWithInput(
        content,
        "Width:",
        60, 400, 10, false,
        function(value)
            NivUI_DB.chiBar = NivUI_DB.chiBar or {}
            NivUI_DB.chiBar.width = value
            if NivUI.ChiBar and NivUI.ChiBar.LoadPosition then
                NivUI.ChiBar.LoadPosition()
            end
            if NivUI.ChiBar and NivUI.ChiBar.RebuildSegments then
                NivUI.ChiBar:RebuildSegments()
            end
        end
    )
    AddFrame(widthSlider)

    local heightSlider = Components.GetSliderWithInput(
        content,
        "Height:",
        5, 60, 1, false,
        function(value)
            NivUI_DB.chiBar = NivUI_DB.chiBar or {}
            NivUI_DB.chiBar.height = value
            if NivUI.ChiBar and NivUI.ChiBar.LoadPosition then
                NivUI.ChiBar.LoadPosition()
            end
            if NivUI.ChiBar and NivUI.ChiBar.RebuildSegments then
                NivUI.ChiBar:RebuildSegments()
            end
        end
    )
    AddFrame(heightSlider)

    local intervalSlider = Components.GetSliderWithInput(
        content,
        "Update Interval:",
        0.05, 1.0, 0.05, true,
        function(value)
            NivUI_DB.chiBar = NivUI_DB.chiBar or {}
            NivUI_DB.chiBar.updateInterval = value
        end
    )
    AddFrame(intervalSlider)

    ----------------------------------------------------------------------------
    -- Refresh on show
    ----------------------------------------------------------------------------
    container:SetScript("OnShow", function()
        local db = NivUI_DB.chiBar or {}

        visibilityDropdown:SetValue()
        spacingSlider:SetValue(db.spacing or chiDefaults.spacing)
        emptyColorPicker:SetValue(db.emptyColor or chiDefaults.emptyColor)
        filledColorPicker:SetValue(db.filledColor or chiDefaults.filledColor)
        borderColorPicker:SetValue(db.borderColor or chiDefaults.borderColor)
        lockedCheck:SetValue(db.locked or false)
        widthSlider:SetValue(db.width or chiDefaults.width)
        heightSlider:SetValue(db.height or chiDefaults.height)
        intervalSlider:SetValue(db.updateInterval or chiDefaults.updateInterval)
    end)

    container.widthSlider = widthSlider
    container.heightSlider = heightSlider

    return container
end

-- Creates the Class Bars tab with subtabs
local staggerContent  -- Forward declaration for OnBarMoved callback
local chiContent  -- Forward declaration for OnBarMoved callback
local function SetupClassBarsTabWithSubtabs()
    local container = CreateFrame("Frame", nil, ContentArea)
    container:SetAllPoints()
    container:Hide()

    -- Sub-tab system
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

    -- Create Stagger sub-tab content
    staggerContent = SetupStaggerBarContent(container)
    staggerContent:SetPoint("TOPLEFT", 0, -32)
    staggerContent:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, staggerContent)

    local staggerTab = Components.GetTab(container, "Stagger")
    staggerTab:SetPoint("TOPLEFT", 0, 0)
    staggerTab:SetScript("OnClick", function() SelectSubTab(1) end)
    table.insert(subTabs, staggerTab)

    -- Create Chi sub-tab content
    chiContent = SetupChiBarContent(container)
    chiContent:SetPoint("TOPLEFT", 0, -32)
    chiContent:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, chiContent)

    local chiTab = Components.GetTab(container, "Chi")
    chiTab:SetPoint("LEFT", staggerTab, "RIGHT", 0, 0)
    chiTab:SetScript("OnClick", function() SelectSubTab(2) end)
    table.insert(subTabs, chiTab)

    -- Select first sub-tab when shown
    container:SetScript("OnShow", function()
        SelectSubTab(currentSubTab)
    end)

    return container
end

--------------------------------------------------------------------------------
-- Initialize Sidebar Tabs
--------------------------------------------------------------------------------

-- Class Bars tab (includes Stagger as sub-tab)
local classBarsContainer = SetupClassBarsTabWithSubtabs()
table.insert(sidebarContainers, classBarsContainer)

local classBarsTab = Components.GetSidebarTab(Sidebar, "Class Bars")
classBarsTab:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", 4, -8)
classBarsTab:SetScript("OnClick", function() SelectSidebarTab(1) end)
table.insert(sidebarTabs, classBarsTab)

-- Unit Frames tab (includes Designer and Assignments as sub-tabs)
local unitFramesContainer = NivUI.UnitFrames:SetupConfigTabWithSubtabs(ContentArea, Components)
table.insert(sidebarContainers, unitFramesContainer)

local unitFramesTab = Components.GetSidebarTab(Sidebar, "Unit Frames")
unitFramesTab:SetPoint("TOPLEFT", classBarsTab, "BOTTOMLEFT", 0, -2)
unitFramesTab:SetScript("OnClick", function() SelectSidebarTab(2) end)
table.insert(sidebarTabs, unitFramesTab)

-- Select first tab by default
ConfigFrame:SetScript("OnShow", function()
    SelectSidebarTab(currentSidebarTab)
end)

--------------------------------------------------------------------------------
-- Callback for bar moved/resized (updates position sliders)
--------------------------------------------------------------------------------

NivUI.OnBarMoved = function()
    -- Update Stagger sliders
    local staggerDb = NivUI_DB.staggerBar
    if staggerContent and staggerContent.widthSlider then
        staggerContent.widthSlider:SetValue(staggerDb.width or 394)
    end
    if staggerContent and staggerContent.heightSlider then
        staggerContent.heightSlider:SetValue(staggerDb.height or 20)
    end

    -- Update Chi sliders
    local chiDb = NivUI_DB.chiBar or {}
    if chiContent and chiContent.widthSlider then
        chiContent.widthSlider:SetValue(chiDb.width or 200)
    end
    if chiContent and chiContent.heightSlider then
        chiContent.heightSlider:SetValue(chiDb.height or 20)
    end
end

-- Export components for other modules
NivUI.Components = Components
