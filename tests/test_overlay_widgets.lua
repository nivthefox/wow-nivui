local LoadedNivUI, assertions = ...
local assertEquals = assertions.equals
local assertNotNil = assertions.isNotNil

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function CreateFrameObject(frameType)
    local frame = {
        frameType = frameType,
        groups = {},
        slots = {},
        points = {},
        shown = true,
    }

    function frame:AddAuraGroup(name, filter, options)
        self.groups[#self.groups + 1] = { name = name, filter = filter, options = options }
    end

    function frame:AddAuraSlot(name, filter, options)
        self.slots[#self.slots + 1] = { name = name, filter = filter, options = options }
    end

    function frame:ClearAllPoints()
        self.points = {}
        self.allPoints = nil
    end

    function frame:CreateFontString()
        return CreateFrameObject("FontString")
    end

    function frame:CreateTexture()
        return CreateFrameObject("Texture")
    end

    function frame:GetStatusBarTexture()
        return self.statusBarTexture
    end

    function frame:Hide()
        self.shown = false
    end

    function frame:SetAllPoints(target)
        self.allPoints = target
    end

    function frame:SetApplicationCount(value)
        self.applicationCount = value
    end

    function frame:SetColorTexture(...)
        self.color = { ... }
    end

    function frame:SetDurationCooldown(value)
        self.durationCooldown = value
    end

    function frame:SetDurationText(value)
        self.durationText = value
    end

    function frame:SetFlowLayoutAnchorPoint(value)
        self.flowAnchor = value
    end

    function frame:SetFlowLayoutAxis(value)
        self.flowAxis = value
    end

    function frame:SetFlowLayoutGrowthDirection(horizontal, vertical)
        self.flowHorizontal = horizontal
        self.flowVertical = vertical
    end

    function frame:SetFlowLayoutMaximumLineSize(value)
        self.maximumLineSize = value
    end

    function frame:SetFont(...)
        self.font = { ... }
    end

    function frame:SetFontObject(value)
        self.fontObject = value
    end

    function frame:SetFrameLevel(value)
        self.frameLevel = value
    end

    function frame:SetFrameStrata(value)
        self.frameStrata = value
    end

    function frame:SetHeight(value)
        self.height = value
    end

    function frame:SetIcon(value)
        self.icon = value
    end

    function frame:SetPoint(...)
        self.points[#self.points + 1] = { ... }
    end

    function frame:SetSize(width, height)
        self.width = width
        self.height = height
    end

    function frame:SetTextColor(...)
        self.textColor = { ... }
    end

    function frame:SetUnit(value)
        self.unit = value
    end

    function frame:SetWidth(value)
        self.width = value
    end

    function frame:Show()
        self.shown = true
    end

    return frame
end

local function CreateHarness()
    local frames = {}
    local NivUI = {
        Filters = LoadedNivUI.Filters,
        OverlayLogic = LoadedNivUI.OverlayLogic,
        Roster = {
            GetClass = function()
                return "PRIEST"
            end,
            GetRole = function()
                return "HEALER"
            end,
            IsAssist = function()
                return false
            end,
            IsLeader = function()
                return false
            end,
        },
        UnitFrames = {},
    }

    function NivUI:GetFontPath()
        return "font.ttf"
    end

    local environment = setmetatable({
        AnchorUtil = {
            FlowDirection = {
                Down = "Down",
                Left = "Left",
                Right = "Right",
                Up = "Up",
            },
            FlowLayoutAxis = {
                Horizontal = "Horizontal",
                Vertical = "Vertical",
            },
        },
        CreateFrame = function(frameType)
            local frame = CreateFrameObject(frameType)
            frames[#frames + 1] = frame
            return frame
        end,
    }, { __index = _G })

    local function loadModule(relativePath)
        local chunk, loadError = loadfile(addonRoot .. "/" .. relativePath)
        if not chunk then
            error(loadError, 0)
        end
        setfenv(chunk, environment)
        chunk("NivUI", NivUI)
    end

    loadModule("modules/unitframes/WidgetFactories.lua")
    loadModule("modules/unitframes/runtime/WidgetTree.lua")

    return {
        frames = frames,
        NivUI = NivUI,
    }
end

local function OverlayConfig(displayType)
    return {
        allow = {},
        anchor = {
            point = "CENTER",
            relativePoint = "CENTER",
            relativeTo = "frame",
            x = 0,
            y = 0,
        },
        auraType = "HELPFUL",
        block = {},
        borderThickness = 2,
        color = { r = 1, g = 0, b = 0, a = 1 },
        displayType = displayType,
        duration = {},
        iconSize = 20,
        maxIcons = 8,
        perRow = 4,
        showDuration = false,
        showStacks = false,
        showSwipe = false,
        spacing = 2,
        stacks = {},
        targetWidget = "healthBar",
        wrap = "DOWN",
        growth = "RIGHT",
    }
end

return {
    ["live icon overlays use AuraContainer groups"] = function()
        local harness = CreateHarness()
        local widget = harness.NivUI.WidgetFactories.overlay(
            CreateFrameObject("Parent"), OverlayConfig("ICON"), nil, "party1")

        assertEquals(widget.inner.frameType, "AuraContainer")
        assertEquals(widget.inner.unit, "party1")
        assertEquals(#widget.inner.groups, 1)
        assertEquals(widget.inner.groups[1].filter, "HELPFUL")
        assertEquals(widget.inner.groups[1].options.maxFrameCount, 8)
        assertEquals(widget.inner.flowAxis, "Horizontal")
        assertNotNil(widget.anchorOverride)
    end,

    ["live border overlays use AuraContainer slots"] = function()
        local harness = CreateHarness()
        local widget = harness.NivUI.WidgetFactories.overlay(
            CreateFrameObject("Parent"), OverlayConfig("BORDER"), nil, "raid1")

        assertEquals(widget.inner.frameType, "AuraContainer")
        assertEquals(#widget.inner.slots, 1)
        assertEquals(widget.borderTarget, "healthBar")
        assertEquals(widget.borderThickness, 2)
    end,

    ["frame overlay tint textures anchor to the status-bar fill"] = function()
        local harness = CreateHarness()
        local parent = CreateFrameObject("Parent")
        local healthBar = CreateFrameObject("StatusBar")
        healthBar.statusBarTexture = CreateFrameObject("FillTexture")
        local widget = harness.NivUI.WidgetFactories.overlay(
            parent, OverlayConfig("FRAME"), nil, "raid1")
        local button = CreateFrameObject("AuraButton")

        widget.inner.slots[1].options.initializeFrame(button)
        harness.NivUI.UnitFrames.Runtime.WidgetTree.ApplyAnchors(parent, {
            healthBar = healthBar,
            ["overlay:Test"] = widget,
        }, {})

        assertEquals(widget.inner.allPoints, healthBar)
        assertEquals(#widget.fillTintTextures, 1)
        assertEquals(widget.fillTintTextures[1].allPoints, healthBar.statusBarTexture)
    end,

    ["border containers anchor around their configured targets"] = function()
        local harness = CreateHarness()
        local parent = CreateFrameObject("Parent")
        local healthBar = CreateFrameObject("StatusBar")
        local widget = harness.NivUI.WidgetFactories.overlay(
            parent, OverlayConfig("BORDER"), nil, "raid1")

        harness.NivUI.UnitFrames.Runtime.WidgetTree.ApplyAnchors(parent, {
            healthBar = healthBar,
            ["overlay:Test"] = widget,
        }, {})

        assertEquals(#widget.inner.points, 2)
        assertEquals(widget.inner.points[1][1], "TOPLEFT")
        assertEquals(widget.inner.points[1][2], healthBar)
        assertEquals(widget.inner.points[1][4], -2)
        assertEquals(widget.inner.points[1][5], 2)
    end,
}
