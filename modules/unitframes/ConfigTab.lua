local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}

local UnitFrameConfig = NivUI.UnitFrames.Config
local StyleDesignerPanel = UnitFrameConfig.StyleDesignerPanel
local AssignmentsPanel = UnitFrameConfig.AssignmentsPanel
local CustomRaidGroupPanel = UnitFrameConfig.CustomRaidGroupPanel

function NivUI.UnitFrames:SetupConfigTabWithSubtabs(parent, Components)
    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints()
    container:Hide()

    local TAB_HEIGHT = 24
    local allTabs = {}
    local customGroupTabs = {}
    local currentSubTab = "designer"
    local addButton
    local SelectSubTab

    local staticTabDefinitions = {
        {
            id = "designer",
            name = "Designer",
            frameType = nil,
            createPanel = function(panelParent)
                return StyleDesignerPanel.Create(panelParent)
            end
        },
        {
            id = "assignments",
            name = "Assignments",
            frameType = nil,
            createPanel = function(panelParent)
                return AssignmentsPanel.Create(panelParent, Components)
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

    addButton:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
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

        local panel = CustomRaidGroupPanel.Create(tabContainer, groupId, Components)
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
        for _, groupId in ipairs(NivUI:GetCustomRaidGroupIds()) do
            local groupData = customGroups[groupId]
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
        local visibleTabs = {}

        for _, tabData in ipairs(allTabs) do
            local shouldShow = tabData.frameType == nil or NivUI:IsFrameEnabled(tabData.frameType)

            if shouldShow then
                tabData.tab:Show()
                visibleTabs[#visibleTabs + 1] = tabData.tab
            else
                tabData.tab:Hide()
            end
        end

        visibleTabs[#visibleTabs + 1] = addButton
        local numRows = NivUI.TabLayout.LayoutRows(container, visibleTabs)

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
