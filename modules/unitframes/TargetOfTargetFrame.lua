local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local targetOfTargetFrame = TargetFrame and TargetFrame.totFrame
local hideBlizzard, restoreBlizzard = Base.CreateHideBlizzardFrame(targetOfTargetFrame)

NivUI.UnitFrames.TargetOfTargetFrame = Base.CreateModule({
    unit = "targettarget",
    frameType = "targettarget",
    defaultName = "Target of Target",
    anchorFrame = function() return TargetFrame and TargetFrame.totFrame or TargetFrame end,
    anchorOffsetX = 0,
    anchorOffsetY = 0,
    hideBlizzard = hideBlizzard,
    restoreBlizzard = restoreBlizzard,
    visibilityDriver = "[@targettarget,exists] show; hide",

    registerEvents = function(frame)
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        frame:RegisterUnitEvent("UNIT_TARGET", "target")
    end,

    onEvent = function(_frame, event, _unit)
        if event == "PLAYER_TARGET_CHANGED" or event == "UNIT_TARGET" then
            local state = NivUI.UnitFrames.TargetOfTargetFrame.GetState()
            if state.customFrame and state.customFrame:IsShown() then
                Base.UpdateAllWidgets(state)
            end
        end
    end,
})
