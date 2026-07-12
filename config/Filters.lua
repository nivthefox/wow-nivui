--- Custom Filters config tab: create and edit named spell lists. Each list becomes a
--- sub-tab; aura widgets reference them (with Allow/Block) from the Unit Frame designer.
NivUI = NivUI or {}
NivUI.Config = NivUI.Config or {}
NivUI.Config.Filters = {}

local Filters = NivUI.Filters

local ROW_HEIGHT = 26
local ICON_SIZE = 18

StaticPopupDialogs["NIVUI_NEW_CUSTOM_FILTER"] = {
    text = "Enter name for new custom filter:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = 1,
    OnAccept = function(dialog)
        local ok, err = Filters:CreateCustom(dialog:GetEditBox():GetText())
        if not ok then
            print("|cffff2020NivUI:|r " .. tostring(err))
        end
    end,
    EditBoxOnEnterPressed = function(editBox)
        local dialog = editBox:GetParent()
        local ok, err = Filters:CreateCustom(editBox:GetText())
        if not ok then
            print("|cffff2020NivUI:|r " .. tostring(err))
        end
        dialog:Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

local function BuildSpellRow(content)
    local row = CreateFrame("Button", nil, content)
    row:SetHeight(ROW_HEIGHT)

    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetColorTexture(0.3, 0.3, 0.3, 0.3)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetPoint("LEFT", 6, 0)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.label:SetJustifyH("LEFT")

    row.removeButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.removeButton:SetSize(60, 20)
    row.removeButton:SetPoint("RIGHT", -4, 0)
    row.removeButton:SetText("Remove")

    return row
end

local function CreateSpellPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints()
    panel.filterName = nil
    panel.rows = {}

    local deleteButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    deleteButton:SetSize(100, 22)
    deleteButton:SetPoint("TOPRIGHT", -4, -2)
    deleteButton:SetText("Delete Filter")

    local addButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    addButton:SetSize(60, 22)
    addButton:SetPoint("BOTTOMRIGHT", -4, 4)
    addButton:SetText("Add")

    local addBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    addBox:SetHeight(22)
    addBox:SetPoint("BOTTOMLEFT", 6, 4)
    addBox:SetPoint("RIGHT", addButton, "LEFT", -12, 0)
    addBox:SetAutoFocus(false)

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", addBox, "TOPLEFT", 0, 2)
    hint:SetText("Enter a spell ID or name")

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 4, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", addBox, "TOPRIGHT", -20, 6)

    local listBg = panel:CreateTexture(nil, "BACKGROUND")
    listBg:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", -2, 2)
    listBg:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 22, -2)
    listBg:SetColorTexture(0.08, 0.08, 0.08, 0.9)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    local emptyText = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("TOPLEFT", 8, -8)
    emptyText:SetText("No spells in this filter.")

    function panel:Populate()
        for _, row in ipairs(self.rows) do
            row:Hide()
        end
        local name = self.filterName
        if not name then
            emptyText:Hide()
            return
        end

        local entries = Filters:GetSortedSpells(name)
        emptyText:SetShown(#entries == 0)

        local width = scrollFrame:GetWidth()
        if width <= 0 then width = 300 end
        content:SetWidth(width)

        local y = 0
        for i, entry in ipairs(entries) do
            local row = self.rows[i]
            if not row then
                row = BuildSpellRow(content)
                self.rows[i] = row
            end

            row:SetPoint("TOPLEFT", 0, -y)
            row:SetPoint("TOPRIGHT", 0, -y)
            row.spellID = entry.spellID
            row.label:SetText(entry.name .. "  |cff888888(" .. entry.spellID .. ")|r")
            if entry.icon then
                row.icon:SetTexture(entry.icon)
                row.icon:Show()
            else
                row.icon:Hide()
            end
            row.removeButton:SetScript("OnClick", function()
                Filters:RemoveSpell(name, row.spellID)
                panel:Populate()
            end)

            row:Show()
            y = y + ROW_HEIGHT
        end

        content:SetHeight(math.max(y, 1))
    end

    function panel:ShowFilter(name)
        self.filterName = name
        self:Populate()
    end

    local function CommitAdd()
        local name = panel.filterName
        if not name then return end
        local spellID, message = Filters:AddSpell(name, addBox:GetText())
        if spellID then
            addBox:SetText("")
            addBox:ClearFocus()
            panel:Populate()
        else
            print("|cffff2020NivUI:|r " .. tostring(message))
        end
    end
    addButton:SetScript("OnClick", CommitAdd)
    addBox:SetScript("OnEnterPressed", CommitAdd)
    addBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    deleteButton:SetScript("OnClick", function()
        if panel.filterName then
            Filters:DeleteCustom(panel.filterName)
        end
    end)

    return panel
end

function NivUI.Config.Filters.SetupTab(ContentArea, Components)
    local container = CreateFrame("Frame", nil, ContentArea)
    container:SetAllPoints()
    container:Hide()

    local tabHolder = CreateFrame("Frame", nil, container)
    tabHolder:SetHeight(30)
    tabHolder:SetPoint("TOPLEFT", 4, -6)
    tabHolder:SetPoint("TOPRIGHT", -4, -6)

    local body = CreateFrame("Frame", nil, container)
    body:SetPoint("TOPLEFT", tabHolder, "BOTTOMLEFT", 0, -4)
    body:SetPoint("BOTTOMRIGHT", 0, 0)

    local emptyLabel = body:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyLabel:SetPoint("TOPLEFT", 8, -8)
    emptyLabel:SetText("No custom filters yet. Click + to create one.")

    local spellPanel = CreateSpellPanel(body)

    local tabButtons = {}

    local addButton = Components.GetTab(tabHolder, "+")
    PanelTemplates_DeselectTab(addButton)
    addButton:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_NEW_CUSTOM_FILTER")
    end)

    local function SelectFilter(name)
        container.currentFilter = name
        for _, btn in ipairs(tabButtons) do
            if btn.filterName == name then
                PanelTemplates_SelectTab(btn)
            else
                PanelTemplates_DeselectTab(btn)
            end
        end
        spellPanel:ShowFilter(name)
    end

    local function RebuildTabs()
        for _, btn in ipairs(tabButtons) do
            btn:Hide()
        end
        wipe(tabButtons)

        local names = Filters:GetCustomNames()
        emptyLabel:SetShown(#names == 0)
        spellPanel:SetShown(#names > 0)

        local previous
        for i, name in ipairs(names) do
            local btn = Components.GetTab(tabHolder, name)
            btn:SetID(i)
            btn.filterName = name
            btn:SetScript("OnClick", function() SelectFilter(name) end)
            if previous then
                btn:SetPoint("LEFT", previous, "RIGHT", 0, 0)
            else
                btn:SetPoint("BOTTOMLEFT", tabHolder, "BOTTOMLEFT", 4, 0)
            end
            tabButtons[i] = btn
            previous = btn
        end

        addButton:ClearAllPoints()
        if previous then
            addButton:SetPoint("LEFT", previous, "RIGHT", 0, 0)
        else
            addButton:SetPoint("BOTTOMLEFT", tabHolder, "BOTTOMLEFT", 4, 0)
        end

        local selection = container.currentFilter
        local stillExists = false
        for _, name in ipairs(names) do
            if name == selection then stillExists = true break end
        end
        if not stillExists then selection = names[1] end
        if selection then
            SelectFilter(selection)
        else
            container.currentFilter = nil
            spellPanel:ShowFilter(nil)
        end
    end

    container:SetScript("OnShow", RebuildTabs)

    NivUI:RegisterCallback("CustomFiltersChanged", function(data)
        if data and data.name and not data.deleted then
            container.currentFilter = data.name
        end
        if container:IsShown() then RebuildTabs() end
    end)
    NivUI:RegisterCallback("ProfileSwitched", function()
        container.currentFilter = nil
        if container:IsShown() then RebuildTabs() end
    end)

    return container
end
