local _, assertions = ...
local assertEquals = assertions.equals
local assertTrue = assertions.isTrue
local assertFalse = assertions.isFalse
local assertNotNil = assertions.isNotNil

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function copy(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}
    for key, child in pairs(value) do
        result[key] = copy(child)
    end
    return result
end

local function createRegion()
    local region = {
        shown = false,
        scripts = {},
        events = {},
        textures = {},
    }

    function region:RegisterEvent(event)
        self.events[event] = true
    end

    function region:RegisterUnitEvent(event)
        self.events[event] = true
    end

    function region:UnregisterEvent(event)
        self.events[event] = nil
    end

    function region:UnregisterAllEvents()
        self.events = {}
    end

    function region:SetScript(name, callback)
        self.scripts[name] = callback
    end

    function region:GetScript(name)
        return self.scripts[name]
    end

    function region:SetSize(width, height)
        self.width = width
        self.height = height
    end

    function region:SetWidth(width)
        self.width = width
    end

    function region:SetHeight(height)
        self.height = height
    end

    function region:SetToplevel(value)
        self.toplevel = value
    end

    function region:SetMovable(value)
        self.movable = value
    end

    function region:SetClampedToScreen(value)
        self.clampedToScreen = value
    end

    function region:EnableMouse(value)
        self.mouseEnabled = value
    end

    function region:RegisterForDrag(...)
        self.dragButtons = { ... }
    end

    function region:StopMovingOrSizing()
        self.moving = false
    end

    function region:SetUserPlaced(value)
        self.userPlaced = value
    end

    function region:SetTitle(title)
        self.title = title
    end

    function region:GetWidth()
        return self.width
    end

    function region:GetHeight()
        return self.height
    end

    function region:SetPoint(...)
        self.point = { ... }
    end

    function region:ClearAllPoints()
        self.point = nil
    end

    function region:SetAllPoints()
        self.allPoints = true
    end

    function region:SetBackdrop(backdrop)
        self.backdrop = backdrop
    end

    function region:SetBackdropBorderColor(...)
        self.borderColor = { ... }
    end

    function region:SetColorTexture(...)
        self.color = { ... }
    end

    function region:CreateTexture()
        local texture = createRegion()
        self.textures[#self.textures + 1] = texture
        return texture
    end

    function region:CreateFontString()
        return createRegion()
    end

    function region:SetTexture(texture)
        self.texture = texture
    end

    function region:SetBlendMode(blendMode)
        self.blendMode = blendMode
    end

    function region:SetFont(path, size, flags)
        self.font = { path, size, flags }
    end

    function region:SetTextColor(...)
        self.textColor = { ... }
    end

    function region:SetShadowOffset(...)
        self.shadowOffset = { ... }
    end

    function region:SetText(text)
        self.text = text
    end

    function region:SetFontObject(fontObject)
        self.fontObject = fontObject
    end

    function region:SetJustifyH(justification)
        self.justification = justification
    end

    function region:SetStatusBarTexture(texture)
        self.statusBarTexturePath = texture
        self.statusBarTexture = self.statusBarTexture or createRegion()
    end

    function region:GetStatusBarTexture()
        return self.statusBarTexture
    end

    function region:SetStatusBarColor(...)
        self.statusBarColor = { ... }
    end

    function region:SetMinMaxValues(minimum, maximum)
        self.minimum = minimum
        self.maximum = maximum
    end

    function region:SetValue(value)
        self.value = value
    end

    function region:Show()
        local wasShown = self.shown
        self.shown = true
        if not wasShown and self.scripts.OnShow then
            self.scripts.OnShow(self)
        end
    end

    function region:Hide()
        local wasShown = self.shown
        self.shown = false
        if wasShown and self.scripts.OnHide then
            self.scripts.OnHide(self)
        end
    end

    function region:IsShown()
        return self.shown
    end

    function region:SetParent(parent)
        self.parent = parent
    end

    return region
end

local function loadChunk(path, environment, ...)
    local chunk, loadError = loadfile(path)
    if not chunk then
        error(loadError, 0)
    end
    setfenv(chunk, environment)
    return chunk(...)
end

local function createAddon(profileData)
    local frames = {}
    local combatLocked = false
    local specializationID = 268
    local namespace = {}
    local environment = setmetatable({
        C_Timer = {
            NewTicker = function()
                return { Cancel = function() end }
            end,
            NewTimer = function(_, callback)
                callback()
                return { Cancel = function() end }
            end,
        },
        C_UnitAuras = {
            GetPlayerAuraBySpellID = function()
                return nil
            end,
        },
        CreateFrame = function()
            local frame = createRegion()
            frame.Inset = createRegion()
            frames[#frames + 1] = frame
            return frame
        end,
        GetRealmName = function()
            return "Test Realm"
        end,
        GetTime = function()
            return 0
        end,
        GetSpecialization = function()
            return 1
        end,
        GetSpecializationInfo = function()
            return specializationID
        end,
        InCombatLockdown = function()
            return combatLocked
        end,
        RegisterStateDriver = function() end,
        ReloadUI = function() end,
        SlashCmdList = {},
        UIParent = createRegion(),
        UnitAffectingCombat = function()
            return combatLocked
        end,
        UnitClass = function()
            return "Tester", "MONK"
        end,
        UnitHealthMax = function()
            return 1000
        end,
        UnitName = function()
            return "Tester"
        end,
        UnitPartialPower = function()
            return 0
        end,
        UnitPower = function()
            return 3
        end,
        UnitPowerMax = function()
            return 5
        end,
        UnitStagger = function()
            return 200
        end,
        UnregisterStateDriver = function() end,
        hooksecurefunc = function() end,
        issecretvalue = function()
            return false
        end,
        print = function() end,
        wipe = function(tableToWipe)
            for key in pairs(tableToWipe) do
                tableToWipe[key] = nil
            end
        end,
        NivUI_DB = {
            version = 2,
            profiles = copy(profileData),
        },
        NivUI_CurrentProfile = "Alpha",
    }, { __index = _G })

    local harness = {
        environment = environment,
        frames = frames,
        namespace = namespace,
    }

    function harness:load(relativePath)
        loadChunk(addonRoot .. "/" .. relativePath, environment, "NivUI", namespace)
    end

    function harness:fire(event, ...)
        local eventFrames = {}
        for index, frame in ipairs(frames) do
            eventFrames[index] = frame
        end
        for _, frame in ipairs(eventFrames) do
            local callback = frame.events[event] and frame.scripts.OnEvent
            if callback then
                callback(frame, event, ...)
            end
        end
    end

    function harness:initialize()
        self:fire("ADDON_LOADED", "NivUI")
    end

    function harness:setCombatLocked(locked)
        combatLocked = locked
    end

    function harness:setSpecializationID(specID)
        specializationID = specID
    end

    harness:load("NivUI.lua")
    harness:load("modules/ReferenceIntegrity.lua")
    harness:load("modules/config/Lifecycle.lua")
    namespace.activeProfileName = "Alpha"
    harness.providedGetActiveProfile = type(namespace.GetActiveProfile) == "function"
    if not harness.providedGetActiveProfile then
        function namespace:GetActiveProfile()
            return environment.NivUI_DB.profiles[self.activeProfileName]
        end
    end

    return harness
end

local function assertColor(actual, expected, message)
    assertEquals(actual[1], expected.r, message .. " red")
    assertEquals(actual[2], expected.g, message .. " green")
    assertEquals(actual[3], expected.b, message .. " blue")
    assertEquals(actual[4], expected.a, message .. " alpha")
end

local alphaStyle = {
    frame = { width = 120, height = 36 },
    healthBar = { color = { r = 0.8, g = 0.1, b = 0.1, a = 1 } },
}

local betaStyle = {
    frame = { width = 240, height = 72 },
    healthBar = { color = { r = 0.1, g = 0.2, b = 0.9, a = 1 } },
}

local function unitFrameProfiles()
    return {
        Alpha = {
            unitFrameEnabled = { player = true },
            unitFrameAssignments = { player = "Alpha Style" },
            unitFrameStyles = { ["Alpha Style"] = copy(alphaStyle) },
            unitFrameVisibilityOverrides = { player = "[combat] show; hide" },
        },
        Beta = {
            unitFrameEnabled = { player = true },
            unitFrameAssignments = { player = "Beta Style" },
            unitFrameStyles = { ["Beta Style"] = copy(betaStyle) },
            unitFrameVisibilityOverrides = { player = "show" },
        },
    }
end

local function createConfigHarness()
    local harness = createAddon(unitFrameProfiles())
    local NivUI = harness.namespace
    local environment = harness.environment

    local function setupTab()
        return environment.CreateFrame()
    end

    NivUI.Config = {
        Bars = {
            SetupTab = function()
                return setupTab()
            end,
        },
        Filters = { SetupTab = setupTab },
        Overlays = { SetupTab = setupTab },
        Profiles = { SetupTab = setupTab },
    }
    NivUI.UnitFrames = { SetupConfigTabWithSubtabs = setupTab }
    environment.UISpecialFrames = {}
    environment.ButtonFrameTemplate_HidePortrait = function() end
    environment.ButtonFrameTemplate_HideButtonBar = function() end
    environment.PanelTemplates_TabResize = function() end
    environment.PanelTemplates_DeselectTab = function() end

    local frameCountBeforeConfigLoad = #harness.frames
    harness:load("ConfigFrame.lua")

    return harness, NivUI, environment, frameCountBeforeConfigLoad
end

local alphaBar = {
    point = "CENTER",
    x = 10,
    y = 20,
    width = 120,
    height = 12,
    spacing = 2,
    visibility = "always",
    emptyColor = { r = 0.1, g = 0.2, b = 0.3, a = 0.4 },
    filledColor = { r = 0.5, g = 0.6, b = 0.7, a = 0.8 },
    borderColor = { r = 0.9, g = 0.8, b = 0.7, a = 0.6 },
    updateInterval = 0.1,
}

local betaBar = {
    point = "CENTER",
    x = -30,
    y = -40,
    width = 260,
    height = 26,
    spacing = 5,
    visibility = "never",
    emptyColor = { r = 0.8, g = 0.7, b = 0.6, a = 0.5 },
    filledColor = { r = 0.4, g = 0.3, b = 0.2, a = 0.1 },
    borderColor = { r = 0.2, g = 0.4, b = 0.6, a = 0.8 },
    updateInterval = 0.2,
}

local function assertSegmentedBar(frame, expected, message)
    assertEquals(frame:GetWidth(), expected.width, message .. " width")
    assertEquals(frame:GetHeight(), expected.height, message .. " height")
    assertEquals(frame:IsShown(), expected.visibility == "always", message .. " visibility")
    assertColor(frame.segments[1].bg.color, expected.emptyColor, message .. " empty color")
    assertColor(frame.segments[1].bar.color, expected.filledColor, message .. " filled color")
    assertColor(frame.border.borderColor, expected.borderColor, message .. " border color")
end

local alphaStagger = {
    visibility = "always",
    updateInterval = 0.2,
    width = 310,
    height = 18,
    point = "CENTER",
    x = 15,
    y = 25,
    foregroundTexture = "AlphaTexture",
    backgroundColor = { r = 0.1, g = 0.3, b = 0.5, a = 0.7 },
    borderStyle = "thin",
    borderColor = { r = 0.2, g = 0.4, b = 0.6, a = 0.8 },
    font = "AlphaFont",
    fontSize = 11,
    fontColor = { r = 0.9, g = 0.8, b = 0.7, a = 1 },
    fontShadow = true,
}

local betaStagger = {
    visibility = "never",
    updateInterval = 0.3,
    width = 470,
    height = 28,
    point = "CENTER",
    x = -35,
    y = -45,
    foregroundTexture = "BetaTexture",
    backgroundColor = { r = 0.7, g = 0.5, b = 0.3, a = 0.1 },
    borderStyle = "thick",
    borderColor = { r = 0.8, g = 0.6, b = 0.4, a = 0.2 },
    font = "BetaFont",
    fontSize = 17,
    fontColor = { r = 0.3, g = 0.2, b = 0.1, a = 1 },
    fontShadow = false,
}

local function assertStaggerBar(frame, expected, message)
    assertEquals(frame:GetWidth(), expected.width, message .. " width")
    assertEquals(frame:GetHeight(), expected.height, message .. " height")
    assertEquals(frame:IsShown(), expected.visibility == "always", message .. " visibility")
    assertEquals(frame.bar.statusBarTexturePath, expected.foregroundTexture, message .. " texture")
    assertColor(frame.bg.color, expected.backgroundColor, message .. " background color")
    assertColor(frame.border.borderColor, expected.borderColor, message .. " border color")
    assertEquals(frame.textLeft.font[1], expected.font, message .. " font")
    assertEquals(frame.textLeft.font[2], expected.fontSize, message .. " font size")
end

return {
    ["resetting an inactive profile defers module defaults until activation"] = function()
        local profiles = unitFrameProfiles()
        profiles.Beta.testBar = { width = 999 }
        local harness = createAddon(profiles)
        local NivUI = harness.namespace
        local database = harness.environment.NivUI_DB
        local applyCount = 0

        NivUI.classBarRegistry.test = {
            dbKey = "testBar",
            defaults = { width = 160, nested = { value = 42 } },
        }
        NivUI:RegisterProfileApplyCallback("test-reset", function()
            applyCount = applyCount + 1
        end)
        harness:load("modules/profiles/Profiles.lua")
        harness:initialize()

        local activeProfile = NivUI:GetActiveProfile()
        assertTrue(NivUI.Profiles:ResetProfile("Beta"))
        assertEquals(NivUI:GetActiveProfile(), activeProfile, "inactive reset preserves active profile")
        assertEquals(database.profiles.Beta.testBar, nil, "inactive module defaults remain deferred")
        assertNotNil(database.profiles.Beta.unitFrameStyles.Default, "inactive references are reconciled")
        assertEquals(applyCount, 0, "inactive reset does not apply active profile")

        assertTrue(NivUI.Profiles:SwitchProfile("Beta"))
        assertEquals(database.profiles.Beta.testBar.width, 160, "module default after activation")
        assertEquals(database.profiles.Beta.testBar.nested.value, 42, "nested default after activation")
        assertEquals(applyCount, 1, "activation applies reset profile")
    end,

    ["resetting the active profile restores defaults and reapplies it"] = function()
        local profiles = unitFrameProfiles()
        profiles.Alpha.testBar = { width = 999, nested = { value = -1 } }
        profiles.Alpha.classBarEnabled = { test = true }
        local harness = createAddon(profiles)
        local NivUI = harness.namespace
        local applyCount = 0

        NivUI.classBarRegistry.test = {
            dbKey = "testBar",
            defaults = { width = 160, nested = { value = 42 } },
        }
        NivUI:RegisterProfileApplyCallback("test-reset", function()
            applyCount = applyCount + 1
        end)
        harness:load("modules/profiles/Profiles.lua")
        harness:initialize()

        local previousProfile = NivUI:GetActiveProfile()
        assertTrue(NivUI.Profiles:ResetProfile())

        local resetProfile = NivUI:GetActiveProfile()
        assertTrue(resetProfile ~= previousProfile, "active reset replaces the stored profile")
        assertEquals(resetProfile.testBar.width, 160, "module width default")
        assertEquals(resetProfile.testBar.nested.value, 42, "nested module default")
        assertEquals(resetProfile.classBarEnabled.test, nil, "enabled state returns to opt-in default")
        assertNotNil(resetProfile.unitFrameStyles.Default, "references are reconciled")
        assertEquals(applyCount, 1, "active reset reapplies profile")
    end,

    ["resetting a missing profile fails without mutation"] = function()
        local harness = createAddon(unitFrameProfiles())
        local NivUI = harness.namespace
        local database = harness.environment.NivUI_DB
        local applyCount = 0

        NivUI:RegisterProfileApplyCallback("test-reset", function()
            applyCount = applyCount + 1
        end)
        harness:load("modules/profiles/Profiles.lua")
        harness:initialize()

        local activeProfile = NivUI:GetActiveProfile()
        local success, message = NivUI.Profiles:ResetProfile("Missing")

        assertFalse(success, "missing reset result")
        assertEquals(message, "Profile does not exist", "missing reset message")
        assertEquals(NivUI:GetActiveProfile(), activeProfile, "missing reset preserves active profile")
        assertEquals(database.profiles.Missing, nil, "missing profile remains absent")
        assertEquals(applyCount, 0, "missing reset does not apply profile")
    end,

    ["database initialization repairs references before config is opened"] = function()
        local profiles = {
            Alpha = {
                unitFrameStyles = { Valid = {} },
                unitFrameAssignments = { player = "Missing" },
                customRaidGroups = { group = { styleName = "Missing" } },
            },
        }
        local harness = createAddon(profiles)
        local database = harness.environment.NivUI_DB
        database.charMeta = {
            ["Tester-Test Realm"] = {
                specProfileMap = { [268] = "Missing" },
            },
        }

        harness:initialize()

        assertEquals(database.profiles.Alpha.unitFrameAssignments.player, "Valid")
        assertEquals(database.profiles.Alpha.customRaidGroups.group.styleName, "Valid")
        assertEquals(database.charMeta["Tester-Test Realm"].specProfileMap[268], nil)
        assertEquals(harness.namespace.ConfigFrame, nil, "config remains unconstructed")
    end,

    ["active profile API tracks direct switches in both directions"] = function()
        local profiles = unitFrameProfiles()
        local harness = createAddon(profiles)
        local NivUI = harness.namespace
        harness:load("modules/profiles/Profiles.lua")
        harness:initialize()

        assertTrue(harness.providedGetActiveProfile, "NivUI should provide GetActiveProfile")
        assertEquals(NivUI.activeProfileName, "Alpha", "initial active profile name")
        assertEquals(NivUI:GetActiveProfile(), harness.environment.NivUI_DB.profiles.Alpha,
            "initial active profile table")

        local switchedToBeta = NivUI.Profiles:SwitchProfile("Beta")
        assertTrue(switchedToBeta, "Alpha to Beta switch")
        assertEquals(NivUI.activeProfileName, "Beta", "active profile name after Alpha to Beta")
        assertEquals(NivUI:GetActiveProfile(), harness.environment.NivUI_DB.profiles.Beta,
            "active profile table after Alpha to Beta")

        local switchedToAlpha = NivUI.Profiles:SwitchProfile("Alpha")
        assertTrue(switchedToAlpha, "Beta to Alpha switch")
        assertEquals(NivUI.activeProfileName, "Alpha", "active profile name after Beta to Alpha")
        assertEquals(NivUI:GetActiveProfile(), harness.environment.NivUI_DB.profiles.Alpha,
            "active profile table after Beta to Alpha")
    end,

    ["the config frame is constructed only on the first slash command after initialization"] = function()
        local harness, NivUI, environment, frameCountBeforeConfigLoad = createConfigHarness()

        assertEquals(#harness.frames, frameCountBeforeConfigLoad,
            "loading ConfigFrame.lua should not construct UI")
        assertNotNil(NivUI.CreateConfigFrame, "lazy config constructor")
        assertEquals(NivUI.ConfigFrame, nil, "config frame before initialization")

        environment.SlashCmdList.NIVUI("")
        assertEquals(NivUI.ConfigFrame, nil, "config frame before ADDON_LOADED")

        harness:initialize()
        environment.SlashCmdList.NIVUI("")

        local configFrame = NivUI.ConfigFrame
        assertNotNil(configFrame, "config frame after the first slash command")
        assertTrue(configFrame:IsShown(), "config frame opens after construction")

        local frameCountAfterConstruction = #harness.frames
        environment.SlashCmdList.NIVUI("")
        assertFalse(configFrame:IsShown(), "second slash command hides the existing frame")
        assertEquals(#harness.frames, frameCountAfterConstruction,
            "second slash command should not reconstruct UI")
    end,

    ["a config open requested during combat waits without constructing UI"] = function()
        local harness, NivUI, environment, frameCountBeforeConfigLoad = createConfigHarness()
        harness:initialize()
        harness:setCombatLocked(true)

        environment.SlashCmdList.NIVUI("")
        environment.SlashCmdList.NIVUI("")

        assertEquals(NivUI.ConfigFrame, nil, "config frame during combat")
        assertEquals(#harness.frames, frameCountBeforeConfigLoad,
            "combat request should not construct UI")

        harness:setCombatLocked(false)
        harness:fire("PLAYER_REGEN_ENABLED")

        assertNotNil(NivUI.ConfigFrame, "config frame after combat")
        assertTrue(NivUI.ConfigFrame:IsShown(), "config frame opens after combat")
        local frameCountAfterConstruction = #harness.frames

        harness:fire("PLAYER_REGEN_ENABLED")
        assertEquals(#harness.frames, frameCountAfterConstruction,
            "repeated combat end should not reconstruct UI")
        assertTrue(NivUI.ConfigFrame:IsShown(), "repeated combat end keeps config open")
    end,

    ["combat force-closes visible config without reopening it"] = function()
        local harness, NivUI, environment = createConfigHarness()
        harness:initialize()
        environment.SlashCmdList.NIVUI("")

        assertTrue(NivUI.ConfigFrame:IsShown(), "config frame before combat")

        harness:setCombatLocked(true)
        harness:fire("PLAYER_REGEN_DISABLED")
        assertFalse(NivUI.ConfigFrame:IsShown(), "config frame during combat")

        harness:setCombatLocked(false)
        harness:fire("PLAYER_REGEN_ENABLED")
        assertFalse(NivUI.ConfigFrame:IsShown(), "force-closed config frame after combat")
    end,

    ["combat closes every registered config surface"] = function()
        local harness = createAddon(unitFrameProfiles())
        local NivUI = harness.namespace
        local environment = harness.environment
        local hiddenPopups = {}
        local closedMenus = 0
        local firstWindow = environment.CreateFrame()
        local secondWindow = environment.CreateFrame()
        local colorPicker = environment.CreateFrame()

        environment.StaticPopup_Hide = function(popupName)
            hiddenPopups[popupName] = true
        end
        environment.Menu = {
            GetManager = function()
                return {
                    CloseMenus = function()
                        closedMenus = closedMenus + 1
                    end,
                }
            end,
        }
        function colorPicker:SetupColorPickerAndShow()
            self:Show()
        end
        environment.ColorPickerFrame = colorPicker

        NivUI:RegisterConfigWindow(firstWindow)
        NivUI:RegisterConfigWindow(secondWindow)
        NivUI:RegisterConfigPopup("NIVUI_TEST_POPUP")
        NivUI:ShowConfigColorPicker({})
        firstWindow:Show()
        secondWindow:Show()

        harness:setCombatLocked(true)
        harness:fire("PLAYER_REGEN_DISABLED")

        assertFalse(firstWindow:IsShown(), "first registered window")
        assertFalse(secondWindow:IsShown(), "second registered window")
        assertFalse(colorPicker:IsShown(), "registered color picker")
        assertTrue(hiddenPopups.NIVUI_TEST_POPUP, "registered static popup")
        assertEquals(closedMenus, 1, "config menu close count")
    end,

    ["a direct config show during combat is hidden and deferred"] = function()
        local harness, NivUI, environment = createConfigHarness()
        harness:initialize()
        environment.SlashCmdList.NIVUI("")
        environment.SlashCmdList.NIVUI("")
        local configFrame = NivUI.ConfigFrame

        harness:setCombatLocked(true)
        configFrame:Show()
        assertFalse(configFrame:IsShown(), "direct config show during combat")

        harness:setCombatLocked(false)
        harness:fire("PLAYER_REGEN_ENABLED")
        assertTrue(configFrame:IsShown(), "direct config show after combat")
    end,

    ["config changes are permitted only outside combat"] = function()
        local harness = createAddon(unitFrameProfiles())
        local NivUI = harness.namespace

        assertTrue(NivUI:CanChangeConfig(), "config changes outside combat")
        harness:setCombatLocked(true)
        assertFalse(NivUI:CanChangeConfig(), "config changes during combat")
    end,

    ["loading the lazy config module does not preempt legacy database migration"] = function()
        local harness = createAddon(unitFrameProfiles())
        local environment = harness.environment
        local legacyDatabase = {
            comboPointsBar = { width = 321 },
        }
        environment.NivUI_DB = legacyDatabase
        environment.NivUI_CurrentProfile = nil

        local frameCountBeforeConfigLoad = #harness.frames
        harness:load("ConfigFrame.lua")

        assertEquals(environment.NivUI_DB, legacyDatabase, "database identity before initialization")
        assertEquals(environment.NivUI_DB.profiles, nil, "profiles before migration")
        assertEquals(#harness.frames, frameCountBeforeConfigLoad,
            "config module should not create frames before migration")

        harness:initialize()

        assertEquals(environment.NivUI_DB.version, 2, "database version after migration")
        assertEquals(environment.NivUI_DB.profiles.Default.comboPointsBar.width, 321,
            "legacy profile value after migration")
    end,

    ["a direct profile switch requested in combat waits for combat to end"] = function()
        local harness = createAddon(unitFrameProfiles())
        local NivUI = harness.namespace
        harness:load("modules/profiles/Profiles.lua")
        harness:initialize()

        harness:setCombatLocked(true)
        local accepted = NivUI.Profiles:SwitchProfile("Beta")

        assertTrue(accepted, "combat switch request is accepted")
        assertEquals(NivUI.activeProfileName, "Alpha", "active profile remains stable during combat")
        assertEquals(NivUI:GetActiveProfile(), harness.environment.NivUI_DB.profiles.Alpha,
            "active profile table remains stable during combat")

        harness:setCombatLocked(false)
        harness:fire("PLAYER_REGEN_ENABLED")

        assertEquals(NivUI.activeProfileName, "Beta", "active profile changes after combat")
        assertEquals(NivUI:GetActiveProfile(), harness.environment.NivUI_DB.profiles.Beta,
            "active profile table changes after combat")
    end,

    ["profile-scoped unit frame lookups ignore a stale legacy current table"] = function()
        local harness = createAddon(unitFrameProfiles())
        local NivUI = harness.namespace
        harness:load("modules/unitframes/Defaults.lua")
        harness:load("modules/unitframes/StyleManager.lua")
        harness:initialize()

        NivUI.current = harness.environment.NivUI_DB.profiles.Alpha
        NivUI.activeProfileName = "Beta"

        assertTrue(NivUI:IsFrameEnabled("player"), "Beta player enabled state")
        assertEquals(NivUI:GetAssignment("player"), "Beta Style", "Beta player assignment")
        assertEquals(NivUI:GetStyle("Beta Style").frame.width, 240, "Beta style width")
        assertEquals(NivUI:GetStyle("Beta Style").healthBar.color.b, 0.9, "Beta style color")
        assertEquals(NivUI:GetVisibilityOverride("player"), "show", "Beta visibility override")

        NivUI.activeProfileName = "Alpha"
        NivUI.current = harness.environment.NivUI_DB.profiles.Beta

        assertTrue(NivUI:IsFrameEnabled("player"), "Alpha player enabled state")
        assertEquals(NivUI:GetAssignment("player"), "Alpha Style", "Alpha player assignment")
        assertEquals(NivUI:GetStyle("Alpha Style").frame.width, 120, "Alpha style width")
        assertEquals(NivUI:GetStyle("Alpha Style").healthBar.color.r, 0.8, "Alpha style color")
        assertEquals(NivUI:GetVisibilityOverride("player"), "[combat] show; hide",
            "Alpha visibility override")
    end,

    ["an existing single-unit frame adopts each switched profile immediately"] = function()
        local harness = createAddon(unitFrameProfiles())
        local NivUI = harness.namespace
        harness:load("modules/unitframes/Defaults.lua")
        harness:load("modules/unitframes/StyleManager.lua")
        NivUI.WidgetFactories = {
            GetClassColor = function()
                return 1, 1, 1
            end,
            GetPowerColor = function()
                return 1, 1, 1
            end,
        }
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
        harness:load("modules/profiles/Profiles.lua")
        harness:initialize()

        local Base = NivUI.UnitFrames.Base
        function Base.BuildCustomFrame(state)
            state.currentStyle = NivUI:GetStyleWithDefaults(state.styleName)
            state.effectiveVisibilityDriver = NivUI:GetVisibilityOverride(state.frameType)
            state.customFrame = createRegion()
            return true
        end
        function Base.DestroyCustomFrame(state)
            state.currentStyle = nil
            state.customFrame = nil
        end

        local module = Base.CreateModule({ unit = "player", frameType = "player" })
        module.Enable()
        local state = module.GetState()

        assertEquals(state.styleName, "Alpha Style", "initial assignment")
        assertEquals(state.currentStyle.frame.width, 120, "initial style width")
        assertEquals(state.effectiveVisibilityDriver, "[combat] show; hide", "initial visibility")

        NivUI.Profiles:SwitchProfile("Beta")
        assertEquals(state.styleName, "Beta Style", "assignment after Alpha to Beta")
        assertEquals(state.currentStyle.frame.width, 240, "style width after Alpha to Beta")
        assertEquals(state.currentStyle.healthBar.color.b, 0.9, "style color after Alpha to Beta")
        assertEquals(state.effectiveVisibilityDriver, "show", "visibility after Alpha to Beta")

        NivUI.Profiles:SwitchProfile("Alpha")
        assertEquals(state.styleName, "Alpha Style", "assignment after Beta to Alpha")
        assertEquals(state.currentStyle.frame.width, 120, "style width after Beta to Alpha")
        assertEquals(state.currentStyle.healthBar.color.r, 0.8, "style color after Beta to Alpha")
        assertEquals(state.effectiveVisibilityDriver, "[combat] show; hide", "visibility after Beta to Alpha")
    end,

    ["an existing segmented bar adopts size colors and visibility in both directions"] = function()
        local profiles = {
            Alpha = { classBarEnabled = { test = true }, testBar = copy(alphaBar) },
            Beta = { classBarEnabled = { test = true }, testBar = copy(betaBar) },
        }
        local harness = createAddon(profiles)
        local NivUI = harness.namespace
        harness:load("modules/bars/BarBase.lua")
        harness:load("modules/bars/SegmentedBarBase.lua")
        harness:load("modules/profiles/Profiles.lua")

        NivUI.testBarDefaults = copy(alphaBar)
        NivUI.classBarRegistry.test = {
            dbKey = "testBar",
            defaults = NivUI.testBarDefaults,
        }
        local module = NivUI.SegmentedBarBase.CreateModule({
            barType = "test",
            powerType = 1,
            frameName = "NivUITestBar",
            globalRef = "TestBar",
            checkResourceAvailable = function()
                return true
            end,
        })

        harness:initialize()
        harness:fire("PLAYER_LOGIN")
        assertSegmentedBar(module.GetFrame(), alphaBar, "initial Alpha bar")

        NivUI.activeProfileName = "Beta"
        NivUI.current = harness.environment.NivUI_DB.profiles.Alpha
        NivUI:ApplyActiveProfile()
        assertSegmentedBar(module.GetFrame(), betaBar, "bar after Alpha to Beta")

        NivUI.activeProfileName = "Alpha"
        NivUI.current = harness.environment.NivUI_DB.profiles.Beta
        NivUI:ApplyActiveProfile()
        assertSegmentedBar(module.GetFrame(), alphaBar, "bar after Beta to Alpha")
    end,

    ["the Stagger bar applies settings from the active profile without a current alias"] = function()
        local profiles = {
            Alpha = { classBarEnabled = { stagger = true }, staggerBar = copy(alphaStagger) },
            Beta = { classBarEnabled = { stagger = true }, staggerBar = copy(betaStagger) },
        }
        local harness = createAddon(profiles)
        local NivUI = harness.namespace
        harness:load("modules/bars/BarBase.lua")
        harness:load("modules/bars/StaggerBar.lua")
        harness:load("modules/profiles/Profiles.lua")
        harness:initialize()
        harness:fire("PLAYER_LOGIN")

        local module = NivUI.classBarRegistry.stagger.module
        assertStaggerBar(module.GetFrame(), alphaStagger, "initial Alpha Stagger bar")

        NivUI.Profiles:SwitchProfile("Beta")
        NivUI.current = harness.environment.NivUI_DB.profiles.Alpha
        NivUI:ApplySettings()
        assertStaggerBar(module.GetFrame(), betaStagger, "Stagger bar after Alpha to Beta")

        NivUI.Profiles:SwitchProfile("Alpha")
        NivUI.current = harness.environment.NivUI_DB.profiles.Beta
        NivUI:ApplySettings()
        assertStaggerBar(module.GetFrame(), alphaStagger, "Stagger bar after Beta to Alpha")
    end,

    ["every group frame family registers for active profile application"] = function()
        local harness = createAddon(unitFrameProfiles())
        local NivUI = harness.namespace
        NivUI.UnitFrames = {
            Base = {},
        }

        harness:load("modules/unitframes/UnitFrameLifecycle.lua")
        harness:load("modules/unitframes/MultiUnitFrameBase.lua")
        harness:load("modules/unitframes/PartyFrame.lua")
        harness:load("modules/unitframes/BossFrame.lua")
        harness:load("modules/unitframes/ArenaFrame.lua")
        harness:load("modules/unitframes/RaidFrame.lua")
        harness:load("modules/unitframes/CustomRaidGroup.lua")

        assertNotNil(NivUI.profileApplyCallbacks["unitFrame:party"], "party profile application")
        assertNotNil(NivUI.profileApplyCallbacks["unitFrame:boss"], "boss profile application")
        assertNotNil(NivUI.profileApplyCallbacks["unitFrame:arena"], "arena profile application")
        assertNotNil(NivUI.profileApplyCallbacks["unitFrame:raid"], "raid profile application")
        assertNotNil(NivUI.profileApplyCallbacks["unitFrame:customRaid"], "custom raid profile application")
    end,

    ["an existing multi-unit frame refreshes assignments and enabled state"] = function()
        local profiles = {
            Alpha = {
                unitFrameEnabled = { group = true },
                unitFrameAssignments = { group = "Alpha Style" },
                unitFrameStyles = { ["Alpha Style"] = {} },
            },
            Beta = {
                unitFrameEnabled = { group = true },
                unitFrameAssignments = { group = "Beta Style" },
                unitFrameStyles = { ["Beta Style"] = {} },
            },
            Disabled = {
                unitFrameEnabled = { group = false },
                unitFrameAssignments = { group = "Beta Style" },
                unitFrameStyles = { ["Beta Style"] = {} },
            },
        }
        local harness = createAddon(profiles)
        local NivUI = harness.namespace
        local restoreCount = 0
        NivUI.UnitFrames = {
            Base = {
                SetSecureVisibility = function(frame, visible)
                    if visible then
                        frame:Show()
                    else
                        frame:Hide()
                    end
                end,
            },
        }
        function NivUI:GetAssignment(frameType)
            return self:GetActiveProfile().unitFrameAssignments[frameType]
        end
        function NivUI:GetStyleWithDefaults(styleName)
            return { frame = { width = styleName == "Alpha Style" and 120 or 240, height = 40 } }
        end
        function NivUI:GetVisibilityOverride()
            return nil
        end
        function NivUI:IsFrameEnabled(frameType)
            return self:GetActiveProfile().unitFrameEnabled[frameType] == true
        end

        harness:load("modules/unitframes/UnitFrameLifecycle.lua")
        harness:load("modules/unitframes/MultiUnitFrameBase.lua")
        harness:load("modules/profiles/Profiles.lua")
        local module = NivUI.UnitFrames.MultiUnitFrameBase.CreateModule({
            frameType = "group",
            containerName = "NivUITestGroup",
            defaultContainerPosition = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 },
            getUnits = function()
                return {}
            end,
            getOrientation = function()
                return "VERTICAL"
            end,
            getGrowthDirection = function()
                return "DOWN"
            end,
            getSpacing = function()
                return 2
            end,
            memberVisibilityMode = "state_driver",
            hideBlizzardFrames = function() end,
            restoreBlizzardFrames = function()
                restoreCount = restoreCount + 1
            end,
            settingsChangedCallback = "GroupSettingsChanged",
            previewChangedCallback = "GroupPreviewChanged",
        })
        harness:initialize()

        module.Enable()
        assertEquals(module.GetState().styleName, "Alpha Style", "initial multi-unit assignment")

        NivUI.Profiles:SwitchProfile("Beta")
        assertTrue(module.GetState().enabled, "multi-unit frame remains enabled in Beta")
        assertEquals(module.GetState().styleName, "Beta Style", "multi-unit assignment after Alpha to Beta")

        NivUI.Profiles:SwitchProfile("Disabled")
        assertFalse(module.GetState().enabled, "multi-unit frame disables with its profile")
        assertEquals(restoreCount, 1, "Blizzard frames restore on profile disable")

        NivUI.Profiles:SwitchProfile("Alpha")
        assertTrue(module.GetState().enabled, "multi-unit frame re-enables with Alpha")
        assertEquals(module.GetState().styleName, "Alpha Style", "multi-unit assignment after re-enable")
    end,

    ["a specialization switch deferred by combat reconciles module enabled state"] = function()
        local profiles = {
            Alpha = { classBarEnabled = { test = true } },
            Beta = { classBarEnabled = { test = false } },
        }
        local harness = createAddon(profiles)
        local NivUI = harness.namespace
        harness:load("modules/bars/BarBase.lua")
        harness:load("modules/profiles/Profiles.lua")
        NivUI.classBarRegistry.test = { dbKey = "testBar", defaults = {} }

        local module = NivUI.BarBase.CreateModule({
            barType = "test",
            createUI = createRegion,
        })

        harness:initialize()
        harness:fire("PLAYER_LOGIN")
        assertTrue(module.IsEnabled(), "Alpha module enabled before specialization switch")

        harness:setSpecializationID(252)
        NivUI.Profiles:SetSpecProfile(252, "Beta")
        harness:setCombatLocked(true)
        NivUI.Profiles:SetSpecAutoSwitchEnabled(true)

        assertEquals(NivUI.activeProfileName, "Alpha", "profile remains Alpha during combat")
        assertTrue(module.IsEnabled(), "module remains enabled during combat")

        harness:setCombatLocked(false)
        harness:fire("PLAYER_REGEN_ENABLED")

        assertEquals(NivUI.activeProfileName, "Beta", "profile switches after combat")
        assertEquals(NivUI:GetActiveProfile(), harness.environment.NivUI_DB.profiles.Beta,
            "active profile table switches after combat")
        assertFalse(module.IsEnabled(), "module disabled after deferred Beta switch")
    end,
}
