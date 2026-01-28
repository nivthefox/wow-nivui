NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local ROW_HEIGHT = 32
local WIDGET_LIST_WIDTH = 140

local SelectSubTab

NivUI.UnitFrames.currentStyleName = "Default"
NivUI.UnitFrames.refreshCallback = nil

StaticPopupDialogs["NIVUI_NEW_STYLE"] = {
    text = "Enter name for new style:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = 1,
    OnAccept = function(dialog)
        local name = dialog:GetEditBox():GetText()
        if name and name ~= "" then
            local success, err = NivUI:CreateStyle(name)
            if success then
                NivUI.UnitFrames.currentStyleName = name
                if NivUI.UnitFrames.refreshCallback then
                    NivUI.UnitFrames.refreshCallback()
                end
            else
                print("NivUI: " .. (err or "Failed to create style"))
            end
        end
    end,
    EditBoxOnEnterPressed = function(editBox)
        local dialog = editBox:GetParent()
        local name = editBox:GetText()
        if name and name ~= "" then
            local success, err = NivUI:CreateStyle(name)
            if success then
                NivUI.UnitFrames.currentStyleName = name
                if NivUI.UnitFrames.refreshCallback then
                    NivUI.UnitFrames.refreshCallback()
                end
            else
                print("NivUI: " .. (err or "Failed to create style"))
            end
        end
        dialog:Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["NIVUI_DUPLICATE_STYLE"] = {
    text = "Enter name for duplicate of '%s':",
    button1 = "Duplicate",
    button2 = "Cancel",
    hasEditBox = 1,
    OnAccept = function(dialog)
        local name = dialog:GetEditBox():GetText()
        if name and name ~= "" then
            local success, err = NivUI:DuplicateStyle(NivUI.UnitFrames.currentStyleName, name)
            if success then
                NivUI.UnitFrames.currentStyleName = name
                if NivUI.UnitFrames.refreshCallback then
                    NivUI.UnitFrames.refreshCallback()
                end
            else
                print("NivUI: " .. (err or "Failed to duplicate style"))
            end
        end
    end,
    EditBoxOnEnterPressed = function(editBox)
        local dialog = editBox:GetParent()
        local name = editBox:GetText()
        if name and name ~= "" then
            local success, err = NivUI:DuplicateStyle(NivUI.UnitFrames.currentStyleName, name)
            if success then
                NivUI.UnitFrames.currentStyleName = name
                if NivUI.UnitFrames.refreshCallback then
                    NivUI.UnitFrames.refreshCallback()
                end
            else
                print("NivUI: " .. (err or "Failed to duplicate style"))
            end
        end
        dialog:Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["NIVUI_RENAME_STYLE"] = {
    text = "Enter new name for '%s':",
    button1 = "Rename",
    button2 = "Cancel",
    hasEditBox = 1,
    OnAccept = function(dialog)
        local newName = dialog:GetEditBox():GetText()
        if newName and newName ~= "" then
            local success, err = NivUI:RenameStyle(NivUI.UnitFrames.currentStyleName, newName)
            if success then
                NivUI.UnitFrames.currentStyleName = newName
                if NivUI.UnitFrames.refreshCallback then
                    NivUI.UnitFrames.refreshCallback()
                end
            else
                print("NivUI: " .. (err or "Failed to rename style"))
            end
        end
    end,
    EditBoxOnEnterPressed = function(editBox)
        local dialog = editBox:GetParent()
        local newName = editBox:GetText()
        if newName and newName ~= "" then
            local success, err = NivUI:RenameStyle(NivUI.UnitFrames.currentStyleName, newName)
            if success then
                NivUI.UnitFrames.currentStyleName = newName
                if NivUI.UnitFrames.refreshCallback then
                    NivUI.UnitFrames.refreshCallback()
                end
            else
                print("NivUI: " .. (err or "Failed to rename style"))
            end
        end
        dialog:Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["NIVUI_DELETE_STYLE"] = {
    text = "Delete style '%s'? This cannot be undone.",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function()
        local success, err = NivUI:DeleteStyle(NivUI.UnitFrames.currentStyleName)
        if success then
            local names = NivUI:GetStyleNames()
            NivUI.UnitFrames.currentStyleName = names[1] or "Default"
            if NivUI.UnitFrames.refreshCallback then
                NivUI.UnitFrames.refreshCallback()
            end
        else
            print("NivUI: " .. (err or "Failed to delete style"))
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    showAlert = 1,
}

StaticPopupDialogs["NIVUI_CONFIRM_RELOAD"] = {
    text = "Disabling this frame type requires a UI reload. Reload now?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function(_dialog, data)
        NivUI:SetFrameEnabled(data.frameType, false)
    end,
    OnCancel = function(_dialog, data)
        NivUI.current.unitFrameEnabled = NivUI.current.unitFrameEnabled or {}
        NivUI.current.unitFrameEnabled[data.frameType] = false
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["NIVUI_NEW_CUSTOM_RAID_GROUP"] = {
    text = "Enter name for new custom raid group:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = 1,
    OnAccept = function(dialog)
        local name = dialog:GetEditBox():GetText()
        if name and name ~= "" then
            local id, err = NivUI:CreateCustomRaidGroup(name)
            if not id then
                print("NivUI: " .. (err or "Failed to create custom raid group"))
            end
        end
    end,
    EditBoxOnEnterPressed = function(editBox)
        local dialog = editBox:GetParent()
        local name = editBox:GetText()
        if name and name ~= "" then
            local id, err = NivUI:CreateCustomRaidGroup(name)
            if not id then
                print("NivUI: " .. (err or "Failed to create custom raid group"))
            end
        end
        dialog:Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

StaticPopupDialogs["NIVUI_DELETE_CUSTOM_RAID_GROUP"] = {
    text = "Delete custom raid group '%s'? This cannot be undone.",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function(_dialog, data)
        local success, err = NivUI:DeleteCustomRaidGroup(data.groupId)
        if not success then
            print("NivUI: " .. (err or "Failed to delete custom raid group"))
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    showAlert = 1,
}

local function DeepGet(tbl, key)
    local parts = { strsplit(".", key) }
    local current = tbl
    for _, part in ipairs(parts) do
        if type(current) ~= "table" then return nil end
        current = current[part]
    end
    return current
end

local function DeepSet(tbl, key, value)
    local parts = { strsplit(".", key) }
    local current = tbl
    for i = 1, #parts - 1 do
        local part = parts[i]
        if type(current[part]) ~= "table" then
            current[part] = {}
        end
        current = current[part]
    end
    current[parts[#parts]] = value
end

local function CreateWidgetList(parent, onSelect)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(WIDGET_LIST_WIDTH)
    frame:SetPoint("TOPLEFT", 0, 0)
    frame:SetPoint("BOTTOMLEFT", 0, 0)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.08, 0.08, 0.9)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -24, 4)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(WIDGET_LIST_WIDTH - 30)
    content:SetHeight(1)  -- Will be adjusted
    scrollFrame:SetScrollChild(content)

    frame.buttons = {}
    frame.selected = nil

    function frame:Populate()
        for _, btn in pairs(self.buttons) do
            btn:Hide()
        end
        wipe(self.buttons)

        local yOffset = 0
        for _, widgetType in ipairs(NivUI.UnitFrames.WIDGET_ORDER) do
            local btn = CreateFrame("Button", nil, content)
            btn:SetSize(WIDGET_LIST_WIDTH - 30, 24)
            btn:SetPoint("TOPLEFT", 0, -yOffset)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            btn.text:SetPoint("LEFT", 8, 0)
            btn.text:SetText(NivUI.UnitFrames.WIDGET_NAMES[widgetType] or widgetType)

            btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            btn.highlight:SetAllPoints()
            btn.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.3)

            btn.selected = btn:CreateTexture(nil, "BACKGROUND")
            btn.selected:SetAllPoints()
            btn.selected:SetColorTexture(0.2, 0.4, 0.6, 0.5)
            btn.selected:Hide()

            btn.widgetType = widgetType

            btn:SetScript("OnClick", function()
                self:Select(widgetType)
                if onSelect then onSelect(widgetType) end
            end)

            self.buttons[widgetType] = btn
            yOffset = yOffset + 24
        end

        content:SetHeight(yOffset)
    end

    function frame:Select(widgetType)
        if self.selected and self.buttons[self.selected] then
            self.buttons[self.selected].selected:Hide()
            self.buttons[self.selected].text:SetFontObject("GameFontHighlight")
        end

        self.selected = widgetType

        if widgetType and self.buttons[widgetType] then
            self.buttons[widgetType].selected:Show()
            self.buttons[widgetType].text:SetFontObject("GameFontNormal")
        end
    end

    return frame
end

local function CreateWidgetSettingsPanel(parent, getStyle, saveStyle, refreshPreview)
    local frame = CreateFrame("Frame", nil, parent)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.06, 0.06, 0.06, 0.9)

    frame.tabButtons = {}
    frame.tabPanels = {}
    frame.currentTab = 1
    frame.currentWidget = nil

    local tabHolder = CreateFrame("Frame", nil, frame)
    tabHolder:SetHeight(28)
    tabHolder:SetPoint("TOPLEFT", 0, 0)
    tabHolder:SetPoint("TOPRIGHT", 0, 0)
    frame.tabHolder = tabHolder

    local contentArea = CreateFrame("Frame", nil, frame)
    contentArea:SetPoint("TOPLEFT", 0, -42)
    contentArea:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.contentArea = contentArea

    function frame:SelectTab(index)
        for i, btn in ipairs(self.tabButtons) do
            if i == index then
                PanelTemplates_SelectTab(btn)
                if self.tabPanels[i] then
                    self.tabPanels[i]:Show()
                end
            else
                PanelTemplates_DeselectTab(btn)
                if self.tabPanels[i] then
                    self.tabPanels[i]:Hide()
                end
            end
        end
        self.currentTab = index
    end

    function frame:BuildForWidget(widgetType)
        local savedScrollPositions = {}
        for i, panel in ipairs(self.tabPanels) do
            savedScrollPositions[i] = panel:GetVerticalScroll()
        end
        local savedTab = self.currentTab

        self.currentWidget = widgetType

        for _, btn in ipairs(self.tabButtons) do
            btn:Hide()
        end
        wipe(self.tabButtons)

        for _, panel in ipairs(self.tabPanels) do
            panel:Hide()
            panel:SetParent(nil)
        end
        wipe(self.tabPanels)

        if not widgetType then
            return
        end

        local config = NivUI.UnitFrames.WidgetConfigs[widgetType]
        if not config then
            return
        end

        local style = getStyle()
        local widgetData = style and style[widgetType] or {}

        for i, tabConfig in ipairs(config) do
            local tab = CreateFrame("Button", nil, self.tabHolder, "PanelTopTabButtonTemplate")
            tab:SetText(tabConfig.label)
            tab:SetScript("OnShow", function(self)
                PanelTemplates_TabResize(self, 10, nil, 60)
            end)
            tab:GetScript("OnShow")(tab)
            tab:SetScript("OnClick", function()
                self:SelectTab(i)
            end)

            if #self.tabButtons == 0 then
                tab:SetPoint("TOPLEFT", 0, 0)
            else
                tab:SetPoint("LEFT", self.tabButtons[#self.tabButtons], "RIGHT", 0, 0)
            end

            table.insert(self.tabButtons, tab)

            local panel = CreateFrame("ScrollFrame", nil, self.contentArea, "UIPanelScrollFrameTemplate")
            panel:SetPoint("TOPLEFT", 0, 0)
            panel:SetPoint("BOTTOMRIGHT", -24, 0)
            panel:Hide()

            local panelContent = CreateFrame("Frame", nil, panel)
            panelContent:SetWidth(self.contentArea:GetWidth() - 40)
            panelContent:SetHeight(1)
            panel:SetScrollChild(panelContent)

            local yOffset = 0
            for _, entry in ipairs(tabConfig.entries) do
                local show = true
                if entry.showIf then
                    local checkValue = DeepGet(widgetData, entry.showIf.key)
                    show = (checkValue == entry.showIf.value)
                end
                if show and entry.hideIf then
                    local checkValue = DeepGet(widgetData, entry.hideIf.key)
                    show = (checkValue ~= entry.hideIf.value)
                end

                if show then
                    local entryFrame = self:CreateEntry(panelContent, entry, widgetType, widgetData, getStyle, saveStyle, refreshPreview)
                    if entryFrame then
                        entryFrame:SetPoint("TOP", panelContent, "TOP", 0, -yOffset)
                        yOffset = yOffset + (entryFrame:GetHeight() or ROW_HEIGHT) + 4
                    end
                end
            end

            panelContent:SetHeight(math.max(yOffset, 100))
            table.insert(self.tabPanels, panel)
        end

        if #self.tabButtons > 0 then
            local tabToSelect = savedTab
            if tabToSelect > #self.tabButtons then
                tabToSelect = 1
            end
            self:SelectTab(tabToSelect)
        end

        C_Timer.After(0, function()
            for i, panel in ipairs(self.tabPanels) do
                if savedScrollPositions[i] then
                    panel:SetVerticalScroll(savedScrollPositions[i])
                end
            end
        end)
    end

    function frame:CreateEntry(parent, entry, widgetType, widgetData, getStyle, saveStyle, refreshPreview)
        local holder = CreateFrame("Frame", nil, parent)
        holder:SetHeight(ROW_HEIGHT)
        holder:SetPoint("LEFT", 10, 0)
        holder:SetPoint("RIGHT", -10, 0)

        local currentValue = DeepGet(widgetData, entry.key)

        if entry.kind == "checkbox" then
            local checkBox = CreateFrame("CheckButton", nil, holder, "SettingsCheckboxTemplate")
            checkBox:SetPoint("LEFT", holder, "CENTER", -15, 0)
            checkBox:SetText(entry.label)
            checkBox:SetNormalFontObject(GameFontHighlight)
            checkBox:GetFontString():SetPoint("RIGHT", holder, "CENTER", -30, 0)
            checkBox:GetFontString():SetPoint("LEFT", holder, "LEFT", 10, 0)
            checkBox:GetFontString():SetJustifyH("RIGHT")
            checkBox:SetChecked(currentValue)

            checkBox:SetScript("OnClick", function()
                local style = getStyle()
                if style and style[widgetType] then
                    DeepSet(style[widgetType], entry.key, checkBox:GetChecked())
                    saveStyle(style)
                    refreshPreview()
                end
            end)

        elseif entry.kind == "slider" then
            local label = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            label:SetPoint("LEFT", 10, 0)
            label:SetPoint("RIGHT", holder, "CENTER", -40, 0)
            label:SetJustifyH("RIGHT")
            label:SetText(entry.label)

            local editBox = CreateFrame("EditBox", nil, holder, "InputBoxTemplate")
            editBox:SetSize(50, 20)
            editBox:SetPoint("RIGHT", -5, 0)
            editBox:SetAutoFocus(false)
            editBox:SetMaxLetters(6)
            editBox:SetText(tostring(currentValue or entry.min))

            local slider = CreateFrame("Slider", nil, holder, "MinimalSliderWithSteppersTemplate")
            slider:SetPoint("LEFT", holder, "CENTER", -20, 0)
            slider:SetPoint("RIGHT", editBox, "LEFT", -10, 0)
            slider:SetHeight(20)

            local numSteps = math.floor((entry.max - entry.min) / entry.step)
            slider:Init(currentValue or entry.min, entry.min, entry.max, numSteps, {})

            local updating = false

            slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
                if updating then return end
                updating = true
                editBox:SetText(tostring(math.floor(value)))
                local style = getStyle()
                if style and style[widgetType] then
                    DeepSet(style[widgetType], entry.key, value)
                    saveStyle(style)
                    refreshPreview()
                end
                updating = false
            end)

            editBox:SetScript("OnEnterPressed", function(self)
                local value = tonumber(self:GetText()) or entry.min
                value = math.max(entry.min, math.min(entry.max, value))
                updating = true
                slider:SetValue(value)
                local style = getStyle()
                if style and style[widgetType] then
                    DeepSet(style[widgetType], entry.key, value)
                    saveStyle(style)
                    refreshPreview()
                end
                updating = false
                self:ClearFocus()
            end)

            editBox:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)

        elseif entry.kind == "dropdown" then
            local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", 10, 0)
            label:SetPoint("RIGHT", holder, "CENTER", -40, 0)
            label:SetJustifyH("RIGHT")
            label:SetText(entry.label)

            local dropdown = CreateFrame("DropdownButton", nil, holder, "WowStyle1DropdownTemplate")
            dropdown:SetWidth(150)
            dropdown:SetPoint("LEFT", holder, "CENTER", -15, 0)

            local options = type(entry.options) == "string" and NivUI.UnitFrames:GetOptionList(entry.options, { widgetType = widgetType }) or entry.options or {}

            dropdown:SetupMenu(function(_, rootDescription)
                for _, opt in ipairs(options) do
                    rootDescription:CreateRadio(
                        opt.name,
                        function()
                            local style = getStyle()
                            local val = style and style[widgetType] and DeepGet(style[widgetType], entry.key)
                            return val == opt.value
                        end,
                        function()
                            local style = getStyle()
                            if style and style[widgetType] then
                                DeepSet(style[widgetType], entry.key, opt.value)
                                saveStyle(style)
                                refreshPreview()
                                self:BuildForWidget(widgetType)
                            end
                        end
                    )
                end
            end)

        elseif entry.kind == "textureDropdown" then
            local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", 10, 0)
            label:SetPoint("RIGHT", holder, "CENTER", -40, 0)
            label:SetJustifyH("RIGHT")
            label:SetText(entry.label)

            local dropdown = CreateFrame("DropdownButton", nil, holder, "WowStyle1DropdownTemplate")
            dropdown:SetWidth(150)
            dropdown:SetPoint("LEFT", holder, "CENTER", -15, 0)

            dropdown:SetupMenu(function(_, rootDescription)
                local textures = NivUI:GetBarTextures()
                for _, tex in ipairs(textures) do
                    local preview = tex.path and ("|T" .. tex.path .. ":16:80|t " .. tex.name) or tex.name
                    rootDescription:CreateRadio(
                        preview,
                        function()
                            local style = getStyle()
                            local val = style and style[widgetType] and DeepGet(style[widgetType], entry.key)
                            return val == tex.value
                        end,
                        function()
                            local style = getStyle()
                            if style and style[widgetType] then
                                DeepSet(style[widgetType], entry.key, tex.value)
                                saveStyle(style)
                                refreshPreview()
                            end
                        end
                    )
                end
                rootDescription:SetScrollMode(20 * 10)
            end)

        elseif entry.kind == "fontDropdown" then
            local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", 10, 0)
            label:SetPoint("RIGHT", holder, "CENTER", -40, 0)
            label:SetJustifyH("RIGHT")
            label:SetText(entry.label)

            local dropdown = CreateFrame("DropdownButton", nil, holder, "WowStyle1DropdownTemplate")
            dropdown:SetWidth(150)
            dropdown:SetPoint("LEFT", holder, "CENTER", -15, 0)

            dropdown:SetupMenu(function(_, rootDescription)
                local fonts = NivUI:GetFonts()
                for _, font in ipairs(fonts) do
                    rootDescription:CreateRadio(
                        font.name,
                        function()
                            local style = getStyle()
                            local val = style and style[widgetType] and DeepGet(style[widgetType], entry.key)
                            return val == font.value
                        end,
                        function()
                            local style = getStyle()
                            if style and style[widgetType] then
                                DeepSet(style[widgetType], entry.key, font.value)
                                saveStyle(style)
                                refreshPreview()
                            end
                        end
                    )
                end
                rootDescription:SetScrollMode(20 * 10)
            end)

        elseif entry.kind == "colorPicker" then
            local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", 10, 0)
            label:SetPoint("RIGHT", holder, "CENTER", -40, 0)
            label:SetJustifyH("RIGHT")
            label:SetText(entry.label)

            local swatch = CreateFrame("Button", nil, holder, "ColorSwatchTemplate")
            swatch:SetPoint("LEFT", holder, "CENTER", -15, 0)

            local color = currentValue or { r = 1, g = 1, b = 1 }
            swatch.currentColor = CopyTable(color)
            swatch:SetColor(CreateColor(color.r, color.g, color.b))

            swatch:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            swatch:SetScript("OnClick", function(_, button)
                if button == "LeftButton" then
                    local info = {}
                    info.r = swatch.currentColor.r
                    info.g = swatch.currentColor.g
                    info.b = swatch.currentColor.b
                    info.opacity = swatch.currentColor.a
                    info.hasOpacity = entry.hasAlpha

                    info.swatchFunc = function()
                        local r, g, b = ColorPickerFrame:GetColorRGB()
                        local a = entry.hasAlpha and ColorPickerFrame:GetColorAlpha() or nil
                        swatch.currentColor = { r = r, g = g, b = b, a = a }
                        swatch:SetColor(CreateColor(r, g, b))

                        local style = getStyle()
                        if style and style[widgetType] then
                            DeepSet(style[widgetType], entry.key, swatch.currentColor)
                            saveStyle(style)
                            refreshPreview()
                        end
                    end

                    info.cancelFunc = function(previousValues)
                        swatch.currentColor = previousValues
                        swatch:SetColor(CreateColor(previousValues.r, previousValues.g, previousValues.b))
                    end

                    info.previousValues = CopyTable(swatch.currentColor)
                    ColorPickerFrame:SetupColorPickerAndShow(info)
                end
            end)
        end

        return holder
    end

    return frame
end

local function CreateAssignmentsPanel(parent, Components)
    local frame = CreateFrame("Frame", nil, parent)

    local allFrames = {}
    local checkboxes = {}

    local function AddRow(row, spacing)
        spacing = spacing or 0
        if #allFrames == 0 then
            row:SetPoint("TOP", frame, "TOP", 0, 0)
        else
            row:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -spacing)
        end
        table.insert(allFrames, row)
    end

    local header = Components.GetHeader(frame, "Frame Style Assignments")
    AddRow(header)

    for _, frameInfo in ipairs(NivUI.UnitFrames.FRAME_TYPES) do
        local row = CreateFrame("Frame", nil, frame)
        row:SetHeight(24)
        row:SetPoint("LEFT", 20, 0)
        row:SetPoint("RIGHT", -20, 0)

        local checkbox = CreateFrame("CheckButton", nil, row, "SettingsCheckboxTemplate")
        checkbox:SetPoint("LEFT", row, "LEFT", 0, 0)
        checkbox:SetText("")  -- Required for template to render
        checkbox:SetScript("OnClick", function(self)
            if self:GetChecked() then
                NivUI:SetFrameEnabled(frameInfo.value, true)
            else
                local dialog = StaticPopup_Show("NIVUI_CONFIRM_RELOAD")
                if dialog then
                    dialog.data = { frameType = frameInfo.value, checkbox = self }
                end
            end
        end)

        table.insert(checkboxes, { checkbox = checkbox, frameType = frameInfo.value, kind = "enabled" })

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
        label:SetText(frameInfo.name .. ":")
        label:SetWidth(100)
        label:SetJustifyH("LEFT")

        local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
        dropdown:SetPoint("LEFT", label, "RIGHT", 8, 0)
        dropdown:SetWidth(150)
        dropdown:SetDefaultText("Select Style")

        dropdown:SetupMenu(function(_owner, rootDescription)
            local names = NivUI:GetStyleNames()
            for _, name in ipairs(names) do
                rootDescription:CreateRadio(
                    name,
                    function() return NivUI:GetAssignment(frameInfo.value) == name end,
                    function() NivUI:SetAssignment(frameInfo.value, name) end
                )
            end
        end)

        local realtimeCheckbox = CreateFrame("CheckButton", nil, row, "SettingsCheckboxTemplate")
        realtimeCheckbox:SetPoint("LEFT", dropdown, "RIGHT", 16, 0)
        realtimeCheckbox:SetText("")  -- Required for template to render
        realtimeCheckbox:SetScript("OnClick", function(self)
            NivUI:SetRealTimeUpdates(frameInfo.value, self:GetChecked())
        end)

        table.insert(checkboxes, { checkbox = realtimeCheckbox, frameType = frameInfo.value, kind = "realtime" })

        local realtimeLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        realtimeLabel:SetPoint("LEFT", realtimeCheckbox, "RIGHT", 2, 0)
        realtimeLabel:SetText("Real-Time")

        local function ShowRealtimeTooltip(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Real-Time Updates")
            GameTooltip:AddLine("Update health/power every frame instead of 10 times per second.", 1, 1, 1, true)
            GameTooltip:AddLine("More responsive but uses more CPU. Recommended for player frame only.", 1, 0.8, 0, true)
            GameTooltip:Show()
        end
        realtimeCheckbox:SetScript("OnEnter", ShowRealtimeTooltip)
        realtimeCheckbox:SetScript("OnLeave", function() GameTooltip:Hide() end)

        AddRow(row, 4)
    end

    frame:SetScript("OnShow", function()
        for _, entry in ipairs(checkboxes) do
            if entry.kind == "enabled" then
                entry.checkbox:SetChecked(NivUI:IsFrameEnabled(entry.frameType))
            elseif entry.kind == "realtime" then
                entry.checkbox:SetChecked(NivUI:IsRealTimeUpdates(entry.frameType))
            end
        end
    end)

    return frame
end

function NivUI.UnitFrames:SetupConfigTab(parent, _Components)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 8, -60)
    container:SetPoint("BOTTOMRIGHT", -8, 8)
    container:Hide()

    local currentStyle = nil

    local function getStyle()
        return currentStyle
    end

    local function saveStyle(style)
        currentStyle = style
        NivUI:SaveStyle(NivUI.UnitFrames.currentStyleName, style)
    end

    NivUI:InitializeDefaultStyle()

    local topBar = CreateFrame("Frame", nil, container)
    topBar:SetHeight(36)
    topBar:SetPoint("TOPLEFT", 0, 0)
    topBar:SetPoint("TOPRIGHT", 0, 0)

    local styleLabel = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    styleLabel:SetPoint("LEFT", 10, 0)
    styleLabel:SetText("Style:")

    local styleDropdown = CreateFrame("DropdownButton", nil, topBar, "WowStyle1DropdownTemplate")
    styleDropdown:SetWidth(150)
    styleDropdown:SetPoint("LEFT", styleLabel, "RIGHT", 10, 0)

    local function RefreshStyleDropdown()
        styleDropdown:SetupMenu(function(_, rootDescription)
            local names = NivUI:GetStyleNames()
            for _, name in ipairs(names) do
                rootDescription:CreateRadio(
                    name,
                    function() return NivUI.UnitFrames.currentStyleName == name end,
                    function()
                        NivUI.UnitFrames.currentStyleName = name
                        currentStyle = NivUI:GetStyleWithDefaults(name)
                        container:RefreshAll()
                    end
                )
            end
        end)
    end

    local newBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    newBtn:SetSize(60, 22)
    newBtn:SetPoint("LEFT", styleDropdown, "RIGHT", 10, 0)
    newBtn:SetText("New")
    newBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_NEW_STYLE")
    end)

    local dupBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    dupBtn:SetSize(70, 22)
    dupBtn:SetPoint("LEFT", newBtn, "RIGHT", 4, 0)
    dupBtn:SetText("Duplicate")
    dupBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_DUPLICATE_STYLE", NivUI.UnitFrames.currentStyleName)
    end)

    local renameBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    renameBtn:SetSize(70, 22)
    renameBtn:SetPoint("LEFT", dupBtn, "RIGHT", 4, 0)
    renameBtn:SetText("Rename")
    renameBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_RENAME_STYLE", NivUI.UnitFrames.currentStyleName)
    end)

    local delBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    delBtn:SetSize(60, 22)
    delBtn:SetPoint("LEFT", renameBtn, "RIGHT", 4, 0)
    delBtn:SetText("Delete")
    delBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_DELETE_STYLE", NivUI.UnitFrames.currentStyleName)
    end)

    local previewContainer = CreateFrame("Frame", nil, container)
    previewContainer:SetHeight(180)
    previewContainer:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -8)
    previewContainer:SetPoint("TOPRIGHT", topBar, "BOTTOMRIGHT", 0, -8)

    local designer = NivUI.Designer:Create(previewContainer)
    designer:SetAllPoints()

    local bottomArea = CreateFrame("Frame", nil, container)
    bottomArea:SetPoint("TOPLEFT", previewContainer, "BOTTOMLEFT", 0, -8)
    bottomArea:SetPoint("BOTTOMRIGHT", 0, 0)

    local settingsPanel
    local widgetList = CreateWidgetList(bottomArea, function(widgetType)
        designer:SelectWidget(widgetType)
        settingsPanel:BuildForWidget(widgetType)
    end)
    widgetList:SetPoint("TOPLEFT", 0, 0)
    widgetList:SetPoint("BOTTOMLEFT", 0, 0)

    settingsPanel = CreateWidgetSettingsPanel(
        bottomArea,
        getStyle,
        saveStyle,
        function()
            NivUI.Designer:RefreshPreview(designer, NivUI.UnitFrames.currentStyleName)
        end
    )
    settingsPanel:SetPoint("TOPLEFT", widgetList, "TOPRIGHT", 8, 0)
    settingsPanel:SetPoint("BOTTOMRIGHT", 0, 0)

    designer.onSelectionChanged = function(widgetType)
        widgetList:Select(widgetType)
        settingsPanel:BuildForWidget(widgetType)
    end

    function container:RefreshAll()
        currentStyle = NivUI:GetStyleWithDefaults(NivUI.UnitFrames.currentStyleName)
        RefreshStyleDropdown()
        widgetList:Populate()
        NivUI.Designer:BuildPreview(designer, NivUI.UnitFrames.currentStyleName)

        local firstWidget = NivUI.UnitFrames.WIDGET_ORDER[1]
        widgetList:Select(firstWidget)
        designer:SelectWidget(firstWidget)
        settingsPanel:BuildForWidget(firstWidget)
    end

    container:SetScript("OnShow", function()
        NivUI.UnitFrames.refreshCallback = function()
            container:RefreshAll()
        end
        local names = NivUI:GetStyleNames()
        if not NivUI:StyleExists(NivUI.UnitFrames.currentStyleName) then
            NivUI.UnitFrames.currentStyleName = names[1] or "Default"
        end
        container:RefreshAll()
    end)

    return container
end

function NivUI.UnitFrames:SetupAssignmentsTab(parent, Components)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 8, -60)
    container:SetPoint("BOTTOMRIGHT", -8, 8)
    container:Hide()

    local assignmentsPanel = CreateAssignmentsPanel(container, Components)
    assignmentsPanel:SetAllPoints()

    return container
end

local function CreateCustomRaidGroupPanel(parent, groupId, Components)
    local frame = CreateFrame("Frame", nil, parent)

    local allFrames = {}
    local checkboxes = {}
    local memberCheckboxes = {}

    local function AddRow(row, spacing)
        spacing = spacing or 0
        if #allFrames == 0 then
            row:SetPoint("TOP", frame, "TOP", 0, 0)
        else
            row:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -spacing)
        end
        table.insert(allFrames, row)
    end

    local function RefreshPanel()
        for _, row in ipairs(allFrames) do
            row:Hide()
            row:SetParent(nil)
        end
        wipe(allFrames)
        wipe(checkboxes)
        wipe(memberCheckboxes)

        local groupData = NivUI:GetCustomRaidGroup(groupId)
        if not groupData then return end

        local headerRow = CreateFrame("Frame", nil, frame)
        headerRow:SetHeight(32)
        headerRow:SetPoint("LEFT", 20, 0)
        headerRow:SetPoint("RIGHT", -20, 0)

        local headerText = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        headerText:SetPoint("LEFT", 0, 0)
        headerText:SetText(groupData.name)

        local deleteBtn = CreateFrame("Button", nil, headerRow, "UIPanelButtonTemplate")
        deleteBtn:SetSize(60, 22)
        deleteBtn:SetPoint("RIGHT", 0, 0)
        deleteBtn:SetText("Delete")
        deleteBtn:SetScript("OnClick", function()
            local dialog = StaticPopup_Show("NIVUI_DELETE_CUSTOM_RAID_GROUP", groupData.name)
            if dialog then
                dialog.data = { groupId = groupId }
            end
        end)

        AddRow(headerRow)

        local filterRow = CreateFrame("Frame", nil, frame)
        filterRow:SetHeight(28)
        filterRow:SetPoint("LEFT", 20, 0)
        filterRow:SetPoint("RIGHT", -20, 0)

        local filterLabel = filterRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        filterLabel:SetPoint("LEFT", 0, 0)
        filterLabel:SetText("Filter Type:")

        local filterDropdown = CreateFrame("DropdownButton", nil, filterRow, "WowStyle1DropdownTemplate")
        filterDropdown:SetWidth(150)
        filterDropdown:SetPoint("LEFT", filterLabel, "RIGHT", 10, 0)

        filterDropdown:SetupMenu(function(_, rootDescription)
            local options = {
                { name = "By Role", value = "role" },
                { name = "By Raid Member", value = "member" },
            }
            for _, opt in ipairs(options) do
                rootDescription:CreateRadio(
                    opt.name,
                    function() return groupData.filterType == opt.value end,
                    function()
                        groupData.filterType = opt.value
                        NivUI:SaveCustomRaidGroup(groupId, groupData)
                        RefreshPanel()
                    end
                )
            end
        end)

        AddRow(filterRow, 8)

        if groupData.filterType == "role" then
            local rolesHeader = Components.GetHeader(frame, "Roles to Include")
            AddRow(rolesHeader, 12)

            local roleTypes = {
                { key = "tank", label = "Tanks" },
                { key = "healer", label = "Healers" },
                { key = "dps", label = "DPS" },
            }

            for _, roleInfo in ipairs(roleTypes) do
                local roleRow = CreateFrame("Frame", nil, frame)
                roleRow:SetHeight(24)
                roleRow:SetPoint("LEFT", 30, 0)
                roleRow:SetPoint("RIGHT", -20, 0)

                local checkbox = CreateFrame("CheckButton", nil, roleRow, "SettingsCheckboxTemplate")
                checkbox:SetPoint("LEFT", 0, 0)
                checkbox:SetText("")
                checkbox:SetChecked(groupData.roles[roleInfo.key])

                checkbox:SetScript("OnClick", function(self)
                    groupData.roles[roleInfo.key] = self:GetChecked()
                    NivUI:SaveCustomRaidGroup(groupId, groupData)
                end)

                local roleLabel = roleRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                roleLabel:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
                roleLabel:SetText(roleInfo.label)

                table.insert(checkboxes, { checkbox = checkbox, key = roleInfo.key })
                AddRow(roleRow, 4)
            end

        else
            local membersHeader = Components.GetHeader(frame, "Raid Members to Include")
            AddRow(membersHeader, 12)

            local scrollContainer = CreateFrame("Frame", nil, frame)
            scrollContainer:SetHeight(200)
            scrollContainer:SetPoint("LEFT", 30, 0)
            scrollContainer:SetPoint("RIGHT", -20, 0)

            local bg = scrollContainer:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.08, 0.08, 0.08, 0.8)

            local scrollFrame = CreateFrame("ScrollFrame", nil, scrollContainer, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", 4, -4)
            scrollFrame:SetPoint("BOTTOMRIGHT", -24, 4)

            local content = CreateFrame("Frame", nil, scrollFrame)
            content:SetWidth(scrollContainer:GetWidth() - 40)
            content:SetHeight(1)
            scrollFrame:SetScrollChild(content)

            local raidMembers = {}
            if IsInRaid() then
                for i = 1, 40 do
                    local name = GetRaidRosterInfo(i)
                    if name then
                        local shortName = strsplit("-", name)
                        table.insert(raidMembers, shortName)
                    end
                end
            else
                local playerName = UnitName("player")
                table.insert(raidMembers, playerName)
                for i = 1, 4 do
                    local name = UnitName("party" .. i)
                    if name then
                        table.insert(raidMembers, name)
                    end
                end
            end

            for savedName in pairs(groupData.members) do
                local found = false
                for _, name in ipairs(raidMembers) do
                    if name == savedName then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(raidMembers, savedName)
                end
            end

            table.sort(raidMembers)

            local yOffset = 0
            for _, memberName in ipairs(raidMembers) do
                local memberRow = CreateFrame("Frame", nil, content)
                memberRow:SetHeight(22)
                memberRow:SetPoint("TOPLEFT", 0, -yOffset)
                memberRow:SetPoint("TOPRIGHT", 0, -yOffset)

                local checkbox = CreateFrame("CheckButton", nil, memberRow, "SettingsCheckboxTemplate")
                checkbox:SetPoint("LEFT", 0, 0)
                checkbox:SetText("")
                checkbox:SetChecked(groupData.members[memberName] == true)

                checkbox:SetScript("OnClick", function(self)
                    if self:GetChecked() then
                        groupData.members[memberName] = true
                    else
                        groupData.members[memberName] = nil
                    end
                    NivUI:SaveCustomRaidGroup(groupId, groupData)
                end)

                local memberLabel = memberRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                memberLabel:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
                memberLabel:SetText(memberName)

                table.insert(memberCheckboxes, { checkbox = checkbox, name = memberName })
                yOffset = yOffset + 22
            end

            content:SetHeight(math.max(yOffset, 20))

            if #raidMembers == 0 then
                local emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
                emptyText:SetPoint("CENTER", 0, 0)
                emptyText:SetText("No raid members found")
            end

            AddRow(scrollContainer, 4)
        end

        local styleRow = CreateFrame("Frame", nil, frame)
        styleRow:SetHeight(28)
        styleRow:SetPoint("LEFT", 20, 0)
        styleRow:SetPoint("RIGHT", -20, 0)

        local styleLabel = styleRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        styleLabel:SetPoint("LEFT", 0, 0)
        styleLabel:SetText("Style:")

        local styleDropdown = CreateFrame("DropdownButton", nil, styleRow, "WowStyle1DropdownTemplate")
        styleDropdown:SetWidth(150)
        styleDropdown:SetPoint("LEFT", styleLabel, "RIGHT", 10, 0)

        styleDropdown:SetupMenu(function(_, rootDescription)
            local names = NivUI:GetStyleNames()
            for _, styleName in ipairs(names) do
                rootDescription:CreateRadio(
                    styleName,
                    function() return groupData.styleName == styleName end,
                    function()
                        groupData.styleName = styleName
                        NivUI:SaveCustomRaidGroup(groupId, groupData)
                    end
                )
            end
        end)

        AddRow(styleRow, 12)

        local enabledRow = CreateFrame("Frame", nil, frame)
        enabledRow:SetHeight(24)
        enabledRow:SetPoint("LEFT", 20, 0)
        enabledRow:SetPoint("RIGHT", -20, 0)

        local enabledCheckbox = CreateFrame("CheckButton", nil, enabledRow, "SettingsCheckboxTemplate")
        enabledCheckbox:SetPoint("LEFT", 0, 0)
        enabledCheckbox:SetText("")
        enabledCheckbox:SetChecked(groupData.enabled)

        enabledCheckbox:SetScript("OnClick", function(self)
            groupData.enabled = self:GetChecked()
            NivUI:SaveCustomRaidGroup(groupId, groupData)
        end)

        local enabledLabel = enabledRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        enabledLabel:SetPoint("LEFT", enabledCheckbox, "RIGHT", 4, 0)
        enabledLabel:SetText("Enabled")

        AddRow(enabledRow, 8)
    end

    frame:SetScript("OnShow", function()
        RefreshPanel()
    end)

    local eventFrame = CreateFrame("Frame", nil, frame)
    eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    eventFrame:SetScript("OnEvent", function()
        if frame:IsShown() then
            RefreshPanel()
        end
    end)

    return frame
end

function NivUI.UnitFrames:SetupConfigTabWithSubtabs(parent, Components)
    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints()
    container:Hide()

    local TAB_HEIGHT = 24
    local allTabs = {}
    local customGroupTabs = {}
    local currentSubTab = "designer"
    local addButton

    local staticTabDefinitions = {
        {
            id = "designer",
            name = "Designer",
            frameType = nil,
            createPanel = function(panelParent)
                return self:SetupDesignerContent(panelParent, Components)
            end
        },
        {
            id = "assignments",
            name = "Assignments",
            frameType = nil,
            createPanel = function(panelParent)
                return CreateAssignmentsPanel(panelParent, Components)
            end
        },
    }

    for _, def in ipairs(staticTabDefinitions) do
        local tabContainer = CreateFrame("Frame", nil, container)
        tabContainer:SetPoint("BOTTOMRIGHT", 0, 0)
        tabContainer:Hide()

        local panel = def.createPanel(tabContainer)
        panel:SetAllPoints()

        local tab = Components.GetTab(container, def.name)

        local tabData = {
            id = def.id,
            frameType = def.frameType,
            tab = tab,
            container = tabContainer,
            isCustomGroup = false,
        }

        tab:SetScript("OnClick", function()
            SelectSubTab(def.id)
        end)

        table.insert(allTabs, tabData)
    end

    addButton = Components.GetTab(container, "+")
    PanelTemplates_DeselectTab(addButton)

    addButton:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_NEW_CUSTOM_RAID_GROUP")
    end)

    addButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Add Custom Raid Group")
        GameTooltip:AddLine("Create a filtered raid frame group", 1, 1, 1, true)
        GameTooltip:Show()
    end)

    addButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local function CreateCustomGroupTab(groupId, groupData)
        local tabContainer = CreateFrame("Frame", nil, container)
        tabContainer:SetPoint("BOTTOMRIGHT", 0, 0)
        tabContainer:Hide()

        local panel = CreateCustomRaidGroupPanel(tabContainer, groupId, Components)
        panel:SetAllPoints()

        local tab = Components.GetTab(container, groupData.name)

        local tabData = {
            id = "customGroup_" .. groupId,
            groupId = groupId,
            frameType = nil,
            tab = tab,
            container = tabContainer,
            isCustomGroup = true,
        }

        tab:SetScript("OnClick", function()
            SelectSubTab(tabData.id)
        end)

        return tabData
    end

    local function RebuildCustomGroupTabs()
        for _, tabData in ipairs(customGroupTabs) do
            tabData.tab:Hide()
            tabData.tab:SetParent(nil)
            tabData.container:Hide()
            tabData.container:SetParent(nil)
        end
        wipe(customGroupTabs)

        for i = #allTabs, 1, -1 do
            if allTabs[i].isCustomGroup then
                table.remove(allTabs, i)
            end
        end

        local customGroups = NivUI:GetCustomRaidGroups()
        for groupId, groupData in pairs(customGroups) do
            local tabData = CreateCustomGroupTab(groupId, groupData)
            table.insert(allTabs, tabData)
            table.insert(customGroupTabs, tabData)
        end
    end

    local function FindTabById(tabId)
        for _, tabData in ipairs(allTabs) do
            if tabData.id == tabId then
                return tabData
            end
        end
        return nil
    end

    local function FindFirstVisibleTab()
        for _, tabData in ipairs(allTabs) do
            if tabData.tab:IsShown() then
                return tabData
            end
        end
        return nil
    end

    function SelectSubTab(tabId)
        for _, tabData in ipairs(allTabs) do
            if tabData.id == tabId and tabData.tab:IsShown() then
                PanelTemplates_SelectTab(tabData.tab)
                tabData.container:Show()
                currentSubTab = tabId
            else
                PanelTemplates_DeselectTab(tabData.tab)
                tabData.container:Hide()
            end
        end
    end

    local function LayoutTabs()
        local containerWidth = container:GetWidth()
        if containerWidth == 0 then
            containerWidth = 600  -- Fallback width
        end

        local x, y = 0, 0
        local numRows = 1

        for _, tabData in ipairs(allTabs) do
            local shouldShow = tabData.frameType == nil or NivUI:IsFrameEnabled(tabData.frameType)

            if shouldShow then
                tabData.tab:Show()

                local tabWidth = tabData.tab:GetWidth()

                if x + tabWidth > containerWidth and x > 0 then
                    x = 0
                    y = y - TAB_HEIGHT
                    numRows = numRows + 1
                end

                tabData.tab:ClearAllPoints()
                tabData.tab:SetPoint("TOPLEFT", container, "TOPLEFT", x, y)

                x = x + tabWidth
            else
                tabData.tab:Hide()
            end
        end

        local addBtnWidth = addButton:GetWidth()
        if x + addBtnWidth > containerWidth and x > 0 then
            x = 0
            y = y - TAB_HEIGHT
            numRows = numRows + 1
        end
        addButton:ClearAllPoints()
        addButton:SetPoint("TOPLEFT", container, "TOPLEFT", x, y)

        local contentOffset = -(numRows * TAB_HEIGHT) - 10
        for _, tabData in ipairs(allTabs) do
            tabData.container:ClearAllPoints()
            tabData.container:SetPoint("TOPLEFT", 0, contentOffset)
            tabData.container:SetPoint("BOTTOMRIGHT", 0, 0)
        end

        local currentTabData = FindTabById(currentSubTab)
        if not currentTabData or not currentTabData.tab:IsShown() then
            local firstVisible = FindFirstVisibleTab()
            if firstVisible then
                SelectSubTab(firstVisible.id)
            end
        end
    end

    container:SetScript("OnSizeChanged", function()
        LayoutTabs()
    end)

    container:SetScript("OnShow", function()
        RebuildCustomGroupTabs()
        LayoutTabs()
        SelectSubTab(currentSubTab)
    end)

    NivUI:RegisterCallback("FrameEnabledChanged", function(_data)
        if container:IsShown() then
            LayoutTabs()
        end
    end)

    NivUI:RegisterCallback("CustomRaidGroupCreated", function(data)
        if container:IsShown() then
            RebuildCustomGroupTabs()
            LayoutTabs()
            SelectSubTab("customGroup_" .. data.id)
        end
    end)

    NivUI:RegisterCallback("CustomRaidGroupDeleted", function(_data)
        if container:IsShown() then
            if currentSubTab:find("customGroup_") then
                currentSubTab = "designer"
            end
            RebuildCustomGroupTabs()
            LayoutTabs()
            SelectSubTab(currentSubTab)
        end
    end)

    return container
end

function NivUI.UnitFrames:SetupDesignerContent(parent, _Components)
    local container = CreateFrame("Frame", nil, parent)

    local currentStyle = nil

    local function getStyle()
        return currentStyle
    end

    local function saveStyle(style)
        currentStyle = style
        NivUI:SaveStyle(NivUI.UnitFrames.currentStyleName, style)
    end

    NivUI:InitializeDefaultStyle()

    local topBar = CreateFrame("Frame", nil, container)
    topBar:SetHeight(36)
    topBar:SetPoint("TOPLEFT", 0, 0)
    topBar:SetPoint("TOPRIGHT", 0, 0)

    local styleLabel = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    styleLabel:SetPoint("LEFT", 10, 0)
    styleLabel:SetText("Style:")

    local styleDropdown = CreateFrame("DropdownButton", nil, topBar, "WowStyle1DropdownTemplate")
    styleDropdown:SetWidth(120)
    styleDropdown:SetPoint("LEFT", styleLabel, "RIGHT", 10, 0)

    local function RefreshStyleDropdown()
        styleDropdown:SetupMenu(function(_, rootDescription)
            local names = NivUI:GetStyleNames()
            for _, name in ipairs(names) do
                rootDescription:CreateRadio(
                    name,
                    function() return NivUI.UnitFrames.currentStyleName == name end,
                    function()
                        NivUI.UnitFrames.currentStyleName = name
                        currentStyle = NivUI:GetStyleWithDefaults(name)
                        container:RefreshAll()
                    end
                )
            end
        end)
    end

    local newBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    newBtn:SetSize(50, 22)
    newBtn:SetPoint("LEFT", styleDropdown, "RIGHT", 6, 0)
    newBtn:SetText("New")
    newBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_NEW_STYLE")
    end)

    local dupBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    dupBtn:SetSize(50, 22)
    dupBtn:SetPoint("LEFT", newBtn, "RIGHT", 2, 0)
    dupBtn:SetText("Copy")
    dupBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_DUPLICATE_STYLE", NivUI.UnitFrames.currentStyleName)
    end)

    local renameBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    renameBtn:SetSize(60, 22)
    renameBtn:SetPoint("LEFT", dupBtn, "RIGHT", 2, 0)
    renameBtn:SetText("Rename")
    renameBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_RENAME_STYLE", NivUI.UnitFrames.currentStyleName)
    end)

    local delBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    delBtn:SetSize(50, 22)
    delBtn:SetPoint("LEFT", renameBtn, "RIGHT", 2, 0)
    delBtn:SetText("Delete")
    delBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_DELETE_STYLE", NivUI.UnitFrames.currentStyleName)
    end)

    local previewContainer = CreateFrame("Frame", nil, container)
    previewContainer:SetHeight(140)
    previewContainer:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -4)
    previewContainer:SetPoint("TOPRIGHT", topBar, "BOTTOMRIGHT", 0, -4)

    local designer = NivUI.Designer:Create(previewContainer)
    designer:SetAllPoints()

    local bottomArea = CreateFrame("Frame", nil, container)
    bottomArea:SetPoint("TOPLEFT", previewContainer, "BOTTOMLEFT", 0, -4)
    bottomArea:SetPoint("BOTTOMRIGHT", 0, 0)

    local settingsPanel
    local widgetList = CreateWidgetList(bottomArea, function(widgetType)
        designer:SelectWidget(widgetType)
        settingsPanel:BuildForWidget(widgetType)
    end)
    widgetList:SetPoint("TOPLEFT", 0, 0)
    widgetList:SetPoint("BOTTOMLEFT", 0, 0)

    settingsPanel = CreateWidgetSettingsPanel(
        bottomArea,
        getStyle,
        saveStyle,
        function()
            NivUI.Designer:RefreshPreview(designer, NivUI.UnitFrames.currentStyleName)
        end
    )
    settingsPanel:SetPoint("TOPLEFT", widgetList, "TOPRIGHT", 8, 0)
    settingsPanel:SetPoint("BOTTOMRIGHT", 0, 0)

    designer.onSelectionChanged = function(widgetType)
        widgetList:Select(widgetType)
        settingsPanel:BuildForWidget(widgetType)
    end

    function container:RefreshAll()
        currentStyle = NivUI:GetStyleWithDefaults(NivUI.UnitFrames.currentStyleName)
        RefreshStyleDropdown()
        widgetList:Populate()
        NivUI.Designer:BuildPreview(designer, NivUI.UnitFrames.currentStyleName)

        local firstWidget = NivUI.UnitFrames.WIDGET_ORDER[1]
        widgetList:Select(firstWidget)
        designer:SelectWidget(firstWidget)
        settingsPanel:BuildForWidget(firstWidget)
    end

    container:SetScript("OnShow", function()
        NivUI.UnitFrames.refreshCallback = function()
            container:RefreshAll()
        end
        local names = NivUI:GetStyleNames()
        if not NivUI:StyleExists(NivUI.UnitFrames.currentStyleName) then
            NivUI.UnitFrames.currentStyleName = names[1] or "Default"
        end
        container:RefreshAll()
    end)

    return container
end
