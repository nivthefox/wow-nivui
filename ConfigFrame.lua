-- NivUI Config Frame
-- Modern configuration UI using Platynator-style components

local FRAME_WIDTH = 480
local FRAME_HEIGHT = 620
local ROW_HEIGHT = 32
local SECTION_SPACING = 12

--------------------------------------------------------------------------------
-- Component Helpers (Platynator-style)
--------------------------------------------------------------------------------

local Components = {}

-- Create a checkbox with label
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

-- Create a basic dropdown
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

-- Create a slider with +/- steppers
function Components.GetSlider(parent, labelText, min, max, step, formatter, callback)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(ROW_HEIGHT)
    holder:SetPoint("LEFT", 20, 0)
    holder:SetPoint("RIGHT", -20, 0)

    holder.Label = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    holder.Label:SetJustifyH("RIGHT")
    holder.Label:SetPoint("LEFT", 0, 0)
    holder.Label:SetPoint("RIGHT", holder, "CENTER", -40, 0)
    holder.Label:SetText(labelText)

    holder.Slider = CreateFrame("Slider", nil, holder, "MinimalSliderWithSteppersTemplate")
    holder.Slider:SetPoint("LEFT", holder, "CENTER", -20, 0)
    holder.Slider:SetPoint("RIGHT", -20, 0)
    holder.Slider:SetHeight(20)

    local numSteps = math.floor((max - min) / step)
    holder.Slider:Init(min, min, max, numSteps, {
        [MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(
            MinimalSliderWithSteppersMixin.Label.Right,
            function(value)
                local formatted = formatter and formatter(value) or tostring(value)
                return WHITE_FONT_COLOR:WrapTextInColorCode(formatted)
            end
        )
    })

    holder.Slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if callback then callback(value) end
    end)

    function holder:GetValue()
        return holder.Slider.Slider:GetValue()
    end

    function holder:SetValue(value)
        holder.Slider:SetValue(value)
    end

    holder:SetScript("OnMouseWheel", function(_, delta)
        if holder.Slider.Slider:IsEnabled() then
            holder.Slider:SetValue(holder.Slider.Slider:GetValue() + delta * step)
        end
    end)

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

    local colorMonitor = CreateFrame("Frame", nil, holder)

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

-- Create a section inset frame
function Components.GetInset(parent)
    local inset = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
    return inset
end

-- Create a tab button
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
-- Tab System
--------------------------------------------------------------------------------

local tabs = {}
local tabContainers = {}
local currentTab = 1

local function SelectTab(index)
    for i, tab in ipairs(tabs) do
        if i == index then
            PanelTemplates_SelectTab(tab)
            tabContainers[i]:Show()
        else
            PanelTemplates_DeselectTab(tab)
            tabContainers[i]:Hide()
        end
    end
    currentTab = index
end

--------------------------------------------------------------------------------
-- Stagger Bar Tab
--------------------------------------------------------------------------------

local function SetupStaggerBarTab()
    local container = CreateFrame("Frame", nil, ConfigFrame)
    container:SetPoint("TOPLEFT", 8, -60)
    container:SetPoint("BOTTOMRIGHT", -8, 8)
    container:Hide()

    -- ScrollFrame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 0)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(FRAME_WIDTH - 50, 800)
    scrollFrame:SetScrollChild(content)

    local allFrames = {}
    local currentY = 0

    local function AddFrame(frame)
        if #allFrames == 0 then
            frame:SetPoint("TOP", content, "TOP", 0, currentY)
        else
            frame:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -2)
        end
        table.insert(allFrames, frame)
    end

    local function AddSpacer(height)
        local spacer = CreateFrame("Frame", nil, content)
        spacer:SetHeight(height or SECTION_SPACING)
        spacer:SetPoint("LEFT", 0, 0)
        spacer:SetPoint("RIGHT", 0, 0)
        AddFrame(spacer)
    end

    ----------------------------------------------------------------------------
    -- General Section
    ----------------------------------------------------------------------------
    local generalHeader = Components.GetHeader(content, "General")
    AddFrame(generalHeader)

    local generalInset = Components.GetInset(content)
    generalInset:SetHeight(50)
    generalInset:SetPoint("LEFT", 10, 0)
    generalInset:SetPoint("RIGHT", -10, 0)
    AddFrame(generalInset)

    local visibilityDropdown = Components.GetBasicDropdown(
        generalInset,
        "Bar Visible:",
        function() return NivUI:GetVisibilityOptions() end,
        function(value) return NivUI:GetSetting("visibility") == value end,
        function(value)
            NivUI_StaggerBarDB.visibility = value
            NivUI:ApplySettings("visibility")
        end
    )
    visibilityDropdown:SetParent(generalInset)
    visibilityDropdown:SetPoint("TOP", generalInset, "TOP", 0, -10)
    visibilityDropdown.inset = generalInset

    AddSpacer()

    ----------------------------------------------------------------------------
    -- Appearance Section
    ----------------------------------------------------------------------------
    local appearanceHeader = Components.GetHeader(content, "Appearance")
    AddFrame(appearanceHeader)

    local appearanceInset = Components.GetInset(content)
    appearanceInset:SetHeight(190)
    appearanceInset:SetPoint("LEFT", 10, 0)
    appearanceInset:SetPoint("RIGHT", -10, 0)
    AddFrame(appearanceInset)

    local appearanceFrames = {}

    local fgTextureDropdown = Components.GetTextureDropdown(
        appearanceInset,
        "Foreground:",
        function() return NivUI:GetBarTextures() end,
        function() return NivUI:GetSetting("foregroundTexture") end,
        function(value)
            NivUI_StaggerBarDB.foregroundTexture = value
            NivUI:ApplySettings("barTexture")
        end
    )
    fgTextureDropdown:SetParent(appearanceInset)
    fgTextureDropdown:SetPoint("TOP", appearanceInset, "TOP", 0, -10)
    table.insert(appearanceFrames, fgTextureDropdown)

    local bgTextureDropdown = Components.GetTextureDropdown(
        appearanceInset,
        "Background:",
        function() return NivUI:GetBarTextures() end,
        function() return NivUI:GetSetting("backgroundTexture") end,
        function(value)
            NivUI_StaggerBarDB.backgroundTexture = value
            NivUI:ApplySettings("background")
        end
    )
    bgTextureDropdown:SetParent(appearanceInset)
    bgTextureDropdown:SetPoint("TOP", fgTextureDropdown, "BOTTOM", 0, -2)
    table.insert(appearanceFrames, bgTextureDropdown)

    local bgColorPicker = Components.GetColorPicker(
        appearanceInset,
        "Background Color:",
        true,
        function(color)
            NivUI_StaggerBarDB.backgroundColor = color
            NivUI:ApplySettings("background")
        end
    )
    bgColorPicker:SetParent(appearanceInset)
    bgColorPicker:SetPoint("TOP", bgTextureDropdown, "BOTTOM", 0, -2)
    table.insert(appearanceFrames, bgColorPicker)

    local borderDropdown = Components.GetBasicDropdown(
        appearanceInset,
        "Border Style:",
        function() return NivUI:GetBorders() end,
        function(value) return NivUI:GetSetting("borderStyle") == value end,
        function(value)
            NivUI_StaggerBarDB.borderStyle = value
            NivUI:ApplySettings("border")
        end
    )
    borderDropdown:SetParent(appearanceInset)
    borderDropdown:SetPoint("TOP", bgColorPicker, "BOTTOM", 0, -2)
    table.insert(appearanceFrames, borderDropdown)

    local borderColorPicker = Components.GetColorPicker(
        appearanceInset,
        "Border Color:",
        true,
        function(color)
            NivUI_StaggerBarDB.borderColor = color
            NivUI:ApplySettings("border")
        end
    )
    borderColorPicker:SetParent(appearanceInset)
    borderColorPicker:SetPoint("TOP", borderDropdown, "BOTTOM", 0, -2)
    table.insert(appearanceFrames, borderColorPicker)

    AddSpacer()

    ----------------------------------------------------------------------------
    -- Stagger Colors Section
    ----------------------------------------------------------------------------
    local colorsHeader = Components.GetHeader(content, "Stagger Colors")
    AddFrame(colorsHeader)

    local colorsInset = Components.GetInset(content)
    colorsInset:SetHeight(80)
    colorsInset:SetPoint("LEFT", 10, 0)
    colorsInset:SetPoint("RIGHT", -10, 0)
    AddFrame(colorsInset)

    -- Two rows of two color pickers each
    local lightColorPicker = Components.GetColorPicker(
        colorsInset,
        "Light:",
        false,
        function(color)
            NivUI_StaggerBarDB.colors = NivUI_StaggerBarDB.colors or {}
            NivUI_StaggerBarDB.colors.light = color
        end
    )
    lightColorPicker:SetParent(colorsInset)
    lightColorPicker:SetPoint("TOPLEFT", colorsInset, "TOPLEFT", 10, -10)
    lightColorPicker:SetPoint("RIGHT", colorsInset, "CENTER", -10, 0)

    local moderateColorPicker = Components.GetColorPicker(
        colorsInset,
        "Moderate:",
        false,
        function(color)
            NivUI_StaggerBarDB.colors = NivUI_StaggerBarDB.colors or {}
            NivUI_StaggerBarDB.colors.moderate = color
        end
    )
    moderateColorPicker:SetParent(colorsInset)
    moderateColorPicker:SetPoint("TOPLEFT", colorsInset, "TOP", 10, -10)
    moderateColorPicker:SetPoint("RIGHT", colorsInset, "RIGHT", -20, 0)

    local heavyColorPicker = Components.GetColorPicker(
        colorsInset,
        "Heavy:",
        false,
        function(color)
            NivUI_StaggerBarDB.colors = NivUI_StaggerBarDB.colors or {}
            NivUI_StaggerBarDB.colors.heavy = color
        end
    )
    heavyColorPicker:SetParent(colorsInset)
    heavyColorPicker:SetPoint("TOPLEFT", lightColorPicker, "BOTTOMLEFT", 0, -2)
    heavyColorPicker:SetPoint("RIGHT", colorsInset, "CENTER", -10, 0)

    local extremeColorPicker = Components.GetColorPicker(
        colorsInset,
        "Extreme:",
        false,
        function(color)
            NivUI_StaggerBarDB.colors = NivUI_StaggerBarDB.colors or {}
            NivUI_StaggerBarDB.colors.extreme = color
        end
    )
    extremeColorPicker:SetParent(colorsInset)
    extremeColorPicker:SetPoint("TOPLEFT", moderateColorPicker, "BOTTOMLEFT", 0, -2)
    extremeColorPicker:SetPoint("RIGHT", colorsInset, "RIGHT", -20, 0)

    AddSpacer()

    ----------------------------------------------------------------------------
    -- Text Section
    ----------------------------------------------------------------------------
    local textHeader = Components.GetHeader(content, "Text")
    AddFrame(textHeader)

    local textInset = Components.GetInset(content)
    textInset:SetHeight(145)
    textInset:SetPoint("LEFT", 10, 0)
    textInset:SetPoint("RIGHT", -10, 0)
    AddFrame(textInset)

    local textFrames = {}

    local fontDropdown = Components.GetBasicDropdown(
        textInset,
        "Font:",
        function() return NivUI:GetFonts() end,
        function(value) return NivUI:GetSetting("font") == value end,
        function(value)
            NivUI_StaggerBarDB.font = value
            NivUI:ApplySettings("font")
        end
    )
    fontDropdown:SetParent(textInset)
    fontDropdown:SetPoint("TOP", textInset, "TOP", 0, -10)
    table.insert(textFrames, fontDropdown)

    local fontSizeSlider = Components.GetSlider(
        textInset,
        "Font Size:",
        8, 24, 1,
        function(val) return tostring(math.floor(val)) end,
        function(value)
            NivUI_StaggerBarDB.fontSize = value
            NivUI:ApplySettings("font")
        end
    )
    fontSizeSlider:SetParent(textInset)
    fontSizeSlider:SetPoint("TOP", fontDropdown, "BOTTOM", 0, -2)
    table.insert(textFrames, fontSizeSlider)

    local fontColorPicker = Components.GetColorPicker(
        textInset,
        "Font Color:",
        false,
        function(color)
            NivUI_StaggerBarDB.fontColor = color
            NivUI:ApplySettings("font")
        end
    )
    fontColorPicker:SetParent(textInset)
    fontColorPicker:SetPoint("TOP", fontSizeSlider, "BOTTOM", 0, -2)
    table.insert(textFrames, fontColorPicker)

    local fontShadowCheck = Components.GetCheckbox(
        textInset,
        "Text Shadow",
        function(checked)
            NivUI_StaggerBarDB.fontShadow = checked
            NivUI:ApplySettings("font")
        end
    )
    fontShadowCheck:SetParent(textInset)
    fontShadowCheck:SetPoint("TOP", fontColorPicker, "BOTTOM", 0, -2)
    table.insert(textFrames, fontShadowCheck)

    AddSpacer()

    ----------------------------------------------------------------------------
    -- Position Section
    ----------------------------------------------------------------------------
    local positionHeader = Components.GetHeader(content, "Position")
    AddFrame(positionHeader)

    local positionInset = Components.GetInset(content)
    positionInset:SetHeight(145)
    positionInset:SetPoint("LEFT", 10, 0)
    positionInset:SetPoint("RIGHT", -10, 0)
    AddFrame(positionInset)

    local positionFrames = {}

    local lockedCheck = Components.GetCheckbox(
        positionInset,
        "Locked",
        function(checked)
            NivUI_StaggerBarDB.locked = checked
            NivUI:ApplySettings("locked")
        end
    )
    lockedCheck:SetParent(positionInset)
    lockedCheck:SetPoint("TOP", positionInset, "TOP", 0, -10)
    table.insert(positionFrames, lockedCheck)

    local widthSlider = Components.GetSlider(
        positionInset,
        "Width:",
        100, 600, 10,
        function(val) return tostring(math.floor(val)) end,
        function(value)
            NivUI_StaggerBarDB.width = value
            NivUI:ApplySettings("position")
        end
    )
    widthSlider:SetParent(positionInset)
    widthSlider:SetPoint("TOP", lockedCheck, "BOTTOM", 0, -2)
    table.insert(positionFrames, widthSlider)

    local heightSlider = Components.GetSlider(
        positionInset,
        "Height:",
        5, 60, 1,
        function(val) return tostring(math.floor(val)) end,
        function(value)
            NivUI_StaggerBarDB.height = value
            NivUI:ApplySettings("position")
        end
    )
    heightSlider:SetParent(positionInset)
    heightSlider:SetPoint("TOP", widthSlider, "BOTTOM", 0, -2)
    table.insert(positionFrames, heightSlider)

    local intervalSlider = Components.GetSlider(
        positionInset,
        "Update Interval:",
        0.05, 1.0, 0.05,
        function(val) return string.format("%.2f sec", val) end,
        function(value)
            NivUI_StaggerBarDB.updateInterval = value
        end
    )
    intervalSlider:SetParent(positionInset)
    intervalSlider:SetPoint("TOP", heightSlider, "BOTTOM", 0, -2)
    table.insert(positionFrames, intervalSlider)

    ----------------------------------------------------------------------------
    -- Refresh on show
    ----------------------------------------------------------------------------
    container:SetScript("OnShow", function()
        local db = NivUI_StaggerBarDB
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

--------------------------------------------------------------------------------
-- Initialize Tabs
--------------------------------------------------------------------------------

local staggerBarContainer = SetupStaggerBarTab()
table.insert(tabContainers, staggerBarContainer)

local staggerBarTab = Components.GetTab(ConfigFrame, "Stagger Bar")
staggerBarTab:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 10, -25)
staggerBarTab:SetScript("OnClick", function() SelectTab(1) end)
table.insert(tabs, staggerBarTab)

-- Select first tab by default
ConfigFrame:SetScript("OnShow", function()
    SelectTab(currentTab)
end)

--------------------------------------------------------------------------------
-- Callback for bar moved/resized (updates position sliders)
--------------------------------------------------------------------------------

NivUI.OnBarMoved = function()
    local db = NivUI_StaggerBarDB
    if staggerBarContainer.widthSlider then
        staggerBarContainer.widthSlider:SetValue(db.width or 394)
    end
    if staggerBarContainer.heightSlider then
        staggerBarContainer.heightSlider:SetValue(db.height or 20)
    end
end
