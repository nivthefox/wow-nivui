NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local function HideBlizzardToTFrame(state)
    local totFrame = TargetFrame and TargetFrame.totFrame
    if not totFrame then return end

    if InCombatLockdown and InCombatLockdown() then
        state.pendingHide = true
        return
    end

    state.pendingHide = false

    -- NOTE: Do NOT call UnregisterAllEvents - it breaks Edit Mode
    if totFrame.EnableMouse then
        totFrame:EnableMouse(false)
    end
    if totFrame.SetMouseClickEnabled then
        totFrame:SetMouseClickEnabled(false)
    end
    if totFrame.SetMouseMotionEnabled then
        totFrame:SetMouseMotionEnabled(false)
    end
    if totFrame.SetHitRectInsets then
        totFrame:SetHitRectInsets(10000, 10000, 10000, 10000)
    end

    Base.HideRegions(totFrame)

    -- Kill named children starting with TargetFrameToT
    local children = { totFrame:GetChildren() }
    for _, child in ipairs(children) do
        local name = child:GetName()
        if name and name:find("^TargetFrameToT") then
            Base.KillVisual(child)
        end
    end

    state.blizzardHidden = true

    if not totFrame.NivUI_SoftHideHooked then
        totFrame.NivUI_SoftHideHooked = true
        totFrame:HookScript("OnShow", function()
            if state.blizzardHidden then
                HideBlizzardToTFrame(state)
            end
        end)
    end
end

NivUI.UnitFrames.TargetOfTargetFrame = Base.CreateModule({
    unit = "targettarget",
    frameType = "targettarget",
    defaultName = "Target of Target",
    anchorFrame = function() return TargetFrame and TargetFrame.totFrame or TargetFrame end,
    anchorOffsetX = 0,
    anchorOffsetY = 0,
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
            Base.CheckVisibility(state)
            if state.customFrame and state.customFrame:IsShown() then
                Base.UpdateAllWidgets(state)
            end
        end
    end,
})
