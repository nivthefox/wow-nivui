local _, assertions = ...
local assertEquals = assertions.equals

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function createFrame()
    local frame = {
        events = {},
        unitEvents = {},
        scripts = {},
    }

    function frame:RegisterEvent(event)
        self.events[event] = true
    end

    function frame:RegisterUnitEvent(event, unit)
        self.unitEvents[event] = unit
    end

    function frame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    return frame
end

local function loadChunk(path, environment, ...)
    local chunk, loadError = loadfile(path)
    if not chunk then
        error(loadError, 0)
    end
    setfenv(chunk, environment)
    return chunk(...)
end

local function createHarness()
    local combatLocked = false
    local frames = {}
    local enabled = {
        single = true,
        multi = true,
        raid10 = true,
    }
    local customGroups = {
        group = {
            enabled = true,
            styleName = "Shared Style",
        },
    }
    local NivUI = {
        UnitFrames = {},
        WidgetFactories = {},
        eventCallbacks = {},
        profileApplyCallbacks = {},
        EditMode = {
            IsActive = function()
                return false
            end,
        },
    }

    function NivUI:RegisterCallback(event, callback)
        self.eventCallbacks[event] = self.eventCallbacks[event] or {}
        self.eventCallbacks[event][#self.eventCallbacks[event] + 1] = callback
    end

    function NivUI:TriggerEvent(event, data)
        for _, callback in ipairs(self.eventCallbacks[event] or {}) do
            callback(data)
        end
    end

    function NivUI:RegisterProfileApplyCallback(name, callback)
        self.profileApplyCallbacks[name] = callback
    end

    function NivUI:IsFrameEnabled(frameType)
        return enabled[frameType] == true
    end

    function NivUI:GetAssignment()
        return "Shared Style"
    end

    function NivUI:GetCustomRaidGroups()
        return customGroups
    end

    function NivUI:GetCustomRaidGroup(groupId)
        return customGroups[groupId]
    end

    local environment = setmetatable({
        C_Timer = {
            NewTicker = function()
                return { Cancel = function() end }
            end,
        },
        CreateFrame = function()
            local frame = createFrame()
            frames[#frames + 1] = frame
            return frame
        end,
        InCombatLockdown = function()
            return combatLocked
        end,
        UIParent = createFrame(),
        wipe = function(target)
            for key in pairs(target) do
                target[key] = nil
            end
        end,
    }, { __index = _G })

    local harness = {
        counts = {
            single = 0,
            multi = 0,
            raid = 0,
            customRaid = 0,
        },
    }

    function harness:load(relativePath)
        loadChunk(addonRoot .. "/" .. relativePath, environment, "NivUI", NivUI)
    end

    function harness:setEnabled(value)
        enabled.single = value
        enabled.multi = value
        enabled.raid10 = value
        customGroups.group.enabled = value
    end

    function harness:setCombatLocked(locked)
        combatLocked = locked
    end

    harness:load("modules/unitframes/UnitFrameLifecycle.lua")
    harness:load("modules/unitframes/runtime/HealthUpdater.lua")
    harness:load("modules/unitframes/runtime/StandardWidgetUpdater.lua")
    harness:load("modules/unitframes/runtime/CastbarUpdater.lua")
    harness:load("modules/unitframes/runtime/AuraOverlays.lua")
    harness:load("modules/unitframes/runtime/WidgetTree.lua")
    harness:load("modules/unitframes/runtime/EventRouter.lua")
    harness:load("modules/unitframes/runtime/SecureFrame.lua")
    harness:load("modules/unitframes/runtime/NameRefresh.lua")
    harness:load("modules/unitframes/UnitFrameBase.lua")
    local single = NivUI.UnitFrames.Base.CreateModule({
        unit = "player",
        frameType = "single",
    })

    harness:load("modules/unitframes/MultiUnitFrameBase.lua")
    local multi = NivUI.UnitFrames.MultiUnitFrameBase.CreateModule({
        frameType = "multi",
        hideBlizzardFrames = function() end,
        settingsChangedCallback = "MultiSettingsChanged",
        previewChangedCallback = "MultiPreviewChanged",
    })

    harness:load("modules/unitframes/RaidFrame.lua")
    harness:load("modules/unitframes/CustomRaidGroup.lua")

    function single.Refresh()
        harness.counts.single = harness.counts.single + 1
    end

    function multi.Refresh()
        harness.counts.multi = harness.counts.multi + 1
    end

    function NivUI.UnitFrames.RaidFrame.Refresh(raidSize)
        if raidSize == "raid10" then
            harness.counts.raid = harness.counts.raid + 1
        end
    end

    function NivUI.UnitFrames.CustomRaidGroup.Refresh(groupId)
        if groupId == "group" then
            harness.counts.customRaid = harness.counts.customRaid + 1
        end
    end

    harness.NivUI = NivUI
    harness.Base = NivUI.UnitFrames.Base
    return harness
end

local function assertRefreshCounts(harness, expected, message)
    for family, actual in pairs(harness.counts) do
        assertEquals(actual, expected, message .. " for " .. family)
    end
end

return {
    ["the shared update pass preserves widget update order"] = function()
        local harness = createHarness()
        local calls = {}
        local updaterNames = {
            "UpdateHealthBar",
            "UpdateHealthText",
            "UpdatePowerBar",
            "UpdatePowerText",
            "UpdatePortrait",
            "UpdateNameText",
            "UpdateLevelText",
            "UpdateStatusIndicators",
            "UpdateStatusText",
            "UpdateRaidMarker",
            "UpdateLeaderIcon",
            "UpdateRoleIcon",
            "UpdateCastbar",
            "UpdateRangeAlpha",
            "UpdateOverlays",
        }

        for _, updaterName in ipairs(updaterNames) do
            harness.Base[updaterName] = function()
                calls[#calls + 1] = updaterName
            end
        end

        harness.Base.UpdateAllWidgets({ customFrame = { widgets = {} } })

        assertEquals(table.concat(calls, ","), table.concat(updaterNames, ","), "widget update order")
    end,

    ["the shared event router dispatches each event family"] = function()
        local harness = createHarness()
        local calls = {}
        local updaterNames = {
            "UpdateHealthBar",
            "UpdateHealthText",
            "UpdatePowerBar",
            "UpdatePowerText",
            "UpdatePortrait",
            "UpdateNameText",
            "UpdateLevelText",
            "UpdateStatusIndicators",
            "UpdateStatusText",
            "UpdateRaidMarker",
            "UpdateOverlays",
            "UpdateCastbar",
        }

        for _, updaterName in ipairs(updaterNames) do
            harness.Base[updaterName] = function()
                calls[#calls + 1] = updaterName
            end
        end

        harness.Base.HandleEvent({}, "UNIT_MAXHEALTH")
        harness.Base.HandleEvent({}, "UNIT_MAXPOWER")
        harness.Base.HandleEvent({}, "UNIT_MODEL_CHANGED")
        harness.Base.HandleEvent({}, "UNIT_NAME_UPDATE")
        harness.Base.HandleEvent({}, "UNIT_LEVEL")
        harness.Base.HandleEvent({}, "PLAYER_REGEN_ENABLED")
        harness.Base.HandleEvent({}, "UNIT_FLAGS")
        harness.Base.HandleEvent({}, "RAID_TARGET_UPDATE")
        harness.Base.HandleEvent({}, "UNIT_AURA")
        harness.Base.HandleEvent({}, "UNIT_SPELLCAST_START")

        local expected = {
            "UpdateHealthBar",
            "UpdateHealthText",
            "UpdatePowerBar",
            "UpdatePowerText",
            "UpdatePortrait",
            "UpdateNameText",
            "UpdateLevelText",
            "UpdateStatusIndicators",
            "UpdateStatusText",
            "UpdateStatusText",
            "UpdateRaidMarker",
            "UpdateOverlays",
            "UpdateCastbar",
        }
        assertEquals(table.concat(calls, ","), table.concat(expected, ","), "event dispatch order")
    end,

    ["the standard event contract remains stable"] = function()
        local harness = createHarness()
        local frame = createFrame()

        harness.Base.RegisterStandardEvents(frame, "party1")

        local unitEvents = {
            "UNIT_MAXHEALTH",
            "UNIT_ABSORB_AMOUNT_CHANGED",
            "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
            "UNIT_HEAL_PREDICTION",
            "UNIT_MAX_HEALTH_MODIFIERS_CHANGED",
            "UNIT_MAXPOWER",
            "UNIT_DISPLAYPOWER",
            "UNIT_MODEL_CHANGED",
            "UNIT_NAME_UPDATE",
            "UNIT_LEVEL",
            "UNIT_FACTION",
            "UNIT_FLAGS",
            "UNIT_CONNECTION",
            "UNIT_AURA",
            "UNIT_SPELLCAST_START",
            "UNIT_SPELLCAST_STOP",
            "UNIT_SPELLCAST_FAILED",
            "UNIT_SPELLCAST_INTERRUPTED",
            "UNIT_SPELLCAST_SUCCEEDED",
            "UNIT_SPELLCAST_CHANNEL_START",
            "UNIT_SPELLCAST_CHANNEL_STOP",
            "UNIT_SPELLCAST_CHANNEL_UPDATE",
        }

        for _, event in ipairs(unitEvents) do
            assertEquals(frame.unitEvents[event], "party1", event .. " unit")
        end
        assertEquals(frame.events.RAID_TARGET_UPDATE, true, "raid target event")
    end,

    ["a style change refreshes only families assigned to that style"] = function()
        local harness = createHarness()

        harness.NivUI:TriggerEvent("StyleChanged", { styleName = "Unassigned Style" })

        assertRefreshCounts(harness, 0, "unassigned style refresh count")
    end,

    ["all unit frame families refresh for each structural invalidation"] = function()
        local harness = createHarness()

        harness.NivUI:TriggerEvent("CustomFiltersChanged", { name = "Test Filter" })
        assertRefreshCounts(harness, 1, "filter refresh count")

        harness.NivUI:TriggerEvent("OverlaysChanged", { name = "Test Overlay" })
        assertRefreshCounts(harness, 2, "overlay collection refresh count")

        harness.NivUI:TriggerEvent("OverlayModified", { name = "Test Overlay" })
        assertRefreshCounts(harness, 3, "overlay definition refresh count")

        harness.NivUI:TriggerEvent("StyleChanged", { styleName = "Shared Style" })
        assertRefreshCounts(harness, 4, "style refresh count")

        harness.NivUI:TriggerEvent("StyleRenamed", { oldName = "Old Style", newName = "Shared Style" })
        assertRefreshCounts(harness, 5, "style rename refresh count")

        harness.NivUI:TriggerEvent("StyleDeleted", { styleName = "Old Style", fallback = "Shared Style" })
        assertRefreshCounts(harness, 6, "style deletion refresh count")
    end,

    ["disabled unit frame families ignore structural invalidations"] = function()
        local harness = createHarness()
        harness:setEnabled(false)
        harness.NivUI:TriggerEvent("CustomFiltersChanged", { name = "Test Filter" })

        assertRefreshCounts(harness, 0, "disabled refresh count")
    end,

    ["structural invalidations are never deferred by combat"] = function()
        local harness = createHarness()
        harness:setCombatLocked(true)

        harness.NivUI:TriggerEvent("CustomFiltersChanged", { name = "Test Filter" })

        assertRefreshCounts(harness, 1, "combat refresh count")
    end,
}
