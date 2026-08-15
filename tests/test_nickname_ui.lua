local _, assertions = ...

local assertEquals = assertions.equals
local assertTrue = assertions.isTrue
local assertFalse = assertions.isFalse
local assertNil = assertions.isNil

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

local function CreateFrameStub(frameType, template, registry)
    local frame = {
        frameType = frameType,
        registry = registry,
        template = template,
        scripts = {},
        shown = true,
        text = "",
    }

    local noOpMethods = {
        "ClearAllPoints", "HighlightText", "SetAllPoints", "SetAutoFocus", "SetFocus",
        "SetHeight", "SetJustifyH", "SetPoint", "SetScrollChild", "SetSize", "SetTextColor",
        "SetWidth",
    }
    for _, method in ipairs(noOpMethods) do
        frame[method] = function() end
    end

    function frame:CreateFontString()
        return CreateFrameStub("FontString", nil, self.registry)
    end

    function frame:GetText()
        return self.text
    end

    function frame:GetWidth()
        return 500
    end

    function frame:Hide()
        self.shown = false
    end

    function frame:IsShown()
        return self.shown
    end

    function frame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    function frame:SetShown(shown)
        self.shown = shown
    end

    function frame:SetText(text)
        self.text = text
    end

    function frame:Show()
        self.shown = true
    end

    if registry then
        registry[#registry + 1] = frame
    end
    return frame
end

local function CreateHarness()
    local combat = false
    local menuCallbacks = {}
    local popupRequest
    local registeredPopup
    local callbacks = {}
    local frames = {}
    local saves = {}
    local storage = { ["alina-realm"] = "Lina" }
    local identities = { party1 = "alina-realm" }
    local NivUI = {
        Config = {},
        Nicknames = {},
    }

    function NivUI.Nicknames.NormalizeIdentity(identity)
        if type(identity) ~= "string" or not identity:find("-") then
            return nil
        end
        return identity:lower()
    end

    function NivUI.Nicknames.GetUnitIdentity(unit)
        return identities[unit]
    end

    function NivUI.Nicknames:Get(identity)
        return storage[identity]
    end

    function NivUI.Nicknames:GetEntries()
        return { { identity = "alina-realm", nickname = storage["alina-realm"] } }
    end

    function NivUI.Nicknames:Save(identity, nickname)
        saves[#saves + 1] = { identity = identity, nickname = nickname }
        storage[identity] = nickname ~= "" and nickname or nil
        return true, nil, identity:lower()
    end

    function NivUI:RegisterConfigPopup(name)
        registeredPopup = name
    end

    function NivUI:RegisterCallback(event, callback)
        callbacks[event] = callback
    end

    local environment = setmetatable({
        CANCEL = "Cancel",
        SAVE = "Save",
        InCombatLockdown = function()
            return combat
        end,
        Menu = {
            ModifyMenu = function(tag, callback)
                menuCallbacks[tag] = callback
            end,
        },
        StaticPopupDialogs = {},
        StaticPopup_Show = function(name, text, _, data)
            popupRequest = { name = name, text = text, data = data }
        end,
        UnitPopupMenus = { PARTY = {}, TARGET = {} },
        CreateFrame = function(frameType, _, _, template)
            return CreateFrameStub(frameType, template, frames)
        end,
    }, { __index = _G })

    Load("config/Nicknames.lua", environment, NivUI)

    return {
        callbacks = callbacks,
        environment = environment,
        frames = frames,
        identities = identities,
        menuCallbacks = menuCallbacks,
        NivUI = NivUI,
        popup = function()
            return popupRequest
        end,
        registeredPopup = function()
            return registeredPopup
        end,
        saves = saves,
        setCombat = function(value)
            combat = value
        end,
        storage = storage,
    }
end

local function CreateRoot()
    local root = { entries = { { text = "Existing", callback = function() end } } }
    function root:CreateButton(text, callback)
        self.entries[#self.entries + 1] = { text = text, callback = callback }
    end
    return root
end

return {
    ["profile changes close every registered static NivUI modal"] = function()
        local callbacks = {}
        local hidden = {}
        local eventFrame = CreateFrameStub("Frame")
        function eventFrame:RegisterEvent() end
        local NivUI = { Config = {} }
        function NivUI:RegisterCallback(event, callback)
            callbacks[event] = callback
        end

        local environment = setmetatable({
            ColorPickerFrame = nil,
            CreateFrame = function()
                return eventFrame
            end,
            InCombatLockdown = function()
                return false
            end,
            Menu = nil,
            SLASH_NIVUI1 = nil,
            SlashCmdList = {},
            StaticPopup_Hide = function(name)
                hidden[name] = true
            end,
        }, { __index = _G })
        Load("modules/config/Lifecycle.lua", environment, NivUI)
        NivUI:RegisterConfigPopup("FIRST_MODAL")
        NivUI:RegisterConfigPopup("SECOND_MODAL")

        callbacks.ProfileSwitched()
        assertTrue(hidden.FIRST_MODAL)
        assertTrue(hidden.SECOND_MODAL)
    end,

    ["every native unit menu tag receives the supported extension callback"] = function()
        local harness = CreateHarness()

        assertTrue(type(harness.menuCallbacks.MENU_UNIT_PARTY) == "function")
        assertTrue(type(harness.menuCallbacks.MENU_UNIT_TARGET) == "function")
        assertEquals(harness.registeredPopup(), "NIVUI_SET_NICKNAME")
    end,

    ["a player menu appends one action without relying on the owner table"] = function()
        local harness = CreateHarness()
        local root = CreateRoot()
        local originalCallback = root.entries[1].callback

        assertTrue(harness.NivUI.Config.Nicknames.ExtendUnitMenu({ unsupportedOwner = true }, root, {
            unit = "party1",
        }))
        assertEquals(#root.entries, 2)
        assertEquals(root.entries[1].text, "Existing")
        assertEquals(root.entries[1].callback, originalCallback)
        assertEquals(root.entries[2].text, "Set Nickname...")
    end,

    ["combat non-player and incomplete contexts do not add a menu action"] = function()
        local harness = CreateHarness()
        local root = CreateRoot()

        assertFalse(harness.NivUI.Config.Nicknames.ExtendUnitMenu(nil, root, { unit = "target" }))
        assertFalse(harness.NivUI.Config.Nicknames.ExtendUnitMenu(nil, root, {}))
        harness.setCombat(true)
        assertFalse(harness.NivUI.Config.Nicknames.ExtendUnitMenu(nil, root, { unit = "party1" }))
        assertEquals(#root.entries, 1)
    end,

    ["the menu action opens a modal bound to the captured identity"] = function()
        local harness = CreateHarness()
        local root = CreateRoot()
        harness.NivUI.Config.Nicknames.ExtendUnitMenu(nil, root, { unit = "party1" })

        root.entries[2].callback()
        harness.identities.party1 = "changed-realm"

        local request = harness.popup()
        assertEquals(request.name, "NIVUI_SET_NICKNAME")
        assertEquals(request.data.identity, "alina-realm")

        local editBox = CreateFrameStub("EditBox")
        editBox:SetText("Updated")
        local dialog = { EditBox = editBox }
        harness.environment.StaticPopupDialogs[request.name].OnAccept(dialog, request.data)
        assertEquals(harness.saves[1].identity, "alina-realm")
        assertEquals(harness.saves[1].nickname, "Updated")
    end,

    ["the modal prefills only the stored profile nickname"] = function()
        local harness = CreateHarness()
        local popup = harness.environment.StaticPopupDialogs.NIVUI_SET_NICKNAME
        local editBox = CreateFrameStub("EditBox")
        local dialog = { EditBox = editBox }

        popup.OnShow(dialog, { identity = "alina-realm" })
        assertEquals(editBox:GetText(), "Lina")
    end,

    ["the configuration tab lists and saves arbitrary normalized entries"] = function()
        local harness = CreateHarness()
        local parent = CreateFrameStub("Frame")
        local components = {
            GetHeader = function()
                return CreateFrameStub("Header")
            end,
        }

        local container = harness.NivUI.Config.Nicknames.SetupTab(parent, components)
        container.scripts.OnShow()

        local editBoxes = {}
        local saveButton
        local listedIdentity = false
        local listedNickname = false
        for _, frame in ipairs(harness.frames) do
            if frame.frameType == "EditBox" then
                editBoxes[#editBoxes + 1] = frame
            elseif frame.text == "Save" then
                saveButton = frame
            elseif frame.text == "alina-realm" then
                listedIdentity = true
            elseif frame.text == "Lina" then
                listedNickname = true
            end
        end

        assertEquals(#editBoxes, 2)
        assertTrue(listedIdentity)
        assertTrue(listedNickname)
        assertTrue(saveButton ~= nil)

        editBoxes[1]:SetText("Other-Realm")
        editBoxes[2]:SetText("Other")
        saveButton.scripts.OnClick()
        assertEquals(harness.saves[#harness.saves].identity, "Other-Realm")
        assertEquals(harness.saves[#harness.saves].nickname, "Other")
    end,

    ["the main configuration frame includes a top-level Nicknames tab"] = function()
        local file = io.open(addonRoot .. "/ConfigFrame.lua", "r")
        assertTrue(file ~= nil)
        local source = file:read("*a")
        file:close()

        assertTrue(source:find("NivUI.Config.Nicknames.SetupTab", 1, true) ~= nil)
        assertTrue(source:find('GetSidebarTab(Sidebar, "Nicknames")', 1, true) ~= nil)
    end,
}
