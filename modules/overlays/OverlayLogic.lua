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
    config.wrap = OverlayLogic.NormalizeWrap(config.growth, config.wrap)
    return config
end

--- The set of growth directions that grow along a vertical axis. Any value not
--- in this set (including nil and unknown strings) is treated as horizontal.
local VERTICAL_GROWTH = {
    UP = true,
    DOWN = true,
}

--- Valid perpendicular wrap members per orientation. Horizontal growth wraps
--- vertically (DOWN/UP); vertical growth wraps horizontally (RIGHT/LEFT). Used
--- by NormalizeWrap to decide whether a saved wrap is coherent with its growth.
local VALID_WRAP = {
    horizontal = { DOWN = true, UP = true },
    vertical = { RIGHT = true, LEFT = true },
}

--- Origin corner per (effective growth, effective wrap) pair. All icons share
--- this single corner; each icon's { x, y } is a signed offset from it. The
--- corner sits opposite both the growth and wrap directions so the grid grows
--- into the frame from that corner.
local ORIGIN_CORNER = {
    RIGHT = { DOWN = "TOPLEFT", UP = "BOTTOMLEFT" },
    LEFT = { DOWN = "TOPRIGHT", UP = "BOTTOMRIGHT" },
    UP = { RIGHT = "BOTTOMLEFT", LEFT = "BOTTOMRIGHT" },
    DOWN = { RIGHT = "TOPLEFT", LEFT = "TOPRIGHT" },
}

--- Reports whether a growth direction grows vertically (UP or DOWN). nil and
--- unknown strings are horizontal, hence false.
--- @param growth string|nil The overlay's growth value
--- @return boolean True for UP/DOWN, false otherwise
function OverlayLogic.IsVerticalGrowth(growth)
    return VERTICAL_GROWTH[growth] == true
end

--- Returns the default wrap for a growth direction: "RIGHT" for vertical growth,
--- "DOWN" for horizontal (or unknown/nil) growth.
--- @param growth string|nil The overlay's growth value
--- @return string "RIGHT" if vertical else "DOWN"
function OverlayLogic.DefaultWrapFor(growth)
    if OverlayLogic.IsVerticalGrowth(growth) then
        return "RIGHT"
    end
    return "DOWN"
end

--- Normalizes a wrap direction against its growth. A wrap that is a valid
--- perpendicular member of the growth's orientation is preserved; anything else
--- (nil, an out-of-orientation value, or garbage) falls to DefaultWrapFor.
--- Unknown growth is treated as horizontal.
--- @param growth string|nil The overlay's growth value
--- @param wrap string|nil The overlay's saved wrap value
--- @return string A wrap valid for the growth's orientation
function OverlayLogic.NormalizeWrap(growth, wrap)
    local orientation = OverlayLogic.IsVerticalGrowth(growth) and "vertical" or "horizontal"
    if VALID_WRAP[orientation][wrap] then
        return wrap
    end
    return OverlayLogic.DefaultWrapFor(growth)
end

--- Computes the grid layout for an additive overlay: a single origin corner plus
--- a signed { x, y } offset per icon, with icon 1 always at { 0, 0 }. The
--- container is sized to a SINGLE icon slot (width == height == iconSize): the
--- user's anchor settings position the container, and because icon 1 is
--- congruent with it, they pin icon 1 directly. Icons 2..N flow along the
--- growth axis (wrapping in the perpendicular wrap direction every perLine
--- icons) and extend beyond the container's rect by design. The model is total
--- over any input (unknown growth behaves as RIGHT; invalid/nil wrap falls to
--- the orientation default).
--- @param params table { growth, wrap, perLine, maxIcons, iconSize, spacing }
--- @return table { width, height, anchor, icons = { [i] = { x = n, y = n } } }
function OverlayLogic.ComputeGridLayout(params)
    local growth = params.growth
    if not ORIGIN_CORNER[growth] then
        growth = "RIGHT"
    end
    local wrap = OverlayLogic.NormalizeWrap(growth, params.wrap)

    local perLine = params.perLine
    local maxIcons = params.maxIcons
    local step = params.iconSize + params.spacing
    local vertical = OverlayLogic.IsVerticalGrowth(growth)

    local anchor = ORIGIN_CORNER[growth][wrap]
    -- x grows positive from LEFT corners, negative from RIGHT corners; y grows
    -- positive from BOTTOM corners, negative from TOP corners.
    local xSign = anchor:find("RIGHT") and -1 or 1
    local ySign = anchor:find("BOTTOM") and 1 or -1

    local icons = {}
    for i = 1, maxIcons do
        local line = math.floor((i - 1) / perLine)
        local pos = (i - 1) % perLine
        local along = pos * step
        local across = line * step
        local x, y
        if vertical then
            x = across
            y = along
        else
            x = along
            y = across
        end
        icons[i] = { x = xSign * x, y = ySign * y }
    end

    return { width = params.iconSize, height = params.iconSize, anchor = anchor, icons = icons }
end

--- Maps a growth direction to its flow-layout primary axis token.
local FLOW_AXIS = {
    RIGHT = "Horizontal",
    LEFT = "Horizontal",
    UP = "Vertical",
    DOWN = "Vertical",
}

--- Computes the 12.1 AuraContainer flow-layout parameters for an additive
--- overlay: axis, growth direction tokens, origin anchor point, and the
--- pixel-based maximum line size that reproduces perLine wrapping. Direction
--- values are string tokens ("Horizontal", "Right", ...) so this module stays
--- WoW-free; the widget factory maps them onto AnchorUtil enums. Inputs are
--- normalized exactly as ComputeGridLayout does (unknown growth behaves as
--- RIGHT; invalid/nil wrap falls to the orientation default).
--- @param params table { growth, wrap, perLine, iconSize, spacing }
--- @return table { axis, horizontal, vertical, anchorPoint, maximumLineSize }
function OverlayLogic.ComputeContainerLayout(params)
    local growth = params.growth
    if not ORIGIN_CORNER[growth] then
        growth = "RIGHT"
    end
    local wrap = OverlayLogic.NormalizeWrap(growth, params.wrap)
    local vertical = OverlayLogic.IsVerticalGrowth(growth)

    local horizontal, verticalDir
    if vertical then
        horizontal = (wrap == "LEFT") and "Left" or "Right"
        verticalDir = (growth == "UP") and "Up" or "Down"
    else
        horizontal = (growth == "LEFT") and "Left" or "Right"
        verticalDir = (wrap == "UP") and "Up" or "Down"
    end

    return {
        axis = FLOW_AXIS[growth],
        horizontal = horizontal,
        vertical = verticalDir,
        anchorPoint = ORIGIN_CORNER[growth][wrap],
        maximumLineSize = params.perLine * params.iconSize + (params.perLine - 1) * params.spacing,
    }
end

--- Offset of a point name along one axis of a size-`s` rect, measured from the
--- rect's center (x: LEFT/RIGHT negative/positive; y: BOTTOM/TOP negative/positive).
local function PointOffset(point, axisA, axisB, s)
    if point:find(axisA) then
        return -s / 2
    elseif point:find(axisB) then
        return s / 2
    end
    return 0
end

--- Translates a user anchor config into the equivalent anchor for an
--- AuraContainer. The legacy widget was a single-icon rect whose configured
--- point pinned icon 1; the container instead spans the whole (secret-sized)
--- grid growing from its flow origin corner. Anchoring the container BY that
--- corner, shifted by the fixed point-to-corner delta on a one-icon rect,
--- keeps icon 1 exactly where the legacy layout put it. Never mutates the
--- input anchor table.
--- @param anchor table The user anchor config { point, relativeTo, relativePoint, x, y }
--- @param originCorner string The flow origin corner (e.g. "TOPLEFT")
--- @param iconSize number The overlay's icon size
--- @return table { point, relativeTo, relativePoint, x, y }
function OverlayLogic.TranslateContainerAnchor(anchor, originCorner, iconSize)
    local point = anchor.point or "CENTER"
    local dx = PointOffset(originCorner, "LEFT", "RIGHT", iconSize) - PointOffset(point, "LEFT", "RIGHT", iconSize)
    local dy = PointOffset(originCorner, "BOTTOM", "TOP", iconSize) - PointOffset(point, "BOTTOM", "TOP", iconSize)
    return {
        point = originCorner,
        relativeTo = anchor.relativeTo,
        relativePoint = anchor.relativePoint or point,
        x = (anchor.x or 0) + dx,
        y = (anchor.y or 0) + dy,
    }
end

--- Merges an array of spellID sets into one include/exclude map, or nil when
--- there is nothing to merge (candidateFilters distinguishes nil from empty).
local function MergeSpellMaps(spellMaps)
    if #spellMaps == 0 then
        return nil
    end
    local merged = {}
    for _, spells in ipairs(spellMaps) do
        for spellID in pairs(spells) do
            merged[spellID] = true
        end
    end
    return merged
end

--- Translates a widget's allow/block filter inputs into AuraContainer group
--- descriptors, preserving 12.0 BuildSpec semantics: block filters veto (AND
--- NOT), allow filters are an OR, and an empty allow set shows everything.
--- Because a single group cannot OR builtin tokens with each other or with a
--- spell list, each allow builtin becomes its own group and all allow spell
--- lists share one spell-ID group. Known divergences from 12.0, accepted:
--- an aura matching several allow groups renders once per group (12.0 deduped),
--- and maxFrameCount caps each group rather than the total.
--- @param inputs table { prefix, allowTokens, blockTokens, allowSpellMaps, blockSpellMaps }
--- @return table Array of { filterString, includeSpellIDs, excludeSpellIDs }
function OverlayLogic.BuildContainerGroupSpecs(inputs)
    local base = inputs.prefix
    for _, token in ipairs(inputs.blockTokens) do
        base = base .. "|!" .. token
    end

    local excludeSpellIDs = MergeSpellMaps(inputs.blockSpellMaps)
    local specs = {}

    for _, token in ipairs(inputs.allowTokens) do
        specs[#specs + 1] = {
            filterString = base .. "|" .. token,
            excludeSpellIDs = excludeSpellIDs,
        }
    end

    local includeSpellIDs = MergeSpellMaps(inputs.allowSpellMaps)
    if includeSpellIDs then
        specs[#specs + 1] = {
            filterString = base,
            includeSpellIDs = includeSpellIDs,
            excludeSpellIDs = excludeSpellIDs,
        }
    end

    if #specs == 0 then
        specs[1] = {
            filterString = base,
            excludeSpellIDs = excludeSpellIDs,
        }
    end

    return specs
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
