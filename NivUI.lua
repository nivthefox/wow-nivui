-- NivUI: Core namespace and shared configuration
-- This file loads first and sets up the global namespace

NivUI = NivUI or {}

-- Saved variables (initialized on ADDON_LOADED)
NivUI_StaggerBarDB = NivUI_StaggerBarDB or {}

-- Default settings for the stagger bar
NivUI.defaults = {
    -- Position and size
    updateInterval = 0.2,
    width = 394,
    height = 20,
    point = "CENTER",
    x = 0,
    y = -200,
    locked = false,

    -- Bar appearance
    barTexture = "Interface\\TargetingFrame\\UI-StatusBar",

    -- Font settings
    font = "Fonts\\FRIZQT__.TTF",
    fontSize = 12,
    fontColor = { r = 1, g = 1, b = 1 },
    fontShadow = true,

    -- Stagger colors
    colors = {
        light = { r = 0, g = 1, b = 0 },
        moderate = { r = 1, g = 1, b = 0 },
        heavy = { r = 1, g = 0, b = 0 },
        extreme = { r = 1, g = 0, b = 1 },
    },
}

-- Fallback bar textures (used if SharedMedia unavailable)
local BUILTIN_TEXTURES = {
    { path = "Interface\\TargetingFrame\\UI-StatusBar", name = "Default" },
    { path = "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill", name = "Target Frame" },
    { path = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill", name = "Raid Frame" },
    { path = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar", name = "Skills Bar" },
}

-- Fallback fonts (used if SharedMedia unavailable)
local BUILTIN_FONTS = {
    { path = "Fonts\\FRIZQT__.TTF", name = "Friz Quadrata" },
    { path = "Fonts\\ARIALN.TTF", name = "Arial Narrow" },
    { path = "Fonts\\MORPHEUS.TTF", name = "Morpheus" },
    { path = "Fonts\\SKURRI.TTF", name = "Skurri" },
}

-- Get SharedMedia if available
function NivUI:GetSharedMedia()
    if self.LSM == nil then
        self.LSM = LibStub and LibStub("LibSharedMedia-3.0", true) or false
    end
    return self.LSM
end

-- Get available bar textures (from SharedMedia or fallback)
function NivUI:GetBarTextures()
    local LSM = self:GetSharedMedia()
    if LSM then
        local list = LSM:List("statusbar")
        local textures = {}
        for _, name in ipairs(list) do
            table.insert(textures, {
                path = LSM:Fetch("statusbar", name),
                name = name,
            })
        end
        return textures
    end
    return BUILTIN_TEXTURES
end

-- Get available fonts (from SharedMedia or fallback)
function NivUI:GetFonts()
    local LSM = self:GetSharedMedia()
    if LSM then
        local list = LSM:List("font")
        local fonts = {}
        for _, name in ipairs(list) do
            table.insert(fonts, {
                path = LSM:Fetch("font", name),
                name = name,
            })
        end
        return fonts
    end
    return BUILTIN_FONTS
end

-- For backwards compat, these are populated on first access
NivUI.barTextures = nil
NivUI.fonts = nil

-- Registry for apply callbacks (modules register here, config calls them)
NivUI.applyCallbacks = {}

function NivUI:RegisterApplyCallback(name, callback)
    self.applyCallbacks[name] = callback
end

function NivUI:ApplySettings(settingName)
    if settingName then
        -- Apply specific setting
        local callback = self.applyCallbacks[settingName]
        if callback then callback() end
    else
        -- Apply all settings
        for _, callback in pairs(self.applyCallbacks) do
            callback()
        end
    end
end

-- Helper to get a saved value with fallback to default
function NivUI:GetSetting(key)
    local db = NivUI_StaggerBarDB
    if db[key] ~= nil then
        return db[key]
    end
    return self.defaults[key]
end

-- Helper to get stagger colors specifically (nested table)
function NivUI:GetColors()
    local db = NivUI_StaggerBarDB
    if db.colors then
        return db.colors
    end
    return self.defaults.colors
end

-- Initialize saved variables with defaults (call on ADDON_LOADED)
function NivUI:InitializeDB()
    for k, v in pairs(self.defaults) do
        if NivUI_StaggerBarDB[k] == nil then
            if type(v) == "table" then
                NivUI_StaggerBarDB[k] = {}
                for k2, v2 in pairs(v) do
                    if type(v2) == "table" then
                        NivUI_StaggerBarDB[k][k2] = {}
                        for k3, v3 in pairs(v2) do
                            NivUI_StaggerBarDB[k][k2][k3] = v3
                        end
                    else
                        NivUI_StaggerBarDB[k][k2] = v2
                    end
                end
            else
                NivUI_StaggerBarDB[k] = v
            end
        end
    end
end
