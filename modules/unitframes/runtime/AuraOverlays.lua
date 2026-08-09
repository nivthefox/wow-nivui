local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Runtime = NivUI.UnitFrames.Runtime or {}

local AuraOverlays = {}
NivUI.UnitFrames.Runtime.AuraOverlays = AuraOverlays
local Facade

function AuraOverlays.SetFacade(facade)
    Facade = facade
end
--- Set cooldown from aura duration object (secret-safe).
--- @param icon Frame The icon frame with a cooldown child
--- @param unit string The unit ID
--- @param auraInstanceID number The aura instance ID
--- @return boolean True if cooldown was successfully set
local function SetCooldownFromAura(icon, unit, auraInstanceID)
    if not icon.cooldown then return false end
    if not C_UnitAuras or not C_UnitAuras.GetAuraDuration then
        pcall(icon.cooldown.SetCooldown, icon.cooldown, 0, 0)
        return false
    end
    local ok, durationObj = pcall(C_UnitAuras.GetAuraDuration, unit, auraInstanceID)
    if not ok or not durationObj then
        pcall(icon.cooldown.SetCooldown, icon.cooldown, 0, 0)
        return false
    end
    if icon.cooldown.SetCooldownFromDurationObject then
        local setOk = pcall(icon.cooldown.SetCooldownFromDurationObject, icon.cooldown, durationObj)
        return setOk
    end
    pcall(icon.cooldown.SetCooldown, icon.cooldown, 0, 0)
    return false
end

-- Cap on how many aura slots to examine per unit. Filtering discards auras after
-- enumeration, so scan generously (Blizzard tops out around 40) rather than stopping
-- at the icon count and missing matches further down the list.
local AURA_SCAN_LIMIT = 40

--- @return boolean True if the aura matches at least one built-in filter (combat-safe)
local function MatchesAnyBuiltin(unit, auraInstanceID, builtinFilters)
    for _, builtinFilter in ipairs(builtinFilters) do
        -- issecretvalue guard degrades to "matches" if the API ever returns a secret.
        local out = C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraInstanceID, builtinFilter)
        if issecretvalue(out) or out == false then
            return true
        end
    end
    return false
end

--- @return boolean True if the readable spellId is present in one of the spell sets
local function MatchesAnySpell(spellId, idReadable, spellSets)
    if not idReadable then return false end
    for _, spells in ipairs(spellSets) do
        if spells[spellId] ~= nil then
            return true
        end
    end
    return false
end

--- Decides whether a single aura survives a widget's filter spec. Block filters veto;
--- allow filters are an OR, and an empty allow set lets everything through.
--- @return boolean
local function AuraPassesFilters(unit, aura, spec)
    local spellId = aura.spellId
    local idReadable = not issecretvalue(spellId)

    if MatchesAnyBuiltin(unit, aura.auraInstanceID, spec.blockBuiltin) then return false end
    if MatchesAnySpell(spellId, idReadable, spec.blockSpells) then return false end
    if not spec.hasAllow then return true end
    if MatchesAnyBuiltin(unit, aura.auraInstanceID, spec.allowBuiltin) then return true end
    if MatchesAnySpell(spellId, idReadable, spec.allowSpells) then return true end
    return false
end

--- Collects auras for a unit using the secret-safe GetAuraSlots/GetAuraDataBySlot APIs.
--- @param unit string The unit ID
--- @param filter string The enumeration filter (e.g. "HELPFUL", "HARMFUL", "HARMFUL|RAID")
--- @param maxIcons number Maximum number of auras to collect
--- @param spec table The filter spec from NivUI.Filters:BuildSpec
--- @return table Array of aura data tables
local function CollectAuras(unit, filter, maxIcons, spec)
    local auras = {}
    if not C_UnitAuras or not C_UnitAuras.GetAuraSlots then return auras end

    local slots = { C_UnitAuras.GetAuraSlots(unit, filter, AURA_SCAN_LIMIT) }
    for i = 2, #slots do
        local aura = C_UnitAuras.GetAuraDataBySlot(unit, slots[i])
        if aura and aura.auraInstanceID and AuraPassesFilters(unit, aura, spec) then
            auras[#auras + 1] = aura
            if #auras >= maxIcons then break end
        end
    end
    return auras
end

--- Updates an aura overlay widget for a unit frame.
--- Uses instance-ID-based C APIs to avoid reading secret-protected aura fields.
--- @param state table The unit frame state table
--- @param widgetName string The overlay widget key (e.g. "overlay:Buffs")
--- @param filter string The aura filter string ("HELPFUL" or "HARMFUL")
local function UpdateAuraWidget(state, widgetName, filter)
    if not state.customFrame or not state.customFrame.widgets then return end
    local widget = state.customFrame.widgets[widgetName]
    if not widget then return end
    if state.forPreview then return end

    local unit = state.unit
    if not UnitExists(unit) then
        for _, icon in ipairs(widget.icons) do
            icon:Hide()
        end
        return
    end

    local config = widget.config
    local showDuration = config.showDuration
    local showSwipe = config.showSwipe
    local showStacks = config.showStacks
    local isColor = config.displayType == "COLOR"
    local color = isColor and config.color or nil

    local prefix = filter:find("HELPFUL") and "HELPFUL" or "HARMFUL"
    local spec = NivUI.Filters:BuildSpec(config, prefix)
    local auras = CollectAuras(unit, filter, config.maxIcons, spec)

    for i, icon in ipairs(widget.icons) do
        local aura = auras[i]
        if aura then
            if isColor then
                icon.texture:SetColorTexture(color.r, color.g, color.b, color.a or 1)
            else
                icon.texture:SetTexture(aura.icon)
            end

            if icon.cooldown then
                if (showDuration or showSwipe) and aura.auraInstanceID then
                    local hadDuration = SetCooldownFromAura(icon, unit, aura.auraInstanceID)
                    icon.cooldown:SetDrawSwipe(showSwipe and true or false)
                    icon.cooldown:SetHideCountdownNumbers(not (showDuration and hadDuration))
                    if showDuration and hadDuration then
                        NivUI.UnitFrames.ApplyCooldownFont(icon.cooldown, config.duration)
                    end
                else
                    pcall(icon.cooldown.SetCooldown, icon.cooldown, 0, 0)
                    icon.cooldown:SetHideCountdownNumbers(true)
                end
            end

            if showStacks and C_UnitAuras.GetAuraApplicationDisplayCount then
                local count = C_UnitAuras.GetAuraApplicationDisplayCount(unit, aura.auraInstanceID, 2, 99)
                if count then
                    icon.stacks:SetText(count)
                else
                    icon.stacks:SetText("")
                end
            else
                icon.stacks:SetText("")
            end

            icon.auraInstanceID = aura.auraInstanceID
            icon:Show()
        else
            if icon.cooldown then
                pcall(icon.cooldown.SetCooldown, icon.cooldown, 0, 0)
            end
            icon:Hide()
        end
    end
end

--- Determines whether a transformative overlay widget is currently active by
--- counting matching auras. CRITICAL: activation reads only the collected count,
--- never any aura field, because in combat aura fields are secret values that
--- would taint on comparison. Preview and missing-unit paths force inactive.
--- @param state table The unit frame state table
--- @param widget table The transformative overlay widget
local function UpdateTransformativeActivation(state, widget)
    if state.forPreview then
        widget.overlayActive = false
        return
    end

    local unit = state.unit
    if not UnitExists(unit) then
        widget.overlayActive = false
        return
    end

    local config = widget.config
    local prefix = widget.filter:find("HELPFUL") and "HELPFUL" or "HARMFUL"
    local spec = NivUI.Filters:BuildSpec(config, prefix)
    widget.overlayActive = #CollectAuras(unit, widget.filter, 1, spec) > 0
end

--- Dispatch from a target widget key to the update function that recomputes its
--- routine color. Used to refresh bars whose FRAME overlay tint changed.
local FRAME_TARGET_REFRESH = {
    healthBar = function(state) Facade.UpdateHealthBar(state) end,
    powerBar = function(state) Facade.UpdatePowerBar(state) end,
    castbar = function(state) Facade.UpdateCastbar(state) end,
}

--- Resolves the border holder's target frame for a BORDER claim. "frame" targets
--- the whole custom frame; any other key targets that named widget.
--- @param state table The unit frame state table
--- @param targetWidget string The target widget key
--- @return table|nil The target frame, or nil if absent
local function ResolveBorderTarget(state, targetWidget)
    if targetWidget == "frame" then
        return state.customFrame
    end
    return state.customFrame.widgets[targetWidget]
end

--- Resolves transformative overlay conflicts and applies the winning FRAME tints
--- and BORDER outlines. Runs once per evaluation pass after every overlay's
--- activation has been computed. Full re-evaluation, no stored previous state.
--- @param state table The unit frame state table
local function ResolveTransformativeOverlays(state)
    if not state.customFrame or not state.customFrame.widgets then return end

    local claims = {}
    for _, widget in pairs(state.customFrame.widgets) do
        if widget.isOverlay and NivUI.OverlayLogic.IsTransformative(widget.config.displayType) then
            local config = widget.config
            claims[#claims + 1] = {
                name = widget.overlayName,
                priority = config.priority or 1,
                targetWidget = config.targetWidget or "healthBar",
                kind = config.displayType,
                active = widget.overlayActive or false,
                widget = widget,
                config = config,
            }
        end
    end

    -- No transformative overlays exist. If a prior pass left frame tints, clear
    -- them and refresh the previously-claimed bars back to routine colors.
    if #claims == 0 then
        if state.frameOverlayColors then
            local previous = state.frameOverlayColors
            state.frameOverlayColors = nil
            for target in pairs(previous) do
                local refresh = FRAME_TARGET_REFRESH[target]
                if refresh then refresh(state) end
            end
        end
        return
    end

    local winners = NivUI.OverlayLogic.ResolveTransformative(claims)

    -- FRAME: build the new tint map, then refresh every bar that was tinted last
    -- pass or is tinted this pass so losers fall back to their routine color.
    local newColors = {}
    for target, winnerClaim in pairs(winners.FRAME) do
        newColors[target] = winnerClaim.config.color
    end

    local union = {}
    for target in pairs(newColors) do union[target] = true end
    if state.frameOverlayColors then
        for target in pairs(state.frameOverlayColors) do union[target] = true end
    end

    state.frameOverlayColors = next(newColors) and newColors or nil

    for target in pairs(union) do
        local refresh = FRAME_TARGET_REFRESH[target]
        if refresh then refresh(state) end
    end

    -- BORDER: every BORDER claim's holder is re-anchored around its target and
    -- shown when it is this pass's winner, hidden otherwise. Re-anchoring every
    -- pass makes the outline appear as soon as a previously-absent target exists.
    for _, claim in ipairs(claims) do
        if claim.kind == "BORDER" then
            local widget = claim.widget
            local winnerClaim = winners.BORDER[claim.targetWidget]
            if winnerClaim == claim then
                local target = ResolveBorderTarget(state, claim.targetWidget)
                if target and target.IsShown and target:IsShown() then
                    local t = claim.config.borderThickness or 2
                    widget:ClearAllPoints()
                    widget:SetPoint("TOPLEFT", target, "TOPLEFT", -t, t)
                    widget:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", t, -t)
                    widget:Show()
                else
                    widget:Hide()
                end
            else
                widget:Hide()
            end
        end
    end
end

--- Updates every aura overlay widget on a unit frame. Additive overlays (Icon,
--- Color) render their grid via UpdateAuraWidget; transformative overlays (Frame,
--- Border) only compute activation here, then a single resolution pass applies
--- the winning tints and outlines per target widget.
--- @param state table The unit frame state table
function AuraOverlays.UpdateOverlays(state)
    if not state.customFrame or not state.customFrame.widgets then return end
    for key, widget in pairs(state.customFrame.widgets) do
        if widget.isOverlay then
            if NivUI.OverlayLogic.IsTransformative(widget.config.displayType) then
                UpdateTransformativeActivation(state, widget)
            else
                UpdateAuraWidget(state, key, widget.filter)
            end
        end
    end
    ResolveTransformativeOverlays(state)
end
