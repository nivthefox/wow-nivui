local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local hideBlizzard, restoreBlizzard = Base.CreateHideBlizzardFrame(PlayerFrame)

NivUI.UnitFrames.PlayerFrame = Base.CreateModule({
    unit = "player",
    frameType = "player",
    defaultName = "Player",
    anchorFrame = PlayerFrame,
    anchorOffsetX = 24,
    anchorOffsetY = 0,
    hideBlizzard = hideBlizzard,
    restoreBlizzard = restoreBlizzard,
})
