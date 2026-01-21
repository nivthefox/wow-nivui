-- NivUI Stagger Bar
-- Shows actual stagger values because colors aren't enough

local SPEC_MONK_BREWMASTER = 268
local STAGGER_LIGHT = 124273
local STAGGER_MODERATE = 124274
local STAGGER_HEAVY = 124275

-- Color thresholds
local THRESHOLDS = {
    moderate = 0.30,
    heavy = 0.60,
    extreme = 1.00,
}

-- Create the main frame (includes padding for click area)
local StaggerBar = CreateFrame("Frame", "NivUIStaggerBar", UIParent)
StaggerBar:SetSize(394, 20)
StaggerBar:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
StaggerBar:SetResizable(true)
StaggerBar:SetResizeBounds(100, 16, 800, 60)
StaggerBar:Hide()

-- Background for the whole clickable area (transparent)
local clickBg = StaggerBar:CreateTexture(nil, "BACKGROUND", nil, -1)
clickBg:SetAllPoints()
clickBg:SetColorTexture(0, 0, 0, 0)

-- The actual bar container (fills the frame)
local barContainer = CreateFrame("Frame", nil, StaggerBar)
barContainer:SetAllPoints()
StaggerBar.barContainer = barContainer

-- Resize handle (bottom-right corner)
local resizeHandle = CreateFrame("Button", nil, StaggerBar)
resizeHandle:SetSize(16, 16)
resizeHandle:SetPoint("BOTTOMRIGHT", StaggerBar, "BOTTOMRIGHT", 0, 0)
resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeHandle:Hide()
StaggerBar.resizeHandle = resizeHandle

resizeHandle:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        StaggerBar:StartSizing("BOTTOMRIGHT")
    end
end)

resizeHandle:SetScript("OnMouseUp", function(self, button)
    StaggerBar:StopMovingOrSizing()
    local db = NivUI_StaggerBarDB
    db.width = StaggerBar:GetWidth()
    db.height = StaggerBar:GetHeight()
    -- Notify config frame if it's listening
    if NivUI.OnBarMoved then NivUI.OnBarMoved() end
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

-- Text overlay (centered on bar)
local text = StaggerBar:CreateFontString(nil, "OVERLAY")
text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
text:SetPoint("CENTER", barContainer, "CENTER", 0, 0)
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

-- Format numbers: 6423 -> 6.4k, 1234567 -> 1.2m
local function FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fm", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fk", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

-- Stagger decay rate
local STAGGER_TICK_RATE = 0.5
local STAGGER_DECAY_PER_SECOND = 0.10

-- Get tick damage from stagger debuff
local function GetStaggerTickDamage()
    local stagger = UnitStagger("player") or 0

    local auraData = C_UnitAuras.GetPlayerAuraBySpellID(STAGGER_HEAVY)
                  or C_UnitAuras.GetPlayerAuraBySpellID(STAGGER_MODERATE)
                  or C_UnitAuras.GetPlayerAuraBySpellID(STAGGER_LIGHT)

    if auraData and auraData.points and auraData.points[1] then
        return auraData.points[1]
    end

    return stagger * STAGGER_DECAY_PER_SECOND * STAGGER_TICK_RATE
end

-- Get color based on stagger percentage
local function GetStaggerColor(percent)
    local colors = NivUI:GetColors()
    if percent >= THRESHOLDS.extreme then
        return colors.extreme
    elseif percent >= THRESHOLDS.heavy then
        return colors.heavy
    elseif percent >= THRESHOLDS.moderate then
        return colors.moderate
    else
        return colors.light
    end
end

-- Forward declaration for visibility check
local UpdateVisibility

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

    if percent >= THRESHOLDS.extreme then
        StaggerBar.bg:SetColorTexture(0.5, 0, 0, 0.8)
        local overflow = stagger - maxHealth
        StaggerBar.bar:SetMinMaxValues(0, maxHealth)
        StaggerBar.bar:SetValue(overflow)
    else
        StaggerBar.bg:SetColorTexture(0, 0, 0, 0.8)
        StaggerBar.bar:SetMinMaxValues(0, maxHealth)
        StaggerBar.bar:SetValue(stagger)
    end

    StaggerBar.bar:SetStatusBarColor(color.r, color.g, color.b)

    local tickDamage = GetStaggerTickDamage()
    local dps = tickDamage * 2
    local dpsPercent = math.floor((dps / maxHealth) * 1000) / 10

    local dpsText = FormatNumber(dps)
    StaggerBar.text:SetText(dpsText .. "/s (" .. dpsPercent .. "%)")

    UpdateVisibility()
end

-- Check if we should show the bar
local function ShouldShow()
    if not NivUI:GetSetting("locked") then return true end
    if not isBrewmaster then return false end

    if inCombat then return true end
    local stagger = UnitStagger("player")
    if stagger and stagger > 0 then return true end

    return false
end

-- Update visibility
UpdateVisibility = function()
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
    isBrewmaster = (spec == 1)
    UpdateVisibility()
end

-- OnUpdate handler
local function OnUpdate(self, elapsed)
    lastUpdate = lastUpdate + elapsed

    local interval = NivUI:GetSetting("updateInterval")

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
        if not NivUI:GetSetting("locked") then
            self:StartMoving()
        end
    end)

    StaggerBar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db = NivUI_StaggerBarDB
        local point, _, _, x, y = self:GetPoint()
        db.point = point
        db.x = x
        db.y = y
        -- Notify config frame if it's listening
        if NivUI.OnBarMoved then NivUI.OnBarMoved() end
    end)
end

-- Load saved position and size
local function LoadPosition()
    local db = NivUI_StaggerBarDB
    local defaults = NivUI.defaults

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

    if NivUI:GetSetting("locked") then
        StaggerBar.resizeHandle:Hide()
    else
        StaggerBar.resizeHandle:Show()
    end
end

-- Apply bar texture from saved settings
local function ApplyBarTexture()
    local texture = NivUI:GetSetting("barTexture")
    StaggerBar.bar:SetStatusBarTexture(texture)
end

-- Apply font settings from saved settings
local function ApplyFontSettings()
    local db = NivUI_StaggerBarDB
    local defaults = NivUI.defaults

    local fontPath = db.font or defaults.font
    local fontSize = db.fontSize or defaults.fontSize
    local fontShadow = db.fontShadow
    if fontShadow == nil then fontShadow = defaults.fontShadow end

    local flags = fontShadow and "OUTLINE" or ""
    StaggerBar.text:SetFont(fontPath, fontSize, flags)

    local fontColor = db.fontColor or defaults.fontColor
    StaggerBar.text:SetTextColor(fontColor.r, fontColor.g, fontColor.b, 1)
end

-- Apply lock state
local function ApplyLockState()
    local locked = NivUI:GetSetting("locked")
    if locked then
        StaggerBar.resizeHandle:Hide()
    else
        StaggerBar.resizeHandle:Show()
        -- Show preview when unlocked
        local colors = NivUI:GetColors()
        StaggerBar.bar:SetMinMaxValues(0, 1)
        StaggerBar.bar:SetValue(0)
        StaggerBar.bar:SetStatusBarColor(colors.light.r, colors.light.g, colors.light.b)
        StaggerBar.bg:SetColorTexture(0, 0, 0, 0.8)
        StaggerBar.text:SetText("0/s (0%)")
        StaggerBar:Show()
    end
    UpdateVisibility()
end

-- Register apply callbacks with NivUI
NivUI:RegisterApplyCallback("barTexture", ApplyBarTexture)
NivUI:RegisterApplyCallback("font", ApplyFontSettings)
NivUI:RegisterApplyCallback("locked", ApplyLockState)
NivUI:RegisterApplyCallback("position", LoadPosition)

-- Make these available for config frame
NivUI.StaggerBar = StaggerBar
NivUI.UpdateVisibility = UpdateVisibility

-- Event handler
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == "NivUI" then
            NivUI:InitializeDB()
            LoadPosition()
            ApplyBarTexture()
            ApplyFontSettings()
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

    if not module or module == "" then
        -- No args: open config frame
        if NivUIConfigFrame then
            if NivUIConfigFrame:IsShown() then
                NivUIConfigFrame:Hide()
            else
                NivUIConfigFrame:Show()
            end
        else
            print("NivUI: Config frame not loaded")
        end
    elseif module == "stagger" then
        if cmd == "lock" then
            NivUI_StaggerBarDB.locked = true
            ApplyLockState()
            print("NivUI Stagger Bar: Locked")
        elseif cmd == "unlock" then
            NivUI_StaggerBarDB.locked = false
            ApplyLockState()
            print("NivUI Stagger Bar: Unlocked - drag to move, corner to resize")
        elseif cmd == "show" then
            StaggerBar:Show()
            print("NivUI Stagger Bar: Forced visible (will hide on combat end)")
        elseif cmd == "reset" then
            NivUI_StaggerBarDB = {}
            NivUI:InitializeDB()
            LoadPosition()
            ApplyBarTexture()
            ApplyFontSettings()
            print("NivUI Stagger Bar: Reset to defaults")
        else
            print("NivUI Stagger Bar commands:")
            print("  /nivui stagger lock - Lock position")
            print("  /nivui stagger unlock - Unlock for repositioning")
            print("  /nivui stagger show - Force show (for testing)")
            print("  /nivui stagger reset - Reset to defaults")
        end
    else
        print("NivUI commands:")
        print("  /nivui - Open config panel")
        print("  /nivui stagger - Stagger bar options")
    end
end
