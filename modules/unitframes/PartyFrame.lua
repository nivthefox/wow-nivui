NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base
local MultiUnitFrameBase = NivUI.UnitFrames.MultiUnitFrameBase

local ROLE_PRIORITY = {
    TANK = 1,
    HEALER = 2,
    DAMAGER = 3,
    NONE = 4,
}

local function GetPartyUnits()
    local units = {}
    local includePlayer = NivUI:DoesPartyIncludePlayer()

    if includePlayer then
        table.insert(units, "player")
    end

    for i = 1, 4 do
        table.insert(units, "party" .. i)
    end

    local sortMode = NivUI:GetPartySortMode()
    if sortMode == "ROLE" then
        table.sort(units, function(a, b)
            local roleA = UnitGroupRolesAssigned(a) or "NONE"
            local roleB = UnitGroupRolesAssigned(b) or "NONE"
            return (ROLE_PRIORITY[roleA] or 4) < (ROLE_PRIORITY[roleB] or 4)
        end)
    end

    return units
end

local function ShouldShowPartyFrames(state)
    if state.previewMode then
        return true
    end

    if IsInRaid() then
        return false
    end

    local showWhenSolo = NivUI:DoesPartyShowWhenSolo()
    if showWhenSolo then
        return true
    end

    return IsInGroup()
end

local function ShouldShowPartyUnit(state, unit)
    if state.previewMode then
        return true
    end

    if unit == "player" then
        return NivUI:DoesPartyIncludePlayer() and ShouldShowPartyFrames(state)
    end

    return UnitExists(unit)
end

local function GetPartyDefaultName(unit)
    if unit == "player" then
        return UnitName("player")
    end
    return "Party Member"
end

local function HideBlizzardPartyFrames(state)
    if InCombatLockdown and InCombatLockdown() then
        state.pendingHide = true
        return
    end

    state.pendingHide = false

    if CompactPartyFrame then
        CompactPartyFrame:UnregisterAllEvents()
        CompactPartyFrame:Hide()
        CompactPartyFrame:SetScript("OnShow", function(self) self:Hide() end)
    end

    for i = 1, 4 do
        local frame = _G["PartyMemberFrame" .. i]
        if frame then
            Base.KillVisual(frame)
        end
    end

    state.blizzardHidden = true
end

local function OnPartySettingsChanged(state, data)
    local PartyFrame = NivUI.UnitFrames.PartyFrame

    if data.setting == "includePlayer" then
        PartyFrame.Refresh()
    elseif data.setting == "spacing" or data.setting == "orientation" or data.setting == "growthDirection" or data.setting == "sortMode" then
        PartyFrame.LayoutMemberFrames()
    elseif data.setting == "showWhenSolo" then
        if not state.hasVisibilityDriver then
            local shouldShow = ShouldShowPartyFrames(state)
            Base.SetSecureVisibility(state.container, shouldShow)
            if shouldShow then
                PartyFrame.LayoutMemberFrames()
                PartyFrame.UpdateAllMemberFrames()
            end
        end
    end
end

NivUI.UnitFrames.PartyFrame = MultiUnitFrameBase.CreateModule({
    frameType = "party",
    frameNamePrefix = "NivUI_PartyFrame_",
    containerName = "NivUI_PartyContainer",
    defaultContainerPosition = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 20, y = -200 },
    defaultName = GetPartyDefaultName,
    type2Attribute = "togglemenu",

    getUnits = GetPartyUnits,
    getOrientation = function() return NivUI:GetPartyOrientation() end,
    getGrowthDirection = function() return NivUI:GetPartyGrowthDirection() end,
    getSpacing = function() return NivUI:GetPartySpacing() end,

    memberVisibilityMode = "manual",
    shouldShowContainer = ShouldShowPartyFrames,
    shouldShowUnit = ShouldShowPartyUnit,

    hideBlizzardFrames = HideBlizzardPartyFrames,

    events = {
        "GROUP_ROSTER_UPDATE",
        "PLAYER_ENTERING_WORLD",
        "ZONE_CHANGED_NEW_AREA",
    },

    settingsChangedCallback = "PartySettingsChanged",
    previewChangedCallback = "PartyPreviewChanged",
    onSettingsChanged = OnPartySettingsChanged,
})
