local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Runtime = NivUI.UnitFrames.Runtime or {}

local CastbarUpdater = {}
NivUI.UnitFrames.Runtime.CastbarUpdater = CastbarUpdater
local function GetWidgetConfig(state, widgetName)
    local config = state.currentStyle and state.currentStyle[widgetName]
    if not config then
        return NivUI.UnitFrames.DEFAULT_STYLE[widgetName]
    end
    return config
end
--- Updates the castbar widget for a unit frame.
--- Handles casting, channeling, and empowered casts with stage markers.
--- @param state table The unit frame state table
function CastbarUpdater.UpdateCastbar(state)
    if not state.customFrame or not state.customFrame.widgets.castbar then return end
    local widget = state.customFrame.widgets.castbar
    local config = GetWidgetConfig(state, "castbar")
    local unit = state.unit

    local name, _text, texture, startTimeMS, endTimeMS, _isTradeSkill, _castID, notInterruptible, _spellID = UnitCastingInfo(unit)
    local isChanneling = false
    local isEmpowered = false
    local numStages = 0
    local _isEmpoweredFlag

    if not name then
        name, _text, texture, startTimeMS, endTimeMS, _isTradeSkill, notInterruptible, _spellID, _isEmpoweredFlag, numStages = UnitChannelInfo(unit)
        isChanneling = true
        isEmpowered = numStages and numStages > 0
    end

    if not name then
        widget:Hide()
        if state.castbarTicking then
            state.castbarTicking = false
            widget:SetScript("OnUpdate", nil)
        end
        if widget.ClearStages then
            widget:ClearStages()
        end
        return
    end

    if isEmpowered and not issecretvalue(endTimeMS) then
        local holdTime = GetUnitEmpowerHoldAtMaxTime(unit)
        if holdTime and not issecretvalue(holdTime) then
            endTimeMS = endTimeMS + holdTime
        end
    end

    local fillBackward = isChanneling and not isEmpowered

    if issecretvalue(startTimeMS) then
        local duration = isChanneling and UnitChannelDuration(unit) or UnitCastingDuration(unit)
        local direction = fillBackward and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime
        widget:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, direction)

        if widget.timer and config.showTimer then
            if not state.castbarTicking then
                state.castbarTicking = true
                widget:SetScript("OnUpdate", function()
                    widget.timer:SetFormattedText("%.1fs", duration:GetRemainingDuration())
                end)
            end
        elseif state.castbarTicking then
            state.castbarTicking = false
            widget:SetScript("OnUpdate", nil)
        end
    else
        local durationSec = (endTimeMS - startTimeMS) / 1000
        widget:SetMinMaxValues(0, 1)

        if not state.castbarTicking then
            state.castbarTicking = true
            widget:SetScript("OnUpdate", function()
                local elapsed = (GetTime() * 1000 - startTimeMS) / 1000
                local progress = elapsed / durationSec
                widget:SetValue(fillBackward and (1 - progress) or progress)

                if widget.timer and config.showTimer then
                    local remaining = (endTimeMS - GetTime() * 1000) / 1000
                    widget.timer:SetFormattedText("%.1fs", remaining)
                end

                if isEmpowered and widget.UpdateStage then
                    widget:UpdateStage(elapsed)
                end
            end)
        end
    end

    if isEmpowered and widget.AddStages and not issecretvalue(endTimeMS) then
        local totalDurationMS = endTimeMS - startTimeMS
        widget:AddStages(numStages, unit, totalDurationMS)
    elseif widget.ClearStages then
        widget:ClearStages()
    end

    if widget.spellName and config.showSpellName then
        widget.spellName:SetText(name or "")
    end

    if widget.icon and config.showIcon then
        widget.icon:SetTexture(texture)
    end

    local cast = config.castingColor
    local nonInt = config.nonInterruptibleColor
    widget:GetStatusBarTexture():SetVertexColorFromBoolean(notInterruptible,
        CreateColor(nonInt.r, nonInt.g, nonInt.b),
        CreateColor(cast.r, cast.g, cast.b))

    widget:Show()
end
