NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base
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
        BossTargetFrameContainer:UnregisterAllEvents()
        BossTargetFrameContainer:Hide()
        BossTargetFrameContainer:SetScript("OnShow", function(self) self:Hide() end)
    end

    for i = 1, MAX_BOSS_FRAMES do
        local frame = _G["Boss" .. i .. "TargetFrame"]
        if frame then
            Base.KillVisual(frame)
        end
    end

    state.blizzardHidden = true
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
