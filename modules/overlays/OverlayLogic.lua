--- OverlayLogic: pure, WoW-free logic backing the Overlays system. Holds the
--- display-type classification, overlay normalization, config-condition
--- evaluation, and transformative conflict resolution. Loads with only the
--- NivUI namespace bootstrap and touches no WoW API at load or runtime, so it is
--- unit-testable in a headless Lua runner. Keep it that way.
NivUI = NivUI or {}
NivUI.OverlayLogic = NivUI.OverlayLogic or {}

local OverlayLogic = NivUI.OverlayLogic

--- Local deep copy so this module has no dependency on NivUI.DeepCopy (which
--- lives in a WoW-loaded file). Recursively copies tables; returns non-tables
--- as-is.
--- @param value any The value to copy
--- @return any A deep copy of value (tables) or value itself (non-tables)
local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

--- The set of display types that are transformative (binary, resolved by
--- priority against a target widget) rather than additive (grid cells).
local TRANSFORMATIVE = {
    FRAME = true,
    BORDER = true,
}

--- Reports whether a display type is transformative (FRAME or BORDER). Additive
--- types (ICON, COLOR), nil, and unknown strings are not transformative.
--- @param displayType string|nil The overlay's displayType value
--- @return boolean True for FRAME/BORDER, false otherwise
function OverlayLogic.IsTransformative(displayType)
    return TRANSFORMATIVE[displayType] == true
end

--- Fills any missing keys on an overlay config from the defaults table,
--- deep-copying table-valued defaults so overlays never share sub-tables.
--- Existing values are preserved. The legacy dispelIndicator key is deleted.
--- Mutates and returns the same config table.
--- @param config table The overlay config to normalize (mutated in place)
--- @param defaults table The Overlays.DEFAULTS table to fill from
--- @return table The same config table, now normalized
function OverlayLogic.NormalizeOverlay(config, defaults)
    for key, defaultValue in pairs(defaults) do
        if config[key] == nil then
            config[key] = DeepCopy(defaultValue)
        end
    end
    config.dispelIndicator = nil
    return config
end

--- Evaluates a showIf/hideIf condition against a resolved value. A nil
--- condition is always true. An anyOf condition is true when value is a member
--- of the anyOf list; otherwise the condition is an equality check against
--- cond.value.
--- @param cond table|nil The condition ({ key, value } or { key, anyOf }) or nil
--- @param value any The value looked up for cond.key
--- @return boolean Whether the condition passes
function OverlayLogic.EvaluateCondition(cond, value)
    if cond == nil then
        return true
    end
    if cond.anyOf ~= nil then
        for _, candidate in ipairs(cond.anyOf) do
            if value == candidate then
                return true
            end
        end
        return false
    end
    return value == cond.value
end

--- Reports whether claim `a` outranks claim `b` for the same kind and target.
--- Higher priority wins; missing priority is treated as 1; ties break by
--- alphabetically earlier name (string < wins, missing name treated as "").
--- @param a table A transformative claim
--- @param b table Another transformative claim
--- @return boolean True when a should win over b
local function ClaimOutranks(a, b)
    local pa = a.priority or 1
    local pb = b.priority or 1
    if pa ~= pb then
        return pa > pb
    end
    return (a.name or "") < (b.name or "")
end

--- Resolves transformative overlay claims into a single winner per (kind,
--- targetWidget). Only active claims with a targetWidget participate
--- (malformed claims are skipped, never errored on). FRAME and BORDER resolve
--- independently. Higher priority wins; missing priority counts as 1; ties
--- break alphabetically by claim name. The result is order-independent, and
--- each winner is the exact claim table that was passed in (passthrough fields
--- intact).
--- @param claims table Array of claims: { name, priority, targetWidget, kind, active, ... }
--- @return table { FRAME = { [targetWidget] = winnerClaim }, BORDER = { ... } }
function OverlayLogic.ResolveTransformative(claims)
    local result = { FRAME = {}, BORDER = {} }
    for _, claim in ipairs(claims) do
        -- A claim without a targetWidget is malformed; skip it rather than
        -- writing to a nil table key in the per-frame hot path.
        if claim.active and claim.targetWidget ~= nil then
            local byTarget = result[claim.kind]
            if byTarget then
                local current = byTarget[claim.targetWidget]
                if current == nil or ClaimOutranks(claim, current) then
                    byTarget[claim.targetWidget] = claim
                end
            end
        end
    end
    return result
end
