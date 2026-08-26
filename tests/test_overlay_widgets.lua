local LoadedNivUI, assertions = ...
local assertEquals = assertions.equals
local assertNotNil = assertions.isNotNil
local assertNil = assertions.isNil
local assertTrue = assertions.isTrue

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function CreateFrameObject(frameType, parent)
    local frame = {
        frameType = frameType,
        parent = parent,
        groups = {},
        slots = {},
        points = {},
        textures = {},
        events = {},
        scripts = {},
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
        local texture = CreateFrameObject("Texture", self)
        self.textures[#self.textures + 1] = texture
        return texture
    end

    function frame:GetStatusBarTexture()
        return self.statusBarTexture
    end

    function frame:GetHeight()
        return self.height or 1
    end

    function frame:GetWidth()
        return self.width or 1
    end

    function frame:Hide()
        self.shown = false
    end

    function frame:SetAllPoints(target)
        self.allPoints = target
        if target then
            self.width = target:GetWidth()
            self.height = target:GetHeight()
        end
    end

    function frame:SetApplicationCount(value)
        self.applicationCount = value
    end

    function frame:SetColorTexture(...)
        self.color = { ... }
    end

    function frame:SetCooldown(...)
        self.cooldown = { ... }
    end

    function frame:SetDurationCooldown(value)
        self.durationCooldown = value
    end

    function frame:SetDurationText(value)
        self.durationText = value
    end

    function frame:SetDrawEdge(value)
        self.drawEdge = value
    end

    function frame:SetDrawSwipe(value)
        self.drawSwipe = value
    end

    function frame:SetEnabled(value)
        self.enabled = value
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

    function frame:SetHideCountdownNumbers(value)
        self.hideCountdownNumbers = value
    end

    function frame:SetIcon(value)
        self.icon = value
    end

    function frame:SetClipsChildren(value)
        self.clipsChildren = value
    end

    function frame:SetMouseClickEnabled(value)
        self.mouseClickEnabled = value
    end

    function frame:SetMouseMotionEnabled(value)
        self.mouseMotionEnabled = value
    end

    function frame:SetParent(value)
        self.parent = value
    end

    function frame:SetPoint(...)
        local point = { ... }
        self.points[#self.points + 1] = point
        if point[1] == "TOPLEFT" then
            self.topLeftPoint = point
        elseif point[1] == "BOTTOMRIGHT" and self.topLeftPoint and point[2] then
            local target = point[2]
            self.width = target:GetWidth() + (point[4] or 0) - (self.topLeftPoint[4] or 0)
            self.height = target:GetHeight() + (self.topLeftPoint[5] or 0) - (point[5] or 0)
        end
    end

    function frame:SetSize(width, height)
        self.width = width
        self.height = height
    end

    function frame:SetTextColor(...)
        self.textColor = { ... }
    end

    function frame:SetText(value)
        self.text = value
    end

    function frame:SetTexture(value)
        self.texture = value
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

    function frame:RegisterEvent(event)
        self.events[event] = true
    end

    function frame:RegisterUnitEvent(event, unit)
        self.events[event] = unit
    end

    function frame:SetScript(name, script)
        self.scripts[name] = script
    end

    function frame:UnregisterAllEvents()
        self.events = {}
    end

    return frame
end

local function CreateHarness(options)
    options = options or {}
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

    NivUI.UnitFrames.RangeCheck = {
        IsInRange = function()
            return true, true
        end,
    }
    NivUI.UnitFrames.Runtime = {
        MissingRaidBuffProvider = {
            Register = function(widget)
                widget:SetMissingRaidBuffProviders({ MAGE = true, PRIEST = true })
            end,
            Unregister = function()
            end,
        },
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
        C_Spell = {
            GetSpellTexture = function(spellID)
                return "spell:" .. spellID
            end,
        },
        C_XMLUtil = {
            GetTemplateInfo = function(template)
                return template == "DisableUntrustedLayoutScriptsTemplate" and {}
            end,
        },
        CreateFrame = function(frameType, _, parent, template)
            local frame = CreateFrameObject(frameType, parent)
            frame.template = template
            frames[#frames + 1] = frame
            return frame
        end,
        issecretvalue = function(value)
            return options.secretDimensions and type(value) == "number"
        end,
        UnitCanAssist = function()
            return true
        end,
        UnitExists = function()
            return true
        end,
        UnitIsConnected = function()
            return true
        end,
        UnitIsDeadOrGhost = function()
            return false
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

    loadModule("modules/unitframes/MissingRaidBuffOverlay.lua")
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

    ["missing raid buffs build one secure inverse cell per buff"] = function()
        local harness = CreateHarness()
        local config = OverlayConfig("ICON")
        config.allow.MISSING_RAID_BUFFS = true

        local widget = harness.NivUI.WidgetFactories.overlay(
            CreateFrameObject("Parent"), config, nil, "party1")

        assertNil(widget.normalInner)
        assertEquals(#widget.missingRaidBuffCells, 6)
        assertTrue(widget.missingRaidBuffCells[1].window.shown)
        assertEquals(widget.missingRaidBuffCells[2].window.shown, false)
        assertEquals(widget.missingRaidBuffCells[4].window.shown, true)
        assertEquals(widget.missingRaidBuffCells[1].container.groups[1].filter, "HELPFUL")
        assertTrue(widget.missingRaidBuffCells[1].container.groups[1].options.candidateFilters.includeSpellIDs[1459])
        assertEquals(widget.missingRaidBuffCells[1].texture.texture, "spell:1459")
        assertEquals(widget.missingRaidBuffCells[1].badge.template,
            "DisableUntrustedLayoutScriptsTemplate")
        assertTrue(widget.missingRaidBuffCells[1].container.enabled)
    end,

    ["missing raid buffs compose with ordinary Allow filters"] = function()
        local harness = CreateHarness()
        local config = OverlayConfig("ICON")
        config.allow.MISSING_RAID_BUFFS = true
        config.mineOnly = true
        config.allow.RAID = true

        local widget = harness.NivUI.WidgetFactories.overlay(
            CreateFrameObject("Parent"), config, nil, "party1")

        assertNotNil(widget.normalInner)
        assertEquals(#widget.normalInner.groups, 1)
        assertEquals(widget.normalInner.groups[1].filter, "HELPFUL|PLAYER|RAID")
        assertEquals(#widget.missingRaidBuffCells, 6)
    end,

    ["missing raid buff slots reserve every ordinary filter group"] = function()
        local harness = CreateHarness()
        local config = OverlayConfig("ICON")
        config.allow.MISSING_RAID_BUFFS = true
        config.mineOnly = true
        config.allow.RAID = true
        config.allow.BIG_DEFENSIVE = true

        local widget = harness.NivUI.WidgetFactories.overlay(
            CreateFrameObject("Parent"), config, nil, "party1")

        assertEquals(#widget.normalInner.groups, 2)
        assertEquals(widget.missingRaidBuffCells[1].window.points[1][5], -88)
    end,

    ["missing raid buffs use overlay colors for Color displays"] = function()
        local harness = CreateHarness()
        local config = OverlayConfig("COLOR")
        config.allow.MISSING_RAID_BUFFS = true

        local widget = harness.NivUI.WidgetFactories.overlay(
            CreateFrameObject("Parent"), config, nil, "party1")

        assertEquals(widget.missingRaidBuffCells[1].texture.color[1], 1)
        assertEquals(widget.missingRaidBuffCells[1].texture.color[2], 0)
        assertEquals(widget.missingRaidBuffCells[1].texture.color[3], 0)
    end,

    ["missing raid buff eligibility suppresses only the derived cells"] = function()
        local harness = CreateHarness()
        local config = OverlayConfig("ICON")
        config.allow.MISSING_RAID_BUFFS = true
        config.mineOnly = true
        config.allow.RAID = true

        local widget = harness.NivUI.WidgetFactories.overlay(
            CreateFrameObject("Parent"), config, nil, "party1")

        widget:SetMissingRaidBuffEligible(false)

        assertEquals(widget.missingRaidBuffCells[1].window.shown, false)
        assertEquals(widget.missingRaidBuffCells[4].window.shown, false)
        assertTrue(widget.root.shown)
        assertTrue(widget.normalInner.shown)
    end,

    ["missing raid buffs resize Frame displays to their target widget"] = function()
        local harness = CreateHarness()
        local config = OverlayConfig("FRAME")
        config.allow.MISSING_RAID_BUFFS = true
        local parent = CreateFrameObject("Parent")
        local healthBar = CreateFrameObject("StatusBar")
        healthBar:SetSize(180, 24)
        healthBar.statusBarTexture = CreateFrameObject("FillTexture")
        local widget = harness.NivUI.WidgetFactories.overlay(
            parent, config, nil, "party1")

        harness.NivUI.UnitFrames.Runtime.WidgetTree.ApplyAnchors(parent, {
            healthBar = healthBar,
            ["overlay:Test"] = widget,
        }, {})

        assertEquals(widget.root.allPoints, healthBar)
        assertEquals(widget.missingRaidBuffCells[1].badge.width, 180)
        assertEquals(widget.missingRaidBuffCells[1].badge.height, 24)
        assertEquals(widget.missingRaidBuffCells[1].texture.allPoints,
            widget.missingRaidBuffCells[1].badge)
    end,

    ["missing raid buffs resize Border displays around their target widget"] = function()
        local harness = CreateHarness()
        local config = OverlayConfig("BORDER")
        config.allow.MISSING_RAID_BUFFS = true
        local parent = CreateFrameObject("Parent")
        local healthBar = CreateFrameObject("StatusBar")
        healthBar:SetSize(180, 24)
        local widget = harness.NivUI.WidgetFactories.overlay(
            parent, config, nil, "party1")

        harness.NivUI.UnitFrames.Runtime.WidgetTree.ApplyAnchors(parent, {
            healthBar = healthBar,
            ["overlay:Test"] = widget,
        }, {})

        assertEquals(widget.missingRaidBuffCells[1].badge.width, 184)
        assertEquals(widget.missingRaidBuffCells[1].badge.height, 28)
        assertEquals(#widget.missingRaidBuffCells[1].badge.textures, 4)
    end,

    ["missing raid buffs use configured target dimensions when live sizes are secret"] = function()
        local harness = CreateHarness({ secretDimensions = true })
        local config = OverlayConfig("BORDER")
        config.allow.MISSING_RAID_BUFFS = true
        local style = {
            healthBar = { size = { width = 180, height = 24 } },
        }
        local parent = CreateFrameObject("Parent")
        local healthBar = CreateFrameObject("StatusBar")
        healthBar:SetSize(180, 24)
        local widget = harness.NivUI.WidgetFactories.overlay(
            parent, config, style, "party1")

        harness.NivUI.UnitFrames.Runtime.WidgetTree.ApplyAnchors(parent, {
            healthBar = healthBar,
            ["overlay:Test"] = widget,
        }, {})

        assertEquals(widget.missingRaidBuffCells[1].badge.width, 184)
        assertEquals(widget.missingRaidBuffCells[1].badge.height, 28)
    end,

    ["missing raid buffs derive dimensions for fixed-size target widgets"] = function()
        local harness = CreateHarness({ secretDimensions = true })
        local config = OverlayConfig("BORDER")
        config.allow.MISSING_RAID_BUFFS = true
        config.targetWidget = "statusIndicators"
        local style = {
            statusIndicators = { iconSize = 16 },
        }
        local parent = CreateFrameObject("Parent")
        local statusIndicators = CreateFrameObject("Frame")
        statusIndicators:SetSize(32, 16)
        local widget = harness.NivUI.WidgetFactories.overlay(
            parent, config, style, "party1")

        harness.NivUI.UnitFrames.Runtime.WidgetTree.ApplyAnchors(parent, {
            statusIndicators = statusIndicators,
            ["overlay:Test"] = widget,
        }, {})

        assertEquals(widget.missingRaidBuffCells[1].badge.width, 36)
        assertEquals(widget.missingRaidBuffCells[1].badge.height, 20)
    end,

    ["missing raid buff previews use the six raid buff icons"] = function()
        local harness = CreateHarness()
        local config = OverlayConfig("ICON")
        config.allow.MISSING_RAID_BUFFS = true
        config.showDuration = true
        config.showStacks = true
        config.showSwipe = true
        local widget = harness.NivUI.WidgetFactories.overlay(
            CreateFrameObject("Parent"), config, nil, "player", { forPreview = true })

        assertEquals(widget.icons[1].texture.texture, "spell:1459")
        assertEquals(widget.icons[6].texture.texture, "spell:364342")
        assertEquals(widget.icons[1].cooldown.cooldown[1], 0)
        assertEquals(widget.icons[1].stacks.text, "")
        assertTrue(widget.icons[6].shown)
    end,
}
