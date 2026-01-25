NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local hideBlizzard = Base.CreateHideBlizzardFrame(PlayerFrame, {
    childPrefix = "^PlayerFrame",
    extraKills = { "powerBarAlt" },
    containerKey = "PlayerFrameContainer",
    contentKey = "PlayerFrameContent",
})

NivUI.UnitFrames.PlayerFrame = Base.CreateModule({
    unit = "player",
    frameType = "player",
    defaultName = "Player",
    anchorFrame = PlayerFrame,
    anchorOffsetX = 24,
    anchorOffsetY = 0,
    hideBlizzard = hideBlizzard,
})
