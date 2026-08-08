local _, assertions = ...
local assertEquals = assertions.equals
local assertTrue = assertions.isTrue
local assertFalse = assertions.isFalse
local assertNil = assertions.isNil
local assertTableEquals = assertions.tablesEqual

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

local function createFrame()
    local frame = {
        events = {},
        scripts = {},
    }

    function frame:RegisterEvent(event)
        self.events[event] = true
    end

    function frame:SetScript(name, callback)
        self.scripts[name] = callback
    end

    return frame
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}
    for key, child in pairs(value) do
        result[key] = deepCopy(child)
    end
    return result
end

local function createHarness(database, activeProfileName)
    local events = {}
    local NivUI = {
        UnitFrames = {
            DEFAULT_STYLE = {
                frame = { width = 200, height = 60 },
            },
        },
        activeProfileName = activeProfileName or "Default",
    }

    function NivUI.DeepCopy(value)
        return deepCopy(value)
    end

    function NivUI:GetActiveProfile()
        return database.profiles[self.activeProfileName]
    end

    function NivUI:TriggerEvent(name, data)
        events[#events + 1] = { name = name, data = data }
    end

    function NivUI:InitializeDB()
        local profile = self:GetActiveProfile()
        profile.unitFrameStyles = profile.unitFrameStyles or {}
        profile.unitFrameAssignments = profile.unitFrameAssignments or {}
        return true
    end

    function NivUI:ApplyActiveProfile()
    end

    local environment = setmetatable({
        CreateFrame = createFrame,
        GetRealmName = function()
            return "Realm"
        end,
        GetSpecialization = function()
            return nil
        end,
        InCombatLockdown = function()
            return false
        end,
        NivUI_CurrentProfile = NivUI.activeProfileName,
        NivUI_DB = database,
        UnitName = function()
            return "Character"
        end,
        print = function()
        end,
        strtrim = function(value)
            return value:match("^%s*(.-)%s*$")
        end,
        time = function()
            return 1
        end,
    }, { __index = _G })

    local function load(relativePath)
        loadChunk(addonRoot .. "/" .. relativePath, environment, "NivUI", NivUI)
    end

    load("modules/ReferenceIntegrity.lua")
    load("modules/profiles/Profiles.lua")
    load("modules/filters/SpellFilters.lua")
    load("modules/overlays/OverlayLogic.lua")
    load("modules/overlays/Overlays.lua")
    load("modules/unitframes/StyleManager.lua")

    return {
        database = database,
        environment = environment,
        events = events,
        NivUI = NivUI,
    }
end

local function styleProfile()
    return {
        unitFrameStyles = {
            Alpha = { overlays = { Glow = true, Other = true } },
            Beta = { overlays = { Glow = true } },
            Gamma = { overlays = { Other = true } },
        },
        unitFrameAssignments = {
            player = "Beta",
            target = "Alpha",
            focus = "Beta",
        },
        customRaidGroups = {
            first = { name = "First", styleName = "Beta", enabled = true },
            second = { name = "Second", styleName = "Alpha", enabled = true },
            third = { name = "Third", styleName = "Beta", enabled = false },
        },
        customFilters = {
            Important = { spells = {} },
            Other = { spells = {} },
        },
        overlays = {
            Glow = {
                allow = { Important = true, PLAYER = true, Other = true },
                block = { Important = true, RAID = true },
            },
            Other = {
                allow = { Important = true },
                block = {},
            },
        },
    }
end

return {
    ["style rename cascades through standard and custom raid assignments"] = function()
        local profile = styleProfile()
        local harness = createHarness({ profiles = { Default = profile } })

        local success = harness.NivUI:RenameStyle("Beta", "Renamed")

        assertTrue(success)
        assertNil(profile.unitFrameStyles.Beta)
        assertEquals(profile.unitFrameStyles.Renamed.overlays.Glow, true)
        assertEquals(profile.unitFrameAssignments.player, "Renamed")
        assertEquals(profile.unitFrameAssignments.focus, "Renamed")
        assertEquals(profile.unitFrameAssignments.target, "Alpha")
        assertEquals(profile.customRaidGroups.first.styleName, "Renamed")
        assertEquals(profile.customRaidGroups.third.styleName, "Renamed")
        assertEquals(profile.customRaidGroups.second.styleName, "Alpha")
        assertTableEquals(harness.events[#harness.events].data.reassigned, { "focus", "player" })
        assertTableEquals(harness.events[#harness.events].data.customRaidGroups, { "first", "third" })
    end,

    ["style deletion uses a deterministic fallback and name reuse stays detached"] = function()
        local profile = styleProfile()
        local harness = createHarness({ profiles = { Default = profile } })

        local success = harness.NivUI:DeleteStyle("Beta")

        assertTrue(success)
        assertNil(profile.unitFrameStyles.Beta)
        assertEquals(profile.unitFrameAssignments.player, "Alpha")
        assertEquals(profile.unitFrameAssignments.focus, "Alpha")
        assertEquals(profile.customRaidGroups.first.styleName, "Alpha")
        assertEquals(profile.customRaidGroups.third.styleName, "Alpha")
        assertEquals(harness.events[#harness.events].data.fallback, "Alpha")
        assertTableEquals(harness.events[#harness.events].data.reassigned, { "focus", "player" })
        assertTableEquals(harness.events[#harness.events].data.customRaidGroups, { "first", "third" })

        assertTrue(harness.NivUI:CreateStyle("Beta"))
        assertEquals(profile.unitFrameAssignments.player, "Alpha")
        assertEquals(profile.customRaidGroups.first.styleName, "Alpha")
    end,

    ["profile rename and deletion maintain every character specialization mapping"] = function()
        local database = {
            profiles = {
                Default = styleProfile(),
                Alpha = styleProfile(),
                Beta = styleProfile(),
            },
            charMeta = {
                ["One-Realm"] = { specProfileMap = { [71] = "Beta", [72] = "Alpha" } },
                ["Two-Realm"] = { specProfileMap = { [65] = "Beta", [66] = "Default" } },
            },
        }
        local harness = createHarness(database)

        assertTrue(harness.NivUI.Profiles:RenameProfile("Beta", "Renamed"))
        assertEquals(database.charMeta["One-Realm"].specProfileMap[71], "Renamed")
        assertEquals(database.charMeta["Two-Realm"].specProfileMap[65], "Renamed")
        assertEquals(database.charMeta["One-Realm"].specProfileMap[72], "Alpha")
        assertTableEquals(harness.events[#harness.events].data.specializationMappings, {
            { characterKey = "One-Realm", specID = 71 },
            { characterKey = "Two-Realm", specID = 65 },
        })

        assertTrue(harness.NivUI.Profiles:DeleteProfile("Renamed"))
        assertNil(database.charMeta["One-Realm"].specProfileMap[71])
        assertNil(database.charMeta["Two-Realm"].specProfileMap[65])
        assertEquals(database.charMeta["Two-Realm"].specProfileMap[66], "Default")
        assertTableEquals(harness.events[#harness.events].data.specializationMappings, {
            { characterKey = "One-Realm", specID = 71 },
            { characterKey = "Two-Realm", specID = 65 },
        })

        assertTrue(harness.NivUI.Profiles:CreateProfile("Renamed"))
        assertNil(database.charMeta["One-Realm"].specProfileMap[71])
        assertNil(database.charMeta["Two-Realm"].specProfileMap[65])
    end,

    ["filter deletion clears every overlay selection and name reuse stays detached"] = function()
        local profile = styleProfile()
        local harness = createHarness({ profiles = { Default = profile } })

        local success = harness.NivUI.Filters:DeleteCustom("Important")

        assertTrue(success)
        assertNil(profile.customFilters.Important)
        assertNil(profile.overlays.Glow.allow.Important)
        assertNil(profile.overlays.Glow.block.Important)
        assertNil(profile.overlays.Other.allow.Important)
        assertEquals(profile.overlays.Glow.allow.PLAYER, true)
        assertEquals(profile.overlays.Glow.block.RAID, true)
        assertEquals(profile.overlays.Glow.allow.Other, true)
        assertTableEquals(harness.events[#harness.events].data.overlays, {
            { overlayName = "Glow", allow = true, block = true },
            { overlayName = "Other", allow = true, block = false },
        })

        assertTrue(harness.NivUI.Filters:CreateCustom("Important"))
        assertNil(profile.overlays.Glow.allow.Important)
        assertNil(profile.overlays.Glow.block.Important)
    end,

    ["overlay deletion clears every style selection and name reuse stays detached"] = function()
        local profile = styleProfile()
        local harness = createHarness({ profiles = { Default = profile } })

        local success = harness.NivUI.Overlays:Delete("Glow")

        assertTrue(success)
        assertNil(profile.overlays.Glow)
        assertNil(profile.unitFrameStyles.Alpha.overlays.Glow)
        assertNil(profile.unitFrameStyles.Beta.overlays.Glow)
        assertEquals(profile.unitFrameStyles.Alpha.overlays.Other, true)
        assertEquals(profile.unitFrameStyles.Gamma.overlays.Other, true)
        assertTableEquals(harness.events[#harness.events].data.styles, { "Alpha", "Beta" })

        assertTrue(harness.NivUI.Overlays:Create("Glow"))
        assertNil(profile.unitFrameStyles.Alpha.overlays.Glow)
        assertNil(profile.unitFrameStyles.Beta.overlays.Glow)
    end,

    ["database repair removes legacy dangling references without UI code"] = function()
        local profile = {
            unitFrameStyles = {
                Valid = { overlays = { MissingOverlay = true, Present = true } },
            },
            unitFrameAssignments = { player = "MissingStyle", target = "Valid" },
            customRaidGroups = {
                group = { styleName = "MissingStyle" },
            },
            customFilters = {
                PresentFilter = { spells = {} },
            },
            overlays = {
                Present = {
                    allow = { MissingFilter = true, PresentFilter = true, PLAYER = true },
                    block = { MissingFilter = true, RAID = true },
                },
            },
        }
        local database = {
            profiles = { Default = profile },
            charMeta = {
                ["One-Realm"] = { specProfileMap = { [71] = "MissingProfile", [72] = "Default" } },
            },
        }
        local harness = createHarness(database)

        harness.NivUI:RepairReferenceIntegrity()

        assertEquals(profile.unitFrameAssignments.player, "Valid")
        assertEquals(profile.unitFrameAssignments.target, "Valid")
        assertEquals(profile.customRaidGroups.group.styleName, "Valid")
        assertNil(profile.unitFrameStyles.Valid.overlays.MissingOverlay)
        assertEquals(profile.unitFrameStyles.Valid.overlays.Present, true)
        assertNil(profile.overlays.Present.allow.MissingFilter)
        assertNil(profile.overlays.Present.block.MissingFilter)
        assertEquals(profile.overlays.Present.allow.PresentFilter, true)
        assertEquals(profile.overlays.Present.allow.PLAYER, true)
        assertEquals(profile.overlays.Present.block.RAID, true)
        assertNil(database.charMeta["One-Realm"].specProfileMap[71])
        assertEquals(database.charMeta["One-Realm"].specProfileMap[72], "Default")
    end,

    ["model setters reject new dangling references and imports are reconciled"] = function()
        local profile = styleProfile()
        local database = { profiles = { Default = profile } }
        local harness = createHarness(database)

        local assignmentSuccess = harness.NivUI:SetAssignment("player", "Missing")
        local groupSuccess = harness.NivUI:SaveCustomRaidGroup("first", {
            name = "First",
            styleName = "Missing",
        })
        local specSuccess = harness.NivUI.Profiles:SetSpecProfile(71, "Missing")

        assertFalse(assignmentSuccess)
        assertFalse(groupSuccess)
        assertFalse(specSuccess)
        assertEquals(profile.unitFrameAssignments.player, "Beta")
        assertEquals(profile.customRaidGroups.first.styleName, "Beta")
        assertNil(database.charMeta and database.charMeta["Character-Realm"]
            and database.charMeta["Character-Realm"].specProfileMap[71])

        local imported = {
            unitFrameStyles = { Valid = {} },
            unitFrameAssignments = { player = "Missing" },
            customRaidGroups = { group = { styleName = "Missing" } },
        }
        assertTrue(harness.NivUI.Profiles:CreateFromImport("Imported", imported))
        assertEquals(database.profiles.Imported.unitFrameAssignments.player, "Valid")
        assertEquals(database.profiles.Imported.customRaidGroups.group.styleName, "Valid")
        assertTableEquals(imported.unitFrameAssignments, { player = "Missing" })
    end,
}
