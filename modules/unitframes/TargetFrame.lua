NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local hideBlizzard = Base.CreateHideBlizzardFrame(TargetFrame, {
    childPrefix = "^TargetFrame",
    hasAuras = true,
    containerKey = "TargetFrameContainer",
    contentKey = "TargetFrameContent",
})

local function GetDisplayUnit()
    if UnitExists("target") then
        return "target"
    elseif UnitExists("softenemy") then
        return "softenemy"
    elseif UnitExists("softfriend") then
        return "softfriend"
    end
    return "target"
end

NivUI.UnitFrames.TargetFrame = Base.CreateModule({
    unit = "target",
    frameType = "target",
    defaultName = "Target",
    anchorFrame = TargetFrame,
    anchorOffsetX = 24,
    anchorOffsetY = 0,
    hideBlizzard = hideBlizzard,
    visibilityDriver = "[@target,exists] show; [@softenemy,exists] show; [@softfriend,exists] show; hide",

    registerEvents = function(frame)
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        frame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
        frame:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED")

        RegisterAttributeDriver(frame, "unit", "[@target,exists] target; [@softenemy,exists] softenemy; [@softfriend,exists] softfriend; target")
    end,

    preUpdate = function(state, _elapsed)
        local newUnit = GetDisplayUnit()
        if state.unit ~= newUnit then
            state.unit = newUnit
            Base.UpdateAllWidgets(state)
        end
    end,

    onEvent = function(_frame, event, _unit)
        if event == "PLAYER_TARGET_CHANGED"
            or event == "PLAYER_SOFT_ENEMY_CHANGED"
            or event == "PLAYER_SOFT_FRIEND_CHANGED" then
            local state = NivUI.UnitFrames.TargetFrame.GetState()
            local newUnit = GetDisplayUnit()
            if state.unit ~= newUnit then
                state.unit = newUnit
            end
            if state.customFrame and state.customFrame:IsShown() then
                Base.UpdateAllWidgets(state)
            end
        end
    end,
})
