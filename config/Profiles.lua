NivUI = NivUI or {}
NivUI.Config = NivUI.Config or {}
NivUI.Config.Profiles = {}

local FRAME_WIDTH = 680
local SIDEBAR_WIDTH = 100
local ROW_HEIGHT = 32
local SECTION_SPACING = 20

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

--- Sets up the Profiles tab.
--- @param ContentArea Frame The content area frame
--- @param Components table The Components table from ConfigFrame
--- @return Frame container The tab container
function NivUI.Config.Profiles.SetupTab(ContentArea, Components)
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
            local success, err = NivUI.Profiles:SwitchProfile(value)
            if not success and err then
                print("|cffff0000NivUI:|r " .. err)
            end
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

-- Static popup dialogs
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
