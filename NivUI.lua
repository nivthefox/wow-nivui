NivUI = NivUI or {}

NivUI_DB = NivUI_DB or {}

NivUI.UPDATE_INTERVAL = 0.1

NivUI.eventCallbacks = NivUI.eventCallbacks or {}

-- ReloadUI debouncing: allows multiple toggles to coalesce before actually reloading
local pendingReload = false
local reloadTimer = nil

function NivUI:RequestReload()
    if pendingReload then return end
    pendingReload = true

    if reloadTimer then reloadTimer:Cancel() end
    reloadTimer = C_Timer.NewTimer(0.5, function()
        pendingReload = false
        ReloadUI()
    end)
end

NivUI.staggerBarDefaults = {
    visibility = "combat",
    updateInterval = 0.2,
    width = 394,
    height = 20,
    point = "CENTER",
    x = 0,
    y = -200,
    locked = false,

    foregroundTexture = "Default",
    backgroundTexture = "Default",
    backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
    borderStyle = "thin",
    borderColor = { r = 0, g = 0, b = 0, a = 1 },
    borderWidth = 1,

    font = "Friz Quadrata",
    fontSize = 12,
    fontColor = { r = 1, g = 1, b = 1 },
    fontShadow = true,
    colors = {
        light = { r = 0, g = 1, b = 0 },
        moderate = { r = 1, g = 1, b = 0 },
        heavy = { r = 1, g = 0, b = 0 },
        extreme = { r = 1, g = 0, b = 1 },
    },
}

NivUI.staggerBarDefaults.barTexture = NivUI.staggerBarDefaults.foregroundTexture
NivUI.defaults = NivUI.staggerBarDefaults

NivUI.chiBarDefaults = {
    point = "CENTER",
    x = 0,
    y = -250,
    width = 200,
    height = 20,
    spacing = 2,
    locked = true,
    visibility = "combat",
    emptyColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 },
    filledColor = { r = 0.0, g = 0.8, b = 0.6, a = 1.0 },
    borderColor = { r = 0, g = 0, b = 0, a = 1 },
    updateInterval = 0.05,
}

NivUI.essenceBarDefaults = {
    point = "CENTER",
    x = 0,
    y = -280,
    width = 200,
    height = 20,
    spacing = 2,
    locked = true,
    visibility = "combat",
    emptyColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 },
    filledColor = { r = 0.15, g = 0.75, b = 0.85, a = 1.0 },
    borderColor = { r = 0, g = 0, b = 0, a = 1 },
    updateInterval = 0.05,
}

local BUILTIN_TEXTURES = {
    { value = "Default", name = "Default", path = "Interface\\TargetingFrame\\UI-StatusBar" },
    { value = "Target Frame", name = "Target Frame", path = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill" },
    { value = "Raid Frame", name = "Raid Frame", path = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
    { value = "Skills Bar", name = "Skills Bar", path = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar" },
}

local BUILTIN_FONTS = {
    { value = "Friz Quadrata", name = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
    { value = "Arial Narrow", name = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
    { value = "Morpheus", name = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
    { value = "Skurri", name = "Skurri", path = "Fonts\\SKURRI.TTF" },
}

local BUILTIN_BORDERS = {
    { value = "none", name = "None" },
    { value = "thin", name = "Thin (1px)" },
    { value = "thick", name = "Thick (2px)" },
}

function NivUI:GetSharedMedia()
    if self.LSM == nil then
        self.LSM = LibStub and LibStub("LibSharedMedia-3.0", true) or false
    end
    return self.LSM
end

function NivUI:GetBarTextures()
    local LSM = self:GetSharedMedia()
    if LSM then
        local list = LSM:List("statusbar")
        local textures = {}
        for _, name in ipairs(list) do
            local path = LSM:Fetch("statusbar", name)
            table.insert(textures, {
                value = name,
                name = name,
                path = path,
            })
        end
        return textures
    end
    return BUILTIN_TEXTURES
end

function NivUI:GetFonts()
    local LSM = self:GetSharedMedia()
    if LSM then
        local list = LSM:List("font")
        local fonts = {}
        for _, name in ipairs(list) do
            local path = LSM:Fetch("font", name)
            table.insert(fonts, {
                value = name,
                name = name,
                path = path,
            })
        end
        return fonts
    end
    return BUILTIN_FONTS
end

function NivUI:GetBorders()
    return BUILTIN_BORDERS
end

local VISIBILITY_OPTIONS = {
    { value = "always", name = "Always" },
    { value = "combat", name = "In Combat" },
    { value = "never", name = "Never" },
}

function NivUI:GetVisibilityOptions()
    return VISIBILITY_OPTIONS
end

function NivUI:GetTexturePath(nameOrPath)
    local LSM = self:GetSharedMedia()
    if LSM then
        local path = LSM:Fetch("statusbar", nameOrPath)
        if path then return path end
    end
    for _, item in ipairs(BUILTIN_TEXTURES) do
        if item.name == nameOrPath then return item.path end
    end
    return nameOrPath  -- Assume it's a raw path
end

function NivUI:GetFontPath(nameOrPath)
    local LSM = self:GetSharedMedia()
    if LSM then
        local path = LSM:Fetch("font", nameOrPath)
        if path then return path end
    end
    for _, item in ipairs(BUILTIN_FONTS) do
        if item.name == nameOrPath then return item.path end
    end
    return nameOrPath  -- Assume it's a raw path
end

NivUI.barTextures = nil  -- Legacy
NivUI.fonts = nil  -- Legacy

NivUI.applyCallbacks = NivUI.applyCallbacks or {}

function NivUI:RegisterApplyCallback(name, callback)
    self.applyCallbacks[name] = callback
end

function NivUI:ApplySettings(settingName)
    if settingName then
        local callback = self.applyCallbacks[settingName]
        if callback then callback() end
    else
        for _, callback in pairs(self.applyCallbacks) do
            callback()
        end
    end
end

function NivUI:GetSetting(key)
    local db = NivUI.current and NivUI.current.staggerBar or {}
    if db[key] ~= nil then
        return db[key]
    end
    return self.staggerBarDefaults[key]
end

function NivUI:GetColors()
    local db = NivUI.current and NivUI.current.staggerBar or {}
    if db.colors then
        return db.colors
    end
    return self.staggerBarDefaults.colors
end

function NivUI.DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = NivUI.DeepCopy(v)
    end
    return copy
end

function NivUI:InitializeDB()
    if not NivUI.current.staggerBar then
        NivUI.current.staggerBar = {}
    end
    for k, v in pairs(self.staggerBarDefaults) do
        if NivUI.current.staggerBar[k] == nil then
            NivUI.current.staggerBar[k] = NivUI.DeepCopy(v)
        end
    end

    if not NivUI.current.chiBar then
        NivUI.current.chiBar = {}
    end
    for k, v in pairs(self.chiBarDefaults) do
        if NivUI.current.chiBar[k] == nil then
            NivUI.current.chiBar[k] = NivUI.DeepCopy(v)
        end
    end

    if not NivUI.current.essenceBar then
        NivUI.current.essenceBar = {}
    end
    for k, v in pairs(self.essenceBarDefaults) do
        if NivUI.current.essenceBar[k] == nil then
            NivUI.current.essenceBar[k] = NivUI.DeepCopy(v)
        end
    end

    if not NivUI.current.classBarEnabled then
        NivUI.current.classBarEnabled = {}
    end

    if not NivUI.current.unitFrameStyles then
        NivUI.current.unitFrameStyles = {}
    end

    if not NivUI.current.unitFrameAssignments then
        NivUI.current.unitFrameAssignments = {
            player = "Default",
            target = "Default",
            focus = "Default",
            pet = "Default",
            party = "Default",
            boss = "Default",
            arena = "Default",
            targettarget = "Default",
        }
    end
end

function NivUI:RegisterCallback(event, callback)
    if not self.eventCallbacks[event] then
        self.eventCallbacks[event] = {}
    end
    table.insert(self.eventCallbacks[event], callback)
end

function NivUI:TriggerEvent(event, data)
    if not self.eventCallbacks[event] then return end
    for _, callback in ipairs(self.eventCallbacks[event]) do
        callback(data)
    end
end

function NivUI:IsClassBarEnabled(barType)
    if not NivUI.current.classBarEnabled then
        return false
    end
    return NivUI.current.classBarEnabled[barType] == true
end

function NivUI:SetClassBarEnabled(barType, enabled)
    if not NivUI.current.classBarEnabled then
        NivUI.current.classBarEnabled = {}
    end

    NivUI.current.classBarEnabled[barType] = enabled

    self:TriggerEvent("ClassBarEnabledChanged", { barType = barType, enabled = enabled })
end

--- Migrates old flat NivUI_DB structure to the new profiles structure.
--- Called once on ADDON_LOADED if migration is needed.
--- @return boolean migrated True if migration occurred
function NivUI:MigrateToProfiles()
    if NivUI_DB.version and NivUI_DB.version >= 2 then
        return false
    end
    if NivUI_DB.profiles then
        return false
    end

    local oldSettings = NivUI.DeepCopy(NivUI_DB)

    for k in pairs(NivUI_DB) do
        NivUI_DB[k] = nil
    end

    NivUI_DB.version = 2
    NivUI_DB.profiles = { ["Default"] = oldSettings }
    NivUI_DB.profiles["Default"].version = nil

    print("|cff00ff00NivUI:|r Migrated settings to profile system")
    return true
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, _, addon)
    if addon ~= "NivUI" then return end

    NivUI_DB = NivUI_DB or {}
    NivUI_CurrentProfile = NivUI_CurrentProfile or "Default"

    NivUI:MigrateToProfiles()

    if not NivUI_DB.profiles then
        NivUI_DB.profiles = { ["Default"] = {} }
    end
    if not NivUI_DB.profiles[NivUI_CurrentProfile] then
        NivUI_CurrentProfile = "Default"
    end
    if not NivUI_DB.profiles["Default"] then
        NivUI_DB.profiles["Default"] = {}
    end

    NivUI.current = NivUI_DB.profiles[NivUI_CurrentProfile]

    NivUI:InitializeDB()

    self:UnregisterEvent("ADDON_LOADED")
end)

SLASH_NIVUI1 = "/nivui"
SlashCmdList["NIVUI"] = function(msg)
    if not msg or msg == "" then
        if NivUI.ConfigFrame then
            if NivUI.ConfigFrame:IsShown() then
                NivUI.ConfigFrame:Hide()
            else
                NivUI.ConfigFrame:Show()
            end
        else
            print("NivUI: Config frame not loaded")
        end
    else
        print("NivUI: Use /nivui to open the config panel")
    end
end
