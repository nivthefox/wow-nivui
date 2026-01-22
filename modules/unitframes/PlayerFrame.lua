NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local function HideBlizzardPlayerFrame(state)
    if not PlayerFrame then return end

    if InCombatLockdown and InCombatLockdown() then
        state.pendingHide = true
        return
    end

    state.pendingHide = false

    -- Do NOT call UnregisterAllEvents here - it breaks Edit Mode
    if PlayerFrame.EnableMouse then
        PlayerFrame:EnableMouse(false)
    end
    if PlayerFrame.SetMouseClickEnabled then
        PlayerFrame:SetMouseClickEnabled(false)
    end
    if PlayerFrame.SetMouseMotionEnabled then
        PlayerFrame:SetMouseMotionEnabled(false)
    end
    if PlayerFrame.SetHitRectInsets then
        PlayerFrame:SetHitRectInsets(10000, 10000, 10000, 10000)
    end

    Base.HideRegions(PlayerFrame)

    Base.KillVisual(PlayerFrame.PlayerFrameContainer)
    Base.KillVisual(PlayerFrame.PlayerFrameContent)
    Base.KillVisual(PlayerFrame.healthbar)
    Base.KillVisual(PlayerFrame.manabar)
    Base.KillVisual(PlayerFrame.powerBarAlt)

    local children = { PlayerFrame:GetChildren() }
    for _, child in ipairs(children) do
        local name = child:GetName()
        if name and name:find("^PlayerFrame") then
            Base.KillVisual(child)
        end
    end

    state.blizzardHidden = true

    if not PlayerFrame.NivUI_SoftHideHooked then
        PlayerFrame.NivUI_SoftHideHooked = true
        PlayerFrame:HookScript("OnShow", function()
            if state.blizzardHidden then
                HideBlizzardPlayerFrame(state)
            end
        end)
    end
end

NivUI.UnitFrames.PlayerFrame = Base.CreateModule({
    unit = "player",
    frameType = "player",
    defaultName = "Player",
    anchorFrame = PlayerFrame,
    anchorOffsetX = 24,
    anchorOffsetY = 0,
    hideBlizzard = HideBlizzardPlayerFrame,
})
