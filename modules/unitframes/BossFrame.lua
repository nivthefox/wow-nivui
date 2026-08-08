local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}

local MultiUnitFrameBase = NivUI.UnitFrames.MultiUnitFrameBase

local MAX_BOSS_FRAMES = 5

local function GetBossUnits()
    local units = {}
    for i = 1, MAX_BOSS_FRAMES do
        table.insert(units, "boss" .. i)
    end
    return units
end

local function HideBlizzardBossFrames(state)
    if InCombatLockdown and InCombatLockdown() then
        state.pendingHide = true
        return
    end

    state.pendingHide = false

    if BossTargetFrameContainer then
        RegisterStateDriver(BossTargetFrameContainer, "visibility", "hide")
    end

    for i = 1, MAX_BOSS_FRAMES do
        local frame = _G["Boss" .. i .. "TargetFrame"]
        if frame then
            RegisterStateDriver(frame, "visibility", "hide")
        end
    end

    state.blizzardHidden = true
end

local function RestoreBlizzardBossFrames(state)
    if InCombatLockdown and InCombatLockdown() then
        state.pendingRestore = true
        return
    end

    state.pendingRestore = false
    if BossTargetFrameContainer then
        UnregisterStateDriver(BossTargetFrameContainer, "visibility")
    end
    for i = 1, MAX_BOSS_FRAMES do
        local frame = _G["Boss" .. i .. "TargetFrame"]
        if frame then
            UnregisterStateDriver(frame, "visibility")
        end
    end
    state.blizzardHidden = false
end

local BossFrame = MultiUnitFrameBase.CreateModule({
    frameType = "boss",
    frameNamePrefix = "NivUI_BossFrame_",
    containerName = "NivUI_BossContainer",
    defaultContainerPosition = { point = "RIGHT", relativePoint = "RIGHT", x = -100, y = 0 },
    defaultName = "Boss",
    type2Attribute = "togglemenu",

    getUnits = GetBossUnits,
    getOrientation = function() return NivUI:GetBossOrientation() end,
    getGrowthDirection = function() return NivUI:GetBossGrowthDirection() end,
    getSpacing = function() return NivUI:GetBossSpacing() end,

    memberVisibilityMode = "state_driver",
    shouldShowContainer = nil,
    shouldShowUnit = nil,

    hideBlizzardFrames = HideBlizzardBossFrames,
    restoreBlizzardFrames = RestoreBlizzardBossFrames,

    events = {
        "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
        "UNIT_TARGETABLE_CHANGED",
        "ENCOUNTER_START",
        "ENCOUNTER_END",
        "PLAYER_ENTERING_WORLD",
        "ZONE_CHANGED_NEW_AREA",
    },

    settingsChangedCallback = "BossSettingsChanged",
    previewChangedCallback = "BossPreviewChanged",
})

NivUI.UnitFrames.BossFrame = BossFrame
