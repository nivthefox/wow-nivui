local loadedNivUI, assertions = ...

local assertEquals = assertions.equals
local assertTrue = assertions.isTrue
local assertNil = assertions.isNil
local assertTableEquals = assertions.tablesEqual

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function Load(relativePath, environment, NivUI)
    local chunk, loadError = loadfile(addonRoot .. "/" .. relativePath)
    if not chunk then
        error(loadError, 0)
    end
    setfenv(chunk, environment)
    return chunk("NivUI", NivUI)
end

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, nested in pairs(value) do
        copy[key] = DeepCopy(nested)
    end
    return copy
end

local function CreateHarness()
    local encodedSnapshot
    local database = {
        profiles = {
            Default = {
                nicknames = { ["alina-realm"] = "Lina" },
            },
        },
    }
    local NivUI = {
        activeProfileName = "Default",
        DeepCopy = DeepCopy,
        Nicknames = loadedNivUI.Nicknames,
        ReferenceIntegrity = {
            ReplaceProfileReferences = function()
                return 0
            end,
        },
    }

    function NivUI:GetActiveProfile()
        return database.profiles[self.activeProfileName]
    end

    function NivUI:RepairProfileReferences(profile)
        self.Nicknames:RepairProfile(profile)
    end

    function NivUI:InitializeDB()
        return true
    end

    function NivUI:ApplyActiveProfile()
    end

    function NivUI:TriggerEvent()
    end

    local frame = { events = {}, scripts = {} }
    function frame:RegisterEvent(event)
        self.events[event] = true
    end
    function frame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    local environment = setmetatable({
        NivUI_DB = database,
        NivUI_CurrentProfile = "Default",
        C_EncodingUtil = {
            EncodeBase64 = function()
                return "encoded"
            end,
            SerializeCBOR = function(snapshot)
                encodedSnapshot = snapshot
                return "serialized"
            end,
        },
        Enum = {},
        CreateFrame = function()
            return frame
        end,
        GetRealmName = function()
            return "Realm"
        end,
        GetSpecialization = function()
            return nil
        end,
        InCombatLockdown = function()
            return false
        end,
        UnitName = function()
            return "Player"
        end,
    }, { __index = _G })

    Load("modules/profiles/Profiles.lua", environment, NivUI)
    return {
        database = database,
        encodedSnapshot = function()
            return encodedSnapshot
        end,
        environment = environment,
        NivUI = NivUI,
    }
end

return {
    ["profile copy deep-copies nicknames and reset clears them"] = function()
        local harness = CreateHarness()
        local profiles = harness.NivUI.Profiles

        assertTrue(profiles:CopyProfile("Default", "Copied"))
        assertEquals(harness.database.profiles.Copied.nicknames["alina-realm"], "Lina")
        harness.database.profiles.Default.nicknames["alina-realm"] = "Changed"
        assertEquals(harness.database.profiles.Copied.nicknames["alina-realm"], "Lina")

        assertTrue(profiles:ResetProfile("Copied"))
        assertNil(harness.database.profiles.Copied.nicknames)
    end,

    ["profile export serializes nickname storage without runtime resolver state"] = function()
        local harness = CreateHarness()

        assertEquals(harness.NivUI.Profiles:ExportCurrentProfile(), "NIVUI:encoded")
        local snapshot = harness.encodedSnapshot()
        assertEquals(snapshot.kind, "profile")
        assertTableEquals(snapshot.payload.nicknames, { ["alina-realm"] = "Lina" })
        assertNil(snapshot.payload.resolvers)
    end,

    ["profile import validates and deterministically repairs nickname entries"] = function()
        local harness = CreateHarness()
        local payload = {
            nicknames = {
                ["ALINA-Realm"] = "First",
                ["alina-realm"] = "Second",
                ["Incomplete"] = "Ignored",
                ["Other-Realm"] = "Bad|cffff0000",
            },
        }

        assertTrue(harness.NivUI.Profiles:CreateFromImport("Imported", payload))
        assertTableEquals(harness.database.profiles.Imported.nicknames, {
            ["alina-realm"] = "First",
        })
    end,
}
