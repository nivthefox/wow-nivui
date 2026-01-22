NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local function HideBlizzardPetFrame(state)
    if not PetFrame then return end

    if InCombatLockdown and InCombatLockdown() then
        state.pendingHide = true
        return
    end

    state.pendingHide = false

    -- NOTE: Do NOT call UnregisterAllEvents - it breaks Edit Mode
    if PetFrame.EnableMouse then
        PetFrame:EnableMouse(false)
    end
    if PetFrame.SetMouseClickEnabled then
        PetFrame:SetMouseClickEnabled(false)
    end
    if PetFrame.SetMouseMotionEnabled then
        PetFrame:SetMouseMotionEnabled(false)
    end
    if PetFrame.SetHitRectInsets then
        PetFrame:SetHitRectInsets(10000, 10000, 10000, 10000)
    end

    Base.HideRegions(PetFrame)

    local children = { PetFrame:GetChildren() }
    for _, child in ipairs(children) do
        local name = child:GetName()
        if name and name:find("^PetFrame") then
            Base.KillVisual(child)
        end
    end

    state.blizzardHidden = true

    if not PetFrame.NivUI_SoftHideHooked then
        PetFrame.NivUI_SoftHideHooked = true
        PetFrame:HookScript("OnShow", function()
            if state.blizzardHidden then
                HideBlizzardPetFrame(state)
            end
        end)
    end
end

NivUI.UnitFrames.PetFrame = Base.CreateModule({
    unit = "pet",
    frameType = "pet",
    defaultName = "Pet",
    anchorFrame = PetFrame,
    anchorOffsetX = 0,
    anchorOffsetY = 0,
    hideBlizzard = HideBlizzardPetFrame,

    shouldShow = function()
        return UnitExists("pet")
    end,

    registerEvents = function(frame)
        frame:RegisterEvent("UNIT_PET")
        frame:RegisterEvent("PET_BAR_UPDATE")
    end,

    onEvent = function(frame, event, unit)
        if event == "UNIT_PET" or event == "PET_BAR_UPDATE" then
            local state = NivUI.UnitFrames.PetFrame.GetState()
            Base.CheckVisibility(state)
            if state.customFrame and state.customFrame:IsShown() then
                Base.UpdateAllWidgets(state)
            end
        end
    end,
})
