local _, assertions = ...
local assertEquals = assertions.equals
local assertNotNil = assertions.isNotNil

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function CreateFrameStub()
    local frame = {
        events = {},
        scripts = {},
        shown = false,
    }

    function frame:ClearAllPoints()
    end

    function frame:Hide()
        self.shown = false
    end

    function frame:RegisterEvent(event)
        self.events[event] = true
    end

    function frame:RegisterForClicks()
    end

    function frame:SetAttribute()
    end

    function frame:SetParent()
    end

    function frame:SetPoint()
    end

    function frame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    function frame:SetSize()
    end

    function frame:Show()
        self.shown = true
    end

    function frame:UnregisterAllEvents()
        self.events = {}
    end

    return frame
end

local function CreateHarness()
    local names = {
        raid1 = "Volk",
        raid2 = "Flan",
    }
    local refreshedNames = {}
    local eventFrame
    local NivUI = {
        UPDATE_INTERVAL = 0.1,
        UnitFrames = {
            Base = {},
            Lifecycle = {
                Register = function()
                end,
            },
        },
        Roster = {},
    }

    local Base = NivUI.UnitFrames.Base

    function Base.ApplyAnchors()
    end

    function Base.CreateWidgets()
        return {}
    end

    function Base.HandleEvent()
    end

    function Base.RegisterStandardEvents()
    end

    function Base.SetSecureVisibility()
    end

    function Base.UpdateAllWidgets(state)
        refreshedNames[#refreshedNames + 1] = names[state.unit]
    end

    function Base.UpdateCastbar()
    end

    function Base.UpdateHealthBar()
    end

    function Base.UpdateHealthText()
    end

    function Base.UpdatePowerBar()
    end

    function Base.UpdatePowerText()
    end

    function Base.UpdateStatusIndicators()
    end

    function Base.UpdateStatusText()
    end

    function NivUI.Roster:GetRole()
        return "HEALER"
    end

    function NivUI:GetCustomRaidGroup(groupId)
        if groupId ~= "healerMana" then
            return nil
        end
        return {
            enabled = true,
            filterType = "role",
            roles = { healer = true },
            styleName = "Healer Mana",
        }
    end

    function NivUI:GetCustomRaidGroups()
        return {
            healerMana = self:GetCustomRaidGroup("healerMana"),
        }
    end

    function NivUI:GetStyleWithDefaults()
        return {
            frame = {
                height = 20,
                width = 100,
            },
        }
    end

    function NivUI:RegisterCallback()
    end

    function NivUI:RegisterProfileApplyCallback()
    end

    local environment = setmetatable({
        CreateFrame = function()
            local frame = CreateFrameStub()
            if not eventFrame then
                eventFrame = frame
            end
            return frame
        end,
        GetNumGroupMembers = function()
            return 2
        end,
        GetRaidRosterInfo = function(index)
            return names["raid" .. index]
        end,
        IsInRaid = function()
            return true
        end,
        UIParent = CreateFrameStub(),
        UnitExists = function(unit)
            return names[unit] ~= nil
        end,
        UnitIsUnit = function()
            return false
        end,
        UnitName = function(unit)
            return names[unit]
        end,
        issecretvalue = function()
            return false
        end,
        wipe = function(target)
            for key in pairs(target) do
                target[key] = nil
            end
        end,
    }, { __index = _G })

    local chunk, loadError = loadfile(addonRoot .. "/modules/unitframes/CustomRaidGroup.lua")
    if not chunk then
        error(loadError, 0)
    end
    setfenv(chunk, environment)
    chunk("NivUI", NivUI)

    local harness = {
        names = names,
        NivUI = NivUI,
        refreshedNames = refreshedNames,
    }

    function harness:clearRefreshes()
        for index = #refreshedNames, 1, -1 do
            refreshedNames[index] = nil
        end
    end

    function harness:rosterUpdate()
        eventFrame.scripts.OnEvent(eventFrame, "GROUP_ROSTER_UPDATE")
    end

    return harness
end

return {
    ["roster changes refresh identities on reused custom group frames"] = function()
        local harness = CreateHarness()
        harness.NivUI.UnitFrames.CustomRaidGroup.Enable("healerMana")
        harness:clearRefreshes()

        harness.names.raid1 = "Flan"
        harness.names.raid2 = "Lugiara"
        harness:rosterUpdate()

        assertEquals(#harness.refreshedNames, 2, "refreshed frame count")
        assertEquals(harness.refreshedNames[1], "Flan", "first refreshed identity")
        assertEquals(harness.refreshedNames[2], "Lugiara", "second refreshed identity")

        local state = harness.NivUI.UnitFrames.CustomRaidGroup.GetState("healerMana")
        assertNotNil(state.memberStates.raid1, "raid1 member state")
        assertNotNil(state.memberStates.raid2, "raid2 member state")
    end,
}
