local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Config = NivUI.UnitFrames.Config or {}

local ConfigDeletion = NivUI.ConfigDeletion
local SettingsPanel = NivUI.Config.SettingsPanel
local WIDGET_LIST_WIDTH = 140

local StyleDesignerPanel = {
    currentStyleName = "Default",
}
NivUI.UnitFrames.Config.StyleDesignerPanel = StyleDesignerPanel

local function RequestStyleDelete()
    local name = StyleDesignerPanel.currentStyleName
    local profile = NivUI:GetActiveProfile()
    local consequences = ConfigDeletion.DescribeStyle(profile, name)
    ConfigDeletion.Request("style", name, consequences, function()
        local success, err = NivUI:DeleteStyle(name)
        if not success then
            print("NivUI: " .. (err or "Failed to delete style"))
            return
        end

        local names = NivUI:GetStyleNames()
        StyleDesignerPanel.currentStyleName = names[1] or "Default"
        if StyleDesignerPanel.refreshCallback then
            StyleDesignerPanel.refreshCallback()
        end
    end)
end

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
                StyleDesignerPanel.currentStyleName = name
                if StyleDesignerPanel.refreshCallback then
                    StyleDesignerPanel.refreshCallback()
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
                StyleDesignerPanel.currentStyleName = name
                if StyleDesignerPanel.refreshCallback then
                    StyleDesignerPanel.refreshCallback()
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
            local success, err = NivUI:DuplicateStyle(StyleDesignerPanel.currentStyleName, name)
            if success then
                StyleDesignerPanel.currentStyleName = name
                if StyleDesignerPanel.refreshCallback then
                    StyleDesignerPanel.refreshCallback()
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
            local success, err = NivUI:DuplicateStyle(StyleDesignerPanel.currentStyleName, name)
            if success then
                StyleDesignerPanel.currentStyleName = name
                if StyleDesignerPanel.refreshCallback then
                    StyleDesignerPanel.refreshCallback()
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
            local success, err = NivUI:RenameStyle(StyleDesignerPanel.currentStyleName, newName)
            if success then
                StyleDesignerPanel.currentStyleName = newName
                if StyleDesignerPanel.refreshCallback then
                    StyleDesignerPanel.refreshCallback()
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
            local success, err = NivUI:RenameStyle(StyleDesignerPanel.currentStyleName, newName)
            if success then
                StyleDesignerPanel.currentStyleName = newName
                if StyleDesignerPanel.refreshCallback then
                    StyleDesignerPanel.refreshCallback()
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


NivUI:RegisterConfigPopup("NIVUI_NEW_STYLE")
NivUI:RegisterConfigPopup("NIVUI_DUPLICATE_STYLE")
NivUI:RegisterConfigPopup("NIVUI_RENAME_STYLE")

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
        local function AddButton(widgetType, label)
            local btn = CreateFrame("Button", nil, content)
            btn:SetSize(WIDGET_LIST_WIDTH - 30, 24)
            btn:SetPoint("TOPLEFT", 0, -yOffset)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            btn.text:SetPoint("LEFT", 8, 0)
            btn.text:SetText(label)

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

        for _, widgetType in ipairs(NivUI.UnitFrames.WIDGET_ORDER) do
            AddButton(widgetType, NivUI.UnitFrames.WIDGET_NAMES[widgetType] or widgetType)
        end
        AddButton("overlays", "Overlays")

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
    local panel = SettingsPanel.Create(parent, {
        getConfig = function(widgetType) return NivUI.UnitFrames.WidgetConfigs[widgetType] end,
        getData = function(widgetType)
            local style = getStyle()
            return style and style[widgetType] or nil
        end,
        save = function()
            local style = getStyle()
            if style then saveStyle(style) end
        end,
        refreshPreview = refreshPreview,
    })
    panel.BuildForWidget = panel.BuildFor
    return panel
end

--- Designer-facing panel that picks which overlays apply to the current style. Overlays
--- themselves are authored in the Custom Overlays tab; this is only a checkbox list.
local function CreateOverlaySelector(parent, getStyle, saveStyle, refreshPreview)
    local frame = CreateFrame("Frame", nil, parent)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.06, 0.06, 0.06, 0.9)

    local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 12, -10)
    header:SetText("Overlays applied to this style:")

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    hint:SetText("Create and edit overlays in the Custom Overlays tab.")

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -44)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    local emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("TOPLEFT", 4, -4)
    emptyText:SetText("No overlays yet. Add some in the Custom Overlays tab.")

    frame.rows = {}

    function frame:Refresh()
        for _, row in ipairs(self.rows) do
            row:Hide()
        end

        local style = getStyle()
        if not style then return end
        style.overlays = style.overlays or {}

        local names = NivUI.Overlays and NivUI.Overlays:GetNames() or {}
        emptyText:SetShown(#names == 0)

        local width = scrollFrame:GetWidth()
        if width <= 0 then width = 300 end
        content:SetWidth(width)

        local y = 0
        for i, name in ipairs(names) do
            local row = self.rows[i]
            if not row then
                row = CreateFrame("CheckButton", nil, content, "SettingsCheckboxTemplate")
                row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.label:SetPoint("LEFT", row, "RIGHT", 4, 0)
                self.rows[i] = row
            end
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 4, -y)
            row.label:SetText(name)
            row.overlayName = name
            row:SetChecked(style.overlays[name] and true or false)
            row:SetScript("OnClick", function(checkBox)
                local s = getStyle()
                if not s then return end
                s.overlays = s.overlays or {}
                s.overlays[checkBox.overlayName] = checkBox:GetChecked() or nil
                saveStyle(s)
                refreshPreview()
            end)
            row:Show()
            y = y + 26
        end

        content:SetHeight(math.max(y, 1))
    end

    return frame
end


function StyleDesignerPanel.Create(parent)
    local container = CreateFrame("Frame", nil, parent)

    local currentStyle = nil

    local function getStyle()
        return currentStyle
    end

    local function saveStyle(style)
        currentStyle = style
        NivUI:SaveStyle(StyleDesignerPanel.currentStyleName, style)
    end

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
                    function() return StyleDesignerPanel.currentStyleName == name end,
                    function()
                        StyleDesignerPanel.currentStyleName = name
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
        StaticPopup_Show("NIVUI_DUPLICATE_STYLE", StyleDesignerPanel.currentStyleName)
    end)

    local renameBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    renameBtn:SetSize(60, 22)
    renameBtn:SetPoint("LEFT", dupBtn, "RIGHT", 2, 0)
    renameBtn:SetText("Rename")
    renameBtn:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_RENAME_STYLE", StyleDesignerPanel.currentStyleName)
    end)

    local delBtn = CreateFrame("Button", nil, topBar, "UIPanelButtonTemplate")
    delBtn:SetSize(50, 22)
    delBtn:SetPoint("LEFT", renameBtn, "RIGHT", 2, 0)
    delBtn:SetText("Delete")
    delBtn:SetScript("OnClick", function()
        RequestStyleDelete()
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

    local refreshPreview = function()
        NivUI.Designer:RefreshPreview(designer, StyleDesignerPanel.currentStyleName)
    end

    local settingsPanel, overlaySelector

    local function IsOverlaySubject(widgetType)
        return widgetType == "overlays" or (type(widgetType) == "string" and widgetType:find("^overlay:") ~= nil)
    end

    local function RouteContent(widgetType)
        if IsOverlaySubject(widgetType) then
            settingsPanel:Hide()
            overlaySelector:Show()
            overlaySelector:Refresh()
        else
            overlaySelector:Hide()
            settingsPanel:Show()
            settingsPanel:BuildForWidget(widgetType)
        end
    end

    local widgetList = CreateWidgetList(bottomArea, function(widgetType)
        designer:SelectWidget(widgetType)
        RouteContent(widgetType)
    end)
    widgetList:SetPoint("TOPLEFT", 0, 0)
    widgetList:SetPoint("BOTTOMLEFT", 0, 0)

    settingsPanel = CreateWidgetSettingsPanel(bottomArea, getStyle, saveStyle, refreshPreview)
    settingsPanel:SetPoint("TOPLEFT", widgetList, "TOPRIGHT", 8, 0)
    settingsPanel:SetPoint("BOTTOMRIGHT", 0, 0)

    overlaySelector = CreateOverlaySelector(bottomArea, getStyle, saveStyle, refreshPreview)
    overlaySelector:SetPoint("TOPLEFT", widgetList, "TOPRIGHT", 8, 0)
    overlaySelector:SetPoint("BOTTOMRIGHT", 0, 0)
    overlaySelector:Hide()

    designer.onSelectionChanged = function(widgetType)
        widgetList:Select(IsOverlaySubject(widgetType) and "overlays" or widgetType)
        RouteContent(widgetType)
    end

    function container:RefreshAll()
        currentStyle = NivUI:GetStyleWithDefaults(StyleDesignerPanel.currentStyleName)
        RefreshStyleDropdown()
        widgetList:Populate()
        NivUI.Designer:BuildPreview(designer, StyleDesignerPanel.currentStyleName)

        local firstWidget = NivUI.UnitFrames.WIDGET_ORDER[1]
        widgetList:Select(firstWidget)
        designer:SelectWidget(firstWidget)
        RouteContent(firstWidget)
    end

    NivUI:RegisterCallback("OverlaysChanged", function()
        if container:IsShown() then
            if overlaySelector:IsShown() then overlaySelector:Refresh() end
            refreshPreview()
        end
    end)

    NivUI:RegisterCallback("OverlayModified", function()
        if container:IsShown() then refreshPreview() end
    end)

    container:SetScript("OnShow", function()
        StyleDesignerPanel.refreshCallback = function()
            container:RefreshAll()
        end
        local names = NivUI:GetStyleNames()
        if not NivUI:StyleExists(StyleDesignerPanel.currentStyleName) then
            StyleDesignerPanel.currentStyleName = names[1] or "Default"
        end
        container:RefreshAll()
    end)

    return container
end
