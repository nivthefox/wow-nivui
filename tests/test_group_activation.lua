local _, assertions = ...
local assertEquals = assertions.equals

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function CreateHarness()
    local frames = {}
    local globals = {}
    local callbacks = {}
    local profileCallbacks = {}
    local groupSize = 0
    local inRaid = false
    local combat = false
    local showSolo = false
    local revision = 1
    local enabled = { party = true, raid10 = true, raid20 = true, raid40 = true }
    local assignments = { party = "Party", raid10 = "Raid", raid20 = "Raid", raid40 = "Raid-40" }
    local builds = {}
    local updates = {}

    local function CheckCombat()
        assert(not combat, "structural frame change during combat")
    end

    local function CreateFrame(_, name, parent)
        CheckCombat()
        local frame = { events = {}, scripts = {}, shown = true, parent = parent }
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterAllEvents() self.events = {} end
        function frame:SetScript(event, fn) self.scripts[event] = fn end
        function frame:SetSize(width, height)
            CheckCombat()
            self.width, self.height = width, height
        end
        function frame:GetWidth() return self.width end
        function frame:GetHeight() return self.height end
        function frame:SetPoint() CheckCombat() end
        function frame:ClearAllPoints() CheckCombat() end
        function frame:SetAttribute() CheckCombat() end
        function frame:RegisterForClicks() end
        function frame:SetParent(value) CheckCombat(); self.parent = value end
        function frame:Show() CheckCombat(); self.shown = true end
        function frame:Hide() CheckCombat(); self.shown = false end
        function frame:IsShown() return self.shown end
        frames[#frames + 1] = frame
        if name then globals[name] = frame end
        return frame
    end

    local function UnitExists(unit)
        if unit == "player" then return true end
        local prefix, index = unit:match("^(%a+)(%d+)$")
        index = tonumber(index)
        if prefix == "raid" then return inRaid and index <= groupSize end
        return prefix == "party" and not inRaid and index < groupSize
    end

    local Base = {}
    function Base.CreateWidgets(_, _, unit, options)
        CheckCombat()
        local frameType = options.frameType
        builds[frameType] = (builds[frameType] or 0) + 1
        return { overlay = { revision = revision, unit = unit } }
    end
    function Base.ApplyAnchors() end
    function Base.RegisterStandardEvents() end
    function Base.HandleEvent() end
    function Base.UpdateAllWidgets(state)
        updates[state.frameType] = (updates[state.frameType] or 0) + 1
    end
    function Base.UpdateStatusIndicators() end
    function Base.UpdateStatusText() end
    function Base.SetSecureVisibility(frame, visible)
        if visible then frame:Show() else frame:Hide() end
    end

    local customGroups = {
        healers = { enabled = true, filterType = "role", roles = { healer = true },
            excludePlayer = true, styleName = "Raid" },
    }
    local NivUI = {
        UnitFrames = { Base = Base },
        Roster = { GetRole = function() return "HEALER" end },
        EditMode = {
            IsActive = function() return false end,
            ApplyPosition = function() return true end,
            CreateSelectionFrame = function() end,
            RegisterVisibilityDriver = function() end,
            UnregisterVisibilityDriver = function() end,
        },
    }
    function NivUI:RegisterCallback(event, fn)
        callbacks[event] = callbacks[event] or {}
        table.insert(callbacks[event], fn)
    end
    function NivUI:RegisterProfileApplyCallback(name, fn) profileCallbacks[name] = fn end
    function NivUI:TriggerEvent(event, data)
        for _, fn in ipairs(callbacks[event] or {}) do fn(data) end
    end
    function NivUI:IsFrameEnabled(frameType) return enabled[frameType] end
    function NivUI:GetAssignment(frameType) return assignments[frameType] end
    function NivUI:GetStyleWithDefaults() return { frame = { width = 80, height = 40 } } end
    function NivUI:GetVisibilityOverride() return "[combat] show; hide" end
    function NivUI:DoesPartyIncludePlayer() return true end
    function NivUI:DoesPartyShowWhenSolo() return showSolo end
    function NivUI:GetPartySortMode() return "INDEX" end
    function NivUI:GetPartyOrientation() return "VERTICAL" end
    function NivUI:GetPartyGrowthDirection() return "DOWN" end
    function NivUI:GetPartySpacing() return 2 end
    function NivUI:GetRaidSortMode() return "GROUP" end
    function NivUI:GetRaidGroupOrientation() return "HORIZONTAL" end
    function NivUI:GetRaidGroupGrowthDirection() return "RIGHT" end
    function NivUI:GetRaidPlayerGrowthDirection() return "DOWN" end
    function NivUI:GetRaidSpacing() return 2 end
    function NivUI:GetCustomRaidGroups() return customGroups end
    function NivUI:GetCustomRaidGroup(id) return customGroups[id] end

    local environment = setmetatable({
        _G = globals,
        CreateFrame = CreateFrame,
        UIParent = CreateFrame(),
        IsInGroup = function() return groupSize > 0 end,
        IsInRaid = function() return inRaid end,
        GetNumGroupMembers = function() return groupSize end,
        GetInstanceInfo = function() return nil, nil, 0 end,
        GetRaidRosterInfo = function(index) return "Member" .. index, nil, math.ceil(index / 5) end,
        UnitExists = UnitExists,
        UnitName = function(unit) return unit end,
        UnitIsUnit = function(unit, other) return unit == other or unit == "raid1" and other == "player" end,
        InCombatLockdown = function() return combat end,
        RegisterStateDriver = function() CheckCombat() end,
        UnregisterStateDriver = function() CheckCombat() end,
        issecretvalue = function() return false end,
        wipe = function(value) for key in pairs(value) do value[key] = nil end end,
    }, { __index = _G })
    for _, path in ipairs({ "UnitFrameLifecycle", "MultiUnitFrameBase", "PartyFrame", "RaidFrame", "CustomRaidGroup" }) do
        local chunk = assert(loadfile(addonRoot .. "/modules/unitframes/" .. path .. ".lua"))
        setfenv(chunk, environment)
        chunk("NivUI", NivUI)
    end

    local harness = { NivUI = NivUI, builds = builds, updates = updates, enabled = enabled }
    function harness:fire(event)
        local count = #frames
        for index = 1, count do
            local frame = frames[index]
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event) end
        end
    end
    function harness:setGroup(size, raid) groupSize, inRaid = size, raid or false end
    function harness:roster(size, raid)
        self:setGroup(size, raid)
        self:fire("GROUP_ROSTER_UPDATE")
    end
    function harness:setCombat(value) combat = value end
    function harness:edit(event, data)
        revision = revision + 1
        NivUI:TriggerEvent(event or "OverlayModified", data)
    end
    function harness:resetCounts()
        for key in pairs(builds) do builds[key] = nil end
        for key in pairs(updates) do updates[key] = nil end
    end
    function harness:showSolo(value)
        showSolo = value
        NivUI:TriggerEvent("PartySettingsChanged", { setting = "showWhenSolo" })
    end
    function harness:applyProfile()
        for _, fn in pairs(profileCallbacks) do fn() end
    end
    function harness:revision() return revision end
    return harness
end

local function AssertBuilds(harness, party, raid10, raid20, raid40, custom)
    assertEquals(harness.builds.party or 0, party or 0, "party widget builds")
    assertEquals(harness.builds.raid10 or 0, raid10 or 0, "raid10 widget builds")
    assertEquals(harness.builds.raid20 or 0, raid20 or 0, "raid20 widget builds")
    assertEquals(harness.builds.raid40 or 0, raid40 or 0, "raid40 widget builds")
    assertEquals(harness.builds.customRaid_healers or 0, custom or 0, "custom group widget builds")
end

return {
    ["inactive group layouts skip every overlay and style invalidation"] = function()
        local harness = CreateHarness()
        harness:fire("PLAYER_LOGIN")
        harness:resetCounts()
        harness:edit("OverlayModified")
        harness:edit("OverlaysChanged", { name = "New Overlay" })
        harness:edit("CustomFiltersChanged", { name = "Test Filter" })
        harness:edit("StyleChanged", { styleName = "Party" })
        harness:edit("StyleChanged", { styleName = "Raid" })
        AssertBuilds(harness)
    end,
    ["party activation reads current settings once and reuses widgets for later joins"] = function()
        local harness = CreateHarness()
        harness:fire("PLAYER_LOGIN")
        harness:edit()
        harness:resetCounts()
        harness:roster(2)
        AssertBuilds(harness, 5, 0, 0, 0, 1)
        local player = harness.NivUI.UnitFrames.PartyFrame.GetState().memberFrames.player
        assertEquals(player.widgets.overlay.revision, harness:revision(), "activated overlay settings")
        local widgets = player.widgets
        harness:resetCounts()
        harness:roster(3)
        assertEquals(player.widgets, widgets, "existing party widgets survive a join")
        AssertBuilds(harness, 0, 0, 0, 0, 1)
        assertEquals(harness.updates.party > 0, true, "party data still updates")
    end,
    ["reactivating party frames rebuilds even without a configuration edit"] = function()
        local harness = CreateHarness()
        harness:setGroup(2)
        harness:fire("PLAYER_LOGIN")
        harness:roster(0)
        harness:resetCounts()
        harness:roster(2)
        AssertBuilds(harness, 5, 0, 0, 0, 1)
    end,
    ["raid activation and layout transitions rebuild only the selected layout"] = function()
        local harness = CreateHarness()
        harness:fire("PLAYER_LOGIN")
        harness:edit()
        harness:resetCounts()
        harness:roster(10, true)
        AssertBuilds(harness, 0, 10, 0, 0, 9)
        local raid10 = harness.NivUI.UnitFrames.RaidFrame.GetState("raid10")
        assertEquals(raid10.memberFrames.raid1.widgets.overlay.revision, harness:revision(), "raid settings")
        harness:resetCounts()
        harness:roster(11, true)
        AssertBuilds(harness, 0, 0, 20, 0, 1)
        harness:resetCounts()
        harness:roster(12, true)
        AssertBuilds(harness, 0, 0, 0, 0, 1)
        assertEquals(harness.updates.raid20 > 0, true, "raid data still updates")
        harness:resetCounts()
        harness:roster(21, true)
        AssertBuilds(harness, 0, 0, 0, 40, 9)
    end,
    ["active edits and style assignments leave inactive raid layouts untouched"] = function()
        local harness = CreateHarness()
        harness:setGroup(12, true)
        harness:fire("PLAYER_LOGIN")
        harness:resetCounts()
        harness:edit()
        AssertBuilds(harness, 0, 0, 20, 0, 11)
        harness:resetCounts()
        harness:edit("StyleChanged", { styleName = "Raid-40" })
        AssertBuilds(harness)
        harness:edit("AssignmentChanged", { frameType = "raid40" })
        AssertBuilds(harness)
    end,
    ["party preview rebuilds on activation and shows current edits"] = function()
        local harness = CreateHarness()
        harness:fire("PLAYER_LOGIN")
        harness:edit()
        harness:resetCounts()
        harness.NivUI.UnitFrames.PartyFrame.SetPreviewMode(true)
        AssertBuilds(harness, 5)
        harness:resetCounts()
        harness:edit()
        AssertBuilds(harness, 5)
        harness.NivUI.UnitFrames.PartyFrame.SetPreviewMode(false)
        harness:resetCounts()
        harness:edit()
        AssertBuilds(harness)
    end,
    ["raid preview rebuilds only the previewed layout"] = function()
        local harness = CreateHarness()
        harness:fire("PLAYER_LOGIN")
        harness:edit()
        harness:resetCounts()
        harness.NivUI.UnitFrames.RaidFrame.SetPreviewMode("raid40", true)
        AssertBuilds(harness, 0, 0, 0, 40)
        harness:resetCounts()
        harness:edit()
        AssertBuilds(harness, 0, 0, 0, 40)
        harness.NivUI.UnitFrames.RaidFrame.SetPreviewMode("raid40", false)
        harness:resetCounts()
        harness:edit()
        AssertBuilds(harness)
    end,
    ["showing party frames solo activates them even with a visibility override"] = function()
        local harness = CreateHarness()
        harness:fire("PLAYER_LOGIN")
        harness:edit()
        harness:resetCounts()
        harness:showSolo(true)
        AssertBuilds(harness, 5)
        harness:resetCounts()
        harness:edit()
        AssertBuilds(harness, 5)
        harness:showSolo(false)
        harness:resetCounts()
        harness:edit()
        AssertBuilds(harness)
    end,
    ["activation during combat rebuilds once after combat ends"] = function()
        for _, raid in ipairs({ false, true }) do
            local harness = CreateHarness()
            harness:fire("PLAYER_LOGIN")
            harness:edit()
            harness:resetCounts()
            harness:setCombat(true)
            harness:roster(2, raid)
            AssertBuilds(harness)
            harness:setCombat(false)
            harness:fire("PLAYER_REGEN_ENABLED")
            if raid then AssertBuilds(harness, 0, 10, 0, 0, 1)
            else AssertBuilds(harness, 5, 0, 0, 0, 1) end
            harness:resetCounts()
            harness:fire("PLAYER_REGEN_ENABLED")
            AssertBuilds(harness)
        end
    end,
    ["inactive profile changes take effect on the next activation"] = function()
        local harness = CreateHarness()
        harness:fire("PLAYER_LOGIN")
        harness:edit()
        harness:applyProfile()
        harness:resetCounts()
        harness:roster(2)
        AssertBuilds(harness, 5, 0, 0, 0, 1)
        local player = harness.NivUI.UnitFrames.PartyFrame.GetState().memberFrames.player
        assertEquals(player.widgets.overlay.revision, harness:revision(), "profile activation settings")
    end,
    ["profile re-enabling inactive groups preserves their next activation"] = function()
        local harness = CreateHarness()
        harness:fire("PLAYER_LOGIN")
        local customGroups = harness.NivUI:GetCustomRaidGroups()
        for frameType in pairs(harness.enabled) do harness.enabled[frameType] = false end
        customGroups.healers.enabled = false
        harness:applyProfile()
        for frameType in pairs(harness.enabled) do harness.enabled[frameType] = true end
        customGroups.healers.enabled = true
        harness:applyProfile()
        harness:resetCounts()
        harness:roster(2)
        AssertBuilds(harness, 5, 0, 0, 0, 1)
    end,
    ["leaving and rejoining during combat still rebuilds at combat end"] = function()
        local harness = CreateHarness()
        harness:setGroup(2, true)
        harness:fire("PLAYER_LOGIN")
        harness:resetCounts()
        harness:setCombat(true)
        harness:roster(0)
        harness:roster(2, true)
        AssertBuilds(harness)
        harness:setCombat(false)
        harness:fire("PLAYER_REGEN_ENABLED")
        AssertBuilds(harness, 0, 10, 0, 0, 1)
    end,
    ["world and zone events do not rebuild an already active layout"] = function()
        for _, raid in ipairs({ false, true }) do
            local harness = CreateHarness()
            harness:setGroup(2, raid)
            harness:fire("PLAYER_LOGIN")
            harness:resetCounts()
            harness:fire("PLAYER_ENTERING_WORLD")
            harness:fire("ZONE_CHANGED_NEW_AREA")
            AssertBuilds(harness)
        end
    end,
}
