NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local function HideBlizzardTargetFrame(state)
    if not TargetFrame then return end

    if InCombatLockdown and InCombatLockdown() then
        state.pendingHide = true
        return
    end

    state.pendingHide = false

    if TargetFrame.UnregisterAllEvents then
        TargetFrame:UnregisterAllEvents()
    end
    if TargetFrame.EnableMouse then
        TargetFrame:EnableMouse(false)
    end
    if TargetFrame.SetMouseClickEnabled then
        TargetFrame:SetMouseClickEnabled(false)
    end
    if TargetFrame.SetMouseMotionEnabled then
        TargetFrame:SetMouseMotionEnabled(false)
    end
    if TargetFrame.SetHitRectInsets then
        TargetFrame:SetHitRectInsets(10000, 10000, 10000, 10000)
    end

    Base.HideRegions(TargetFrame)

    Base.KillVisual(TargetFrame.TargetFrameContainer)
    Base.KillVisual(TargetFrame.TargetFrameContent)
    Base.KillVisual(TargetFrame.healthbar)
    Base.KillVisual(TargetFrame.manabar)

    if TargetFrame.auraPools then
        TargetFrame.auraPools:ReleaseAll()
        if not TargetFrame.NivUI_AurasDisabled then
            TargetFrame.NivUI_AurasDisabled = true
            TargetFrame.UpdateAuras = function() end
        end
    end

    local children = { TargetFrame:GetChildren() }
    for _, child in ipairs(children) do
        local name = child:GetName()
        if name and name:find("^TargetFrame") then
            Base.KillVisual(child)
        end
    end

    state.blizzardHidden = true

    if not TargetFrame.NivUI_SoftHideHooked then
        TargetFrame.NivUI_SoftHideHooked = true
        TargetFrame:HookScript("OnShow", function()
            if state.blizzardHidden then
                HideBlizzardTargetFrame(state)
            end
        end)
    end
end

NivUI.UnitFrames.TargetFrame = Base.CreateModule({
    unit = "target",
    frameType = "target",
    defaultName = "Target",
    anchorFrame = TargetFrame,
    anchorOffsetX = 24,
    anchorOffsetY = 0,
    hideBlizzard = nil,  -- HideBlizzardTargetFrame,  -- TEMP: testing Edit Mode

    shouldShow = function()
        return UnitExists("target")
    end,

    registerEvents = function(frame)
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    end,

    onEvent = function(frame, event, unit)
        if event == "PLAYER_TARGET_CHANGED" then
            local state = NivUI.UnitFrames.TargetFrame.GetState()
            if UnitExists("target") then
                state.customFrame:Show()
                Base.UpdateAllWidgets(state)
            else
                state.customFrame:Hide()
            end
        end
    end,
})
