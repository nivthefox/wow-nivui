-- NivUI Config Frame
-- Configuration UI for NivUI settings

local FRAME_WIDTH = 300
local FRAME_HEIGHT = 520
local PADDING = 16
local ROW_HEIGHT = 26
local LABEL_WIDTH = 100

-- Create main config frame
local ConfigFrame = CreateFrame("Frame", "NivUIConfigFrame", UIParent, "BackdropTemplate")
ConfigFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
ConfigFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
ConfigFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
ConfigFrame:SetBackdropColor(0, 0, 0, 1)
ConfigFrame:SetMovable(true)
ConfigFrame:EnableMouse(true)
ConfigFrame:RegisterForDrag("LeftButton")
ConfigFrame:SetScript("OnDragStart", ConfigFrame.StartMoving)
ConfigFrame:SetScript("OnDragStop", ConfigFrame.StopMovingOrSizing)
ConfigFrame:Hide()

-- Add to special frames so Escape closes it
table.insert(UISpecialFrames, "NivUIConfigFrame")

-- Title
local title = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", ConfigFrame, "TOP", 0, -16)
title:SetText("NivUI")

-- Close button
local closeButton = CreateFrame("Button", nil, ConfigFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", ConfigFrame, "TOPRIGHT", -4, -4)

-- Content area starts below title
local contentTop = -44
local currentY = contentTop

-- Helper: Create a label
local function CreateLabel(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    return label
end

-- Helper: Create a dropdown
-- itemsOrGetter can be a table of items or a function that returns items
local function CreateDropdown(parent, name, x, y, width, itemsOrGetter, onSelect)
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 16, y + 2)
    UIDropDownMenu_SetWidth(dropdown, width)

    local function GetItems()
        if type(itemsOrGetter) == "function" then
            return itemsOrGetter()
        end
        return itemsOrGetter
    end

    local function Initialize(self, level)
        local items = GetItems()
        for i, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.name
            info.value = item.path or item.value
            info.func = function(self)
                UIDropDownMenu_SetSelectedValue(dropdown, self.value)
                UIDropDownMenu_SetText(dropdown, item.name)
                if onSelect then onSelect(self.value, i) end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(dropdown, Initialize)

    function dropdown:SetValue(value)
        UIDropDownMenu_SetSelectedValue(self, value)
        local items = GetItems()
        for _, item in ipairs(items) do
            if (item.path or item.value) == value then
                UIDropDownMenu_SetText(self, item.name)
                break
            end
        end
    end

    return dropdown
end

-- Helper: Create an editbox with +/- buttons
local function CreateNumberControl(parent, x, y, width, minVal, maxVal, step, onValueChanged)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    container:SetSize(width, 22)

    local minus = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    minus:SetSize(22, 22)
    minus:SetPoint("LEFT", container, "LEFT", 0, 0)
    minus:SetText("-")

    local editbox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    editbox:SetSize(width - 50, 20)
    editbox:SetPoint("LEFT", minus, "RIGHT", 4, 0)
    editbox:SetAutoFocus(false)
    editbox:SetNumeric(false)  -- Allow decimals
    editbox:SetMaxLetters(6)

    local plus = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    plus:SetSize(22, 22)
    plus:SetPoint("LEFT", editbox, "RIGHT", 4, 0)
    plus:SetText("+")

    local function GetValue()
        return tonumber(editbox:GetText()) or minVal
    end

    local function SetValue(val)
        val = math.max(minVal, math.min(maxVal, val))
        if step >= 1 then
            editbox:SetText(tostring(math.floor(val)))
        else
            editbox:SetText(string.format("%.2f", val))
        end
        if onValueChanged then onValueChanged(val) end
    end

    minus:SetScript("OnClick", function()
        SetValue(GetValue() - step)
    end)

    plus:SetScript("OnClick", function()
        SetValue(GetValue() + step)
    end)

    editbox:SetScript("OnEnterPressed", function(self)
        SetValue(GetValue())
        self:ClearFocus()
    end)

    editbox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    container.SetValue = SetValue
    container.GetValue = GetValue
    container.editbox = editbox

    return container
end

-- Helper: Create a color swatch
local function CreateColorSwatch(parent, x, y, onColorChanged)
    local swatch = CreateFrame("Button", nil, parent, "BackdropTemplate")
    swatch:SetSize(20, 20)
    swatch:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    swatch:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    swatch:SetBackdropBorderColor(0, 0, 0, 1)

    function swatch:SetColor(r, g, b)
        self.r, self.g, self.b = r, g, b
        self:SetBackdropColor(r, g, b, 1)
    end

    function swatch:GetColor()
        return self.r or 1, self.g or 1, self.b or 1
    end

    swatch:SetScript("OnClick", function(self)
        local r, g, b = self:GetColor()

        local function OnColorChanged()
            local newR, newG, newB = ColorPickerFrame:GetColorRGB()
            self:SetColor(newR, newG, newB)
            if onColorChanged then onColorChanged(newR, newG, newB) end
        end

        local function OnCancel(previousValues)
            self:SetColor(previousValues.r, previousValues.g, previousValues.b)
            if onColorChanged then onColorChanged(previousValues.r, previousValues.g, previousValues.b) end
        end

        ColorPickerFrame:SetupColorPickerAndShow({
            r = r,
            g = g,
            b = b,
            swatchFunc = OnColorChanged,
            opacityFunc = OnColorChanged,
            okayFunc = OnColorChanged,
            cancelFunc = OnCancel,
            previousValues = { r = r, g = g, b = b },
        })
    end)

    return swatch
end

-- Helper: Create a checkbox
local function CreateCheckbox(parent, text, x, y, onToggle)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    label:SetText(text)

    checkbox:SetScript("OnClick", function(self)
        if onToggle then onToggle(self:GetChecked()) end
    end)

    return checkbox
end

-- Helper: Create a simple editbox
local function CreateSimpleEditbox(parent, x, y, width, onValueChanged)
    local editbox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    editbox:SetSize(width, 20)
    editbox:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 2)
    editbox:SetAutoFocus(false)
    editbox:SetNumeric(false)
    editbox:SetMaxLetters(10)

    editbox:SetScript("OnEnterPressed", function(self)
        if onValueChanged then onValueChanged(tonumber(self:GetText())) end
        self:ClearFocus()
    end)

    editbox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    return editbox
end

-- Section: Bar Style
CreateLabel(ConfigFrame, "Bar Style:", PADDING, currentY)
local barTextureDropdown = CreateDropdown(
    ConfigFrame,
    "NivUIBarTextureDropdown",
    LABEL_WIDTH,
    currentY,
    140,
    function() return NivUI:GetBarTextures() end,
    function(value)
        NivUI_StaggerBarDB.barTexture = value
        NivUI:ApplySettings("barTexture")
    end
)
currentY = currentY - ROW_HEIGHT - 8

-- Section: Font
CreateLabel(ConfigFrame, "Font:", PADDING, currentY)
local fontDropdown = CreateDropdown(
    ConfigFrame,
    "NivUIFontDropdown",
    LABEL_WIDTH,
    currentY,
    140,
    function() return NivUI:GetFonts() end,
    function(value)
        NivUI_StaggerBarDB.font = value
        NivUI:ApplySettings("font")
    end
)
currentY = currentY - ROW_HEIGHT

CreateLabel(ConfigFrame, "Font Size:", PADDING, currentY)
local fontSizeControl = CreateNumberControl(
    ConfigFrame,
    LABEL_WIDTH,
    currentY,
    100,
    8, 24, 1,
    function(value)
        NivUI_StaggerBarDB.fontSize = value
        NivUI:ApplySettings("font")
    end
)
currentY = currentY - ROW_HEIGHT

CreateLabel(ConfigFrame, "Font Color:", PADDING, currentY)
local fontColorSwatch = CreateColorSwatch(
    ConfigFrame,
    LABEL_WIDTH,
    currentY,
    function(r, g, b)
        NivUI_StaggerBarDB.fontColor = { r = r, g = g, b = b }
        NivUI:ApplySettings("font")
    end
)
currentY = currentY - ROW_HEIGHT

local fontShadowCheck = CreateCheckbox(
    ConfigFrame,
    "Text Shadow",
    PADDING,
    currentY,
    function(checked)
        NivUI_StaggerBarDB.fontShadow = checked
        NivUI:ApplySettings("font")
    end
)
currentY = currentY - ROW_HEIGHT - 8

-- Section: Position & Size
local sectionLabel = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sectionLabel:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", PADDING, currentY)
sectionLabel:SetText("Position & Size:")
sectionLabel:SetTextColor(1, 0.82, 0)
currentY = currentY - ROW_HEIGHT

local lockedCheck = CreateCheckbox(
    ConfigFrame,
    "Locked",
    PADDING,
    currentY,
    function(checked)
        NivUI_StaggerBarDB.locked = checked
        NivUI:ApplySettings("locked")
    end
)
currentY = currentY - ROW_HEIGHT

CreateLabel(ConfigFrame, "Left:", PADDING, currentY)
local leftEditbox = CreateSimpleEditbox(
    ConfigFrame,
    PADDING + 35,
    currentY,
    55,
    function(value)
        if value then
            NivUI_StaggerBarDB.x = value
            NivUI:ApplySettings("position")
        end
    end
)

CreateLabel(ConfigFrame, "Top:", PADDING + 110, currentY)
local topEditbox = CreateSimpleEditbox(
    ConfigFrame,
    PADDING + 145,
    currentY,
    55,
    function(value)
        if value then
            NivUI_StaggerBarDB.y = value
            NivUI:ApplySettings("position")
        end
    end
)
currentY = currentY - ROW_HEIGHT

CreateLabel(ConfigFrame, "Width:", PADDING, currentY)
local widthEditbox = CreateSimpleEditbox(
    ConfigFrame,
    PADDING + 45,
    currentY,
    50,
    function(value)
        if value and value >= 100 and value <= 800 then
            NivUI_StaggerBarDB.width = value
            NivUI:ApplySettings("position")
        end
    end
)

CreateLabel(ConfigFrame, "Height:", PADDING + 110, currentY)
local heightEditbox = CreateSimpleEditbox(
    ConfigFrame,
    PADDING + 155,
    currentY,
    45,
    function(value)
        if value and value >= 16 and value <= 60 then
            NivUI_StaggerBarDB.height = value
            NivUI:ApplySettings("position")
        end
    end
)
currentY = currentY - ROW_HEIGHT - 8

-- Section: Stagger Colors
local colorSectionLabel = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
colorSectionLabel:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", PADDING, currentY)
colorSectionLabel:SetText("Stagger Colors:")
colorSectionLabel:SetTextColor(1, 0.82, 0)
currentY = currentY - ROW_HEIGHT

CreateLabel(ConfigFrame, "Light:", PADDING, currentY)
local lightColorSwatch = CreateColorSwatch(
    ConfigFrame,
    PADDING + 70,
    currentY,
    function(r, g, b)
        NivUI_StaggerBarDB.colors = NivUI_StaggerBarDB.colors or {}
        NivUI_StaggerBarDB.colors.light = { r = r, g = g, b = b }
    end
)

CreateLabel(ConfigFrame, "Moderate:", PADDING + 110, currentY)
local moderateColorSwatch = CreateColorSwatch(
    ConfigFrame,
    PADDING + 180,
    currentY,
    function(r, g, b)
        NivUI_StaggerBarDB.colors = NivUI_StaggerBarDB.colors or {}
        NivUI_StaggerBarDB.colors.moderate = { r = r, g = g, b = b }
    end
)
currentY = currentY - ROW_HEIGHT

CreateLabel(ConfigFrame, "Heavy:", PADDING, currentY)
local heavyColorSwatch = CreateColorSwatch(
    ConfigFrame,
    PADDING + 70,
    currentY,
    function(r, g, b)
        NivUI_StaggerBarDB.colors = NivUI_StaggerBarDB.colors or {}
        NivUI_StaggerBarDB.colors.heavy = { r = r, g = g, b = b }
    end
)

CreateLabel(ConfigFrame, "Extreme:", PADDING + 110, currentY)
local extremeColorSwatch = CreateColorSwatch(
    ConfigFrame,
    PADDING + 180,
    currentY,
    function(r, g, b)
        NivUI_StaggerBarDB.colors = NivUI_StaggerBarDB.colors or {}
        NivUI_StaggerBarDB.colors.extreme = { r = r, g = g, b = b }
    end
)
currentY = currentY - ROW_HEIGHT - 8

-- Section: Update Interval
CreateLabel(ConfigFrame, "Update Interval:", PADDING, currentY)
local intervalControl = CreateNumberControl(
    ConfigFrame,
    LABEL_WIDTH + 10,
    currentY,
    90,
    0.05, 1.0, 0.05,
    function(value)
        NivUI_StaggerBarDB.updateInterval = value
    end
)
local secLabel = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
secLabel:SetPoint("LEFT", intervalControl, "RIGHT", 4, 0)
secLabel:SetText("sec")

-- Function to refresh all UI elements from saved vars
local function RefreshUI()
    local db = NivUI_StaggerBarDB
    local defaults = NivUI.defaults

    -- Bar texture
    barTextureDropdown:SetValue(db.barTexture or defaults.barTexture)

    -- Font
    fontDropdown:SetValue(db.font or defaults.font)
    fontSizeControl.SetValue(db.fontSize or defaults.fontSize)
    local fontColor = db.fontColor or defaults.fontColor
    fontColorSwatch:SetColor(fontColor.r, fontColor.g, fontColor.b)
    local shadow = db.fontShadow
    if shadow == nil then shadow = defaults.fontShadow end
    fontShadowCheck:SetChecked(shadow)

    -- Position & Size
    lockedCheck:SetChecked(db.locked or false)
    leftEditbox:SetText(tostring(math.floor(db.x or defaults.x)))
    topEditbox:SetText(tostring(math.floor(db.y or defaults.y)))
    widthEditbox:SetText(tostring(math.floor(db.width or defaults.width)))
    heightEditbox:SetText(tostring(math.floor(db.height or defaults.height)))

    -- Stagger colors
    local colors = db.colors or defaults.colors
    lightColorSwatch:SetColor(colors.light.r, colors.light.g, colors.light.b)
    moderateColorSwatch:SetColor(colors.moderate.r, colors.moderate.g, colors.moderate.b)
    heavyColorSwatch:SetColor(colors.heavy.r, colors.heavy.g, colors.heavy.b)
    extremeColorSwatch:SetColor(colors.extreme.r, colors.extreme.g, colors.extreme.b)

    -- Update interval
    intervalControl.SetValue(db.updateInterval or defaults.updateInterval)
end

-- Callback when bar is moved/resized by dragging
NivUI.OnBarMoved = function()
    local db = NivUI_StaggerBarDB
    leftEditbox:SetText(tostring(math.floor(db.x or 0)))
    topEditbox:SetText(tostring(math.floor(db.y or 0)))
    widthEditbox:SetText(tostring(math.floor(db.width or 394)))
    heightEditbox:SetText(tostring(math.floor(db.height or 20)))
end

-- Refresh when shown
ConfigFrame:SetScript("OnShow", RefreshUI)
