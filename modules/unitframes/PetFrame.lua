local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}

local Base = NivUI.UnitFrames.Base

local hideBlizzard, restoreBlizzard = Base.CreateHideBlizzardFrame(PetFrame)

NivUI.UnitFrames.PetFrame = Base.CreateModule({
    unit = "pet",
    frameType = "pet",
    defaultName = "Pet",
    anchorFrame = PetFrame,
    anchorOffsetX = 0,
    anchorOffsetY = 0,
    hideBlizzard = hideBlizzard,
    restoreBlizzard = restoreBlizzard,
    visibilityDriver = "[@pet,exists] show; hide",

    registerEvents = function(frame)
        frame:RegisterEvent("UNIT_PET")
        frame:RegisterEvent("PET_BAR_UPDATE")
    end,

    onEvent = function(_frame, event, _unit)
        if event == "UNIT_PET" or event == "PET_BAR_UPDATE" then
            local state = NivUI.UnitFrames.PetFrame.GetState()
            if state.customFrame and state.customFrame:IsShown() then
                Base.UpdateAllWidgets(state)
            end
        end
    end,
})
