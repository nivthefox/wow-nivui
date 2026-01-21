-- NivUI Stagger Bar
-- Shows actual stagger values because colors aren't enough

local SPEC_MONK_BREWMASTER = 268
local STAGGER_LIGHT = 124273
local STAGGER_MODERATE = 124274
local STAGGER_HEAVY = 124275

-- Color thresholds and values
local COLORS = {
    light = { r = 0, g = 1, b = 0 },       -- green
    moderate = { r = 1, g = 1, b = 0 },    -- yellow
    heavy = { r = 1, g = 0, b = 0 },       -- red
    extreme = { r = 1, g = 0, b = 1 },     -- magenta
}

local THRESHOLDS = {
    moderate = 0.30,
    heavy = 0.60,
    extreme = 1.00,
}

-- Saved variables (will be initialized on load)
NivUI_StaggerBarDB = NivUI_StaggerBarDB or {}

local defaults = {
    updateInterval = 0.2,
    width = 394,
    height = 20,
    point = "CENTER",
    x = 0,
    y = -200,
    locked = false,
}

-- Create the main frame (includes padding for click area)
local StaggerBar = CreateFrame("Frame", "NivUIStaggerBar", UIParent)
StaggerBar:SetSize(394, 20)  -- Taller for easier clicking
StaggerBar:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
StaggerBar:SetResizable(true)
StaggerBar:SetResizeBounds(100, 16, 800, 60)  -- min/max sizes
StaggerBar:Hide()

-- Background for the whole clickable area (transparent)
local clickBg = StaggerBar:CreateTexture(nil, "BACKGROUND", nil, -1)
clickBg:SetAllPoints()
clickBg:SetColorTexture(0, 0, 0, 0)  -- Invisible but clickable

-- The actual bar container (4px tall, at bottom of frame)
local barContainer = CreateFrame("Frame", nil, StaggerBar)
barContainer:SetHeight(4)
barContainer:SetPoint("LEFT", StaggerBar, "LEFT", 0, 0)
barContainer:SetPoint("RIGHT", StaggerBar, "RIGHT", 0, 0)
barContainer:SetPoint("BOTTOM", StaggerBar, "BOTTOM", 0, 0)
StaggerBar.barContainer = barContainer

-- Resize handle (bottom-right corner)
local resizeHandle = CreateFrame("Button", nil, StaggerBar)
resizeHandle:SetSize(16, 16)
resizeHandle:SetPoint("BOTTOMRIGHT", StaggerBar, "BOTTOMRIGHT", 0, 0)
resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeHandle:Hide()  -- Only show when unlocked
StaggerBar.resizeHandle = resizeHandle

resizeHandle:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        StaggerBar:StartSizing("BOTTOMRIGHT")
    end
end)

resizeHandle:SetScript("OnMouseUp", function(self, button)
    StaggerBar:StopMovingOrSizing()
    -- Save size
    local db = NivUI_StaggerBarDB
    db.width = StaggerBar:GetWidth()
    db.height = StaggerBar:GetHeight()
end)

-- Background for the bar
local bg = barContainer:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.8)
StaggerBar.bg = bg

-- Status bar
local bar = CreateFrame("StatusBar", nil, barContainer)
bar:SetAllPoints()
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)
StaggerBar.bar = bar

-- Spark
local spark = bar:CreateTexture(nil, "OVERLAY")
spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
spark:SetSize(4, 4)
spark:SetBlendMode("ADD")
spark:SetPoint("CENTER", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
StaggerBar.spark = spark

-- Text overlay (above the bar)
local text = StaggerBar:CreateFontString(nil, "OVERLAY")
text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
text:SetPoint("BOTTOM", barContainer, "TOP", 0, 2)
text:SetTextColor(1, 1, 1, 1)
StaggerBar.text = text

-- Border around the bar
local border = CreateFrame("Frame", nil, barContainer, "BackdropTemplate")
border:SetPoint("TOPLEFT", -1, 1)
border:SetPoint("BOTTOMRIGHT", 1, -1)
border:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
border:SetBackdropBorderColor(0, 0, 0, 1)
StaggerBar.border = border

-- State
local lastUpdate = 0
local isBrewmaster = false
local inCombat = false

-- Format large numbers
local function FormatNumber(num)
    if num > 999999 then
        return string.format("%.2fm", num / 1000000)
    elseif num > 99999 then
        return string.format("%dk", math.floor(num / 1000))
    elseif num > 9999 then
        return string.format("%.1fk", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

-- Debug mode
local debugMode = false
local lastDebugTime = 0

-- Stagger decay rate: approximately 10% of pool per second, ticks every 0.5s
local STAGGER_TICK_RATE = 0.5
local STAGGER_DECAY_PER_SECOND = 0.10

-- Helper to get table keys (for debug)
local function GetKeysArray(t)
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, tostring(k))
    end
    return keys
end

-- Get tick damage from stagger debuff
local function GetStaggerTickDamage()
    local stagger = UnitStagger("player") or 0

    -- Try to get from aura data first
    local auraData = C_UnitAuras.GetPlayerAuraBySpellID(STAGGER_HEAVY)
                  or C_UnitAuras.GetPlayerAuraBySpellID(STAGGER_MODERATE)
                  or C_UnitAuras.GetPlayerAuraBySpellID(STAGGER_LIGHT)

    if debugMode then
        local now = GetTime()
        if now - lastDebugTime >= 1 then  -- Throttle debug output
            lastDebugTime = now
            if auraData then
                print("NivUI Debug: Found aura, spellId=" .. tostring(auraData.spellId))
                print("NivUI Debug: aura keys: " .. table.concat(GetKeysArray(auraData) or {}, ", "))
                if auraData.points then
                    print("NivUI Debug: points has " .. #auraData.points .. " entries")
                    for i, v in ipairs(auraData.points) do
                        print("NivUI Debug: points[" .. i .. "] = " .. tostring(v))
                    end
                else
                    print("NivUI Debug: No points table")
                end
            else
                print("NivUI Debug: No stagger aura found via GetPlayerAuraBySpellID")
            end
            print("NivUI Debug: UnitStagger = " .. tostring(stagger))
        end
    end

    -- If API gives us the value, use it
    if auraData and auraData.points and auraData.points[1] then
        return auraData.points[1]
    end

    -- Fallback: calculate from stagger pool
    -- Tick damage = pool * decay_per_second * tick_interval
    return stagger * STAGGER_DECAY_PER_SECOND * STAGGER_TICK_RATE
end

-- Get color based on stagger percentage
local function GetStaggerColor(percent)
    if percent >= THRESHOLDS.extreme then
        return COLORS.extreme
    elseif percent >= THRESHOLDS.heavy then
        return COLORS.heavy
    elseif percent >= THRESHOLDS.moderate then
        return COLORS.moderate
    else
        return COLORS.light
    end
end

-- Update the bar display
local function UpdateBar()
    local stagger = UnitStagger("player")
    local maxHealth = UnitHealthMax("player")

    if not stagger or not maxHealth or maxHealth == 0 then
        StaggerBar.text:SetText("")
        StaggerBar.bar:SetValue(0)
        return
    end

    local percent = stagger / maxHealth
    local color = GetStaggerColor(percent)

    -- Handle overflow (stagger > 100% health)
    if percent >= THRESHOLDS.extreme then
        -- Red background for overflow
        StaggerBar.bg:SetColorTexture(0.5, 0, 0, 0.8)
        -- Bar shows overflow amount
        local overflow = stagger - maxHealth
        StaggerBar.bar:SetMinMaxValues(0, maxHealth)
        StaggerBar.bar:SetValue(overflow)
    else
        -- Normal black background
        StaggerBar.bg:SetColorTexture(0, 0, 0, 0.8)
        StaggerBar.bar:SetMinMaxValues(0, maxHealth)
        StaggerBar.bar:SetValue(stagger)
    end

    StaggerBar.bar:SetStatusBarColor(color.r, color.g, color.b)

    -- Get tick damage and format text
    local tickDamage = GetStaggerTickDamage()
    local displayTick = tickDamage * 2  -- damage per second (ticks every 0.5s)
    local tickPercent = math.floor((tickDamage / maxHealth) * 1000) / 10

    local tickText = FormatNumber(displayTick)
    StaggerBar.text:SetText(tickText .. "/s (" .. tickPercent .. "%)")
end

-- Check if we should show the bar
local function ShouldShow()
    if not isBrewmaster then return false end
    if not inCombat then return false end
    return true
end

-- Update visibility
local function UpdateVisibility()
    if ShouldShow() then
        StaggerBar:Show()
    else
        StaggerBar:Hide()
    end
end

-- Check spec
local function CheckSpec()
    local _, class = UnitClass("player")
    if class ~= "MONK" then
        isBrewmaster = false
        return
    end

    local spec = GetSpecialization()
    isBrewmaster = (spec == 1)  -- Brewmaster is spec index 1
    UpdateVisibility()
end

-- OnUpdate handler
local function OnUpdate(self, elapsed)
    lastUpdate = lastUpdate + elapsed

    local db = NivUI_StaggerBarDB
    local interval = db.updateInterval or defaults.updateInterval

    if lastUpdate >= interval then
        lastUpdate = 0
        UpdateBar()
    end
end

-- Make draggable
local function EnableDragging()
    StaggerBar:SetMovable(true)
    StaggerBar:EnableMouse(true)
    StaggerBar:RegisterForDrag("LeftButton")

    StaggerBar:SetScript("OnDragStart", function(self)
        local db = NivUI_StaggerBarDB
        if not db.locked then
            self:StartMoving()
        end
    end)

    StaggerBar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local db = NivUI_StaggerBarDB
        local point, _, _, x, y = self:GetPoint()
        db.point = point
        db.x = x
        db.y = y
    end)
end

-- Load saved position
local function LoadPosition()
    local db = NivUI_StaggerBarDB
    StaggerBar:ClearAllPoints()
    StaggerBar:SetPoint(
        db.point or defaults.point,
        UIParent,
        db.point or defaults.point,
        db.x or defaults.x,
        db.y or defaults.y
    )
    StaggerBar:SetSize(
        db.width or defaults.width,
        db.height or defaults.height
    )
    -- Show resize handle if unlocked
    if db.locked then
        StaggerBar.resizeHandle:Hide()
    else
        StaggerBar.resizeHandle:Show()
    end
end

-- Event handler
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == "NivUI" then
            -- Initialize saved variables with defaults
            for k, v in pairs(defaults) do
                if NivUI_StaggerBarDB[k] == nil then
                    NivUI_StaggerBarDB[k] = v
                end
            end
            LoadPosition()
            EnableDragging()
            CheckSpec()
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        CheckSpec()
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        UpdateVisibility()
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        UpdateVisibility()
    elseif event == "PLAYER_ENTERING_WORLD" then
        CheckSpec()
        inCombat = UnitAffectingCombat("player")
        UpdateVisibility()
    end
end

-- Register events
StaggerBar:RegisterEvent("ADDON_LOADED")
StaggerBar:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
StaggerBar:RegisterEvent("PLAYER_REGEN_DISABLED")
StaggerBar:RegisterEvent("PLAYER_REGEN_ENABLED")
StaggerBar:RegisterEvent("PLAYER_ENTERING_WORLD")
StaggerBar:SetScript("OnEvent", OnEvent)
StaggerBar:SetScript("OnUpdate", OnUpdate)

-- Slash commands
SLASH_NIVUI1 = "/nivui"
SlashCmdList["NIVUI"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end

    local module = args[1]
    local cmd = args[2]

    if module == "stagger" then
        if cmd == "lock" then
            NivUI_StaggerBarDB.locked = true
            StaggerBar.resizeHandle:Hide()
            print("NivUI Stagger Bar: Locked")
        elseif cmd == "unlock" then
            NivUI_StaggerBarDB.locked = false
            StaggerBar.resizeHandle:Show()
            print("NivUI Stagger Bar: Unlocked - drag to move, corner to resize")
        elseif cmd == "show" then
            StaggerBar:Show()
            print("NivUI Stagger Bar: Forced visible (will hide on combat end)")
        elseif cmd == "reset" then
            NivUI_StaggerBarDB = {}
            for k, v in pairs(defaults) do
                NivUI_StaggerBarDB[k] = v
            end
            LoadPosition()
            print("NivUI Stagger Bar: Reset to defaults")
        elseif cmd == "debug" then
            debugMode = not debugMode
            print("NivUI Stagger Bar: Debug mode " .. (debugMode and "ON" or "OFF"))
            if debugMode then
                print("  Watch chat for API output (throttled to 1/sec)")
            end
        else
            print("NivUI Stagger Bar commands:")
            print("  /nivui stagger lock - Lock position")
            print("  /nivui stagger unlock - Unlock for repositioning")
            print("  /nivui stagger show - Force show (for testing)")
            print("  /nivui stagger reset - Reset to defaults")
            print("  /nivui stagger debug - Toggle debug output")
        end
    else
        print("NivUI commands:")
        print("  /nivui stagger - Stagger bar options")
    end
end
