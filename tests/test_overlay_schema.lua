local NivUI, assertions = ...
local assertEquals = assertions.equals
local assertTrue = assertions.isTrue
local assertNil = assertions.isNil
local assertNotNil = assertions.isNotNil
local assertTableEquals = assertions.tablesEqual

local Overlays = NivUI.Overlays
local UnitFrames = NivUI.UnitFrames

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function CreateFrameStub(_, _, initialParent)
    local frame = { scripts = {}, width = 600, height = 32, scroll = 0, parent = initialParent }
    for _, method in ipairs({ "ClearAllPoints", "SetAllPoints", "SetColorTexture", "SetPoint", "SetText" }) do
        frame[method] = function() end
    end
    function frame:CreateTexture() return CreateFrameStub() end
    function frame:GetWidth() return self.width end
    function frame:GetHeight() return self.height end
    function frame:SetWidth(width) self.width = width end
    function frame:SetHeight(height) self.height = height end
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    function frame:GetScript(name) return self.scripts[name] end
    function frame:Show() self.shown = true end
    function frame:Hide() self.shown = false end
    function frame:SetParent(parent) self.parent = parent end
    function frame:SetScrollChild(child) self.scrollChild = child end
    function frame:GetVerticalScroll() return self.scroll end
    function frame:SetVerticalScroll(scroll) self.scroll = scroll end
    return frame
end

local function CreateSettingsPanel(data)
    local namespace = { OverlayLogic = NivUI.OverlayLogic, TabLayout = NivUI.TabLayout }
    local environment = setmetatable({
        CreateFrame = CreateFrameStub,
        C_Timer = { After = function(_, callback) callback() end },
        PanelTemplates_TabResize = function() end,
        PanelTemplates_SelectTab = function() end,
        PanelTemplates_DeselectTab = function() end,
        wipe = function(value)
            for key in pairs(value) do value[key] = nil end
        end,
    }, { __index = _G })
    local chunk = assert(loadfile(addonRoot .. "/modules/config/SettingsPanel.lua"))
    setfenv(chunk, environment)
    chunk("NivUI", namespace)

    local panel = namespace.Config.SettingsPanel.Create(CreateFrameStub(), {
        getConfig = function() return Overlays.CONFIG end,
        getData = function() return data end,
    })
    function panel:CreateEntry(parent, entry)
        parent.entries = parent.entries or {}
        parent.entries[#parent.entries + 1] = entry
        return CreateFrameStub()
    end
    return panel
end

local function VisibleKeys(panel)
    local visible = {}
    local filterTabVisible = false
    for _, tabPanel in ipairs(panel.tabPanels) do
        for _, entry in ipairs(tabPanel.scrollChild.entries or {}) do
            if entry.kind == "filterMatrix" then
                filterTabVisible = true
            elseif entry.key then
                visible[entry.key] = true
            end
        end
    end
    return visible, filterTabVisible
end

local function CollectVisibleKeys(displayType)
    local data = {
        displayType = displayType,
        auraType = "HARMFUL",
        showDuration = true,
        showStacks = true,
    }
    local panel = CreateSettingsPanel(data)
    panel:BuildFor("Test Overlay")
    return VisibleKeys(panel)
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

local ICON_KEYS = {
    "auraType", "displayType", "mineOnly",
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
    "displayType", "auraType", "color", "targetWidget", "mineOnly",
}

local BORDER_KEYS = {
    "displayType", "auraType", "color", "targetWidget", "mineOnly",
    "borderThickness", "strata", "frameLevel",
}

return {
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

    ["Filter tab is visible for all four display types"] = function()
        for _, displayType in ipairs({ "ICON", "COLOR", "FRAME", "BORDER" }) do
            local _, filterVisible = CollectVisibleKeys(displayType)
            assertTrue(filterVisible, "Filter tab must be visible for " .. displayType)
        end
    end,

    ["Filter tab exposes Mine Only before the matrix"] = function()
        for _, tab in ipairs(Overlays.CONFIG) do
            if tab.label == "Filter" then
                assertEquals(tab.entries[1].kind, "checkbox")
                assertEquals(tab.entries[1].key, "mineOnly")
                assertEquals(tab.entries[1].label, "Mine Only")
                assertEquals(tab.entries[2].kind, "filterMatrix")
                return
            end
        end
        error("Filter tab not found")
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

    ["rebuilding settings follows duration and stack toggles and hides old panels"] = function()
        local data = { displayType = "ICON", showDuration = false, showStacks = false }
        local panel = CreateSettingsPanel(data)
        panel:BuildFor("Test Overlay")
        local visible = VisibleKeys(panel)
        assertNil(visible["duration.font"])
        assertNil(visible["stacks.font"])

        data.showDuration = true
        panel:BuildFor("Test Overlay")
        visible = VisibleKeys(panel)
        assertTrue(visible["duration.font"])
        assertNil(visible["stacks.font"])

        data.showStacks = true
        panel:BuildFor("Test Overlay")
        visible = VisibleKeys(panel)
        assertTrue(visible["duration.font"])
        assertTrue(visible["stacks.font"])
        local oldPanels = { unpack(panel.tabPanels) }
        panel:SelectTab(#panel.tabPanels)

        data.displayType = "FRAME"
        panel:BuildFor("Test Overlay")
        visible = VisibleKeys(panel)
        assertNil(visible["duration.font"])
        assertNil(visible["stacks.font"])
        assertNil(visible.perRow)
        assertTrue(visible.targetWidget)
        for _, oldPanel in ipairs(oldPanels) do
            assertEquals(oldPanel.shown, false, "old panel hidden after rebuild")
            assertNil(oldPanel.parent, "old panel detached after rebuild")
        end
    end,
}
