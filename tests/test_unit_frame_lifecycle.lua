local _, assertions = ...
local assertEquals = assertions.equals

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function createFrame()
    local frame = {
        events = {},
        scripts = {},
    }

    function frame:RegisterEvent(event)
        self.events[event] = true
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

    function harness:fire(event)
        for _, frame in ipairs(frames) do
            local callback = frame.events[event] and frame.scripts.OnEvent
            if callback then
                callback(frame, event)
            end
        end
    end

    function harness:setCombatLocked(locked)
        combatLocked = locked
    end

    function harness:setEnabled(value)
        enabled.single = value
        enabled.multi = value
        enabled.raid10 = value
        customGroups.group.enabled = value
    end

    harness:load("modules/unitframes/UnitFrameLifecycle.lua")
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
    return harness
end

local function assertRefreshCounts(harness, expected, message)
    for family, actual in pairs(harness.counts) do
        assertEquals(actual, expected, message .. " for " .. family)
    end
end

return {
    ["a style change refreshes only families assigned to that style"] = function()
        local harness = createHarness()

        harness.NivUI:TriggerEvent("StyleChanged", { styleName = "Unassigned Style" })

        assertRefreshCounts(harness, 0, "unassigned style refresh count")
    end,

    ["all unit frame families refresh for each structural invalidation outside combat"] = function()
        local harness = createHarness()

        harness.NivUI:TriggerEvent("CustomFiltersChanged", { name = "Test Filter" })
        assertRefreshCounts(harness, 1, "filter refresh count")

        harness.NivUI:TriggerEvent("OverlaysChanged", { name = "Test Overlay" })
        assertRefreshCounts(harness, 2, "overlay collection refresh count")

        harness.NivUI:TriggerEvent("OverlayModified", { name = "Test Overlay" })
        assertRefreshCounts(harness, 3, "overlay definition refresh count")

        harness.NivUI:TriggerEvent("StyleChanged", { styleName = "Shared Style" })
        assertRefreshCounts(harness, 4, "style refresh count")
    end,

    ["structural invalidations during combat coalesce until combat ends"] = function()
        local harness = createHarness()
        harness:setCombatLocked(true)

        harness.NivUI:TriggerEvent("CustomFiltersChanged", { name = "Test Filter" })
        harness.NivUI:TriggerEvent("OverlaysChanged", { name = "Test Overlay" })
        harness.NivUI:TriggerEvent("OverlayModified", { name = "Test Overlay" })
        harness.NivUI:TriggerEvent("StyleChanged", { styleName = "Shared Style" })
        assertRefreshCounts(harness, 0, "combat refresh count")

        harness:setCombatLocked(false)
        harness:fire("PLAYER_REGEN_ENABLED")
        assertRefreshCounts(harness, 1, "deferred refresh count")

        harness:fire("PLAYER_REGEN_ENABLED")
        assertRefreshCounts(harness, 1, "repeated combat-end refresh count")
    end,

    ["a pending structural refresh is discarded when its family is disabled"] = function()
        local harness = createHarness()
        harness:setCombatLocked(true)
        harness.NivUI:TriggerEvent("CustomFiltersChanged", { name = "Test Filter" })

        harness:setEnabled(false)
        harness:setCombatLocked(false)
        harness:fire("PLAYER_REGEN_ENABLED")

        assertRefreshCounts(harness, 0, "disabled refresh count")
    end,
}
