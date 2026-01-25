NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local MultiUnitFrameBase = NivUI.UnitFrames.MultiUnitFrameBase

local MAX_ARENA_FRAMES = 5

local function GetArenaUnits()
    local units = {}
    for i = 1, MAX_ARENA_FRAMES do
        table.insert(units, "arena" .. i)
    end
    return units
end

local function ShouldShowArenaFrames(state)
    if state.previewMode then
        return true
    end

    for i = 1, MAX_ARENA_FRAMES do
        if UnitExists("arena" .. i) then
            return true
        end
    end

    return false
end

local function ShouldShowArenaUnit(state, unit)
    if state.previewMode then
        return true
    end

    return UnitExists(unit)
end

local function HideBlizzardArenaFrames(state)
    if InCombatLockdown and InCombatLockdown() then
        state.pendingHide = true
        return
    end

    state.pendingHide = false

    if CompactArenaFrame then
        CompactArenaFrame:UnregisterAllEvents()
        CompactArenaFrame:Hide()
        CompactArenaFrame:SetScript("OnShow", function(self) self:Hide() end)
    end

    state.blizzardHidden = true
end

local ArenaFrame = MultiUnitFrameBase.CreateModule({
    frameType = "arena",
    frameNamePrefix = "NivUI_ArenaFrame_",
    containerName = "NivUI_ArenaContainer",
    defaultContainerPosition = { point = "RIGHT", relativePoint = "RIGHT", x = -100, y = 100 },
    defaultName = "Arena",
    type2Attribute = "focus",

    getUnits = GetArenaUnits,
    getOrientation = function() return NivUI:GetArenaOrientation() end,
    getGrowthDirection = function() return NivUI:GetArenaGrowthDirection() end,
    getSpacing = function() return NivUI:GetArenaSpacing() end,

    memberVisibilityMode = "manual",
    shouldShowContainer = ShouldShowArenaFrames,
    shouldShowUnit = ShouldShowArenaUnit,

    hideBlizzardFrames = HideBlizzardArenaFrames,

    events = {
        "ARENA_OPPONENT_UPDATE",
        "ARENA_PREP_OPPONENT_SPECIALIZATIONS",
        "PVP_MATCH_STATE_CHANGED",
        "PLAYER_ENTERING_WORLD",
        "ZONE_CHANGED_NEW_AREA",
    },

    settingsChangedCallback = "ArenaSettingsChanged",
    previewChangedCallback = "ArenaPreviewChanged",
})

NivUI.UnitFrames.ArenaFrame = ArenaFrame
