local STAGGER_LIGHT = 124273
local STAGGER_MODERATE = 124274
local STAGGER_HEAVY = 124275

local THRESHOLDS = {
    moderate = 0.30,
    heavy = 0.60,
    extreme = 1.00,
}

local lastUpdate = 0
local isBrewmaster = false
local inCombat = false

local function GetSetting(key)
    local db = NivUI.current and NivUI.current.staggerBar
    if db and db[key] ~= nil then
        return db[key]
    end
    return NivUI.staggerBarDefaults[key]
end

local function GetColors()
    local db = NivUI.current and NivUI.current.staggerBar
    if db and db.colors then
        return db.colors
    end
    return NivUI.staggerBarDefaults.colors
end

local function FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fm", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fk", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

local STAGGER_TICK_RATE = 0.5
local STAGGER_DECAY_PER_SECOND = 0.10

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

local function GetStaggerColor(percent)
    local colors = GetColors()
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

local UpdateVisibility
local UpdateBar

local function ShouldShow()
    local visibility = GetSetting("visibility")

    if visibility == "never" then return false end
    if not GetSetting("locked") then return true end
    if not isBrewmaster then return false end
    if visibility == "always" then return true end

    if inCombat then return true end
    local stagger = UnitStagger("player")
    if stagger and stagger > 0 then return true end

    return false
end

UpdateVisibility = function()
    local frame = NivUI.StaggerBar
    if not frame then return end

    if ShouldShow() then
        frame:Show()
    else
        frame:Hide()
    end
end

UpdateBar = function()
    local frame = NivUI.StaggerBar
    if not frame then return end

    local stagger = UnitStagger("player")
    local maxHealth = UnitHealthMax("player")

    if not stagger or not maxHealth or maxHealth == 0 then
        frame.textLeft:SetText("")
        frame.textCenter:SetText("")
        frame.textRight:SetText("")
        frame.bar:SetValue(0)
        return
    end

    local percent = stagger / maxHealth
    local color = GetStaggerColor(percent)

    if percent >= THRESHOLDS.extreme then
        frame.bg:SetColorTexture(0.5, 0, 0, 0.8)
        local overflow = stagger - maxHealth
        frame.bar:SetMinMaxValues(0, maxHealth)
        frame.bar:SetValue(overflow)
    else
        frame.bg:SetColorTexture(0, 0, 0, 0.8)
        frame.bar:SetMinMaxValues(0, maxHealth)
        frame.bar:SetValue(stagger)
    end

    frame.bar:SetStatusBarColor(color.r, color.g, color.b)

    local tickDamage = GetStaggerTickDamage()
    local dps = tickDamage * 2
    local dpsPercent = math.floor((dps / maxHealth) * 1000) / 10

    frame.textLeft:SetText(FormatNumber(stagger))
    frame.textCenter:SetText(FormatNumber(dps) .. "/s")
    frame.textRight:SetText(dpsPercent .. "%")

    UpdateVisibility()
end

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

local function OnUpdate(self, elapsed)
    lastUpdate = lastUpdate + elapsed

    local interval = GetSetting("updateInterval")

    if lastUpdate >= interval then
        lastUpdate = 0
        UpdateBar()
    end
end

local function LoadPosition(frame)
    local db = NivUI.current.staggerBar
    local defaults = NivUI.staggerBarDefaults

    frame:ClearAllPoints()
    frame:SetPoint(
        db.point or defaults.point,
        UIParent,
        db.point or defaults.point,
        db.x or defaults.x,
        db.y or defaults.y
    )
    frame:SetSize(
        db.width or defaults.width,
        db.height or defaults.height
    )

    if GetSetting("locked") then
        frame.resizeHandle:Hide()
    else
        frame.resizeHandle:Show()
    end
end

local function ApplyBarTexture(frame)
    local textureName = GetSetting("foregroundTexture") or GetSetting("barTexture")
    local texturePath = NivUI:GetTexturePath(textureName)
    frame.bar:SetStatusBarTexture(texturePath)
    frame.spark:ClearAllPoints()
    frame.spark:SetPoint("CENTER", frame.bar:GetStatusBarTexture(), "RIGHT", 0, 0)
end

local function ApplyBackground(frame)
    local bgColor = GetSetting("backgroundColor")
    if bgColor then
        frame.bg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
    end
end

local function ApplyBorder(frame)
    local borderStyle = GetSetting("borderStyle")
    local borderColor = GetSetting("borderColor")

    if borderStyle == "none" then
        frame.border:SetBackdrop(nil)
    else
        local width = borderStyle == "thick" and 2 or 1
        frame.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = width,
        })
        if borderColor then
            frame.border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        else
            frame.border:SetBackdropBorderColor(0, 0, 0, 1)
        end
    end
end

local function ApplyFontSettings(frame)
    local db = NivUI.current.staggerBar
    local defaults = NivUI.staggerBarDefaults

    local fontName = db.font or defaults.font
    local fontPath = NivUI:GetFontPath(fontName)
    local fontSize = db.fontSize or defaults.fontSize
    local fontShadow = db.fontShadow
    if fontShadow == nil then fontShadow = defaults.fontShadow end

    local flags = fontShadow and "OUTLINE" or ""

    local fontColor = db.fontColor or defaults.fontColor
    local r = fontColor.r or 1
    local g = fontColor.g or 1
    local b = fontColor.b or 1

    for _, text in ipairs({frame.textLeft, frame.textCenter, frame.textRight}) do
        text:SetFont(fontPath, fontSize, flags)
        text:SetTextColor(r, g, b, 1)
    end
end

local function ApplyLockState(frame)
    local locked = GetSetting("locked")
    if locked then
        frame.resizeHandle:Hide()
    else
        frame.resizeHandle:Show()
        local colors = GetColors()
        frame.bar:SetMinMaxValues(0, 1)
        frame.bar:SetValue(0)
        frame.bar:SetStatusBarColor(colors.light.r, colors.light.g, colors.light.b)
        frame.bg:SetColorTexture(0, 0, 0, 0.8)
        frame.textLeft:SetText("0")
        frame.textCenter:SetText("0/s")
        frame.textRight:SetText("0%")
        frame:Show()
    end
    UpdateVisibility()
end

local function EnableDragging(frame)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
        if not GetSetting("locked") then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db = NivUI.current.staggerBar
        local point, _, _, x, y = self:GetPoint()
        db.point = point
        db.x = x
        db.y = y
        if NivUI.OnBarMoved then NivUI.OnBarMoved() end
    end)
end

local function CreateStaggerBarUI()
    local frame = CreateFrame("Frame", "NivUIStaggerBar", UIParent)
    frame:SetSize(394, 20)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    frame:SetResizable(true)
    frame:SetResizeBounds(100, 5, 800, 60)
    frame:Hide()

    local clickBg = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    clickBg:SetAllPoints()
    clickBg:SetColorTexture(0, 0, 0, 0)

    local barContainer = CreateFrame("Frame", nil, frame)
    barContainer:SetAllPoints()
    frame.barContainer = barContainer

    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeHandle:Hide()
    frame.resizeHandle = resizeHandle

    resizeHandle:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            frame:StartSizing("BOTTOMRIGHT")
        end
    end)

    resizeHandle:SetScript("OnMouseUp", function(self)
        frame:StopMovingOrSizing()
        local db = NivUI.current.staggerBar
        db.width = frame:GetWidth()
        db.height = frame:GetHeight()
        if NivUI.OnBarMoved then NivUI.OnBarMoved() end
    end)

    local bg = barContainer:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.8)
    frame.bg = bg

    local bar = CreateFrame("StatusBar", nil, barContainer)
    bar:SetAllPoints()
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    frame.bar = bar

    local spark = bar:CreateTexture(nil, "OVERLAY")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    spark:SetSize(4, 4)
    spark:SetBlendMode("ADD")
    spark:SetPoint("CENTER", bar:GetStatusBarTexture(), "RIGHT", 0, 0)
    frame.spark = spark

    local textLeft = bar:CreateFontString(nil, "OVERLAY")
    textLeft:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    textLeft:SetPoint("LEFT", bar, "LEFT", 4, 0)
    textLeft:SetTextColor(1, 1, 1, 1)
    textLeft:SetShadowOffset(0, 0)
    frame.textLeft = textLeft

    local textCenter = bar:CreateFontString(nil, "OVERLAY")
    textCenter:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    textCenter:SetPoint("CENTER", bar, "CENTER", 0, 0)
    textCenter:SetTextColor(1, 1, 1, 1)
    textCenter:SetShadowOffset(0, 0)
    frame.textCenter = textCenter

    local textRight = bar:CreateFontString(nil, "OVERLAY")
    textRight:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    textRight:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    textRight:SetTextColor(1, 1, 1, 1)
    textRight:SetShadowOffset(0, 0)
    frame.textRight = textRight

    frame.text = textCenter

    local border = CreateFrame("Frame", nil, barContainer, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0, 0, 0, 1)
    frame.border = border

    return frame
end

local function RegisterEvents(frame)
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")

    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_SPECIALIZATION_CHANGED" then
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
    end)
end

local function OnEnable(frame)
    NivUI.StaggerBar = frame

    LoadPosition(frame)
    ApplyBarTexture(frame)
    ApplyBackground(frame)
    ApplyBorder(frame)
    ApplyFontSettings(frame)
    EnableDragging(frame)
    CheckSpec()

    NivUI:RegisterApplyCallback("barTexture", function() ApplyBarTexture(frame) end)
    NivUI:RegisterApplyCallback("background", function() ApplyBackground(frame) end)
    NivUI:RegisterApplyCallback("border", function() ApplyBorder(frame) end)
    NivUI:RegisterApplyCallback("visibility", UpdateVisibility)
    NivUI:RegisterApplyCallback("font", function() ApplyFontSettings(frame) end)
    NivUI:RegisterApplyCallback("locked", function() ApplyLockState(frame) end)
    NivUI:RegisterApplyCallback("position", function() LoadPosition(frame) end)
end

local function OnDisable()
    NivUI.StaggerBar = nil
end

NivUI:RegisterClassBar("stagger", {
    displayName = "Stagger Bar",
    tabName = "Stagger",
    sortOrder = 1,
    globalRef = "StaggerBar",
    contentHeight = 900,

    defaults = {
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
    },

    configSections = {
        { type = "enable" },
        { type = "header", text = "General" },
        { type = "visibility", applySetting = "visibility" },
        { type = "header", text = "Appearance" },
        { type = "fgTexture", applySetting = "barTexture" },
        { type = "bgTexture", applySetting = "background" },
        { type = "bgColor", applySetting = "background" },
        { type = "borderDropdown", applySetting = "border" },
        { type = "borderColor", applySetting = "border" },
        { type = "header", text = "Stagger Colors" },
        { type = "color", nestedKey = "colors", key = "light", label = "Light:" },
        { type = "color", nestedKey = "colors", key = "moderate", label = "Moderate:" },
        { type = "color", nestedKey = "colors", key = "heavy", label = "Heavy:" },
        { type = "color", nestedKey = "colors", key = "extreme", label = "Extreme:" },
        { type = "header", text = "Text" },
        { type = "fontDropdown", applySetting = "font" },
        { type = "fontSizeSlider", applySetting = "font" },
        { type = "fontColor", applySetting = "font" },
        { type = "fontShadow", applySetting = "font" },
        { type = "header", text = "Position" },
        { type = "lockedCheckbox", applySetting = "locked" },
        { type = "widthSlider", applySetting = "position" },
        { type = "heightSlider", applySetting = "position" },
        { type = "intervalSlider" },
    },

    createModule = function()
        return NivUI.BarBase.CreateModule({
            barType = "stagger",
            createUI = CreateStaggerBarUI,
            registerEvents = RegisterEvents,
            onUpdate = OnUpdate,
            onEnable = OnEnable,
            onDisable = OnDisable,
        })
    end,
})

NivUI.UpdateVisibility = UpdateVisibility
