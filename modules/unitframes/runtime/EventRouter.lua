local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Runtime = NivUI.UnitFrames.Runtime or {}

local EventRouter = {}
NivUI.UnitFrames.Runtime.EventRouter = EventRouter
local Facade

function EventRouter.SetFacade(facade)
    Facade = facade
end

local CASTBAR_EVENTS = {
    UNIT_SPELLCAST_START = true,
    UNIT_SPELLCAST_STOP = true,
    UNIT_SPELLCAST_FAILED = true,
    UNIT_SPELLCAST_INTERRUPTED = true,
    UNIT_SPELLCAST_SUCCEEDED = true,
    UNIT_SPELLCAST_CHANNEL_START = true,
    UNIT_SPELLCAST_CHANNEL_STOP = true,
    UNIT_SPELLCAST_CHANNEL_UPDATE = true,
}
--- Handles shared event dispatch for all unit frame types.
--- Routes common events (health, power, model, name, level, faction, status,
--- raid marker, castbar) to the appropriate update functions.
--- Frame-type-specific events (visibility, leader/role/resting) are handled
--- by the individual frame type's OnEvent after calling this function.
--- @param state table The unit frame state table (or memberState for multi-unit frames)
--- @param event string The event name
function EventRouter.HandleEvent(state, event)
    if event == "UNIT_HEALTH" then
        Facade.UpdateHealthBar(state)
        Facade.UpdateHealthText(state)
        Facade.UpdateStatusText(state)
    elseif event == "UNIT_MAXHEALTH"
        or event == "UNIT_ABSORB_AMOUNT_CHANGED"
        or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED"
        or event == "UNIT_HEAL_PREDICTION"
        or event == "UNIT_MAX_HEALTH_MODIFIERS_CHANGED" then
        Facade.UpdateHealthBar(state)
        Facade.UpdateHealthText(state)
    elseif event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
        Facade.UpdatePowerBar(state)
        Facade.UpdatePowerText(state)
    elseif event == "UNIT_MODEL_CHANGED" then
        Facade.UpdatePortrait(state)
    elseif event == "UNIT_NAME_UPDATE" then
        Facade.UpdateNameText(state)
    elseif event == "UNIT_LEVEL" then
        Facade.UpdateLevelText(state)
    elseif event == "UNIT_FACTION" then
        Facade.UpdateHealthBar(state)
        Facade.UpdateNameText(state)
    elseif event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_REGEN_DISABLED" then
        Facade.UpdateStatusIndicators(state)
        Facade.UpdateStatusText(state)
    elseif event == "UNIT_FLAGS" or event == "UNIT_CONNECTION" then
        Facade.UpdateStatusText(state)
    elseif event == "RAID_TARGET_UPDATE" then
        Facade.UpdateRaidMarker(state)
    elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
        Facade.UpdateThreatText(state)
    elseif CASTBAR_EVENTS[event] then
        Facade.UpdateCastbar(state)
    end
end

--- Registers the standard set of unit events shared by all frame types.
--- This includes health, power, model, name, level, faction, status flags,
--- connection, spellcast, and raid target events. AuraContainers update themselves.
--- Does NOT register PLAYER_REGEN_ENABLED/DISABLED — multi-unit frames handle
--- those at the container level; single-unit frames register them separately.
--- @param frame Frame The frame to register events on
--- @param unit string The unit token (e.g., "player", "party1")
function EventRouter.RegisterStandardEvents(frame, unit)
    frame:RegisterUnitEvent("UNIT_HEALTH", unit)
    frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit)
    frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", unit)
    frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", unit)
    frame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", unit)
    frame:RegisterUnitEvent("UNIT_MAX_HEALTH_MODIFIERS_CHANGED", unit)
    frame:RegisterUnitEvent("UNIT_MAXPOWER", unit)
    frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit)
    frame:RegisterUnitEvent("UNIT_MODEL_CHANGED", unit)
    frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit)
    frame:RegisterUnitEvent("UNIT_LEVEL", unit)
    frame:RegisterUnitEvent("UNIT_FACTION", unit)
    frame:RegisterUnitEvent("UNIT_FLAGS", unit)
    frame:RegisterUnitEvent("UNIT_CONNECTION", unit)
    for castEvent in pairs(CASTBAR_EVENTS) do
        frame:RegisterUnitEvent(castEvent, unit)
    end
    frame:RegisterEvent("RAID_TARGET_UPDATE")
end
