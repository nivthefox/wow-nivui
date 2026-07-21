-- tests/test_overlay_schema.lua
-- Data-shape contract tests for the overlay schema after the Display Types
-- redesign: Overlays.CONFIG / Overlays.DEFAULTS and the NivUI.UnitFrames option
-- lists. Also verifies the adaptive visibility matrix from the design doc
-- (docs/overlay-display-types.html) by walking CONFIG per display type.

local Overlays = NivUI.Overlays
local UnitFrames = NivUI.UnitFrames

--------------------------------------------------------------------------------
-- Dot-path lookup into a data table (e.g. "duration.font").
--------------------------------------------------------------------------------

local function DeepGet(root, path)
    local node = root
    for segment in path:gmatch("[^.]+") do
        if type(node) ~= "table" then
            return nil
        end
        node = node[segment]
    end
    return node
end

--------------------------------------------------------------------------------
-- Evaluate a showIf/hideIf condition against a data table, resolving the
-- condition's key through the same dot-path lookup used for nested settings.
--------------------------------------------------------------------------------

local function ConditionPasses(cond, data)
    if not cond then
        return true
    end
    local value = DeepGet(data, cond.key)
    return NivUI.OverlayLogic.EvaluateCondition(cond, value)
end

--------------------------------------------------------------------------------
-- Walk every tab in Overlays.CONFIG for a given display type and collect the
-- set of visible entry keys. Keyless entries (e.g. the filter matrix) are
-- skipped for the key set but tracked so we can assert the Filter tab shows.
--------------------------------------------------------------------------------

local function CollectVisibleKeys(displayType)
    local data = {
        displayType = displayType,
        auraType = "HARMFUL",
        showDuration = true,
        showStacks = true,
    }

    local visible = {}
    local filterTabVisible = false

    for _, tab in ipairs(Overlays.CONFIG) do
        if ConditionPasses(tab.showIf, data) then
            for _, entry in ipairs(tab.entries) do
                if not entry.key and entry.kind == "filterMatrix" then
                    filterTabVisible = true
                elseif entry.key then
                    local showOk = ConditionPasses(entry.showIf, data)
                    local hideOk = true
                    if entry.hideIf then
                        hideOk = not NivUI.OverlayLogic.EvaluateCondition(
                            entry.hideIf, DeepGet(data, entry.hideIf.key))
                    end
                    if showOk and hideOk then
                        visible[entry.key] = true
                    end
                end
            end
        end
    end

    return visible, filterTabVisible
end

local function SortedKeys(set)
    local keys = {}
    for k in pairs(set) do
        keys[#keys + 1] = k
    end
    table.sort(keys)
    return keys
end

local function ExpectedSet(list)
    local set = {}
    for _, k in ipairs(list) do
        set[k] = true
    end
    return set
end

--------------------------------------------------------------------------------
-- Expected visible key sets per display type, from the design doc matrix.
--------------------------------------------------------------------------------

local ICON_KEYS = {
    "auraType", "priority", "displayType",
    "iconSize", "spacing",
    "anchor.point", "anchor.relativeTo", "anchor.relativePoint", "anchor.x", "anchor.y",
    "strata", "frameLevel",
    "perRow", "maxIcons", "growth", "wrap",
    "showDuration", "showSwipe", "showStacks",
    "duration.font", "duration.fontSize", "duration.fontOutline", "duration.color",
    "stacks.font", "stacks.fontSize", "stacks.fontOutline", "stacks.color",
}

local function WithColor(list)
    local copy = {}
    for _, k in ipairs(list) do
        copy[#copy + 1] = k
    end
    copy[#copy + 1] = "color"
    return copy
end

local COLOR_KEYS = WithColor(ICON_KEYS)

local FRAME_KEYS = {
    "displayType", "auraType", "priority", "color", "targetWidget",
}

local BORDER_KEYS = {
    "displayType", "auraType", "priority", "color", "targetWidget",
    "borderThickness", "strata", "frameLevel",
}

return {
    --------------------------------------------------------------------------
    -- Removed Dispellable feature
    --------------------------------------------------------------------------

    ["no Dispellable tab in CONFIG"] = function()
        for _, tab in ipairs(Overlays.CONFIG) do
            assertTrue(tab.label ~= "Dispellable", "CONFIG must not contain a Dispellable tab")
        end
    end,

    ["no dispelIndicator entry anywhere in CONFIG"] = function()
        for _, tab in ipairs(Overlays.CONFIG) do
            for _, entry in ipairs(tab.entries) do
                assertTrue(entry.key ~= "dispelIndicator",
                    "CONFIG must not contain a dispelIndicator entry")
            end
        end
    end,

    ["DEFAULTS.dispelIndicator is nil"] = function()
        assertNil(Overlays.DEFAULTS.dispelIndicator, "dispelIndicator removed from DEFAULTS")
    end,

    ["UnitFrames.DISPEL_INDICATOR is nil"] = function()
        assertNil(UnitFrames.DISPEL_INDICATOR, "DISPEL_INDICATOR option list removed")
    end,

    --------------------------------------------------------------------------
    -- New DEFAULTS fields
    --------------------------------------------------------------------------

    ["DEFAULTS has the five new fields with exact values"] = function()
        assertEquals(Overlays.DEFAULTS.displayType, "ICON", "displayType default")
        assertEquals(Overlays.DEFAULTS.priority, 1, "priority default")
        assertTableEquals(Overlays.DEFAULTS.color, { r = 1, g = 0, b = 0, a = 1 }, "color default")
        assertEquals(Overlays.DEFAULTS.targetWidget, "healthBar", "targetWidget default")
        assertEquals(Overlays.DEFAULTS.borderThickness, 2, "borderThickness default")
    end,

    --------------------------------------------------------------------------
    -- Option lists
    --------------------------------------------------------------------------

    ["OVERLAY_DISPLAY_TYPES is the ordered four-type list"] = function()
        assertTableEquals(UnitFrames.OVERLAY_DISPLAY_TYPES, {
            { value = "ICON", name = "Icon" },
            { value = "COLOR", name = "Color" },
            { value = "FRAME", name = "Frame" },
            { value = "BORDER", name = "Border" },
        }, "OVERLAY_DISPLAY_TYPES contents and order")
    end,

    ["GetOverlayTargetWidgetOptions first entry is Unit Frame"] = function()
        local options = UnitFrames:GetOverlayTargetWidgetOptions()
        assertNotNil(options, "GetOverlayTargetWidgetOptions should return a list")
        assertTableEquals(options[1], { value = "frame", name = "Unit Frame" },
            "first target widget option is the whole frame labeled 'Unit Frame'")
    end,

    ["GetOverlayTargetWidgetOptions contains healthBar"] = function()
        local options = UnitFrames:GetOverlayTargetWidgetOptions()
        local found = false
        for _, opt in ipairs(options) do
            if opt.value == "healthBar" then
                found = true
            end
        end
        assertTrue(found, "target widget options must include a healthBar entry")
    end,

    --------------------------------------------------------------------------
    -- Visibility matrix (Filter tab always visible)
    --------------------------------------------------------------------------

    ["Filter tab is visible for all four display types"] = function()
        for _, displayType in ipairs({ "ICON", "COLOR", "FRAME", "BORDER" }) do
            local _, filterVisible = CollectVisibleKeys(displayType)
            assertTrue(filterVisible, "Filter tab must be visible for " .. displayType)
        end
    end,

    ["ICON visible key set matches the spec matrix"] = function()
        local visible = CollectVisibleKeys("ICON")
        assertTableEquals(SortedKeys(visible), SortedKeys(ExpectedSet(ICON_KEYS)),
            "ICON visible keys")
    end,

    ["COLOR visible key set matches the spec matrix"] = function()
        local visible = CollectVisibleKeys("COLOR")
        assertTableEquals(SortedKeys(visible), SortedKeys(ExpectedSet(COLOR_KEYS)),
            "COLOR visible keys")
    end,

    ["FRAME visible key set matches the spec matrix"] = function()
        local visible = CollectVisibleKeys("FRAME")
        assertTableEquals(SortedKeys(visible), SortedKeys(ExpectedSet(FRAME_KEYS)),
            "FRAME visible keys")
    end,

    ["BORDER visible key set matches the spec matrix"] = function()
        local visible = CollectVisibleKeys("BORDER")
        assertTableEquals(SortedKeys(visible), SortedKeys(ExpectedSet(BORDER_KEYS)),
            "BORDER visible keys")
    end,

    --------------------------------------------------------------------------
    -- Wrap direction: new setting on the additive (Icon/Color) types only.
    --------------------------------------------------------------------------

    ["DEFAULTS.wrap is DOWN"] = function()
        assertEquals(Overlays.DEFAULTS.wrap, "DOWN", "wrap default is DOWN (horizontal default growth)")
    end,

    ["Layout tab has a wrap dropdown wired to OVERLAY_WRAP"] = function()
        local wrapEntry
        for _, tab in ipairs(Overlays.CONFIG) do
            if tab.label == "Layout" then
                for _, entry in ipairs(tab.entries) do
                    if entry.key == "wrap" then
                        wrapEntry = entry
                    end
                end
            end
        end
        assertNotNil(wrapEntry, "Layout tab must contain a wrap entry")
        assertEquals(wrapEntry.kind, "dropdown", "wrap entry is a dropdown")
        assertEquals(wrapEntry.options, "OVERLAY_WRAP", "wrap dropdown resolves the OVERLAY_WRAP option list")
    end,

    ["perRow label reads Icons Per Line"] = function()
        local perRowEntry
        for _, tab in ipairs(Overlays.CONFIG) do
            for _, entry in ipairs(tab.entries) do
                if entry.key == "perRow" then
                    perRowEntry = entry
                end
            end
        end
        assertNotNil(perRowEntry, "CONFIG must contain a perRow entry")
        assertEquals(perRowEntry.label, "Icons Per Line", "perRow label relabeled for either orientation")
    end,

    ["OVERLAY_WRAP_HORIZONTAL is the ordered Down/Up pair"] = function()
        assertTableEquals(UnitFrames.OVERLAY_WRAP_HORIZONTAL, {
            { value = "DOWN", name = "Down" },
            { value = "UP", name = "Up" },
        }, "OVERLAY_WRAP_HORIZONTAL contents and order (default Down first)")
    end,

    ["OVERLAY_WRAP_VERTICAL is the ordered Right/Left pair"] = function()
        assertTableEquals(UnitFrames.OVERLAY_WRAP_VERTICAL, {
            { value = "RIGHT", name = "Right" },
            { value = "LEFT", name = "Left" },
        }, "OVERLAY_WRAP_VERTICAL contents and order (default Right first)")
    end,
}
