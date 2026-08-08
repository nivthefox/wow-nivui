--- Custom Overlays config tab: create and edit named aura overlays. Each overlay becomes a
--- sub-tab holding the shared settings panel; unit-frame styles pick which overlays apply
--- from the designer's Overlays list.
local _, NivUI = ...

NivUI.Config = NivUI.Config or {}
NivUI.Config.Overlays = {}

local Overlays = NivUI.Overlays
local ConfigDeletion = NivUI.ConfigDeletion
local TAB_HEIGHT = 24

StaticPopupDialogs["NIVUI_NEW_OVERLAY"] = {
    text = "Enter name for new overlay:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = 1,
    OnAccept = function(dialog)
        local ok, err = Overlays:Create(dialog:GetEditBox():GetText())
        if not ok then
            print("|cffff2020NivUI:|r " .. tostring(err))
        end
    end,
    EditBoxOnEnterPressed = function(editBox)
        local dialog = editBox:GetParent()
        local ok, err = Overlays:Create(editBox:GetText())
        if not ok then
            print("|cffff2020NivUI:|r " .. tostring(err))
        end
        dialog:Hide()
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

NivUI:RegisterConfigPopup("NIVUI_NEW_OVERLAY")

function NivUI.Config.Overlays.RequestDelete(name)
    if type(name) ~= "string" or name == "" then
        return false
    end

    local profile = NivUI:GetActiveProfile()
    local consequences = ConfigDeletion.DescribeOverlay(profile, name)
    return ConfigDeletion.Request("overlay", name, consequences, function()
        local success, err = Overlays:Delete(name)
        if not success then
            print("|cffff2020NivUI:|r " .. tostring(err))
        end
    end)
end

function NivUI.Config.Overlays.SetupTab(ContentArea, Components)
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
    emptyLabel:SetText("No overlays yet. Click + to create one.")

    local deleteButton = CreateFrame("Button", nil, body, "UIPanelButtonTemplate")
    deleteButton:SetSize(110, 22)
    deleteButton:SetPoint("TOPRIGHT", -4, -2)
    deleteButton:SetText("Delete Overlay")

    -- Overlay edits mutate the live profile table directly, so they persist without an
    -- explicit save. We debounce an OverlayModified event to rebuild frames using the
    -- overlay without thrashing on every slider tick. OverlayModified (not OverlaysChanged)
    -- so this panel doesn't rebuild itself out from under an in-progress edit.
    local modifyPending = false
    local function NotifyModified()
        if modifyPending then return end
        modifyPending = true
        C_Timer.After(0.15, function()
            modifyPending = false
            NivUI:TriggerEvent("OverlayModified")
        end)
    end

    local settingsPanel = NivUI.UnitFrames:CreateSettingsPanel(body, {
        getConfig = function() return Overlays.CONFIG end,
        getData = function(name) return name and Overlays:Get(name) or nil end,
        save = NotifyModified,
    })
    settingsPanel:SetPoint("TOPLEFT", 0, -28)
    settingsPanel:SetPoint("BOTTOMRIGHT", 0, 0)

    local tabButtons = {}

    local addButton = Components.GetTab(tabHolder, "+")
    PanelTemplates_DeselectTab(addButton)
    addButton:SetScript("OnClick", function()
        StaticPopup_Show("NIVUI_NEW_OVERLAY")
    end)

    local function LayoutTabs()
        local buttons = {}
        for _, button in ipairs(tabButtons) do
            buttons[#buttons + 1] = button
        end
        buttons[#buttons + 1] = addButton

        local rows = NivUI.TabLayout.LayoutRows(tabHolder, buttons, {
            startX = 4,
            rightInset = 4,
        })
        tabHolder:SetHeight(rows * TAB_HEIGHT + 6)
    end

    local function SelectOverlay(name)
        container.currentOverlay = name
        for _, btn in ipairs(tabButtons) do
            if btn.overlayName == name then
                PanelTemplates_SelectTab(btn)
            else
                PanelTemplates_DeselectTab(btn)
            end
        end
        settingsPanel:BuildFor(name)
        settingsPanel:SetShown(name ~= nil)
        deleteButton:SetShown(name ~= nil)
    end

    local function RebuildTabs()
        for _, btn in ipairs(tabButtons) do
            btn:Hide()
        end
        wipe(tabButtons)

        local names = Overlays:GetNames()
        emptyLabel:SetShown(#names == 0)

        for i, name in ipairs(names) do
            local btn = Components.GetTab(tabHolder, name)
            btn:SetID(i)
            btn.overlayName = name
            btn:SetScript("OnClick", function() SelectOverlay(name) end)
            tabButtons[i] = btn
        end

        LayoutTabs()

        local selection = container.currentOverlay
        local stillExists = false
        for _, name in ipairs(names) do
            if name == selection then stillExists = true break end
        end
        if not stillExists then selection = names[1] end
        SelectOverlay(selection)
    end

    deleteButton:SetScript("OnClick", function()
        local name = container.currentOverlay
        if not name then
            return
        end

        NivUI.Config.Overlays.RequestDelete(name)
    end)

    container:SetScript("OnShow", RebuildTabs)
    container:SetScript("OnSizeChanged", LayoutTabs)

    NivUI:RegisterCallback("OverlaysChanged", function(data)
        if data and data.name and not data.deleted then
            container.currentOverlay = data.name
        end
        if container:IsShown() then RebuildTabs() end
    end)
    NivUI:RegisterCallback("ProfileSwitched", function()
        container.currentOverlay = nil
        if container:IsShown() then RebuildTabs() end
    end)

    return container
end
