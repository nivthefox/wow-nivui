local NivUI, assertions = ...

local assertEquals = assertions.equals
local assertTrue = assertions.isTrue
local assertFalse = assertions.isFalse
local assertNil = assertions.isNil
local assertNotNil = assertions.isNotNil
local assertTableEquals = assertions.tablesEqual

local Nicknames = NivUI.Nicknames
local registeredResolvers = {}

local function RegisterResolver(resolver)
    registeredResolvers[#registeredResolvers + 1] = resolver
    return Nicknames:RegisterResolver(resolver)
end

local function Reset()
    for _, resolver in ipairs(registeredResolvers) do
        Nicknames:UnregisterResolver(resolver)
    end
    registeredResolvers = {}
    Nicknames:SetDiagnosticSink(function() end)
end

return {
    ["profile nicknames resolve before the normal character name"] = function()
        local profile = {}
        Reset(profile)
        profile.nicknames = { ["alina-moon-guard"] = "Lina" }

        assertEquals(Nicknames:Resolve("Alina-Moon-Guard", "Alina", nil, profile), "Lina")
        assertEquals(Nicknames:Resolve("Borin-Moon-Guard", "Borin", nil, profile), "Borin")
    end,

    ["external resolvers use registration order and stop at the first usable result"] = function()
        local profile = { nicknames = { ["alina-realm"] = "Profile" } }
        Reset(profile)
        local calls = {}
        RegisterResolver(function()
            calls[#calls + 1] = "first"
            return "  "
        end)
        RegisterResolver(function()
            calls[#calls + 1] = "second"
            return "External"
        end)
        RegisterResolver(function()
            calls[#calls + 1] = "third"
            return "Late"
        end)

        assertEquals(Nicknames:Resolve("Alina-Realm", "Alina", nil, profile), "External")
        assertTableEquals(calls, { "first", "second" })
    end,

    ["resolver registration is idempotent and unregistration restores fallback"] = function()
        local profile = { nicknames = { ["alina-realm"] = "Profile" } }
        Reset(profile)
        local calls = 0
        local resolver = function()
            calls = calls + 1
            return "External"
        end

        assertTrue(RegisterResolver(resolver))
        assertTrue(Nicknames:RegisterResolver(resolver))
        assertEquals(Nicknames:Resolve("Alina-Realm", "Alina", nil, profile), "External")
        assertEquals(calls, 1)
        assertTrue(Nicknames:UnregisterResolver(resolver))
        assertEquals(Nicknames:Resolve("Alina-Realm", "Alina", nil, profile), "Profile")
        assertFalse(Nicknames:UnregisterResolver(resolver))
    end,

    ["a resolution pass keeps its starting resolver order"] = function()
        local profile = {}
        Reset(profile)
        local later = function()
            return "Later"
        end
        local first = function()
            RegisterResolver(later)
            return nil
        end
        RegisterResolver(first)

        local snapshot = Nicknames:BeginResolutionPass()
        assertEquals(Nicknames:Resolve("Alina-Realm", "Alina", snapshot, profile), "Alina")
        assertEquals(Nicknames:Resolve("Alina-Realm", "Alina", nil, profile), "Later")
    end,

    ["resolver failures are isolated throttled and recoverable"] = function()
        local profile = { nicknames = { ["alina-realm"] = "Profile" } }
        Reset(profile)
        local diagnostics = {}
        local shouldFail = true
        Nicknames:SetDiagnosticSink(function(message)
            diagnostics[#diagnostics + 1] = message
        end)
        RegisterResolver(function()
            if shouldFail then
                error("temporary failure")
            end
            return "Recovered"
        end)

        assertEquals(Nicknames:Resolve("Alina-Realm", "Alina", nil, profile), "Profile")
        assertEquals(Nicknames:Resolve("Alina-Realm", "Alina", nil, profile), "Profile")
        assertEquals(#diagnostics, 1)
        shouldFail = false
        assertEquals(Nicknames:Resolve("Alina-Realm", "Alina", nil, profile), "Recovered")
    end,

    ["invalid resolver outputs continue through fallback resolution"] = function()
        local profile = { nicknames = { ["alina-realm"] = "Profile" } }
        Reset(profile)
        for _, result in ipairs({ 42, "Bad|cffff0000", "abcdefghijklm" }) do
            RegisterResolver(function()
                return result
            end)
        end

        assertEquals(Nicknames:Resolve("Alina-Realm", "Alina", nil, profile), "Profile")
    end,

    ["unit resolution ignores non-player and identities without any realm"] = function()
        local profile = { nicknames = { ["alina-realm"] = "Profile" } }
        Reset(profile)
        local resolverCalls = 0
        RegisterResolver(function()
            resolverCalls = resolverCalls + 1
            return "External"
        end)

        local player = false
        UnitIsPlayer = function()
            return player
        end
        UnitFullName = function()
            return "Alina", nil
        end
        GetNormalizedRealmName = function()
            return nil
        end

        assertEquals(Nicknames:ResolveUnit("target", "Normal", nil, profile), "Normal")
        player = true
        assertEquals(Nicknames:ResolveUnit("target", "Normal", nil, profile), "Normal")
        assertEquals(resolverCalls, 0)
    end,

    ["unit identity uses the current realm when UnitFullName omits it"] = function()
        local profile = { nicknames = { ["alina-realm"] = "Profile" } }
        Reset(profile)
        local explicitRealm = false

        UnitIsPlayer = function()
            return true
        end
        UnitFullName = function()
            if explicitRealm then
                return "Alina", "OtherRealm"
            end
            return "Alina", nil
        end
        GetNormalizedRealmName = function()
            return "Realm"
        end

        assertEquals(Nicknames.GetUnitIdentity("target"), "alina-realm")
        assertEquals(Nicknames:ResolveUnit("target", "Normal", nil, profile), "Profile")
        explicitRealm = true
        assertEquals(Nicknames.GetUnitIdentity("target"), "alina-otherrealm")
    end,

    ["saving normalizes replaces and removes arbitrary identities"] = function()
        local profile = {}
        Reset(profile)

        local success, _, normalized = Nicknames:Save("  Alina-Moon-Guard  ", "  Lina  ", profile)
        assertTrue(success)
        assertEquals(normalized, "alina-moon-guard")
        assertEquals(profile.nicknames[normalized], "Lina")

        assertTrue(Nicknames:Save("ALINA-moon-guard", "New", profile))
        assertEquals(profile.nicknames[normalized], "New")
        assertTrue(Nicknames:Save("alina-MOON-GUARD", "   ", profile))
        assertNil(profile.nicknames[normalized])
    end,

    ["invalid saves do not mutate profile storage"] = function()
        local profile = { nicknames = { ["valid-realm"] = "Valid" } }
        Reset(profile)
        profile.nicknames = { ["valid-realm"] = "Valid" }

        assertFalse(Nicknames:Save("Incomplete", "Name", profile))
        assertFalse(Nicknames:Save("Other-Realm", "Bad\nName", profile))
        assertFalse(Nicknames:Save("Other-Realm", "Bad|Ttexture|t", profile))
        assertTableEquals(profile.nicknames, { ["valid-realm"] = "Valid" })
    end,

    ["nickname length is measured in Unicode characters"] = function()
        local twelve = "éééééééééééé"
        local thirteen = twelve .. "é"

        assertEquals(Nicknames.ValidateNickname(twelve, false), twelve)
        assertNil(Nicknames.ValidateNickname(thirteen, false))
        assertEquals(Nicknames.TruncateText(thirteen, 12), twelve)
    end,

    ["older profiles remain storage-free until a nickname is saved"] = function()
        local profile = {}
        Reset(profile)

        assertNil(Nicknames:Get("Alina-Realm", profile))
        assertNil(profile.nicknames)
        assertTrue(Nicknames:Save("Alina-Realm", "", profile))
        assertNil(profile.nicknames)
        assertTrue(Nicknames:Save("Alina-Realm", "Lina", profile))
        assertNotNil(profile.nicknames)
    end,

    ["stored data repair is deterministic and ignores malformed entries"] = function()
        local profile = {
            nicknames = {
                ["ALINA-Realm"] = "First",
                ["alina-realm"] = "Second",
                ["NoRealm"] = "Ignored",
                ["Other-Realm"] = "Bad|cffff0000",
                [17] = "NumberKey",
            },
        }

        local repaired = Nicknames:RepairProfile(profile)
        assertTrue(repaired > 0)
        assertTableEquals(profile.nicknames, { ["alina-realm"] = "First" })
    end,

    ["separate identities may share one nickname"] = function()
        local profile = {}
        Reset(profile)
        assertTrue(Nicknames:Save("Alina-Realm", "Shared", profile))
        assertTrue(Nicknames:Save("Borin-Realm", "Shared", profile))

        assertEquals(Nicknames:Resolve("Alina-Realm", "Alina", nil, profile), "Shared")
        assertEquals(Nicknames:Resolve("Borin-Realm", "Borin", nil, profile), "Shared")
        assertEquals(#Nicknames:GetEntries(profile), 2)
    end,
}
