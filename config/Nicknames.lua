local _, NivUI = ...

NivUI.Config = NivUI.Config or {}

local Nicknames = NivUI.Nicknames
local NicknameConfig = {}
NivUI.Config.Nicknames = NicknameConfig

local POPUP_NAME = "NIVUI_SET_NICKNAME"
local ROW_HEIGHT = 28

local function GetPopupEditBox(dialog)
    if dialog.GetEditBox then
        return dialog:GetEditBox()
    end
    return dialog.EditBox
end

function NicknameConfig.SaveModal(dialog, data)
    if type(data) ~= "table" or not data.identity then
        return false
    end

    local editBox = GetPopupEditBox(dialog)
    local success, saveError = Nicknames:Save(data.identity, editBox:GetText())
    if not success then
        print("|cffff2020NivUI:|r " .. saveError)
    end
    return success
end

function NicknameConfig.OpenModal(identity)
    local normalized = Nicknames.NormalizeIdentity(identity)
    if not normalized or InCombatLockdown() then
        return false
    end

    StaticPopup_Show(POPUP_NAME, normalized, nil, { identity = normalized })
    return true
end

function NicknameConfig.ExtendUnitMenu(_, rootDescription, contextData)
    if InCombatLockdown() then
        return false
    end
    if type(contextData) ~= "table" or not contextData.unit then
        return false
    end

    local identity = Nicknames.GetUnitIdentity(contextData.unit)
    if not identity then
        return false
    end

    rootDescription:CreateButton("Set Nickname...", function()
        NicknameConfig.OpenModal(identity)
    end)
    return true
end

StaticPopupDialogs[POPUP_NAME] = {
    text = "Set a nickname for %s:",
    button1 = SAVE,
    button2 = CANCEL,
    hasEditBox = 1,
    editBoxWidth = 220,
    OnAccept = function(dialog, data)
        NicknameConfig.SaveModal(dialog, data)
    end,
    OnShow = function(dialog, data)
        local editBox = GetPopupEditBox(dialog)
        editBox:SetText(type(data) == "table" and Nicknames:Get(data.identity) or "")
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    EditBoxOnEnterPressed = function(editBox)
        local dialog = editBox:GetParent()
        if NicknameConfig.SaveModal(dialog, dialog.data) then
            dialog:Hide()
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    preferredIndex = 3,
}

NivUI:RegisterConfigPopup(POPUP_NAME)

if Menu and type(Menu.ModifyMenu) == "function" and type(UnitPopupMenus) == "table" then
    for unitType in pairs(UnitPopupMenus) do
        Menu.ModifyMenu("MENU_UNIT_" .. unitType, NicknameConfig.ExtendUnitMenu)
    end
end

local function CreateEntryRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    row.identity = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.identity:SetPoint("LEFT", 8, 0)
    row.identity:SetWidth(180)
    row.identity:SetJustifyH("LEFT")

    row.nickname = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.nickname:SetPoint("LEFT", row.identity, "RIGHT", 8, 0)
    row.nickname:SetPoint("RIGHT", -142, 0)
    row.nickname:SetJustifyH("LEFT")

    row.edit = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.edit:SetSize(58, 22)
    row.edit:SetPoint("RIGHT", -70, 0)
    row.edit:SetText("Edit")

    row.remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.remove:SetSize(64, 22)
    row.remove:SetPoint("RIGHT", -2, 0)
    row.remove:SetText("Remove")

    return row
end

function NicknameConfig.SetupTab(contentArea, Components)
    local container = CreateFrame("Frame", nil, contentArea)
    container:SetAllPoints()
    container:Hide()

    local header = Components.GetHeader(container, "Unit Frame Nicknames")
    header:SetPoint("TOPLEFT", 8, -8)
    header:SetPoint("TOPRIGHT", -8, -8)

    local identityLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    identityLabel:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 12, -12)
    identityLabel:SetText("Character-Realm")

    local identityBox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    identityBox:SetSize(210, 22)
    identityBox:SetPoint("TOPLEFT", identityLabel, "BOTTOMLEFT", 4, -4)
    identityBox:SetAutoFocus(false)

    local nicknameLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nicknameLabel:SetPoint("LEFT", identityLabel, "RIGHT", 120, 0)
    nicknameLabel:SetText("Nickname")

    local nicknameBox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    nicknameBox:SetSize(150, 22)
    nicknameBox:SetPoint("TOPLEFT", nicknameLabel, "BOTTOMLEFT", 4, -4)
    nicknameBox:SetAutoFocus(false)

    local saveButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    saveButton:SetSize(70, 22)
    saveButton:SetPoint("LEFT", nicknameBox, "RIGHT", 10, 0)
    saveButton:SetText("Save")

    local feedback = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    feedback:SetPoint("TOPLEFT", identityBox, "BOTTOMLEFT", 0, -6)
    feedback:SetPoint("RIGHT", -12, 0)
    feedback:SetJustifyH("LEFT")

    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", feedback, "BOTTOMLEFT", 0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 8)

    local list = CreateFrame("Frame", nil, scrollFrame)
    list:SetSize(1, 1)
    scrollFrame:SetScrollChild(list)

    local emptyText = list:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("TOPLEFT", 8, -8)
    emptyText:SetText("No nicknames are configured for this profile.")

    local rows = {}

    function container:Refresh()
        for _, row in ipairs(rows) do
            row:Hide()
        end

        local entries = Nicknames:GetEntries()
        emptyText:SetShown(#entries == 0)
        local width = scrollFrame:GetWidth()
        if width <= 0 then
            width = 420
        end
        list:SetWidth(width)

        for index, entry in ipairs(entries) do
            local row = rows[index]
            if not row then
                row = CreateEntryRow(list)
                rows[index] = row
            end

            local identity = entry.identity
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))
            row:SetPoint("TOPRIGHT", 0, -((index - 1) * ROW_HEIGHT))
            row.identity:SetText(identity)
            row.nickname:SetText(entry.nickname)
            row.edit:SetScript("OnClick", function()
                identityBox:SetText(identity)
                nicknameBox:SetText(Nicknames:Get(identity) or "")
                nicknameBox:SetFocus()
                nicknameBox:HighlightText()
            end)
            row.remove:SetScript("OnClick", function()
                Nicknames:Save(identity, "")
            end)
            row:Show()
        end

        list:SetHeight(math.max(#entries * ROW_HEIGHT, 1))
    end

    local function Commit()
        local success, saveError, normalized = Nicknames:Save(identityBox:GetText(), nicknameBox:GetText())
        if not success then
            feedback:SetTextColor(1, 0.25, 0.25)
            feedback:SetText(saveError)
            return
        end

        feedback:SetTextColor(0.25, 1, 0.25)
        feedback:SetText("Saved " .. normalized .. ".")
        identityBox:SetText("")
        nicknameBox:SetText("")
        container:Refresh()
    end

    saveButton:SetScript("OnClick", Commit)
    identityBox:SetScript("OnEnterPressed", Commit)
    nicknameBox:SetScript("OnEnterPressed", Commit)
    container:SetScript("OnShow", function()
        feedback:SetText("")
        container:Refresh()
    end)

    NivUI:RegisterCallback("NicknamesChanged", function()
        if container:IsShown() then
            container:Refresh()
        end
    end)

    return container
end
