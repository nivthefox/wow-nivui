--- Overlays: user-defined aura-driven visuals applied to unit-frame styles. Depending on
--- its display type, an overlay renders matching auras as an icon grid, a colored-cell
--- grid, a target widget's bar tint, or a border around a target widget. Each overlay
--- carries its own display, layout, and filter config and scans either buffs (HELPFUL)
--- or debuffs (HARMFUL). Overlays are profile-scoped under NivUI.current.overlays; a
--- style references them by name via style.overlays. Editing an overlay lives in the
--- Custom Overlays tab.
NivUI = NivUI or {}
NivUI.Overlays = NivUI.Overlays or {}

local Overlays = NivUI.Overlays

Overlays.DEFAULTS = {
    auraType = "HELPFUL",
    iconSize = 20,
    spacing = 2,
    perRow = 8,
    maxIcons = 16,
    growth = "RIGHT",
    showDuration = true,
    showSwipe = true,
    showStacks = true,
    duration = { font = "Friz Quadrata", fontSize = 12, fontOutline = "OUTLINE", color = { r = 1, g = 1, b = 1, a = 1 } },
    stacks = { font = "Friz Quadrata", fontSize = 12, fontOutline = "OUTLINE", color = { r = 1, g = 1, b = 1, a = 1 } },
    strata = "MEDIUM",
    frameLevel = 5,
    displayType = "ICON",
    priority = 1,
    color = { r = 1, g = 0, b = 0, a = 1 },
    targetWidget = "healthBar",
    borderThickness = 2,
    anchor = { point = "BOTTOMLEFT", relativeTo = "frame", relativePoint = "TOPLEFT", x = 0, y = 4 },
    allow = {},
    block = {},
}

--- Config schema for an overlay's settings tabs, consumed by the shared settings panel.
--- The overlay's Display Type drives an adaptive UI: additive types (Icon/Color)
--- expose grid, layout, and display settings, while transformative types
--- (Frame/Border) expose a target widget and a fixed color instead. Entry- and
--- tab-level showIf conditions are evaluated by OverlayLogic.EvaluateCondition.
local ADDITIVE_TYPES = { "ICON", "COLOR" }
local COLORABLE_TYPES = { "COLOR", "FRAME", "BORDER" }
local TARGETED_TYPES = { "FRAME", "BORDER" }
local STRATA_TYPES = { "ICON", "COLOR", "BORDER" }

Overlays.CONFIG = {
    {
        label = "General",
        entries = {
            { kind = "dropdown", key = "displayType", label = "Display Type", options = "OVERLAY_DISPLAY_TYPES" },
            { kind = "dropdown", key = "auraType", label = "Aura Type", options = "AURA_TYPE" },
            { kind = "numericInput", key = "priority", label = "Priority", min = 1 },
            { kind = "colorPicker", key = "color", label = "Color", hasAlpha = true, showIf = { key = "displayType", anyOf = COLORABLE_TYPES } },
            { kind = "dropdown", key = "targetWidget", label = "Target Widget", options = "OVERLAY_TARGET_WIDGETS", showIf = { key = "displayType", anyOf = TARGETED_TYPES } },
            { kind = "slider", key = "borderThickness", label = "Border Thickness", min = 1, max = 16, step = 1, showIf = { key = "displayType", value = "BORDER" } },
            { kind = "slider", key = "iconSize", label = "Icon Size", min = 12, max = 40, step = 1, showIf = { key = "displayType", anyOf = ADDITIVE_TYPES } },
            { kind = "slider", key = "spacing", label = "Spacing", min = 0, max = 8, step = 1, showIf = { key = "displayType", anyOf = ADDITIVE_TYPES } },
            { kind = "dropdown", key = "anchor.relativeTo", label = "Anchored To", options = "WIDGET_PARENTS", showIf = { key = "displayType", anyOf = ADDITIVE_TYPES } },
            { kind = "dropdown", key = "anchor.point", label = "Point", options = "ANCHOR_POINTS", showIf = { key = "displayType", anyOf = ADDITIVE_TYPES } },
            { kind = "dropdown", key = "anchor.relativePoint", label = "Attach To", options = "ANCHOR_POINTS", showIf = { key = "displayType", anyOf = ADDITIVE_TYPES } },
            { kind = "slider", key = "anchor.x", label = "X Offset", min = -200, max = 200, step = 1, showIf = { key = "displayType", anyOf = ADDITIVE_TYPES } },
            { kind = "slider", key = "anchor.y", label = "Y Offset", min = -200, max = 200, step = 1, showIf = { key = "displayType", anyOf = ADDITIVE_TYPES } },
            { kind = "dropdown", key = "strata", label = "Frame Strata", options = "FRAME_STRATA", showIf = { key = "displayType", anyOf = STRATA_TYPES } },
            { kind = "slider", key = "frameLevel", label = "Frame Level", min = 1, max = 100, step = 1, showIf = { key = "displayType", anyOf = STRATA_TYPES } },
        },
    },
    {
        label = "Layout",
        showIf = { key = "displayType", anyOf = ADDITIVE_TYPES },
        entries = {
            { kind = "slider", key = "perRow", label = "Icons Per Row", min = 1, max = 16, step = 1 },
            { kind = "slider", key = "maxIcons", label = "Max Icons", min = 1, max = 40, step = 1 },
            { kind = "dropdown", key = "growth", label = "Growth Direction", options = "AURA_GROWTH" },
        },
    },
    {
        label = "Display",
        showIf = { key = "displayType", anyOf = ADDITIVE_TYPES },
        entries = {
            { kind = "checkbox", key = "showDuration", label = "Show Duration" },
            { kind = "checkbox", key = "showSwipe", label = "Show Duration Swipe" },
            { kind = "fontDropdown", key = "duration.font", label = "Duration Font", showIf = { key = "showDuration", value = true } },
            { kind = "slider", key = "duration.fontSize", label = "Duration Size", min = 6, max = 24, step = 1, showIf = { key = "showDuration", value = true } },
            { kind = "dropdown", key = "duration.fontOutline", label = "Duration Outline", options = "FONT_OUTLINES", showIf = { key = "showDuration", value = true } },
            { kind = "colorPicker", key = "duration.color", label = "Duration Color", hasAlpha = true, showIf = { key = "showDuration", value = true } },
            { kind = "checkbox", key = "showStacks", label = "Show Stacks" },
            { kind = "fontDropdown", key = "stacks.font", label = "Stacks Font", showIf = { key = "showStacks", value = true } },
            { kind = "slider", key = "stacks.fontSize", label = "Stacks Size", min = 6, max = 24, step = 1, showIf = { key = "showStacks", value = true } },
            { kind = "dropdown", key = "stacks.fontOutline", label = "Stacks Outline", options = "FONT_OUTLINES", showIf = { key = "showStacks", value = true } },
            { kind = "colorPicker", key = "stacks.color", label = "Stacks Color", hasAlpha = true, showIf = { key = "showStacks", value = true } },
        },
    },
    {
        label = "Filter",
        entries = {
            { kind = "filterMatrix" },
        },
    },
}

local function GetStore()
    local profile = NivUI.current
    if not profile then return nil end
    profile.overlays = profile.overlays or {}
    return profile.overlays
end

--- @return table Sorted array of overlay names
function Overlays:GetNames()
    local store = GetStore()
    local names = {}
    if store then
        for name in pairs(store) do
            names[#names + 1] = name
        end
        table.sort(names)
    end
    return names
end

--- @return table|nil The overlay's normalized config table (the live profile table, or nil)
function Overlays:Get(name)
    local store = GetStore()
    local config = store and store[name] or nil
    if config then
        return NivUI.OverlayLogic.NormalizeOverlay(config, self.DEFAULTS)
    end
    return nil
end

--- @return boolean, string|nil True on success; false, error message otherwise
function Overlays:Create(name)
    name = type(name) == "string" and strtrim(name) or ""
    if name == "" then
        return false, "Name cannot be empty"
    end
    local store = GetStore()
    if not store then
        return false, "No active profile"
    end
    if store[name] then
        return false, "An overlay named '" .. name .. "' already exists"
    end
    store[name] = NivUI.DeepCopy(self.DEFAULTS)
    NivUI:TriggerEvent("OverlaysChanged", { name = name })
    return true
end

function Overlays:Delete(name)
    local store = GetStore()
    if store and store[name] then
        store[name] = nil
        NivUI:TriggerEvent("OverlaysChanged", { name = name, deleted = true })
    end
end
