local FRAME_WIDTH = 680
local FRAME_HEIGHT = 650
local ROW_HEIGHT = 32
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

-- Class Bars tab (from config/Bars.lua)
local classBarsContainer, barResults = NivUI.Config.Bars.SetupTab(ContentArea, Components)
table.insert(sidebarContainers, classBarsContainer)
NivUI.Config.Bars.SetupOnBarMoved(barResults)

local classBarsTab = Components.GetSidebarTab(Sidebar, "Class Bars")
classBarsTab:SetPoint("TOPLEFT", Sidebar, "TOPLEFT", 4, -8)
classBarsTab:SetScript("OnClick", function() SelectSidebarTab(1) end)
table.insert(sidebarTabs, classBarsTab)

-- Unit Frames tab (from modules/unitframes/ConfigTab.lua)
local unitFramesContainer = NivUI.UnitFrames:SetupConfigTabWithSubtabs(ContentArea, Components)
table.insert(sidebarContainers, unitFramesContainer)

local unitFramesTab = Components.GetSidebarTab(Sidebar, "Unit Frames")
unitFramesTab:SetPoint("TOPLEFT", classBarsTab, "BOTTOMLEFT", 0, -2)
unitFramesTab:SetScript("OnClick", function() SelectSidebarTab(2) end)
table.insert(sidebarTabs, unitFramesTab)

-- Profiles tab (from config/Profiles.lua)
local profilesContainer = NivUI.Config.Profiles.SetupTab(ContentArea, Components)
table.insert(sidebarContainers, profilesContainer)

local profilesTab = Components.GetSidebarTab(Sidebar, "Profiles")
profilesTab:SetPoint("TOPLEFT", unitFramesTab, "BOTTOMLEFT", 0, -2)
profilesTab:SetScript("OnClick", function() SelectSidebarTab(3) end)
table.insert(sidebarTabs, profilesTab)

ConfigFrame:SetScript("OnShow", function()
    SelectSidebarTab(currentSidebarTab)
end)

-- Exports
NivUI.Components = Components
NivUI.ConfigFrame = ConfigFrame
