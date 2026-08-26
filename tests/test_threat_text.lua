local _, assertions = ...
local assertEquals = assertions.equals
local assertFalse = assertions.isFalse
local assertTrue = assertions.isTrue

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function loadChunk(relativePath, environment, NivUI)
    local chunk = assert(loadfile(addonRoot .. "/" .. relativePath))
    setfenv(chunk, environment)
    chunk("NivUI", NivUI)
end

local function createWidgetHarness()
    local leadPercentage
    local leadIsSecret = false
    local leadCalls = {}
    local threatStatus
    local isTanking
    local playerRole = "DAMAGER"

    local function createFontString()
        local text = {}

        function text:SetAllPoints() end
        function text:SetFont() end
        function text:SetJustifyH() end
        function text:SetJustifyV() end
        function text:SetText(value)
            self.value = value
        end
        function text:SetTextColor(r, g, b, a)
            self.color = { r = r, g = g, b = b, a = a }
        end
        function text:SetFormattedText(format, ...)
            self.value = string.format(format, ...)
        end

        return text
    end

    local function createFrame()
        local frame = { shown = true }

        function frame:SetSize(width, height)
            self.width = width
            self.height = height
        end
        function frame:SetWidth(width)
            self.width = width
        end
        function frame:SetFrameStrata() end
        function frame:SetFrameLevel() end
        function frame:CreateFontString()
            return createFontString()
        end
        function frame:Show()
            self.shown = true
        end
        function frame:Hide()
            self.shown = false
        end
        function frame:IsShown()
            return self.shown
        end

        return frame
    end

    local NivUI = {
        UnitFrames = {
            Runtime = {},
            DEFAULT_STYLE = {
                threatText = {
                    colorMode = "threat",
                    invertForTanks = true,
                    color = { r = 1, g = 1, b = 1, a = 1 },
                    safeColor = { r = 1, g = 1, b = 1, a = 1 },
                    warningColor = { r = 1, g = 0.5, b = 0, a = 1 },
                    dangerColor = { r = 1, g = 0, b = 0, a = 1 },
                },
            },
        },
        Roster = {},
    }

    function NivUI.Roster:GetRole()
        return playerRole
    end

    function NivUI:GetFontPath(font)
        return font
    end

    local environment = setmetatable({
        CreateFrame = createFrame,
        issecretvalue = function(value)
            return leadIsSecret and value == leadPercentage
        end,
        UnitThreatPercentageOfLead = function(sourceUnit, targetUnit)
            leadCalls[#leadCalls + 1] = { sourceUnit, targetUnit }
            return leadPercentage
        end,
        UnitDetailedThreatSituation = function()
            return isTanking, threatStatus
        end,
    }, { __index = _G })

    loadChunk("modules/unitframes/WidgetFactories.lua", environment, NivUI)
    loadChunk("modules/unitframes/runtime/StandardWidgetUpdater.lua", environment, NivUI)

    local harness = {
        NivUI = NivUI,
        leadCalls = leadCalls,
    }

    function harness:setLeadPercentage(value, isSecret)
        leadPercentage = value
        leadIsSecret = isSecret == true
    end

    function harness:setThreatStatus(value, tanking)
        threatStatus = value
        isTanking = tanking
    end

    function harness:setPlayerRole(role)
        playerRole = role
    end

    function harness:createState(frameType, unit, threatConfig)
        local widget = createFrame()
        widget.text = createFontString()
        return {
            frameType = frameType,
            unit = unit,
            currentStyle = threatConfig and { threatText = threatConfig } or nil,
            customFrame = {
                widgets = {
                    threatText = widget,
                },
            },
        }, widget
    end

    return harness
end

local function assertColor(widget, expected, message)
    assertEquals(widget.text.color.r, expected.r, message .. " red")
    assertEquals(widget.text.color.g, expected.g, message .. " green")
    assertEquals(widget.text.color.b, expected.b, message .. " blue")
    assertEquals(widget.text.color.a, expected.a or 1, message .. " alpha")
end

local function registeredThreatEvents(relativePath, globalName)
    local capturedConfig
    local Base = {}

    function Base.CreateHideBlizzardFrame()
        return function() end, function() end
    end

    function Base.CreateModule(config)
        capturedConfig = config
        return {}
    end

    local NivUI = {
        UnitFrames = {
            Base = Base,
        },
    }
    local environment = setmetatable({
        [globalName] = {},
        RegisterAttributeDriver = function() end,
    }, { __index = _G })

    loadChunk(relativePath, environment, NivUI)

    local events = {}
    local frame = {}
    function frame:RegisterEvent(event)
        events[event] = true
    end

    capturedConfig.registerEvents(frame)
    return events
end

return {
    ["the threat widget factory creates a compact preview value"] = function()
        local harness = createWidgetHarness()
        local widget = harness.NivUI.WidgetFactories.threatText({}, {
            width = 60,
            font = "Friz Quadrata",
            fontSize = 12,
            fontOutline = "OUTLINE",
            alignment = "CENTER",
            colorMode = "threat",
            invertForTanks = true,
            color = { r = 1, g = 1, b = 1, a = 1 },
            safeColor = { r = 0.8, g = 0.9, b = 1, a = 1 },
            warningColor = { r = 1, g = 0.5, b = 0, a = 1 },
            dangerColor = { r = 1, g = 0, b = 0, a = 1 },
        })

        assertEquals(widget.width, 60, "widget width")
        assertEquals(widget.text.value, "200%", "preview value")
        assertEquals(widget.widgetType, "threatText", "widget type")
        assertColor(widget, { r = 0.8, g = 0.9, b = 1, a = 1 }, "preview safe color")
    end,

    ["threat text displays a lead above one hundred percent"] = function()
        local harness = createWidgetHarness()
        harness:setLeadPercentage(207.6)
        local state, widget = harness:createState("target", "target")

        harness.NivUI.UnitFrames.Runtime.StandardWidgetUpdater.UpdateThreatText(state)

        assertEquals(widget.text.value, "208%", "lead percentage")
        assertTrue(widget:IsShown(), "widget visibility")
        assertEquals(harness.leadCalls[1][1], "player", "source unit")
        assertEquals(harness.leadCalls[1][2], "target", "target unit")
    end,

    ["threat text supports focus frames"] = function()
        local harness = createWidgetHarness()
        harness:setLeadPercentage(145)
        local state, widget = harness:createState("focus", "focus")

        harness.NivUI.UnitFrames.Runtime.StandardWidgetUpdater.UpdateThreatText(state)

        assertEquals(widget.text.value, "145%", "focus threat lead")
        assertTrue(widget:IsShown(), "focus widget visibility")
    end,

    ["damage roles use safe warning and danger colors"] = function()
        local harness = createWidgetHarness()
        harness:setLeadPercentage(95)
        harness:setPlayerRole("DAMAGER")
        local state, widget = harness:createState("target", "target")

        local cases = {
            { status = 0, color = { r = 1, g = 1, b = 1, a = 1 } },
            { status = 1, color = { r = 1, g = 0.5, b = 0, a = 1 } },
            { status = 2, color = { r = 1, g = 0, b = 0, a = 1 } },
            { status = 3, color = { r = 1, g = 0, b = 0, a = 1 } },
        }

        for _, case in ipairs(cases) do
            harness:setThreatStatus(case.status, case.status >= 2)
            harness.NivUI.UnitFrames.Runtime.StandardWidgetUpdater.UpdateThreatText(state)
            assertColor(widget, case.color, "damage status " .. case.status)
        end
    end,

    ["tank roles invert safe warning and danger states"] = function()
        local harness = createWidgetHarness()
        harness:setLeadPercentage(160)
        harness:setPlayerRole("TANK")
        local state, widget = harness:createState("target", "target")

        local cases = {
            { status = 0, color = { r = 1, g = 0, b = 0, a = 1 } },
            { status = 1, color = { r = 1, g = 0, b = 0, a = 1 } },
            { status = 2, color = { r = 1, g = 0.5, b = 0, a = 1 } },
            { status = 3, color = { r = 1, g = 1, b = 1, a = 1 } },
        }

        for _, case in ipairs(cases) do
            harness:setThreatStatus(case.status, case.status >= 2)
            harness.NivUI.UnitFrames.Runtime.StandardWidgetUpdater.UpdateThreatText(state)
            assertColor(widget, case.color, "tank status " .. case.status)
        end
    end,

    ["configured threat colors replace the defaults"] = function()
        local harness = createWidgetHarness()
        harness:setLeadPercentage(120)
        harness:setThreatStatus(1, false)
        local state, widget = harness:createState("target", "target", {
            colorMode = "threat",
            invertForTanks = false,
            color = { r = 1, g = 1, b = 1, a = 1 },
            safeColor = { r = 0.1, g = 0.2, b = 0.3, a = 0.4 },
            warningColor = { r = 0.2, g = 0.3, b = 0.4, a = 0.5 },
            dangerColor = { r = 0.3, g = 0.4, b = 0.5, a = 0.6 },
        })

        harness.NivUI.UnitFrames.Runtime.StandardWidgetUpdater.UpdateThreatText(state)

        assertColor(widget, { r = 0.2, g = 0.3, b = 0.4, a = 0.5 }, "custom warning")
    end,

    ["single color mode ignores threat status"] = function()
        local harness = createWidgetHarness()
        harness:setLeadPercentage(200)
        harness:setThreatStatus(3, true)
        local state, widget = harness:createState("target", "target", {
            colorMode = "static",
            color = { r = 0.2, g = 0.4, b = 0.6, a = 0.8 },
        })

        harness.NivUI.UnitFrames.Runtime.StandardWidgetUpdater.UpdateThreatText(state)

        assertColor(widget, { r = 0.2, g = 0.4, b = 0.6, a = 0.8 }, "single color")
    end,

    ["threat text clears and hides when no threat exists"] = function()
        local harness = createWidgetHarness()
        harness:setLeadPercentage(nil)
        local state, widget = harness:createState("target", "target")
        widget.text:SetText("92%")

        harness.NivUI.UnitFrames.Runtime.StandardWidgetUpdater.UpdateThreatText(state)

        assertEquals(widget.text.value, "", "cleared text")
        assertFalse(widget:IsShown(), "widget visibility")
    end,

    ["threat text hides protected lead values"] = function()
        local harness = createWidgetHarness()
        harness:setLeadPercentage(180, true)
        local state, widget = harness:createState("target", "target")

        harness.NivUI.UnitFrames.Runtime.StandardWidgetUpdater.UpdateThreatText(state)

        assertEquals(widget.text.value, "", "cleared text")
        assertFalse(widget:IsShown(), "widget visibility")
    end,

    ["threat text remains hidden on unsupported frame types"] = function()
        local harness = createWidgetHarness()
        harness:setLeadPercentage(170)
        local state, widget = harness:createState("boss", "boss1")

        harness.NivUI.UnitFrames.Runtime.StandardWidgetUpdater.UpdateThreatText(state)

        assertEquals(#harness.leadCalls, 0, "threat API calls")
        assertFalse(widget:IsShown(), "widget visibility")
    end,

    ["target and focus frames subscribe to threat changes"] = function()
        local targetEvents = registeredThreatEvents("modules/unitframes/TargetFrame.lua", "TargetFrame")
        local focusEvents = registeredThreatEvents("modules/unitframes/FocusFrame.lua", "FocusFrame")

        assertTrue(targetEvents.UNIT_THREAT_LIST_UPDATE, "target threat list event")
        assertTrue(targetEvents.UNIT_THREAT_SITUATION_UPDATE, "target threat situation event")
        assertTrue(focusEvents.UNIT_THREAT_LIST_UPDATE, "focus threat list event")
        assertTrue(focusEvents.UNIT_THREAT_SITUATION_UPDATE, "focus threat situation event")
    end,
}
