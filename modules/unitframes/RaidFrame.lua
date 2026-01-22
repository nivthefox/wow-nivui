NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local states = {
    raid10 = {
        enabled = false,
        previewMode = false,
        container = nil,
        groupFrames = {},      -- Keyed by group number (1-8)
        memberFrames = {},     -- Keyed by unit ID: "raid1", "raid2", etc.
        memberStates = {},     -- State objects for each member frame
        styleName = nil,
        maxGroups = 2,
    },
    raid20 = {
        enabled = false,
        previewMode = false,
        container = nil,
        groupFrames = {},
        memberFrames = {},
        memberStates = {},
        styleName = nil,
        maxGroups = 4,
    },
    raid40 = {
        enabled = false,
        previewMode = false,
        container = nil,
        groupFrames = {},
        memberFrames = {},
        memberStates = {},
        styleName = nil,
        maxGroups = 8,
    },
}

local UpdateAllRaidMembers

local function GetActiveRaidSize()
    if not IsInRaid() then
        return nil
    end

    local _, _, difficultyID = GetInstanceInfo()
    if difficultyID == 16 then
        return "raid20"  -- Mythic always uses raid20
    end

    local occupiedGroups = {}
    for i = 1, GetNumGroupMembers() do
        local _, _, subgroup = GetRaidRosterInfo(i)
        if subgroup then
            occupiedGroups[subgroup] = true
        end
    end

    local groupCount = 0
    for _ in pairs(occupiedGroups) do
        groupCount = groupCount + 1
    end

    if groupCount <= 2 then
        return "raid10"
    elseif groupCount <= 4 then
        return "raid20"
    else
        return "raid40"
    end
end

local function GetGroupUnits(groupNum)
    local units = {}
    for i = 1, 40 do
        local unit = "raid" .. i
        if UnitExists(unit) then
            local _, _, subgroup = GetRaidRosterInfo(i)
            if subgroup == groupNum then
                table.insert(units, unit)
            end
        end
    end
    return units
end

local function ShouldShowRaidFrames(raidSize)
    local state = states[raidSize]
    if state.previewMode then
        return true
    end

    local activeSize = GetActiveRaidSize()
    return activeSize == raidSize
end

local function LayoutGroupMembers(raidSize, groupNum)
    local state = states[raidSize]
    local groupFrame = state.groupFrames[groupNum]
    if not groupFrame then return end

    local playerGrowth = NivUI:GetRaidPlayerGrowthDirection(raidSize)
    local spacing = NivUI:GetRaidSpacing(raidSize)

    local style = NivUI:GetStyleWithDefaults(state.styleName)
    local frameConfig = style.frame or {}
    local frameWidth = frameConfig.width or 80
    local frameHeight = frameConfig.height or 40

    local xOffset, yOffset = 0, 0
    local xStep, yStep = 0, 0

    if playerGrowth == "DOWN" then
        yStep = -(frameHeight + spacing)
    elseif playerGrowth == "UP" then
        yStep = frameHeight + spacing
    elseif playerGrowth == "RIGHT" then
        xStep = frameWidth + spacing
    elseif playerGrowth == "LEFT" then
        xStep = -(frameWidth + spacing)
    end

    local units
    if state.previewMode then
        units = {}
        for i = 1, 5 do
            local fakeIndex = (groupNum - 1) * 5 + i
            table.insert(units, "raid" .. fakeIndex)
        end
    else
        units = GetGroupUnits(groupNum)
    end

    local visibleCount = 0
    for _, unit in ipairs(units) do
        local frame = state.memberFrames[unit]
        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", xOffset, yOffset)
            frame:Show()

            visibleCount = visibleCount + 1
            xOffset = xOffset + xStep
            yOffset = yOffset + yStep
        end
    end

    local groupWidth, groupHeight
    if playerGrowth == "DOWN" or playerGrowth == "UP" then
        groupWidth = frameWidth
        groupHeight = math.max(1, visibleCount * frameHeight + math.max(0, visibleCount - 1) * spacing)
    else
        groupWidth = math.max(1, visibleCount * frameWidth + math.max(0, visibleCount - 1) * spacing)
        groupHeight = frameHeight
    end
    groupFrame:SetSize(groupWidth, groupHeight)

    return visibleCount > 0
end

local function LayoutGroupFrames(raidSize)
    local state = states[raidSize]
    if not state.container then return end

    local groupOrientation = NivUI:GetRaidGroupOrientation(raidSize)
    local groupGrowth = NivUI:GetRaidGroupGrowthDirection(raidSize)
    local spacing = NivUI:GetRaidSpacing(raidSize)

    local xOffset, yOffset = 0, 0
    local visibleGroups = 0

    for groupNum = 1, state.maxGroups do
        local groupFrame = state.groupFrames[groupNum]
        if groupFrame then
            local hasMembers = LayoutGroupMembers(raidSize, groupNum)

            if hasMembers or state.previewMode then
                groupFrame:ClearAllPoints()
                groupFrame:SetPoint("TOPLEFT", state.container, "TOPLEFT", xOffset, yOffset)
                groupFrame:Show()

                visibleGroups = visibleGroups + 1

                local groupWidth = groupFrame:GetWidth()
                local groupHeight = groupFrame:GetHeight()

                if groupOrientation == "VERTICAL" then
                    if groupGrowth == "DOWN" then
                        yOffset = yOffset - (groupHeight + spacing)
                    else  -- UP
                        yOffset = yOffset + (groupHeight + spacing)
                    end
                else  -- HORIZONTAL
                    if groupGrowth == "RIGHT" then
                        xOffset = xOffset + (groupWidth + spacing)
                    else  -- LEFT
                        xOffset = xOffset - (groupWidth + spacing)
                    end
                end
            else
                groupFrame:Hide()
            end
        end
    end

    if visibleGroups > 0 then
        local style = NivUI:GetStyleWithDefaults(state.styleName)
        local frameConfig = style.frame or {}
        local frameWidth = frameConfig.width or 80
        local frameHeight = frameConfig.height or 40
        local playerGrowth = NivUI:GetRaidPlayerGrowthDirection(raidSize)

        local groupWidth, groupHeight
        if playerGrowth == "DOWN" or playerGrowth == "UP" then
            groupWidth = frameWidth
            groupHeight = 5 * frameHeight + 4 * spacing
        else
            groupWidth = 5 * frameWidth + 4 * spacing
            groupHeight = frameHeight
        end

        local containerWidth, containerHeight
        if groupOrientation == "VERTICAL" then
            containerWidth = groupWidth
            containerHeight = visibleGroups * groupHeight + (visibleGroups - 1) * spacing
        else
            containerWidth = visibleGroups * groupWidth + (visibleGroups - 1) * spacing
            containerHeight = groupHeight
        end

        state.container:SetSize(containerWidth, containerHeight)
    end
end

local function CreateMemberFrame(raidSize, unit, parentGroup)
    local state = states[raidSize]
    local style = NivUI:GetStyleWithDefaults(state.styleName)
    if not style then return nil end

    local frameConfig = style.frame or {}
    local frameWidth = frameConfig.width or 80
    local frameHeight = frameConfig.height or 40

    local frameName = "NivUI_RaidFrame_" .. raidSize .. "_" .. unit
    local frame = CreateFrame("Button", frameName, parentGroup, "SecureUnitButtonTemplate")
    frame:SetSize(frameWidth, frameHeight)

    if frameConfig.strata then frame:SetFrameStrata(frameConfig.strata) end
    if frameConfig.frameLevel then frame:SetFrameLevel(frameConfig.frameLevel) end

    frame:SetAttribute("unit", unit)
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "togglemenu")
    frame:RegisterForClicks("AnyUp")

    if frameConfig.showBorder then
        frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.border:SetAllPoints()
        local borderSize = frameConfig.borderSize or 1
        local borderColor = frameConfig.borderColor or { r = 0, g = 0, b = 0, a = 1 }
        frame.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = borderSize,
        })
        frame.border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    end

    frame.widgets = Base.CreateWidgets(frame, style, unit)
    Base.ApplyAnchors(frame, frame.widgets, style)

    local memberState = {
        unit = unit,
        frameType = raidSize,
        defaultName = "Raid Member",
        customFrame = frame,
        currentStyle = style,
        styleName = state.styleName,
        timeSinceLastUpdate = 0,
        castbarTicking = false,
    }

    state.memberStates[unit] = memberState

    frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    frame:RegisterUnitEvent("UNIT_MAXPOWER", unit)
    frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit)
    frame:RegisterUnitEvent("UNIT_MODEL_CHANGED", unit)
    frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
    frame:RegisterUnitEvent("UNIT_LEVEL", unit)
    frame:RegisterUnitEvent("UNIT_FACTION", unit)
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")

    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", unit)
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", unit)

    frame:SetScript("OnEvent", function(self, event, _eventUnit)
        if event == "UNIT_MAXHEALTH" then
            Base.UpdateHealthBar(memberState)
            Base.UpdateHealthText(memberState)
        elseif event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
            Base.UpdatePowerBar(memberState)
            Base.UpdatePowerText(memberState)
        elseif event == "UNIT_MODEL_CHANGED" then
            Base.UpdatePortrait(memberState)
        elseif event == "UNIT_NAME_UPDATE" then
            Base.UpdateNameText(memberState)
        elseif event == "UNIT_LEVEL" then
            Base.UpdateLevelText(memberState)
        elseif event == "UNIT_FACTION" then
            Base.UpdateHealthBar(memberState)
            Base.UpdateNameText(memberState)
        elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
            Base.UpdateStatusIndicators(memberState)
        elseif event:find("SPELLCAST") then
            Base.UpdateCastbar(memberState)
        end
    end)

    local UPDATE_INTERVAL = 0.1
    frame:SetScript("OnUpdate", function(self, elapsed)
        if not NivUI:IsRealTimeUpdates(raidSize) then
            memberState.timeSinceLastUpdate = memberState.timeSinceLastUpdate + elapsed
            if memberState.timeSinceLastUpdate < UPDATE_INTERVAL then return end
            memberState.timeSinceLastUpdate = 0
        end

        Base.UpdateHealthBar(memberState)
        Base.UpdateHealthText(memberState)
        Base.UpdatePowerBar(memberState)
        Base.UpdatePowerText(memberState)
        Base.UpdateCastbar(memberState)
    end)

    return frame
end

local function DestroyMemberFrame(raidSize, unit)
    local state = states[raidSize]
    local frame = state.memberFrames[unit]
    if frame then
        frame:UnregisterAllEvents()
        frame:SetScript("OnUpdate", nil)
        frame:SetScript("OnEvent", nil)
        frame:Hide()
        frame:SetParent(nil)
    end
    state.memberFrames[unit] = nil
    state.memberStates[unit] = nil
end

local function BuildRaidFrames(raidSize)
    local state = states[raidSize]

    for unit in pairs(state.memberFrames) do
        DestroyMemberFrame(raidSize, unit)
    end
    for groupNum in pairs(state.groupFrames) do
        if state.groupFrames[groupNum] then
            state.groupFrames[groupNum]:Hide()
            state.groupFrames[groupNum]:SetParent(nil)
        end
    end
    wipe(state.groupFrames)

    state.styleName = NivUI:GetAssignment(raidSize)

    if not state.container then
        state.container = CreateFrame("Frame", "NivUI_RaidContainer_" .. raidSize, UIParent)
        state.container:SetSize(400, 200)  -- Will be resized by layout

        local positionApplied = NivUI.EditMode and NivUI.EditMode:ApplyPosition(raidSize, state.container)
        if not positionApplied then
            state.container:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end

        if NivUI.EditMode then
            NivUI.EditMode:CreateSelectionFrame(raidSize, state.container)
            if NivUI.EditMode:IsActive() then
                NivUI.EditMode:ShowSelection(raidSize)
            end
        end
    end

    for groupNum = 1, state.maxGroups do
        local groupFrame = CreateFrame("Frame", "NivUI_RaidGroup_" .. raidSize .. "_" .. groupNum, state.container)
        groupFrame:SetSize(80, 200)  -- Will be resized by layout
        state.groupFrames[groupNum] = groupFrame

        for memberIndex = 1, 5 do
            local unitIndex = (groupNum - 1) * 5 + memberIndex
            local unit = "raid" .. unitIndex
            local frame = CreateMemberFrame(raidSize, unit, groupFrame)
            if frame then
                state.memberFrames[unit] = frame
            end
        end
    end

    LayoutGroupFrames(raidSize)
    UpdateAllRaidMembers(raidSize)
end

function UpdateAllRaidMembers(raidSize)
    local state = states[raidSize]
    for unit, memberState in pairs(state.memberStates) do
        if state.memberFrames[unit] and state.memberFrames[unit]:IsShown() then
            Base.UpdateAllWidgets(memberState)
        end
    end
end

local function DestroyRaidFrames(raidSize)
    local state = states[raidSize]

    for unit in pairs(state.memberFrames) do
        DestroyMemberFrame(raidSize, unit)
    end

    for groupNum in pairs(state.groupFrames) do
        if state.groupFrames[groupNum] then
            state.groupFrames[groupNum]:Hide()
            state.groupFrames[groupNum]:SetParent(nil)
        end
    end
    wipe(state.groupFrames)

    if state.container then
        state.container:Hide()
        state.container:SetParent(nil)
        state.container = nil
    end
end

local function OnGroupRosterUpdate()
    local activeSize = GetActiveRaidSize()

    for raidSize, state in pairs(states) do
        if state.enabled then
            if state.previewMode then
                if state.container then
                    state.container:Show()
                end
                LayoutGroupFrames(raidSize)
                UpdateAllRaidMembers(raidSize)
            elseif raidSize == activeSize then
                if state.container then
                    state.container:Show()
                end
                LayoutGroupFrames(raidSize)
                UpdateAllRaidMembers(raidSize)
            else
                if state.container then
                    state.container:Hide()
                end
            end
        end
    end
end

local function HideBlizzardRaidFrames()
    if InCombatLockdown and InCombatLockdown() then
        return
    end

    if CompactRaidFrameContainer then
        CompactRaidFrameContainer:UnregisterAllEvents()
        CompactRaidFrameContainer:Hide()
        CompactRaidFrameContainer:SetScript("OnShow", function(self) self:Hide() end)
    end

    if CompactRaidFrameManager then
        CompactRaidFrameManager:UnregisterAllEvents()
        CompactRaidFrameManager:Hide()
        CompactRaidFrameManager:SetScript("OnShow", function(self) self:Hide() end)
    end
end

local RaidFrame = {}
NivUI.UnitFrames.RaidFrame = RaidFrame

function RaidFrame.Enable(raidSize)
    local state = states[raidSize]
    if not state then return end

    state.enabled = true
    BuildRaidFrames(raidSize)
    HideBlizzardRaidFrames()

    if ShouldShowRaidFrames(raidSize) then
        state.container:Show()
    else
        state.container:Hide()
    end
end

function RaidFrame.Disable(raidSize)
    local state = states[raidSize]
    if not state then return end

    state.enabled = false
    DestroyRaidFrames(raidSize)
    ReloadUI()
end

function RaidFrame.Refresh(raidSize)
    local state = states[raidSize]
    if not state or not state.enabled then return end

    BuildRaidFrames(raidSize)
    if ShouldShowRaidFrames(raidSize) then
        state.container:Show()
    else
        state.container:Hide()
    end
end

function RaidFrame.SetPreviewMode(raidSize, enabled)
    local state = states[raidSize]
    if not state then return end

    state.previewMode = enabled
    if state.enabled then
        LayoutGroupFrames(raidSize)
        UpdateAllRaidMembers(raidSize)

        if enabled then
            state.container:Show()
        elseif not ShouldShowRaidFrames(raidSize) then
            state.container:Hide()
        end
    end
end

function RaidFrame.GetState(raidSize)
    return states[raidSize]
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        for raidSize in pairs(states) do
            if NivUI:IsFrameEnabled(raidSize) then
                RaidFrame.Enable(raidSize)
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE"
        or event == "PLAYER_ENTERING_WORLD"
        or event == "ZONE_CHANGED_NEW_AREA" then
        OnGroupRosterUpdate()
    elseif event == "PLAYER_REGEN_ENABLED" then
        HideBlizzardRaidFrames()
    end
end)

NivUI:RegisterCallback("FrameEnabledChanged", function(data)
    if states[data.frameType] then
        if data.enabled then
            RaidFrame.Enable(data.frameType)
        else
            RaidFrame.Disable(data.frameType)
        end
    end
end)

NivUI:RegisterCallback("AssignmentChanged", function(data)
    if states[data.frameType] and NivUI:IsFrameEnabled(data.frameType) then
        RaidFrame.Refresh(data.frameType)
    end
end)

NivUI:RegisterCallback("StyleChanged", function(data)
    for raidSize, _state in pairs(states) do
        if NivUI:IsFrameEnabled(raidSize) then
            local assignedStyle = NivUI:GetAssignment(raidSize)
            if data.styleName == assignedStyle then
                RaidFrame.Refresh(raidSize)
            end
        end
    end
end)

NivUI:RegisterCallback("RaidSettingsChanged", function(data)
    local state = states[data.raidSize]
    if state and state.enabled then
        LayoutGroupFrames(data.raidSize)
    end
end)

NivUI:RegisterCallback("RaidPreviewChanged", function(data)
    RaidFrame.SetPreviewMode(data.raidSize, data.enabled)
end)
