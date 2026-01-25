NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local hideBlizzard = Base.CreateHideBlizzardFrame(FocusFrame, {
    childPrefix = "^FocusFrame",
    hasAuras = true,
    containerKey = "TargetFrameContainer",
    contentKey = "TargetFrameContent",
})

NivUI.UnitFrames.FocusFrame = Base.CreateModule({
    unit = "focus",
    frameType = "focus",
    defaultName = "Focus",
    anchorFrame = FocusFrame,
    anchorOffsetX = 24,
    anchorOffsetY = 0,
    hideBlizzard = hideBlizzard,
    visibilityDriver = "[@focus,exists] show; hide",

    registerEvents = function(frame)
        frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    end,

    onEvent = function(_frame, event, _unit)
        if event == "PLAYER_FOCUS_CHANGED" then
            local state = NivUI.UnitFrames.FocusFrame.GetState()
            if state.customFrame and state.customFrame:IsShown() then
                Base.UpdateAllWidgets(state)
            end
        end
    end,
})
