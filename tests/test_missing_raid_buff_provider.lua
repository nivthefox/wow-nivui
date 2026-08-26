local LoadedNivUI, assertions = ...
local assertEquals = assertions.equals
local assertTrue = assertions.isTrue

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function CreateHarness(options)
    local classes = options.classes
    local eventFrame
    local NivUI = {
        Roster = {},
        UnitFrames = {},
    }

    function NivUI.Roster:GetClass(unit)
        return classes[unit]
    end

    local environment = setmetatable({
        CreateFrame = function()
            local frame = { events = {} }
            function frame:RegisterEvent(event)
                self.events[event] = true
            end
            function frame:SetScript(_, script)
                self.script = script
            end
            eventFrame = frame
            return frame
        end,
        GetNumGroupMembers = function()
            return options.count
        end,
        IsInGroup = function()
            return options.inGroup
        end,
        IsInRaid = function()
            return options.inRaid
        end,
        UnitExists = function(unit)
            return classes[unit] ~= nil
        end,
    }, { __index = _G })

    local chunk = assert(loadfile(addonRoot .. "/modules/unitframes/runtime/MissingRaidBuffProvider.lua"))
    setfenv(chunk, environment)
    chunk("NivUI", NivUI)

    return {
        classes = classes,
        eventFrame = eventFrame,
        provider = NivUI.UnitFrames.Runtime.MissingRaidBuffProvider,
    }
end

return {
    ["solo players do not advertise raid buffs"] = function()
        local harness = CreateHarness({
            inGroup = false,
            inRaid = false,
            count = 0,
            classes = { player = "MAGE" },
        })

        local classes = harness.provider.CollectProviderClasses()
        assertEquals(next(classes), nil)
    end,

    ["party provider detection includes the player and party members"] = function()
        local harness = CreateHarness({
            inGroup = true,
            inRaid = false,
            count = 3,
            classes = {
                player = "MAGE",
                party1 = "PRIEST",
                party2 = "WARRIOR",
            },
        })

        local classes = harness.provider.CollectProviderClasses()
        assertTrue(classes.MAGE)
        assertTrue(classes.PRIEST)
        assertTrue(classes.WARRIOR)
        assertEquals(classes.EVOKER, nil)
    end,

    ["raid provider detection uses raid unit tokens"] = function()
        local harness = CreateHarness({
            inGroup = true,
            inRaid = true,
            count = 2,
            classes = {
                player = "MAGE",
                raid1 = "EVOKER",
                raid2 = "SHAMAN",
            },
        })

        local classes = harness.provider.CollectProviderClasses()
        assertTrue(classes.EVOKER)
        assertTrue(classes.SHAMAN)
        assertEquals(classes.MAGE, nil)
    end,

    ["registered widgets refresh when the roster changes"] = function()
        local harness = CreateHarness({
            inGroup = true,
            inRaid = false,
            count = 2,
            classes = {
                player = "MAGE",
                party1 = "PRIEST",
            },
        })
        local snapshots = {}
        local widget = {}

        function widget:SetMissingRaidBuffProviders(classes)
            snapshots[#snapshots + 1] = classes
        end

        harness.provider.Register(widget)
        harness.classes.party1 = "EVOKER"
        harness.eventFrame.script()

        assertTrue(harness.eventFrame.events.PLAYER_REGEN_ENABLED)
        assertEquals(#snapshots, 2)
        assertTrue(snapshots[1].MAGE)
        assertTrue(snapshots[1].PRIEST)
        assertTrue(snapshots[2].MAGE)
        assertTrue(snapshots[2].EVOKER)
        assertEquals(snapshots[2].PRIEST, nil)
    end,
}
