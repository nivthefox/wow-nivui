local _, NivUI = ...

NivUI.Config = NivUI.Config or {}

local ConfigControls = NivUI.ConfigControls
local ROW_HEIGHT = 32
local LABEL_WIDTH = 200
local CONTROL_MAX_WIDTH = 350

local SettingsPanel = {}
NivUI.Config.SettingsPanel = SettingsPanel
local function DeepGet(tbl, key)
    local current = tbl
    for part in key:gmatch("[^.]+") do
        if type(current) ~= "table" then return nil end
        current = current[part]
    end
    return current
end

local function DeepSet(tbl, key, value)
    local parts = {}
    for part in key:gmatch("[^.]+") do
        parts[#parts + 1] = part
    end
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


--- Creates a reusable tabbed settings panel. Both the unit-frame designer (editing a
--- style's widget) and the Custom Overlays tab (editing an overlay) drive it through opts.
--- @param parent Frame The parent frame
--- @param opts table getConfig(subject)->tab schema, getData(subject)->live table,
---   save(subject) persists, refreshPreview() optional post-change hook
--- @return Frame The panel, with :BuildFor(subject)
SettingsPanel.GetValue = DeepGet
SettingsPanel.SetValue = DeepSet

function SettingsPanel.Create(parent, opts)
    local frame = CreateFrame("Frame", nil, parent)
    frame.opts = opts
    frame.subject = nil

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.06, 0.06, 0.06, 0.9)

    frame.tabButtons = {}
    frame.tabPanels = {}
    frame.currentTab = 1

    function frame:GetData()
        return self.opts.getData(self.subject)
    end

    function frame:Commit(key, value)
        local data = self.opts.getData(self.subject)
        if not data then return end
        DeepSet(data, key, value)
        if self.opts.save then self.opts.save(self.subject) end
        if self.opts.refreshPreview then self.opts.refreshPreview() end
    end

    function frame:CommitList(listName, rowKey, value)
        local data = self.opts.getData(self.subject)
        if not data then return end
        data[listName] = data[listName] or {}
        data[listName][rowKey] = value
        if self.opts.save then self.opts.save(self.subject) end
        if self.opts.refreshPreview then self.opts.refreshPreview() end
    end

    local TAB_HEIGHT = 24
    local TAB_CONTENT_GAP = 14
    local tabHolder = CreateFrame("Frame", nil, frame)
    tabHolder:SetHeight(28)
    tabHolder:SetPoint("TOPLEFT", 0, 0)
    tabHolder:SetPoint("TOPRIGHT", 0, 0)
    frame.tabHolder = tabHolder

    local contentArea = CreateFrame("Frame", nil, frame)
    contentArea:SetPoint("TOPLEFT", 0, -(TAB_HEIGHT + TAB_CONTENT_GAP))
    contentArea:SetPoint("BOTTOMRIGHT", 0, 0)
    frame.contentArea = contentArea

    local function LayoutTabRows(self)
        if #self.tabButtons == 0 then return end

        local numRows = NivUI.TabLayout.LayoutRows(self.tabHolder, self.tabButtons)

        self.tabHolder:SetHeight(numRows * TAB_HEIGHT + 4)
        self.contentArea:ClearAllPoints()
        self.contentArea:SetPoint("TOPLEFT", 0, -(numRows * TAB_HEIGHT + TAB_CONTENT_GAP))
        self.contentArea:SetPoint("BOTTOMRIGHT", 0, 0)
    end
    frame.LayoutTabRows = LayoutTabRows

    frame:SetScript("OnSizeChanged", function(self)
        LayoutTabRows(self)
    end)

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

    function frame:BuildFor(subject)
        local savedScrollPositions = {}
        for i, panel in ipairs(self.tabPanels) do
            savedScrollPositions[i] = panel:GetVerticalScroll()
        end
        local savedTab = self.currentTab

        self.subject = subject

        for _, btn in ipairs(self.tabButtons) do
            btn:Hide()
        end
        wipe(self.tabButtons)

        for _, panel in ipairs(self.tabPanels) do
            panel:Hide()
            panel:SetParent(nil)
        end
        wipe(self.tabPanels)

        if not subject then
            return
        end

        local config = self.opts.getConfig(subject)
        if not config then
            return
        end

        local widgetData = self.opts.getData(subject) or {}

        local visibleTabs = {}
        for _, tabConfig in ipairs(config) do
            local show = true
            if tabConfig.showIf then
                show = NivUI.OverlayLogic.EvaluateCondition(tabConfig.showIf, DeepGet(widgetData, tabConfig.showIf.key))
            end
            if show then
                visibleTabs[#visibleTabs + 1] = tabConfig
            end
        end

        for i, tabConfig in ipairs(visibleTabs) do
            local tab = CreateFrame("Button", nil, self.tabHolder, "PanelTopTabButtonTemplate")
            tab:SetText(tabConfig.label)
            tab:SetScript("OnShow", function(tabButton)
                PanelTemplates_TabResize(tabButton, 10, nil, 60)
            end)
            tab:GetScript("OnShow")(tab)
            tab:SetScript("OnClick", function()
                self:SelectTab(i)
            end)

            tab:SetPoint("TOPLEFT", 0, 0)

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
                    show = NivUI.OverlayLogic.EvaluateCondition(entry.showIf, DeepGet(widgetData, entry.showIf.key))
                end
                if show and entry.hideIf then
                    local checkValue = DeepGet(widgetData, entry.hideIf.key)
                    show = (checkValue ~= entry.hideIf.value)
                end

                if show then
                    local entryFrame = self:CreateEntry(panelContent, entry, widgetData)
                    if entryFrame then
                        entryFrame:SetPoint("TOP", panelContent, "TOP", 0, -yOffset)
                        yOffset = yOffset + (entryFrame:GetHeight() or ROW_HEIGHT) + 4
                    end
                end
            end

            panelContent:SetHeight(math.max(yOffset, 100))
            table.insert(self.tabPanels, panel)
        end

        self:LayoutTabRows()

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

    function frame:CreateEntry(entryParent, entry, widgetData)
        local panel = self
        local widgetType = self.subject
        local holder = CreateFrame("Frame", nil, entryParent)
        holder:SetHeight(ROW_HEIGHT)
        holder:SetPoint("LEFT", 10, 0)
        holder:SetPoint("RIGHT", -10, 0)

        local currentValue = entry.key and DeepGet(widgetData, entry.key) or nil

        if entry.kind == "checkbox" then
            local checkBox = CreateFrame("CheckButton", nil, holder, "SettingsCheckboxTemplate")
            checkBox:SetPoint("LEFT", holder, "LEFT", LABEL_WIDTH - 15, 0)
            checkBox:SetText(entry.label)
            checkBox:SetNormalFontObject(GameFontHighlight)
            checkBox:GetFontString():SetPoint("RIGHT", holder, "LEFT", LABEL_WIDTH - 30, 0)
            checkBox:GetFontString():SetPoint("LEFT", holder, "LEFT", 10, 0)
            checkBox:GetFontString():SetJustifyH("RIGHT")
            local binding = ConfigControls.BindCheckboxRow(holder, checkBox, {
                canChange = function() return NivUI:CanChangeConfig() end,
                onChanged = function(checked)
                    panel:Commit(entry.key, checked)
                    panel:BuildFor(panel.subject)
                end,
            })
            binding:SetValue(currentValue)

        elseif entry.kind == "filterMatrix" then
            local rows = {}
            for _, builtin in ipairs(NivUI.Filters.BUILTIN) do
                rows[#rows + 1] = {
                    key = builtin.token,
                    label = builtin.label,
                    allowOnly = builtin.allowOnly,
                }
            end
            for _, name in ipairs(NivUI.Filters:GetCustomNames()) do
                rows[#rows + 1] = { key = name, label = name }
            end

            local headerHeight = 18
            local allowX, blockX = -84, -30

            local allowHeader = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            allowHeader:SetPoint("TOP", holder, "TOPRIGHT", allowX, -2)
            allowHeader:SetText("Allow")

            local blockHeader = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            blockHeader:SetPoint("TOP", holder, "TOPRIGHT", blockX, -2)
            blockHeader:SetText("Block")

            local function CreateToggle(rowFrame, rowKey, listName, x)
                local toggle = CreateFrame("CheckButton", nil, rowFrame, "SettingsCheckboxTemplate")
                toggle:SetPoint("CENTER", rowFrame, "RIGHT", x, 0)
                toggle:SetChecked(widgetData[listName] and widgetData[listName][rowKey] or false)
                toggle:SetScript("OnClick", function()
                    panel:CommitList(listName, rowKey, toggle:GetChecked() or nil)
                end)
            end

            for i, row in ipairs(rows) do
                local y = -headerHeight - (i - 1) * ROW_HEIGHT
                local rowFrame = CreateFrame("Frame", nil, holder)
                rowFrame:SetHeight(ROW_HEIGHT)
                rowFrame:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, y)
                rowFrame:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, y)

                local label = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                label:SetPoint("LEFT", 4, 0)
                label:SetPoint("RIGHT", rowFrame, "RIGHT", -100, 0)
                label:SetJustifyH("LEFT")
                label:SetText(row.label)

                CreateToggle(rowFrame, row.key, "allow", allowX)
                if not row.allowOnly then
                    CreateToggle(rowFrame, row.key, "block", blockX)
                end
            end

            holder:SetHeight(headerHeight + #rows * ROW_HEIGHT + 6)

        elseif entry.kind == "slider" then
            local label = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            label:SetPoint("LEFT", 10, 0)
            label:SetPoint("RIGHT", holder, "LEFT", LABEL_WIDTH - 40, 0)
            label:SetJustifyH("RIGHT")
            label:SetText(entry.label)

            local editBox = CreateFrame("EditBox", nil, holder, "InputBoxTemplate")
            editBox:SetSize(50, 20)
            editBox:SetAutoFocus(false)
            editBox:SetMaxLetters(6)

            local slider = CreateFrame("Slider", nil, holder, "MinimalSliderWithSteppersTemplate")
            slider:SetPoint("LEFT", holder, "LEFT", LABEL_WIDTH - 20, 0)
            slider:SetPoint("RIGHT", editBox, "LEFT", -10, 0)
            slider:SetHeight(20)

            do
                local START, RIGHT_INSET = LABEL_WIDTH - 20, 5
                local function UpdateSliderWidth(_, w)
                    w = w or holder:GetWidth()
                    local rightX = math.min(START + CONTROL_MAX_WIDTH, math.max(START + 50, w - RIGHT_INSET))
                    editBox:SetPoint("RIGHT", holder, "LEFT", rightX, 0)
                end
                holder:SetScript("OnSizeChanged", UpdateSliderWidth)
                UpdateSliderWidth(holder, holder:GetWidth())
            end

            ConfigControls.BindSlider(slider, editBox, {
                min = entry.min,
                max = entry.max,
                step = entry.step,
                value = currentValue or entry.min,
                canChange = function() return NivUI:CanChangeConfig() end,
                onChanged = function(value)
                    panel:Commit(entry.key, value)
                end,
            })

        elseif entry.kind == "dropdown" then
            local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", 10, 0)
            label:SetPoint("RIGHT", holder, "LEFT", LABEL_WIDTH - 40, 0)
            label:SetJustifyH("RIGHT")
            label:SetText(entry.label)

            local dropdown = CreateFrame("DropdownButton", nil, holder, "WowStyle1DropdownTemplate")
            dropdown:SetWidth(150)
            dropdown:SetPoint("LEFT", holder, "LEFT", LABEL_WIDTH - 15, 0)

            local options = type(entry.options) == "string" and NivUI.UnitFrames:GetOptionList(entry.options, { widgetType = widgetType, data = widgetData }) or entry.options or {}

            dropdown:SetupMenu(function(_, rootDescription)
                for _, opt in ipairs(options) do
                    rootDescription:CreateRadio(
                        opt.name,
                        function()
                            local data = panel:GetData()
                            return data and DeepGet(data, entry.key) == opt.value
                        end,
                        function()
                            panel:Commit(entry.key, opt.value)
                            panel:BuildFor(panel.subject)
                        end
                    )
                end
            end)

        elseif entry.kind == "textureDropdown" then
            local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", 10, 0)
            label:SetPoint("RIGHT", holder, "LEFT", LABEL_WIDTH - 40, 0)
            label:SetJustifyH("RIGHT")
            label:SetText(entry.label)

            local dropdown = CreateFrame("DropdownButton", nil, holder, "WowStyle1DropdownTemplate")
            dropdown:SetWidth(150)
            dropdown:SetPoint("LEFT", holder, "LEFT", LABEL_WIDTH - 15, 0)

            dropdown:SetupMenu(function(_, rootDescription)
                local textures = NivUI:GetBarTextures()
                for _, tex in ipairs(textures) do
                    local preview = tex.path and ("|T" .. tex.path .. ":16:80|t " .. tex.name) or tex.name
                    rootDescription:CreateRadio(
                        preview,
                        function()
                            local data = panel:GetData()
                            return data and DeepGet(data, entry.key) == tex.value
                        end,
                        function()
                            panel:Commit(entry.key, tex.value)
                        end
                    )
                end
                rootDescription:SetScrollMode(20 * 10)
            end)

        elseif entry.kind == "fontDropdown" then
            local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", 10, 0)
            label:SetPoint("RIGHT", holder, "LEFT", LABEL_WIDTH - 40, 0)
            label:SetJustifyH("RIGHT")
            label:SetText(entry.label)

            local dropdown = CreateFrame("DropdownButton", nil, holder, "WowStyle1DropdownTemplate")
            dropdown:SetWidth(150)
            dropdown:SetPoint("LEFT", holder, "LEFT", LABEL_WIDTH - 15, 0)

            dropdown:SetupMenu(function(_, rootDescription)
                local fonts = NivUI:GetFonts()
                for _, font in ipairs(fonts) do
                    rootDescription:CreateRadio(
                        font.name,
                        function()
                            local data = panel:GetData()
                            return data and DeepGet(data, entry.key) == font.value
                        end,
                        function()
                            panel:Commit(entry.key, font.value)
                        end
                    )
                end
                rootDescription:SetScrollMode(20 * 10)
            end)

        elseif entry.kind == "colorPicker" then
            local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", 10, 0)
            label:SetPoint("RIGHT", holder, "LEFT", LABEL_WIDTH - 40, 0)
            label:SetJustifyH("RIGHT")
            label:SetText(entry.label)

            local swatch = CreateFrame("Button", nil, holder, "ColorSwatchTemplate")
            swatch:SetPoint("LEFT", holder, "LEFT", LABEL_WIDTH - 15, 0)

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
                        if not NivUI:CanChangeConfig() then return end
                        local r, g, b = ColorPickerFrame:GetColorRGB()
                        local a = entry.hasAlpha and ColorPickerFrame:GetColorAlpha() or nil
                        swatch.currentColor = { r = r, g = g, b = b, a = a }
                        swatch:SetColor(CreateColor(r, g, b))
                        panel:Commit(entry.key, swatch.currentColor)
                    end

                    info.cancelFunc = function(previousValues)
                        swatch.currentColor = previousValues
                        swatch:SetColor(CreateColor(previousValues.r, previousValues.g, previousValues.b))
                    end

                    info.previousValues = CopyTable(swatch.currentColor)
                    NivUI:ShowConfigColorPicker(info)
                end
            end)

        elseif entry.kind == "numericInput" then
            local label = holder:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            label:SetPoint("LEFT", 10, 0)
            label:SetPoint("RIGHT", holder, "LEFT", LABEL_WIDTH - 40, 0)
            label:SetJustifyH("RIGHT")
            label:SetText(entry.label)

            local editBox = CreateFrame("EditBox", nil, holder, "InputBoxTemplate")
            editBox:SetSize(50, 20)
            editBox:SetPoint("LEFT", holder, "LEFT", LABEL_WIDTH - 15, 0)
            editBox:SetAutoFocus(false)
            editBox:SetNumeric(true)
            editBox:SetText(tostring(currentValue or entry.min or 1))

            local function CommitNumeric(input)
                if not NivUI:CanChangeConfig() then return end
                local value = math.max(entry.min or 1, math.floor(tonumber(input:GetText()) or entry.min or 1))
                input:SetText(tostring(value))
                panel:Commit(entry.key, value)
            end

            editBox:SetScript("OnEnterPressed", function(input)
                CommitNumeric(input)
                input:ClearFocus()
            end)

            editBox:SetScript("OnEditFocusLost", function(input)
                CommitNumeric(input)
            end)

            editBox:SetScript("OnEscapePressed", function(input)
                input:SetText(tostring(DeepGet(panel:GetData() or {}, entry.key) or entry.min or 1))
                input:ClearFocus()
            end)
        end

        return holder
    end

    return frame
end
