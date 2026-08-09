local _, assertions = ...
local assertEquals = assertions.equals
local assertTrue = assertions.isTrue
local assertNil = assertions.isNil

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function loadChunk(path, environment, ...)
    local chunk, loadError = loadfile(path)
    if not chunk then
        error(loadError, 0)
    end
    setfenv(chunk, environment)
    return chunk(...)
end

local function createProfile()
    return {
        customFilters = {
            Important = { spells = {} },
        },
        overlays = {
            Glow = {
                allow = { Important = true },
                block = { Important = true },
            },
            Other = {
                allow = { Important = true },
                block = {},
            },
        },
        unitFrameStyles = {
            Alpha = { overlays = { Glow = true } },
            Beta = { overlays = { Glow = true } },
            Gamma = { overlays = {} },
        },
        unitFrameAssignments = {
            focus = "Beta",
            player = "Beta",
        },
        customRaidGroups = {
            first = { styleName = "Beta" },
            second = { styleName = "Beta" },
        },
    }
end

local function createHarness()
    local profile = createProfile()
    local database = {
        profiles = {
            Default = profile,
            Secondary = createProfile(),
        },
        charMeta = {
            ["One-Realm"] = { specProfileMap = { [71] = "Secondary" } },
            ["Two-Realm"] = { specProfileMap = { [65] = "Secondary" } },
        },
    }
    local shownPopup
    local registeredPopups = {}
    local NivUI = {}

    function NivUI:GetActiveProfile()
        return profile
    end

    function NivUI:RegisterConfigPopup(name)
        registeredPopups[name] = true
    end

    function NivUI:TriggerEvent()
    end

    local environment = setmetatable({
        NivUI_DB = database,
        StaticPopupDialogs = {},
        StaticPopup_Show = function(name, firstText, secondText, data)
            shownPopup = {
                name = name,
                firstText = firstText,
                secondText = secondText,
                data = data,
            }
            return shownPopup
        end,
        strtrim = function(value)
            return value:match("^%s*(.-)%s*$")
        end,
    }, { __index = _G })

    loadChunk(addonRoot .. "/modules/ReferenceIntegrity.lua", environment, "NivUI", NivUI)
    loadChunk(addonRoot .. "/modules/filters/SpellFilters.lua", environment, "NivUI", NivUI)
    loadChunk(addonRoot .. "/modules/overlays/Overlays.lua", environment, "NivUI", NivUI)
    loadChunk(addonRoot .. "/modules/config/Deletion.lua", environment, "NivUI", NivUI)
    loadChunk(addonRoot .. "/config/Filters.lua", environment, "NivUI", NivUI)
    loadChunk(addonRoot .. "/config/Overlays.lua", environment, "NivUI", NivUI)

    return {
        database = database,
        environment = environment,
        isPopupRegistered = function(name)
            return registeredPopups[name] == true
        end,
        getShownPopup = function()
            return shownPopup
        end,
        NivUI = NivUI,
        profile = profile,
    }
end

return {
    ["canceling a deletion leaves the object and its references untouched"] = function()
        local harness = createHarness()
        local profile = harness.profile
        local shown = harness.NivUI.Config.Filters.RequestDelete("Important")

        assertTrue(shown)
        assertTrue(profile.customFilters.Important ~= nil)
        assertEquals(profile.overlays.Glow.allow.Important, true)
        assertEquals(profile.overlays.Glow.block.Important, true)
        assertEquals(profile.overlays.Other.allow.Important, true)

        local request = harness.getShownPopup()
        local popup = harness.environment.StaticPopupDialogs[request.name]
        popup.OnAccept(nil, request.data)

        assertNil(profile.customFilters.Important)
        assertNil(profile.overlays.Glow.allow.Important)
        assertNil(profile.overlays.Glow.block.Important)
        assertNil(profile.overlays.Other.allow.Important)
    end,

    ["overlay deletion waits for confirmation before changing style references"] = function()
        local harness = createHarness()
        local profile = harness.profile

        local shown = harness.NivUI.Config.Overlays.RequestDelete("Glow")

        assertTrue(shown)
        assertTrue(profile.overlays.Glow ~= nil)
        assertEquals(profile.unitFrameStyles.Alpha.overlays.Glow, true)
        assertEquals(profile.unitFrameStyles.Beta.overlays.Glow, true)

        local request = harness.getShownPopup()
        local popup = harness.environment.StaticPopupDialogs[request.name]
        popup.OnAccept(nil, request.data)

        assertNil(profile.overlays.Glow)
        assertNil(profile.unitFrameStyles.Alpha.overlays.Glow)
        assertNil(profile.unitFrameStyles.Beta.overlays.Glow)
    end,

    ["confirmation text identifies every affected reference category"] = function()
        local harness = createHarness()
        local deletion = harness.NivUI.ConfigDeletion

        assertEquals(deletion.DescribeProfile(harness.database, "Secondary"),
            "This also clears specialization mappings: One-Realm (spec 71), Two-Realm (spec 65).")
        assertEquals(deletion.DescribeStyle(harness.profile, "Beta"),
            "This also reassigns these references to style 'Alpha': unit frames: focus, player; custom raid groups: first, second.")
        assertEquals(deletion.DescribeFilter(harness.profile, "Important"),
            "This also removes the filter from overlays: Glow, Other.")
        assertEquals(deletion.DescribeOverlay(harness.profile, "Glow"),
            "This also removes the overlay from styles: Alpha, Beta.")
    end,

    ["the shared confirmation applies the irreversible deletion policy"] = function()
        local harness = createHarness()

        harness.NivUI.ConfigDeletion.Request("overlay", "Glow", "Affected styles", function()
        end)

        local request = harness.getShownPopup()
        local popup = harness.environment.StaticPopupDialogs[request.name]
        local text = string.format(popup.text, request.firstText, request.secondText)

        assertTrue(harness.isPopupRegistered("NIVUI_CONFIRM_DELETE"))
        assertEquals(request.name, "NIVUI_CONFIRM_DELETE")
        assertEquals(popup.button1, "Delete")
        assertEquals(popup.button2, "Cancel")
        assertTrue(text:find("Delete overlay 'Glow'?", 1, true) ~= nil)
        assertTrue(text:find("This cannot be undone.", 1, true) ~= nil)
        assertTrue(text:find("Affected styles", 1, true) ~= nil)
    end,
}
