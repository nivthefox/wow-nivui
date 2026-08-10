--- OverlayLogic: pure, WoW-free logic backing the Overlays system. Holds the
--- display-type classification, overlay normalization, container layout,
--- filter translation, and config-condition evaluation. Loads with only the
--- NivUI namespace bootstrap and touches no WoW API at load or runtime, so it
--- is unit-testable in a headless Lua runner. Keep it that way.
local _, NivUI = ...

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

--- The set of display types that are transformative (binary slots anchored to
--- a target widget) rather than additive (flow-layout groups).
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
--- Existing values are preserved. Legacy overlay keys are deleted.
--- Mutates and returns the same config table.
--- @param config table The overlay config to normalize (mutated in place)
--- @param defaults table The Overlays.DEFAULTS table to fill from
--- @return table The same config table, now normalized
function OverlayLogic.NormalizeOverlay(config, defaults)
    if type(config) ~= "table" then
        return nil
    end
    if type(defaults) ~= "table" then
        return config
    end

    for key, defaultValue in pairs(defaults) do
        if config[key] == nil then
            config[key] = DeepCopy(defaultValue)
        end
    end
    config.dispelIndicator = nil
    config.priority = nil
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
    if type(params) ~= "table" then
        return nil
    end

    local perLine = params.perLine
    local maxIcons = params.maxIcons
    local iconSize = params.iconSize
    local spacing = params.spacing
    if type(perLine) ~= "number" or perLine <= 0 then
        return nil
    end
    if type(maxIcons) ~= "number" or maxIcons <= 0 then
        return nil
    end
    if type(iconSize) ~= "number" or iconSize <= 0 then
        return nil
    end
    if type(spacing) ~= "number" or spacing < 0 then
        return nil
    end

    local growth = params.growth
    if not ORIGIN_CORNER[growth] then
        growth = "RIGHT"
    end
    local wrap = OverlayLogic.NormalizeWrap(growth, params.wrap)

    local step = iconSize + spacing
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

    return { width = iconSize, height = iconSize, anchor = anchor, icons = icons }
end

local FLOW_AXIS = {
    RIGHT = "Horizontal",
    LEFT = "Horizontal",
    UP = "Vertical",
    DOWN = "Vertical",
}

function OverlayLogic.ComputeContainerLayout(params)
    local growth = params.growth
    if not ORIGIN_CORNER[growth] then
        growth = "RIGHT"
    end
    local wrap = OverlayLogic.NormalizeWrap(growth, params.wrap)
    local vertical = OverlayLogic.IsVerticalGrowth(growth)

    local horizontal
    local verticalDirection
    if vertical then
        horizontal = wrap == "LEFT" and "Left" or "Right"
        verticalDirection = growth == "UP" and "Up" or "Down"
    else
        horizontal = growth == "LEFT" and "Left" or "Right"
        verticalDirection = wrap == "UP" and "Up" or "Down"
    end

    return {
        axis = FLOW_AXIS[growth],
        horizontal = horizontal,
        vertical = verticalDirection,
        anchorPoint = ORIGIN_CORNER[growth][wrap],
        maximumLineSize = params.perLine * params.iconSize + (params.perLine - 1) * params.spacing,
    }
end

local function PointOffset(point, firstDirection, secondDirection, size)
    if point:find(firstDirection) then
        return -size / 2
    end
    if point:find(secondDirection) then
        return size / 2
    end
    return 0
end

function OverlayLogic.TranslateContainerAnchor(anchor, originCorner, iconSize)
    local point = anchor.point or "CENTER"
    local x = PointOffset(originCorner, "LEFT", "RIGHT", iconSize)
        - PointOffset(point, "LEFT", "RIGHT", iconSize)
    local y = PointOffset(originCorner, "BOTTOM", "TOP", iconSize)
        - PointOffset(point, "BOTTOM", "TOP", iconSize)

    return {
        point = originCorner,
        relativeTo = anchor.relativeTo,
        relativePoint = anchor.relativePoint or point,
        x = (anchor.x or 0) + x,
        y = (anchor.y or 0) + y,
    }
end

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
    if type(cond) ~= "table" then
        return false
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
