NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local function HideBlizzardFocusFrame(state)
    if not FocusFrame then return end

    if InCombatLockdown and InCombatLockdown() then
        state.pendingHide = true
        return
    end

    state.pendingHide = false

    -- NOTE: Do NOT call UnregisterAllEvents - it breaks Edit Mode
    if FocusFrame.EnableMouse then
        FocusFrame:EnableMouse(false)
    end
    if FocusFrame.SetMouseClickEnabled then
        FocusFrame:SetMouseClickEnabled(false)
    end
    if FocusFrame.SetMouseMotionEnabled then
        FocusFrame:SetMouseMotionEnabled(false)
    end
    if FocusFrame.SetHitRectInsets then
        FocusFrame:SetHitRectInsets(10000, 10000, 10000, 10000)
    end

    Base.HideRegions(FocusFrame)

    Base.KillVisual(FocusFrame.TargetFrameContainer)
    Base.KillVisual(FocusFrame.TargetFrameContent)
    Base.KillVisual(FocusFrame.healthbar)
    Base.KillVisual(FocusFrame.manabar)

    if FocusFrame.auraPools then
        FocusFrame.auraPools:ReleaseAll()
        if not state.aurasDisabled then
            state.aurasDisabled = true
            FocusFrame.UpdateAuras = function() end
        end
    end

    local children = { FocusFrame:GetChildren() }
    for _, child in ipairs(children) do
        local name = child:GetName()
        if name and name:find("^FocusFrame") then
            Base.KillVisual(child)
        end
    end

    state.blizzardHidden = true

    if not state.softHideHooked then
        state.softHideHooked = true
        FocusFrame:HookScript("OnShow", function()
            if state.blizzardHidden then
                HideBlizzardFocusFrame(state)
            end
        end)
    end
end

NivUI.UnitFrames.FocusFrame = Base.CreateModule({
    unit = "focus",
    frameType = "focus",
    defaultName = "Focus",
    anchorFrame = FocusFrame,
    anchorOffsetX = 24,
    anchorOffsetY = 0,
    hideBlizzard = HideBlizzardFocusFrame,

    shouldShow = function()
        return UnitExists("focus")
    end,

    registerEvents = function(frame)
        frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
    end,

    onEvent = function(_frame, event, _unit)
        if event == "PLAYER_FOCUS_CHANGED" then
            local state = NivUI.UnitFrames.FocusFrame.GetState()
            Base.CheckVisibility(state)
            if state.customFrame and state.customFrame:IsShown() then
                Base.UpdateAllWidgets(state)
            end
        end
    end,
})
