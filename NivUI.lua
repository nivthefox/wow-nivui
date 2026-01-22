NivUI = NivUI or {}

NivUI_DB = NivUI_DB or {}
NivUI_StaggerBarDB = NivUI_StaggerBarDB or {}  -- Legacy, kept for migration

NivUI.staggerBarDefaults = {
    visibility = "combat",
    updateInterval = 0.2,
    width = 394,
    height = 20,
    point = "CENTER",
    x = 0,
    y = -200,
    locked = false,

    -- Bar appearance
    foregroundTexture = "Default",
    backgroundTexture = "Default",
    backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
    borderStyle = "thin",
    borderColor = { r = 0, g = 0, b = 0, a = 1 },
    borderWidth = 1,

    -- Font settings
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

NivUI.staggerBarDefaults.barTexture = NivUI.staggerBarDefaults.foregroundTexture  -- Legacy alias
NivUI.defaults = NivUI.staggerBarDefaults  -- Legacy alias

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

NivUI.applyCallbacks = {}

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
    local db = NivUI_DB.staggerBar or {}
    if db[key] ~= nil then
        return db[key]
    end
    return self.staggerBarDefaults[key]
end

function NivUI:GetColors()
    local db = NivUI_DB.staggerBar or {}
    if db.colors then
        return db.colors
    end
    return self.staggerBarDefaults.colors
end

local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

function NivUI:InitializeDB()
    NivUI_DB.version = NivUI_DB.version or 1

    if not NivUI_DB.staggerBar then
        if next(NivUI_StaggerBarDB) then
            NivUI_DB.staggerBar = DeepCopy(NivUI_StaggerBarDB)
        else
            NivUI_DB.staggerBar = {}
        end
    end

    for k, v in pairs(self.staggerBarDefaults) do
        if NivUI_DB.staggerBar[k] == nil then
            NivUI_DB.staggerBar[k] = DeepCopy(v)
        end
    end

    if not NivUI_DB.unitFrameStyles then
        NivUI_DB.unitFrameStyles = {}
    end

    if not NivUI_DB.unitFrameAssignments then
        NivUI_DB.unitFrameAssignments = {
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
