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

    -- NOTE: Do NOT call UnregisterAllEvents - it breaks Edit Mode
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
        if not state.aurasDisabled then
            state.aurasDisabled = true
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

    if not state.softHideHooked then
        state.softHideHooked = true
        TargetFrame:HookScript("OnShow", function(self)
            if state.blizzardHidden then
                self:SetAlpha(0)
                if not InCombatLockdown() then
                    HideBlizzardTargetFrame(state)
                end
            end
        end)
    end
end

-- Determines which unit to display: hard target takes priority, then soft targets
local function GetDisplayUnit()
    if UnitExists("target") then
        return "target"
    elseif UnitExists("softenemy") then
        return "softenemy"
    elseif UnitExists("softfriend") then
        return "softfriend"
    end
    return "target" -- fallback, frame will be hidden anyway
end

NivUI.UnitFrames.TargetFrame = Base.CreateModule({
    unit = "target",
    frameType = "target",
    defaultName = "Target",
    anchorFrame = TargetFrame,
    anchorOffsetX = 24,
    anchorOffsetY = 0,
    hideBlizzard = HideBlizzardTargetFrame,
    -- Show if any target exists: hard target, soft enemy, or soft friend
    visibilityDriver = "[@target,exists] show; [@softenemy,exists] show; [@softfriend,exists] show; hide",

    registerEvents = function(frame)
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        frame:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
        frame:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED")

        -- Secure attribute driver handles click-targeting even in combat
        -- Priority: hard target > soft enemy > soft friend
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
