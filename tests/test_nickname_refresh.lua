local _, assertions = ...

local assertEquals = assertions.equals
local assertTrue = assertions.isTrue
local assertFalse = assertions.isFalse
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

local function CreateRefreshHarness()
    local identities = {
        player = "player-realm",
        party1 = "first-realm",
        party2 = "second-realm",
    }
    local tick
    local eventFrame = { events = {}, scripts = {} }
    local NivUI = {
        UnitFrames = { Runtime = {} },
        Nicknames = {},
    }

    function NivUI.Nicknames.GetUnitIdentity(unit)
        return identities[unit]
    end

    function NivUI.Nicknames:BeginResolutionPass()
        return { "snapshot" }
    end

    function NivUI.Nicknames.NormalizeIdentity(identity)
        return type(identity) == "string" and identity:lower() or nil
    end

    function eventFrame:RegisterEvent(event)
        self.events[event] = true
    end

    function eventFrame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    local environment = setmetatable({
        InCombatLockdown = function()
            return true
        end,
    }, { __index = _G })
    Load("modules/unitframes/runtime/NameRefresh.lua", environment, NivUI)

    local updates = {}
    NivUI.UnitFrames.Runtime.NameRefresh.Start(
        function(state, snapshot)
            updates[#updates + 1] = { unit = state.unit, snapshot = snapshot[1] }
        end,
        function(callback)
            tick = callback
        end,
        function()
            return eventFrame
        end
    )

    return {
        eventFrame = eventFrame,
        identities = identities,
        NameRefresh = NivUI.UnitFrames.Runtime.NameRefresh,
        tick = function()
            tick()
        end,
        updates = updates,
    }
end

local function VisibleFrame(shown)
    return {
        IsShown = function()
            return shown
        end,
    }
end

return {
    ["profile and local data callbacks trigger immediate name refreshes"] = function()
        local profileCallbacks = {}
        local eventCallbacks = {}
        local repairedProfile
        local refreshAll = 0
        local refreshedIdentity
        local profile = {}
        local NivUI = {
            Nicknames = {
                RepairProfile = function(_, value)
                    repairedProfile = value
                end,
            },
            UnitFrames = {
                Runtime = {
                    NameRefresh = {
                        RefreshAll = function()
                            refreshAll = refreshAll + 1
                        end,
                        RefreshIdentity = function(identity)
                            refreshedIdentity = identity
                        end,
                    },
                },
            },
        }
        function NivUI:GetActiveProfile()
            return profile
        end
        function NivUI:RegisterProfileApplyCallback(name, callback)
            profileCallbacks[name] = callback
        end
        function NivUI:RegisterCallback(name, callback)
            eventCallbacks[name] = callback
        end

        Load("modules/nicknames/Runtime.lua", setmetatable({}, { __index = _G }), NivUI)
        profileCallbacks.nicknames()
        eventCallbacks.NicknamesChanged({ identity = "alina-realm" })

        assertEquals(repairedProfile, profile)
        assertEquals(refreshAll, 1)
        assertEquals(refreshedIdentity, "alina-realm")
    end,

    ["the one-second pass refreshes every visible player together"] = function()
        local harness = CreateRefreshHarness()
        local refresh = harness.NameRefresh
        refresh.RegisterState({ unit = "player", customFrame = VisibleFrame(true) })
        refresh.RegisterState({ unit = "party1", customFrame = VisibleFrame(true) })
        refresh.RegisterState({ unit = "party2", customFrame = VisibleFrame(false) })
        refresh.RegisterState({ unit = "target", customFrame = VisibleFrame(true) })

        harness.tick()

        local units = {}
        for _, update in ipairs(harness.updates) do
            units[update.unit] = update.snapshot
        end
        assertTableEquals(units, { player = "snapshot", party1 = "snapshot" })
    end,

    ["polling has no combat gate and roster events refresh immediately"] = function()
        local harness = CreateRefreshHarness()
        harness.NameRefresh.RegisterState({ unit = "player", customFrame = VisibleFrame(true) })

        harness.tick()
        harness.eventFrame.scripts.OnEvent(harness.eventFrame, "GROUP_ROSTER_UPDATE")

        assertEquals(#harness.updates, 2)
        assertTrue(harness.eventFrame.events.GROUP_ROSTER_UPDATE)
        assertTrue(harness.eventFrame.events.PLAYER_ENTERING_WORLD)
    end,

    ["local nickname changes refresh only matching visible identities"] = function()
        local harness = CreateRefreshHarness()
        harness.NameRefresh.RegisterState({ unit = "player", customFrame = VisibleFrame(true) })
        harness.NameRefresh.RegisterState({ unit = "party1", customFrame = VisibleFrame(true) })

        assertEquals(harness.NameRefresh.RefreshIdentity("FIRST-REALM"), 1)
        assertEquals(#harness.updates, 1)
        assertEquals(harness.updates[1].unit, "party1")
    end,

    ["unregistered states stop participating in refresh passes"] = function()
        local harness = CreateRefreshHarness()
        local state = { unit = "player", customFrame = VisibleFrame(true) }
        harness.NameRefresh.RegisterState(state)
        harness.NameRefresh.UnregisterState(state)

        harness.tick()
        assertEquals(#harness.updates, 0)
    end,

    ["name text uses the resolver result and truncates without splitting UTF-8"] = function()
        local displayed
        local resolverCalls = 0
        local NivUI = {
            UnitFrames = {
                Runtime = {},
                DEFAULT_STYLE = { nameText = {} },
            },
            WidgetFactories = {
                GetClassColor = function()
                    return 1, 1, 1
                end,
                GetPowerColor = function()
                    return 1, 1, 1
                end,
            },
            Nicknames = {
                ResolveUnit = function(_, unit, normalName, snapshot)
                    resolverCalls = resolverCalls + 1
                    assertEquals(unit, "party1")
                    assertEquals(normalName, "Alina")
                    assertEquals(snapshot[1], "snapshot")
                    return "ééé"
                end,
                TruncateText = function(value, maximum)
                    assertEquals(maximum, 2)
                    return value:sub(1, 4)
                end,
            },
        }
        local environment = setmetatable({
            issecretvalue = function()
                return false
            end,
            UnitName = function()
                return "Alina"
            end,
        }, { __index = _G })
        Load("modules/unitframes/runtime/StandardWidgetUpdater.lua", environment, NivUI)

        local state = {
            unit = "party1",
            currentStyle = { nameText = { truncateLength = 2, colorByClass = false } },
            customFrame = {
                widgets = {
                    nameText = {
                        text = {
                            SetText = function(_, value)
                                displayed = value
                            end,
                        },
                    },
                },
            },
        }
        NivUI.UnitFrames.Runtime.StandardWidgetUpdater.UpdateNameText(state, { "snapshot" })

        assertEquals(displayed, "éé")
        assertEquals(resolverCalls, 1)
        assertEquals(state.unit, "party1")
        assertFalse(state.customFrame.unitChanged == true)
    end,
}
