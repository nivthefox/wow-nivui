NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local function HideBlizzardToTFrame(state)
    if not TargetFrame or not TargetFrame.totFrame then return end

    if InCombatLockdown and InCombatLockdown() then
        state.pendingHide = true
        return
    end

    state.pendingHide = false

    Base.KillVisual(TargetFrame.totFrame)

    state.blizzardHidden = true
end

NivUI.UnitFrames.TargetOfTargetFrame = Base.CreateModule({
    unit = "targettarget",
    frameType = "targettarget",
    defaultName = "Target of Target",
    anchorFrame = TargetFrame,
    anchorOffsetX = 150,
    anchorOffsetY = -20,
    hideBlizzard = HideBlizzardToTFrame,

    shouldShow = function()
        return UnitExists("targettarget")
    end,

    registerEvents = function(frame)
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        frame:RegisterUnitEvent("UNIT_TARGET", "target")
    end,

    onEvent = function(frame, event, unit)
        if event == "PLAYER_TARGET_CHANGED" or event == "UNIT_TARGET" then
            local state = NivUI.UnitFrames.TargetOfTargetFrame.GetState()
            if not state.customFrame then return end

            if UnitExists("targettarget") then
                state.customFrame:Show()
                Base.UpdateAllWidgets(state)
            else
                state.customFrame:Hide()
            end
        end
    end,
})
