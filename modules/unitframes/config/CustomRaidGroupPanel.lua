local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Config = NivUI.UnitFrames.Config or {}

local ConfigDeletion = NivUI.ConfigDeletion
local CustomRaidGroupPanel = {}
NivUI.UnitFrames.Config.CustomRaidGroupPanel = CustomRaidGroupPanel

local function RequestCustomRaidGroupDelete(groupId, groupName)
    ConfigDeletion.Request("custom raid group", groupName, "", function()
        local success, err = NivUI:DeleteCustomRaidGroup(groupId)
        if not success then
            print("NivUI: " .. (err or "Failed to delete custom raid group"))
        end
    end)
end


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


NivUI:RegisterConfigPopup("NIVUI_NEW_CUSTOM_RAID_GROUP")

function CustomRaidGroupPanel.Create(parent, groupId, Components)
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
            RequestCustomRaidGroupDelete(groupId, groupData.name)
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

        local excludeRow = CreateFrame("Frame", nil, frame)
        excludeRow:SetHeight(24)
        excludeRow:SetPoint("LEFT", 20, 0)
        excludeRow:SetPoint("RIGHT", -20, 0)

        local excludeCheckbox = CreateFrame("CheckButton", nil, excludeRow, "SettingsCheckboxTemplate")
        excludeCheckbox:SetPoint("LEFT", 0, 0)
        excludeCheckbox:SetText("")
        excludeCheckbox:SetChecked(groupData.excludePlayer or false)

        excludeCheckbox:SetScript("OnClick", function(self)
            groupData.excludePlayer = self:GetChecked()
            NivUI:SaveCustomRaidGroup(groupId, groupData)
        end)

        local excludeLabel = excludeRow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        excludeLabel:SetPoint("LEFT", excludeCheckbox, "RIGHT", 4, 0)
        excludeLabel:SetText("Exclude Player")

        AddRow(excludeRow, 4)

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
