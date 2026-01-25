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

local function OpenTargetMenu()
    local which
    if UnitIsUnit("target", "player") then
        which = "SELF"
    elseif UnitIsUnit("target", "vehicle") then
        which = "VEHICLE"
    elseif UnitIsUnit("target", "pet") then
        which = "PET"
    elseif UnitIsOtherPlayersBattlePet("target") then
        which = "OTHERBATTLEPET"
    elseif UnitIsOtherPlayersPet("target") then
        which = "OTHERPET"
    elseif UnitIsPlayer("target") then
        if UnitInRaid("target") then
            which = "RAID_PLAYER"
        elseif UnitInParty("target") then
            which = "PARTY"
        else
            if UnitCanCooperate("player", "target") then
                which = "PLAYER"
            else
                which = "ENEMY_PLAYER"
            end
        end
    else
        which = "TARGET"
    end

    if which then
        local contextData = {
            fromTargetFrame = true,
            unit = "target",
        }
        UnitPopup_OpenMenu(which, contextData)
    end
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

        frame:SetAttribute("type2", "menu")
        frame:SetAttribute("menu-function", OpenTargetMenu)
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
