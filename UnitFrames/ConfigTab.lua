-- NivUI Unit Frames: Configuration Tab
-- Style designer and frame assignments UI

NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local ROW_HEIGHT = 32
local SECTION_SPACING = 20
local WIDGET_LIST_WIDTH = 140

--------------------------------------------------------------------------------
-- Local Helpers
--------------------------------------------------------------------------------

-- Deep get a nested value from a table using a dot-separated key
local function DeepGet(tbl, key)
    local parts = { strsplit(".", key) }
    local current = tbl
    for _, part in ipairs(parts) do
        if type(current) ~= "table" then return nil end
        current = current[part]
    end
    return current
end

-- Deep set a nested value in a table using a dot-separated key
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

-- Deep copy helper
local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

--------------------------------------------------------------------------------
-- Widget List Component
--------------------------------------------------------------------------------

local function CreateWidgetList(parent, onSelect)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(WIDGET_LIST_WIDTH)
    frame:SetPoint("TOPLEFT", 0, 0)
    frame:SetPoint("BOTTOMLEFT", 0, 0)

    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.08, 0.08, 0.9)

    -- Scroll frame
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
        -- Clear existing buttons
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
        -- Deselect previous
        if self.selected and self.buttons[self.selected] then
            self.buttons[self.selected].selected:Hide()
            self.buttons[self.selected].text:SetFontObject("GameFontHighlight")
        end

        self.selected = widgetType

        -- Select new
        if widgetType and self.buttons[widgetType] then
            self.buttons[widgetType].selected:Show()
            self.buttons[widgetType].text:SetFontObject("GameFontNormal")
        end
    end

    return frame
end

--------------------------------------------------------------------------------
-- Widget Settings Panel
--------------------------------------------------------------------------------

local function CreateWidgetSettingsPanel(parent, getStyle, saveStyle, refreshPreview)
    local frame = CreateFrame("Frame", nil, parent)

    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.06, 0.06, 0.06, 0.9)

    -- Tab buttons at top
    frame.tabButtons = {}
    frame.tabPanels = {}
    frame.currentTab = 1
    frame.currentWidget = nil

    local tabHolder = CreateFrame("Frame", nil, frame)
    tabHolder:SetHeight(28)
    tabHolder:SetPoint("TOPLEFT", 0, 0)
    tabHolder:SetPoint("TOPRIGHT", 0, 0)
    frame.tabHolder = tabHolder

    -- Content area
    local contentArea = CreateFrame("Frame", nil, frame)
    contentArea:SetPoint("TOPLEFT", 0, -32)
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
        self.currentWidget = widgetType

        -- Clear existing tabs and panels
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

        -- Create tabs
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

            -- Position: first tab at left, others anchor to previous
            if #self.tabButtons == 0 then
                tab:SetPoint("TOPLEFT", 0, 0)
            else
                tab:SetPoint("LEFT", self.tabButtons[#self.tabButtons], "RIGHT", 0, 0)
            end

            table.insert(self.tabButtons, tab)

            -- Create panel for this tab
            local panel = CreateFrame("ScrollFrame", nil, self.contentArea, "UIPanelScrollFrameTemplate")
            panel:SetPoint("TOPLEFT", 0, 0)
            panel:SetPoint("BOTTOMRIGHT", -24, 0)
            panel:Hide()

            local panelContent = CreateFrame("Frame", nil, panel)
            panelContent:SetWidth(self.contentArea:GetWidth() - 40)
            panelContent:SetHeight(1)
            panel:SetScrollChild(panelContent)

            -- Build entries
            local yOffset = 0
            for _, entry in ipairs(tabConfig.entries) do
                -- Check showIf/hideIf conditions
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

        -- Restore previous tab if valid, otherwise select first
        if #self.tabButtons > 0 then
            local tabToSelect = self.currentTab
            if tabToSelect > #self.tabButtons then
                tabToSelect = 1
            end
            self:SelectTab(tabToSelect)
        end
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
                                -- Rebuild panel to handle showIf changes
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

--------------------------------------------------------------------------------
-- Frame Assignments Panel
--------------------------------------------------------------------------------

local function CreateAssignmentsPanel(parent, Components)
    local frame = CreateFrame("Frame", nil, parent)

    local allFrames = {}

    local function AddRow(row, spacing)
        spacing = spacing or 0
        if #allFrames == 0 then
            row:SetPoint("TOP", frame, "TOP", 0, -10)
        else
            row:SetPoint("TOP", allFrames[#allFrames], "BOTTOM", 0, -spacing)
        end
        table.insert(allFrames, row)
    end

    -- Header
    local header = Components.GetHeader(frame, "Frame Style Assignments")
    AddRow(header)

    -- Create a dropdown for each frame type
    for _, frameInfo in ipairs(NivUI.UnitFrames.FRAME_TYPES) do
        local dropdown = Components.GetBasicDropdown(
            frame,
            frameInfo.name .. ":",
            function()
                local names = NivUI:GetStyleNames()
                local items = {}
                for _, name in ipairs(names) do
                    table.insert(items, { value = name, name = name })
                end
                return items
            end,
            function(value)
                return NivUI:GetAssignment(frameInfo.value) == value
            end,
            function(value)
                NivUI:SetAssignment(frameInfo.value, value)
            end
        )
        AddRow(dropdown, 4)
    end

    return frame
end

--------------------------------------------------------------------------------
-- Main Setup Function
--------------------------------------------------------------------------------

function NivUI.UnitFrames:SetupConfigTab(parent, Components)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 8, -60)
    container:SetPoint("BOTTOMRIGHT", -8, 8)
    container:Hide()

    -- State
    local currentStyleName = "Default"
    local currentStyle = nil

    local function getStyle()
        return currentStyle
    end

    local function saveStyle(style)
        currentStyle = style
        NivUI:SaveStyle(currentStyleName, style)
    end

    -- Ensure default style exists
    NivUI:InitializeDefaultStyle()

    ----------------------------------------------------------------------------
    -- Top Bar: Style selector and actions
    ----------------------------------------------------------------------------
    local topBar = CreateFrame("Frame", nil, container)
    topBar:SetHeight(36)
    topBar:SetPoint("TOPLEFT", 0, 0)
    topBar:SetPoint("TOPRIGHT", 0, 0)

    -- Style label
    local styleLabel = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    styleLabel:SetPoint("LEFT", 10, 0)
    styleLabel:SetText("Style:")

    -- Style dropdown
    local styleDropdown = CreateFrame("DropdownButton", nil, topBar, "WowStyle1DropdownTemplate")
    styleDropdown:SetWidth(150)
    styleDropdown:SetPoint("LEFT", styleLabel, "RIGHT", 10, 0)

    local function RefreshStyleDropdown()
        styleDropdown:SetupMenu(function(_, rootDescription)
            local names = NivUI:GetStyleNames()
            for _, name in ipairs(names) do
                rootDescription:CreateRadio(
                    name,
                    function() return currentStyleName == name end,
                    function()
                        currentStyleName = name
                        currentStyle = NivUI:GetStyleWithDefaults(name)
                        container:RefreshAll()
                    end
                )
            end
        end)
    end

    -- New button
    local newBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    newBtn:SetSize(60, 22)
    newBtn:SetPoint("LEFT", styleDropdown, "RIGHT", 10, 0)
    newBtn:SetText("New")
    newBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_NEW_STYLE")
    end)

    -- Duplicate button
    local dupBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    dupBtn:SetSize(70, 22)
    dupBtn:SetPoint("LEFT", newBtn, "RIGHT", 4, 0)
    dupBtn:SetText("Duplicate")
    dupBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_DUPLICATE_STYLE", currentStyleName)
    end)

    -- Rename button
    local renameBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    renameBtn:SetSize(70, 22)
    renameBtn:SetPoint("LEFT", dupBtn, "RIGHT", 4, 0)
    renameBtn:SetText("Rename")
    renameBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_RENAME_STYLE", currentStyleName)
    end)

    -- Delete button
    local delBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    delBtn:SetSize(60, 22)
    delBtn:SetPoint("LEFT", renameBtn, "RIGHT", 4, 0)
    delBtn:SetText("Delete")
    delBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_DELETE_STYLE", currentStyleName)
    end)

    ----------------------------------------------------------------------------
    -- Preview Area
    ----------------------------------------------------------------------------
    local previewContainer = CreateFrame("Frame", nil, container)
    previewContainer:SetHeight(180)
    previewContainer:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -8)
    previewContainer:SetPoint("TOPRIGHT", topBar, "BOTTOMRIGHT", 0, -8)

    local designer = NivUI.Designer:Create(previewContainer)
    designer:SetAllPoints()

    ----------------------------------------------------------------------------
    -- Bottom Split: Widget List + Settings
    ----------------------------------------------------------------------------
    local bottomArea = CreateFrame("Frame", nil, container)
    bottomArea:SetPoint("TOPLEFT", previewContainer, "BOTTOMLEFT", 0, -8)
    bottomArea:SetPoint("BOTTOMRIGHT", 0, 0)

    -- Widget list on the left
    local widgetList = CreateWidgetList(bottomArea, function(widgetType)
        designer:SelectWidget(widgetType)
        settingsPanel:BuildForWidget(widgetType)
    end)
    widgetList:SetPoint("TOPLEFT", 0, 0)
    widgetList:SetPoint("BOTTOMLEFT", 0, 0)

    -- Settings panel on the right
    local settingsPanel = CreateWidgetSettingsPanel(
        bottomArea,
        getStyle,
        saveStyle,
        function()
            NivUI.Designer:RefreshPreview(designer, currentStyleName)
        end
    )
    settingsPanel:SetPoint("TOPLEFT", widgetList, "TOPRIGHT", 8, 0)
    settingsPanel:SetPoint("BOTTOMRIGHT", 0, 0)

    -- Link designer selection to widget list
    designer.onSelectionChanged = function(widgetType)
        widgetList:Select(widgetType)
        settingsPanel:BuildForWidget(widgetType)
    end

    ----------------------------------------------------------------------------
    -- Refresh function
    ----------------------------------------------------------------------------
    function container:RefreshAll()
        currentStyle = NivUI:GetStyleWithDefaults(currentStyleName)
        RefreshStyleDropdown()
        widgetList:Populate()
        NivUI.Designer:BuildPreview(designer, currentStyleName)

        -- Select first widget by default
        local firstWidget = NivUI.UnitFrames.WIDGET_ORDER[1]
        widgetList:Select(firstWidget)
        designer:SelectWidget(firstWidget)
        settingsPanel:BuildForWidget(firstWidget)
    end

    ----------------------------------------------------------------------------
    -- OnShow
    ----------------------------------------------------------------------------
    container:SetScript("OnShow", function()
        container:RefreshAll()
    end)

    ----------------------------------------------------------------------------
    -- Static Popups
    ----------------------------------------------------------------------------
    StaticPopupDialogs["NIVUI_NEW_STYLE"] = {
        text = "Enter name for new style:",
        button1 = "Create",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self)
            local name = self.editBox:GetText()
            local success, err = NivUI:CreateStyle(name)
            if success then
                currentStyleName = name
                container:RefreshAll()
            else
                print("NivUI: " .. (err or "Failed to create style"))
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local name = self:GetText()
            local success, err = NivUI:CreateStyle(name)
            if success then
                currentStyleName = name
                container:RefreshAll()
            else
                print("NivUI: " .. (err or "Failed to create style"))
            end
            parent:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopupDialogs["NIVUI_DUPLICATE_STYLE"] = {
        text = "Enter name for duplicate of '%s':",
        button1 = "Duplicate",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self, data)
            local name = self.editBox:GetText()
            local success, err = NivUI:DuplicateStyle(currentStyleName, name)
            if success then
                currentStyleName = name
                container:RefreshAll()
            else
                print("NivUI: " .. (err or "Failed to duplicate style"))
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopupDialogs["NIVUI_DELETE_STYLE"] = {
        text = "Delete style '%s'? This cannot be undone.",
        button1 = "Delete",
        button2 = "Cancel",
        OnAccept = function()
            local success, err = NivUI:DeleteStyle(currentStyleName)
            if success then
                -- Select first available style
                local names = NivUI:GetStyleNames()
                currentStyleName = names[1] or "Default"
                container:RefreshAll()
            else
                print("NivUI: " .. (err or "Failed to delete style"))
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        showAlert = true,
    }

    StaticPopupDialogs["NIVUI_RENAME_STYLE"] = {
        text = "Enter new name for '%s':",
        button1 = "Rename",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self)
            local newName = self.editBox:GetText()
            local success, err = NivUI:RenameStyle(currentStyleName, newName)
            if success then
                currentStyleName = newName
                container:RefreshAll()
            else
                print("NivUI: " .. (err or "Failed to rename style"))
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local newName = self:GetText()
            local success, err = NivUI:RenameStyle(currentStyleName, newName)
            if success then
                currentStyleName = newName
                container:RefreshAll()
            else
                print("NivUI: " .. (err or "Failed to rename style"))
            end
            parent:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    return container
end

--------------------------------------------------------------------------------
-- Assignments Tab Setup
--------------------------------------------------------------------------------

function NivUI.UnitFrames:SetupAssignmentsTab(parent, Components)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", 8, -60)
    container:SetPoint("BOTTOMRIGHT", -8, 8)
    container:Hide()

    -- Create assignments panel
    local assignmentsPanel = CreateAssignmentsPanel(container, Components)
    assignmentsPanel:SetAllPoints()

    return container
end

--------------------------------------------------------------------------------
-- Combined Setup with Sub-tabs (Designer + Assignments)
--------------------------------------------------------------------------------

function NivUI.UnitFrames:SetupConfigTabWithSubtabs(parent, Components)
    local container = CreateFrame("Frame", nil, parent)
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

    -- Create Designer sub-tab content
    local designerContainer = self:SetupDesignerContent(container, Components)
    designerContainer:SetPoint("TOPLEFT", 0, -32)
    designerContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    table.insert(subTabContainers, designerContainer)

    local designerTab = Components.GetTab(container, "Designer")
    designerTab:SetPoint("TOPLEFT", 0, 0)
    designerTab:SetScript("OnClick", function() SelectSubTab(1) end)
    table.insert(subTabs, designerTab)

    -- Create Assignments sub-tab content
    local assignmentsContainer = CreateFrame("Frame", nil, container)
    assignmentsContainer:SetPoint("TOPLEFT", 0, -32)
    assignmentsContainer:SetPoint("BOTTOMRIGHT", 0, 0)
    assignmentsContainer:Hide()

    local assignmentsPanel = CreateAssignmentsPanel(assignmentsContainer, Components)
    assignmentsPanel:SetAllPoints()
    table.insert(subTabContainers, assignmentsContainer)

    local assignmentsTab = Components.GetTab(container, "Assignments")
    assignmentsTab:SetPoint("LEFT", designerTab, "RIGHT", 0, 0)
    assignmentsTab:SetScript("OnClick", function() SelectSubTab(2) end)
    table.insert(subTabs, assignmentsTab)

    -- Select first sub-tab when shown
    container:SetScript("OnShow", function()
        SelectSubTab(currentSubTab)
    end)

    return container
end

--------------------------------------------------------------------------------
-- Designer Content (extracted from SetupConfigTab)
--------------------------------------------------------------------------------

function NivUI.UnitFrames:SetupDesignerContent(parent, Components)
    local container = CreateFrame("Frame", nil, parent)
    container:Hide()

    -- State
    local currentStyleName = "Default"
    local currentStyle = nil

    local function getStyle()
        return currentStyle
    end

    local function saveStyle(style)
        currentStyle = style
        NivUI:SaveStyle(currentStyleName, style)
    end

    -- Ensure default style exists
    NivUI:InitializeDefaultStyle()

    ----------------------------------------------------------------------------
    -- Top Bar: Style selector and actions
    ----------------------------------------------------------------------------
    local topBar = CreateFrame("Frame", nil, container)
    topBar:SetHeight(36)
    topBar:SetPoint("TOPLEFT", 0, 0)
    topBar:SetPoint("TOPRIGHT", 0, 0)

    -- Style label
    local styleLabel = topBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    styleLabel:SetPoint("LEFT", 10, 0)
    styleLabel:SetText("Style:")

    -- Style dropdown
    local styleDropdown = CreateFrame("DropdownButton", nil, topBar, "WowStyle1DropdownTemplate")
    styleDropdown:SetWidth(120)
    styleDropdown:SetPoint("LEFT", styleLabel, "RIGHT", 10, 0)

    local function RefreshStyleDropdown()
        styleDropdown:SetupMenu(function(_, rootDescription)
            local names = NivUI:GetStyleNames()
            for _, name in ipairs(names) do
                rootDescription:CreateRadio(
                    name,
                    function() return currentStyleName == name end,
                    function()
                        currentStyleName = name
                        currentStyle = NivUI:GetStyleWithDefaults(name)
                        container:RefreshAll()
                    end
                )
            end
        end)
    end

    -- New button
    local newBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    newBtn:SetSize(50, 22)
    newBtn:SetPoint("LEFT", styleDropdown, "RIGHT", 6, 0)
    newBtn:SetText("New")
    newBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_NEW_STYLE_2")
    end)

    -- Duplicate button
    local dupBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    dupBtn:SetSize(50, 22)
    dupBtn:SetPoint("LEFT", newBtn, "RIGHT", 2, 0)
    dupBtn:SetText("Copy")
    dupBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_DUPLICATE_STYLE_2", currentStyleName)
    end)

    -- Rename button
    local renameBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    renameBtn:SetSize(60, 22)
    renameBtn:SetPoint("LEFT", dupBtn, "RIGHT", 2, 0)
    renameBtn:SetText("Rename")
    renameBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_RENAME_STYLE_2", currentStyleName)
    end)

    -- Delete button
    local delBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    delBtn:SetSize(50, 22)
    delBtn:SetPoint("LEFT", renameBtn, "RIGHT", 2, 0)
    delBtn:SetText("Delete")
    delBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_DELETE_STYLE_2", currentStyleName)
    end)

    ----------------------------------------------------------------------------
    -- Preview Area
    ----------------------------------------------------------------------------
    local previewContainer = CreateFrame("Frame", nil, container)
    previewContainer:SetHeight(140)
    previewContainer:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -4)
    previewContainer:SetPoint("TOPRIGHT", topBar, "BOTTOMRIGHT", 0, -4)

    local designer = NivUI.Designer:Create(previewContainer)
    designer:SetAllPoints()

    ----------------------------------------------------------------------------
    -- Bottom Split: Widget List + Settings
    ----------------------------------------------------------------------------
    local bottomArea = CreateFrame("Frame", nil, container)
    bottomArea:SetPoint("TOPLEFT", previewContainer, "BOTTOMLEFT", 0, -4)
    bottomArea:SetPoint("BOTTOMRIGHT", 0, 0)

    -- Widget list on the left
    local widgetList = CreateWidgetList(bottomArea, function(widgetType)
        designer:SelectWidget(widgetType)
        settingsPanel:BuildForWidget(widgetType)
    end)
    widgetList:SetPoint("TOPLEFT", 0, 0)
    widgetList:SetPoint("BOTTOMLEFT", 0, 0)

    -- Settings panel on the right
    local settingsPanel = CreateWidgetSettingsPanel(
        bottomArea,
        getStyle,
        saveStyle,
        function()
            NivUI.Designer:RefreshPreview(designer, currentStyleName)
        end
    )
    settingsPanel:SetPoint("TOPLEFT", widgetList, "TOPRIGHT", 8, 0)
    settingsPanel:SetPoint("BOTTOMRIGHT", 0, 0)

    -- Link designer selection to widget list
    designer.onSelectionChanged = function(widgetType)
        widgetList:Select(widgetType)
        settingsPanel:BuildForWidget(widgetType)
    end

    ----------------------------------------------------------------------------
    -- Refresh function
    ----------------------------------------------------------------------------
    function container:RefreshAll()
        currentStyle = NivUI:GetStyleWithDefaults(currentStyleName)
        RefreshStyleDropdown()
        widgetList:Populate()
        NivUI.Designer:BuildPreview(designer, currentStyleName)

        -- Select first widget by default
        local firstWidget = NivUI.UnitFrames.WIDGET_ORDER[1]
        widgetList:Select(firstWidget)
        designer:SelectWidget(firstWidget)
        settingsPanel:BuildForWidget(firstWidget)
    end

    ----------------------------------------------------------------------------
    -- OnShow
    ----------------------------------------------------------------------------
    container:SetScript("OnShow", function()
        container:RefreshAll()
    end)

    ----------------------------------------------------------------------------
    -- Static Popups (use different names to avoid conflicts)
    ----------------------------------------------------------------------------
    StaticPopupDialogs["NIVUI_NEW_STYLE_2"] = {
        text = "Enter name for new style:",
        button1 = "Create",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self)
            local name = self.editBox:GetText()
            local success, err = NivUI:CreateStyle(name)
            if success then
                currentStyleName = name
                container:RefreshAll()
            else
                print("NivUI: " .. (err or "Failed to create style"))
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local name = self:GetText()
            local success, err = NivUI:CreateStyle(name)
            if success then
                currentStyleName = name
                container:RefreshAll()
            else
                print("NivUI: " .. (err or "Failed to create style"))
            end
            parent:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopupDialogs["NIVUI_DUPLICATE_STYLE_2"] = {
        text = "Enter name for duplicate of '%s':",
        button1 = "Duplicate",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self, data)
            local name = self.editBox:GetText()
            local success, err = NivUI:DuplicateStyle(currentStyleName, name)
            if success then
                currentStyleName = name
                container:RefreshAll()
            else
                print("NivUI: " .. (err or "Failed to duplicate style"))
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    StaticPopupDialogs["NIVUI_DELETE_STYLE_2"] = {
        text = "Delete style '%s'? This cannot be undone.",
        button1 = "Delete",
        button2 = "Cancel",
        OnAccept = function()
            local success, err = NivUI:DeleteStyle(currentStyleName)
            if success then
                -- Select first available style
                local names = NivUI:GetStyleNames()
                currentStyleName = names[1] or "Default"
                container:RefreshAll()
            else
                print("NivUI: " .. (err or "Failed to delete style"))
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        showAlert = true,
    }

    StaticPopupDialogs["NIVUI_RENAME_STYLE_2"] = {
        text = "Enter new name for '%s':",
        button1 = "Rename",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self)
            local newName = self.editBox:GetText()
            local success, err = NivUI:RenameStyle(currentStyleName, newName)
            if success then
                currentStyleName = newName
                container:RefreshAll()
            else
                print("NivUI: " .. (err or "Failed to rename style"))
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local newName = self:GetText()
            local success, err = NivUI:RenameStyle(currentStyleName, newName)
            if success then
                currentStyleName = newName
                container:RefreshAll()
            else
                print("NivUI: " .. (err or "Failed to rename style"))
            end
            parent:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    return container
end
