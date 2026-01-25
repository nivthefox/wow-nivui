NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

-- State for each custom group, keyed by groupId
local groupStates = {}

-- Map role filter keys to UnitGroupRolesAssigned return values
local ROLE_MAP = {
    tank = "TANK",
    healer = "HEALER",
    dps = "DAMAGER",
}

local function GetFilteredUnits(groupConfig)
    local units = {}

    if not IsInRaid() and GetNumGroupMembers() <= 5 then
        -- In party or solo - use party units
        local partyUnits = { "player" }
        for i = 1, 4 do
            table.insert(partyUnits, "party" .. i)
        end

        for _, unit in ipairs(partyUnits) do
            if UnitExists(unit) then
                local shouldInclude = false

                if groupConfig.filterType == "role" then
                    local role = UnitGroupRolesAssigned(unit)
                    for roleKey, roleValue in pairs(ROLE_MAP) do
                        if groupConfig.roles[roleKey] and role == roleValue then
                            shouldInclude = true
                            break
                        end
                    end
                else -- member filter
                    local name = UnitName(unit)
                    if name and groupConfig.members[name] then
                        shouldInclude = true
                    end
                end

                if shouldInclude then
                    table.insert(units, unit)
                end
            end
        end
    else
        -- In raid
        for i = 1, 40 do
            local unit = "raid" .. i
            if UnitExists(unit) then
                local shouldInclude = false

                if groupConfig.filterType == "role" then
                    local role = UnitGroupRolesAssigned(unit)
                    for roleKey, roleValue in pairs(ROLE_MAP) do
                        if groupConfig.roles[roleKey] and role == roleValue then
                            shouldInclude = true
                            break
                        end
                    end
                else -- member filter
                    local name = GetRaidRosterInfo(i)
                    if name then
                        -- Strip realm name
                        local shortName = strsplit("-", name)
                        if groupConfig.members[shortName] then
                            shouldInclude = true
                        end
                    end
                end

                if shouldInclude then
                    table.insert(units, unit)
                end
            end
        end
    end

    return units
end

local function ClearFrameWidgets(frame)
    if frame.widgets then
        for _, widget in pairs(frame.widgets) do
            if widget.Hide then widget:Hide() end
            if widget.SetParent then widget:SetParent(nil) end
        end
        wipe(frame.widgets)
    end
    if frame.border then
        frame.border:Hide()
        frame.border:SetParent(nil)
        frame.border = nil
    end
end

local function CreateMemberFrame(groupId, unit, parentContainer, styleName)
    local state = groupStates[groupId]
    local style = NivUI:GetStyleWithDefaults(styleName)
    if not style then return nil end

    local frameConfig = style.frame or {}
    local frameWidth = frameConfig.width or 80
    local frameHeight = frameConfig.height or 40

    local frameName = "NivUI_CustomRaidFrame_" .. groupId .. "_" .. unit
    local frame = _G[frameName]
    local isNewFrame = not frame

    if isNewFrame then
        frame = CreateFrame("Button", frameName, parentContainer, "SecureUnitButtonTemplate")
    else
        ClearFrameWidgets(frame)
        frame:SetParent(parentContainer)
    end

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
        frameType = "customRaid_" .. groupId,
        defaultName = "Raid Member",
        customFrame = frame,
        currentStyle = style,
        styleName = styleName,
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

    frame:SetScript("OnEvent", function(_self, event, _eventUnit)
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
    frame:SetScript("OnUpdate", function(_self, elapsed)
        memberState.timeSinceLastUpdate = memberState.timeSinceLastUpdate + elapsed
        if memberState.timeSinceLastUpdate < UPDATE_INTERVAL then return end
        memberState.timeSinceLastUpdate = 0

        Base.UpdateHealthBar(memberState)
        Base.UpdateHealthText(memberState)
        Base.UpdatePowerBar(memberState)
        Base.UpdatePowerText(memberState)
        Base.UpdateCastbar(memberState)
    end)

    return frame
end

local function DestroyMemberFrame(groupId, unit)
    local state = groupStates[groupId]
    if not state then return end

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

local function LayoutMemberFrames(groupId)
    local state = groupStates[groupId]
    if not state or not state.container then return end

    local groupConfig = NivUI:GetCustomRaidGroup(groupId)
    if not groupConfig then return end

    local style = NivUI:GetStyleWithDefaults(groupConfig.styleName)
    local frameConfig = style and style.frame or {}
    local frameWidth = frameConfig.width or 80
    local frameHeight = frameConfig.height or 40
    local spacing = 2

    local filteredUnits = GetFilteredUnits(groupConfig)

    -- Hide all existing frames first
    for unit, frame in pairs(state.memberFrames) do
        frame:Hide()
        state.memberStates[unit] = nil
    end

    -- Create/show frames for filtered units
    local yOffset = 0
    local visibleCount = 0

    for _, unit in ipairs(filteredUnits) do
        local frame = state.memberFrames[unit]
        if not frame then
            frame = CreateMemberFrame(groupId, unit, state.container, groupConfig.styleName)
            state.memberFrames[unit] = frame
        end

        if frame then
            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", state.container, "TOPLEFT", 0, -yOffset)
            frame:Show()

            visibleCount = visibleCount + 1
            yOffset = yOffset + frameHeight + spacing

            -- Update the frame data
            if state.memberStates[unit] then
                Base.UpdateAllWidgets(state.memberStates[unit])
            end
        end
    end

    -- Resize container
    local containerWidth = frameWidth
    local containerHeight = math.max(1, visibleCount * frameHeight + math.max(0, visibleCount - 1) * spacing)
    state.container:SetSize(containerWidth, containerHeight)
end

local function BuildCustomGroupFrames(groupId)
    local groupConfig = NivUI:GetCustomRaidGroup(groupId)
    if not groupConfig then return end

    local state = groupStates[groupId]
    if not state then
        state = {
            enabled = false,
            previewMode = false,
            container = nil,
            memberFrames = {},
            memberStates = {},
        }
        groupStates[groupId] = state
    end

    -- Clear existing frames
    for unit in pairs(state.memberFrames) do
        DestroyMemberFrame(groupId, unit)
    end

    if not state.container then
        local frameType = "customRaid_" .. groupId
        state.container = CreateFrame("Frame", "NivUI_CustomRaidContainer_" .. groupId, UIParent)
        state.container:SetSize(80, 200)

        local positionApplied = NivUI.EditMode and NivUI.EditMode:ApplyPosition(frameType, state.container)
        if not positionApplied then
            state.container:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
        end

        -- Register with Edit Mode
        if NivUI.EditMode then
            NivUI.EditMode:CreateSelectionFrame(frameType, state.container)
            if NivUI.EditMode:IsActive() then
                NivUI.EditMode:ShowSelection(frameType)
            end
        end
    end

    state.enabled = groupConfig.enabled
    LayoutMemberFrames(groupId)

    Base.SetSecureVisibility(state.container, state.enabled)
end

local function DestroyCustomGroupFrames(groupId)
    local state = groupStates[groupId]
    if not state then return end

    for unit in pairs(state.memberFrames) do
        DestroyMemberFrame(groupId, unit)
    end

    if state.container then
        Base.SetSecureVisibility(state.container, false)
        state.container:SetParent(nil)
        state.container = nil
    end

    groupStates[groupId] = nil
end

local function OnGroupRosterUpdate()
    for groupId, state in pairs(groupStates) do
        if state.enabled then
            LayoutMemberFrames(groupId)
        end
    end
end

-- Public API
local CustomRaidGroup = {}
NivUI.UnitFrames.CustomRaidGroup = CustomRaidGroup

function CustomRaidGroup.Enable(groupId)
    local groupConfig = NivUI:GetCustomRaidGroup(groupId)
    if not groupConfig then return end

    BuildCustomGroupFrames(groupId)
end

function CustomRaidGroup.Disable(groupId)
    local state = groupStates[groupId]
    if state then
        state.enabled = false
        Base.SetSecureVisibility(state.container, false)
    end
end

function CustomRaidGroup.Refresh(groupId)
    local state = groupStates[groupId]
    if not state then return end

    BuildCustomGroupFrames(groupId)
end

function CustomRaidGroup.GetState(groupId)
    return groupStates[groupId]
end

function CustomRaidGroup.GetAllStates()
    return groupStates
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(_self, event)
    if event == "PLAYER_LOGIN" then
        -- Initialize all enabled custom groups
        local customGroups = NivUI:GetCustomRaidGroups()
        for groupId, groupConfig in pairs(customGroups) do
            if groupConfig.enabled then
                CustomRaidGroup.Enable(groupId)
            end
        end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        OnGroupRosterUpdate()
    end
end)

-- Callback handlers
NivUI:RegisterCallback("CustomRaidGroupCreated", function(data)
    local groupConfig = NivUI:GetCustomRaidGroup(data.id)
    if groupConfig and groupConfig.enabled then
        CustomRaidGroup.Enable(data.id)
    end
end)

NivUI:RegisterCallback("CustomRaidGroupDeleted", function(data)
    DestroyCustomGroupFrames(data.id)
end)

NivUI:RegisterCallback("CustomRaidGroupChanged", function(data)
    local state = groupStates[data.id]
    local groupConfig = NivUI:GetCustomRaidGroup(data.id)

    if not groupConfig then return end

    if groupConfig.enabled then
        if state then
            -- Refresh existing group
            BuildCustomGroupFrames(data.id)
        else
            -- Enable new group
            CustomRaidGroup.Enable(data.id)
        end
    else
        -- Disable group
        CustomRaidGroup.Disable(data.id)
    end
end)

NivUI:RegisterCallback("StyleChanged", function(data)
    for groupId, state in pairs(groupStates) do
        if state.enabled then
            local groupConfig = NivUI:GetCustomRaidGroup(groupId)
            if groupConfig and groupConfig.styleName == data.styleName then
                CustomRaidGroup.Refresh(groupId)
            end
        end
    end
end)
