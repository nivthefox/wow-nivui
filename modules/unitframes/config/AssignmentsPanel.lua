local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Config = NivUI.UnitFrames.Config or {}

local AssignmentsPanel = {}
NivUI.UnitFrames.Config.AssignmentsPanel = AssignmentsPanel

StaticPopupDialogs["NIVUI_CONFIRM_RELOAD"] = {
    text = "Disabling this frame type requires a UI reload. Reload now?",
    button1 = "Reload",
    button2 = "Later",
    OnAccept = function(_dialog, data)
        NivUI:SetFrameEnabled(data.frameType, false)
    end,
    OnCancel = function(_dialog, data)
        NivUI:GetActiveProfile().unitFrameEnabled = NivUI:GetActiveProfile().unitFrameEnabled or {}
        NivUI:GetActiveProfile().unitFrameEnabled[data.frameType] = false
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

NivUI:RegisterConfigPopup("NIVUI_CONFIRM_RELOAD")

function AssignmentsPanel.Create(parent, Components)
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
