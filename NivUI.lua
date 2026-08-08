local addonName, NivUI = ...

NivUI_DB = NivUI_DB or {}
NivUI.activeProfileName = NivUI.activeProfileName or NivUI_CurrentProfile or "Default"
NivUI.isInitialized = false

NivUI.UPDATE_INTERVAL = 0.1

NivUI.eventCallbacks = NivUI.eventCallbacks or {}
NivUI.classBarRegistry = NivUI.classBarRegistry or {}

function NivUI:RegisterClassBar(barType, config)
    if type(barType) ~= "string" or barType == "" or type(config) ~= "table" then
        return false
    end

    config.barType = barType
    config.dbKey = barType .. "Bar"
    self.classBarRegistry[barType] = config

    -- Store defaults for backward compatibility
    self[barType .. "BarDefaults"] = config.defaults

    if config.createModule then
        config.module = config.createModule()
    end
    return true
end

function NivUI:GetRegisteredClassBars()
    local ordered = {}
    for _, config in pairs(self.classBarRegistry) do
        table.insert(ordered, config)
    end
    table.sort(ordered, function(a, b)
        return (a.sortOrder or 999) < (b.sortOrder or 999)
    end)
    return ordered
end

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
    if not LSM then
        return BUILTIN_TEXTURES
    end

    local textures = {}
    for _, name in ipairs(LSM:List("statusbar")) do
        local path = LSM:Fetch("statusbar", name)
        table.insert(textures, {
            value = name,
            name = name,
            path = path,
        })
    end
    return textures
end

function NivUI:GetFonts()
    local LSM = self:GetSharedMedia()
    if not LSM then
        return BUILTIN_FONTS
    end

    local fonts = {}
    for _, name in ipairs(LSM:List("font")) do
        local path = LSM:Fetch("font", name)
        table.insert(fonts, {
            value = name,
            name = name,
            path = path,
        })
    end
    return fonts
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
        if path then
            return path
        end
    end
    for _, item in ipairs(BUILTIN_TEXTURES) do
        if item.name == nameOrPath then
            return item.path
        end
    end
    return nameOrPath
end

function NivUI:GetFontPath(nameOrPath)
    local LSM = self:GetSharedMedia()
    if LSM then
        local path = LSM:Fetch("font", nameOrPath)
        if path then
            return path
        end
    end
    for _, item in ipairs(BUILTIN_FONTS) do
        if item.name == nameOrPath then
            return item.path
        end
    end
    return nameOrPath
end

NivUI.applyCallbacks = NivUI.applyCallbacks or {}
NivUI.profileApplyCallbacks = NivUI.profileApplyCallbacks or {}

function NivUI:GetActiveProfile()
    if type(NivUI_DB) ~= "table" or type(NivUI_DB.profiles) ~= "table" then
        return nil
    end
    return NivUI_DB.profiles[self.activeProfileName]
end

function NivUI:RegisterProfileApplyCallback(name, callback)
    if type(name) ~= "string" or name == "" or type(callback) ~= "function" then
        return false
    end
    self.profileApplyCallbacks[name] = callback
    return true
end

function NivUI:ApplyActiveProfile()
    local names = {}
    for name in pairs(self.profileApplyCallbacks) do
        names[#names + 1] = name
    end
    table.sort(names)
    for _, name in ipairs(names) do
        self.profileApplyCallbacks[name]()
    end
end

function NivUI:RegisterApplyCallback(name, callback)
    if type(name) ~= "string" or type(callback) ~= "function" then
        return false
    end
    self.applyCallbacks[name] = callback
    return true
end

function NivUI:ApplySettings(settingName)
    if settingName then
        local callback = self.applyCallbacks[settingName]
        if callback then
            callback()
        end
        return
    end

    for _, callback in pairs(self.applyCallbacks) do
        callback()
    end
end

function NivUI.DeepCopy(src)
    if type(src) ~= "table" then
        return src
    end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = NivUI.DeepCopy(v)
    end
    return copy
end

function NivUI:InitializeDB()
    local profile = self:GetActiveProfile()
    if not profile then
        return false
    end

    for _, config in pairs(self.classBarRegistry) do
        local dbKey = config.dbKey
        if not profile[dbKey] then
            profile[dbKey] = {}
        end
        for k, v in pairs(config.defaults) do
            if profile[dbKey][k] == nil then
                profile[dbKey][k] = NivUI.DeepCopy(v)
            end
        end
    end

    if not profile.classBarEnabled then
        profile.classBarEnabled = {}
    end

    if not profile.unitFrameStyles then
        profile.unitFrameStyles = {}
    end

    if not profile.unitFrameAssignments then
        profile.unitFrameAssignments = {
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
    return true
end

function NivUI:RegisterCallback(event, callback)
    if type(event) ~= "string" or type(callback) ~= "function" then
        return false
    end
    if not self.eventCallbacks[event] then
        self.eventCallbacks[event] = {}
    end
    table.insert(self.eventCallbacks[event], callback)
    return true
end

function NivUI:UnregisterCallback(event, callback)
    if not self.eventCallbacks[event] then
        return
    end
    for i, cb in ipairs(self.eventCallbacks[event]) do
        if cb == callback then
            table.remove(self.eventCallbacks[event], i)
            return
        end
    end
end

function NivUI:TriggerEvent(event, data)
    if not self.eventCallbacks[event] then
        return
    end
    for _, callback in ipairs(self.eventCallbacks[event]) do
        callback(data)
    end
end

function NivUI:IsClassBarEnabled(barType)
    local profile = self:GetActiveProfile()
    if not profile or not profile.classBarEnabled then
        return false
    end
    return profile.classBarEnabled[barType] == true
end

function NivUI:SetClassBarEnabled(barType, enabled)
    local profile = self:GetActiveProfile()
    if not profile then
        return
    end
    if not profile.classBarEnabled then
        profile.classBarEnabled = {}
    end

    profile.classBarEnabled[barType] = enabled

    self:TriggerEvent("ClassBarEnabledChanged", { barType = barType, enabled = enabled })
end

local function RenameStyleShowAbsorb(style)
    local hb = type(style) == "table" and style.healthBar
    if type(hb) ~= "table" or hb.showAbsorb == nil then
        return false
    end
    if hb.showDamageAbsorb == nil then
        hb.showDamageAbsorb = hb.showAbsorb
    end
    hb.showAbsorb = nil
    return true
end

local function MigrateProfileShowAbsorb(profile)
    if type(profile) ~= "table" then
        return false
    end

    profile.migrations = profile.migrations or {}
    if profile.migrations.healthBarShowAbsorbRename then
        return false
    end
    profile.migrations.healthBarShowAbsorbRename = true

    local styles = profile.unitFrameStyles
    if type(styles) ~= "table" then
        return false
    end

    local migrated = false
    for _, style in pairs(styles) do
        if RenameStyleShowAbsorb(style) then
            migrated = true
        end
    end
    return migrated
end

--- Renames the legacy `showAbsorb` healthBar widget config to `showDamageAbsorb`
--- across every profile. Idempotent: a per-profile flag prevents re-runs.
function NivUI:MigrateHealthBarShowAbsorb()
    if not NivUI_DB or not NivUI_DB.profiles then
        return false
    end

    local migratedAny = false
    for _, profile in pairs(NivUI_DB.profiles) do
        if MigrateProfileShowAbsorb(profile) then
            migratedAny = true
        end
    end
    return migratedAny
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
    if addon ~= addonName then
        return
    end

    NivUI_DB = NivUI_DB or {}
    NivUI_CurrentProfile = NivUI_CurrentProfile or "Default"

    NivUI:MigrateToProfiles()
    NivUI:MigrateHealthBarShowAbsorb()

    if not NivUI_DB.profiles then
        NivUI_DB.profiles = { ["Default"] = {} }
    end
    if not NivUI_DB.profiles[NivUI_CurrentProfile] then
        NivUI_CurrentProfile = "Default"
    end
    if not NivUI_DB.profiles["Default"] then
        NivUI_DB.profiles["Default"] = {}
    end

    NivUI.activeProfileName = NivUI_CurrentProfile

    NivUI.isInitialized = NivUI:InitializeDB()

    self:UnregisterEvent("ADDON_LOADED")
end)
