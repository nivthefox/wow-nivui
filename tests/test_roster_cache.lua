local _, assertions = ...
local assertEquals = assertions.equals
local assertNil = assertions.isNil
local assertTrue = assertions.isTrue

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local SECRET = {}

local function loadRosterCache()
    local values = {
        class = "PRIEST",
        role = "HEALER",
        isLeader = true,
        isAssist = false,
    }
    local existing = {
        player = true,
        party1 = true,
    }
    local frame = {
        events = {},
        scripts = {},
    }
    local NivUI = {}

    function frame:RegisterEvent(event)
        self.events[event] = true
    end

    function frame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    local environment = setmetatable({
        NivUI = NivUI,
        CreateFrame = function()
            return frame
        end,
        UnitClass = function()
            return "Player", values.class
        end,
        UnitExists = function(unit)
            return existing[unit] == true
        end,
        UnitGroupRolesAssigned = function()
            return values.role
        end,
        UnitIsGroupAssistant = function()
            return values.isAssist
        end,
        UnitIsGroupLeader = function()
            return values.isLeader
        end,
        issecretvalue = function(value)
            return value == SECRET
        end,
    }, { __index = _G })

    local chunk, loadError = loadfile(addonRoot .. "/modules/unitframes/RosterCache.lua")
    if not chunk then
        error(loadError, 0)
    end
    setfenv(chunk, environment)
    chunk("NivUI", NivUI)

    local harness = {
        frame = frame,
        existing = existing,
        NivUI = NivUI,
        values = values,
    }

    function harness:snapshot(event)
        frame.scripts.OnEvent(frame, event or "GROUP_ROSTER_UPDATE")
    end

    function harness:makeSecret()
        values.class = SECRET
        values.role = SECRET
        values.isLeader = SECRET
        values.isAssist = SECRET
    end

    return harness
end

return {
    ["roster cache registers every snapshot event"] = function()
        local harness = loadRosterCache()
        local expectedEvents = {
            "GROUP_ROSTER_UPDATE",
            "PARTY_LEADER_CHANGED",
            "PLAYER_ENTERING_WORLD",
            "PLAYER_REGEN_ENABLED",
            "PLAYER_ROLES_ASSIGNED",
        }

        for _, event in ipairs(expectedEvents) do
            assertTrue(harness.frame.events[event], event)
        end
    end,

    ["readable live roster values take precedence"] = function()
        local harness = loadRosterCache()

        assertEquals(harness.NivUI.Roster:GetClass("party1"), "PRIEST")
        assertEquals(harness.NivUI.Roster:GetRole("party1"), "HEALER")
        assertEquals(harness.NivUI.Roster:IsLeader("party1"), true)
        assertEquals(harness.NivUI.Roster:IsAssist("party1"), false)
    end,

    ["secret roster values fall back to the last readable snapshot"] = function()
        local harness = loadRosterCache()
        harness:snapshot()
        harness:makeSecret()

        assertEquals(harness.NivUI.Roster:GetClass("party1"), "PRIEST")
        assertEquals(harness.NivUI.Roster:GetRole("party1"), "HEALER")
        assertEquals(harness.NivUI.Roster:IsLeader("party1"), true)
        assertEquals(harness.NivUI.Roster:IsAssist("party1"), false)
    end,

    ["a secret snapshot preserves the last readable values"] = function()
        local harness = loadRosterCache()
        harness:snapshot()
        harness:makeSecret()
        harness:snapshot()

        assertEquals(harness.NivUI.Roster:GetClass("party1"), "PRIEST")
        assertEquals(harness.NivUI.Roster:GetRole("party1"), "HEALER")
        assertEquals(harness.NivUI.Roster:IsLeader("party1"), true)
        assertEquals(harness.NivUI.Roster:IsAssist("party1"), false)
    end,

    ["units removed from the group lose their cached identity"] = function()
        local harness = loadRosterCache()
        harness:snapshot()
        harness.existing.party1 = false
        harness:snapshot()
        harness:makeSecret()

        assertNil(harness.NivUI.Roster:GetClass("party1"))
        assertNil(harness.NivUI.Roster:GetRole("party1"))
        assertNil(harness.NivUI.Roster:IsLeader("party1"))
        assertNil(harness.NivUI.Roster:IsAssist("party1"))
    end,
}
