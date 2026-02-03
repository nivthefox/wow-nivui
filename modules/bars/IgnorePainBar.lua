local lastUpdate = 0
local isProtection = false
local inCombat = false

local function GetSetting(key)
    local db = NivUI.current and NivUI.current.ignorePainBar
    if db and db[key] ~= nil then
        return db[key]
    end
    return NivUI.ignorePainBarDefaults[key]
end

local UpdateVisibility
local UpdateBar

local function ShouldShow()
    local visibility = GetSetting("visibility")

    if visibility == "never" then return false end
    if not GetSetting("locked") then return true end
    if not isProtection then return false end
    if visibility == "always" then return true end

    if inCombat then return true end
    local absorb = UnitGetTotalAbsorbs("player")
    if absorb and absorb > 0 then return true end

    return false
end

UpdateVisibility = function()
    local frame = NivUI.IgnorePainBar
    if not frame then return end

    if ShouldShow() then
        frame:Show()
    else
        frame:Hide()
    end
end

UpdateBar = function()
    local frame = NivUI.IgnorePainBar
    if not frame then return end

    local absorb = UnitGetTotalAbsorbs("player")
    local maxHealth = UnitHealthMax("player")

    if not maxHealth or maxHealth == 0 then
        frame.bar:SetValue(0)
        frame.text:SetText("")
        return
    end

    frame.bar:SetMinMaxValues(0, maxHealth)
    frame.bar:SetValue(absorb or 0)

    -- SetFormattedText handles secret values
    frame.text:SetFormattedText("%.0f", absorb or 0)

    UpdateVisibility()
end

local function CheckSpec()
    local _, class = UnitClass("player")
    if class ~= "WARRIOR" then
        isProtection = false
        return
    end

    local spec = GetSpecialization()
    isProtection = (spec == 3)
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
    local db = NivUI.current.ignorePainBar
    local defaults = NivUI.ignorePainBarDefaults

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
    local textureName = GetSetting("foregroundTexture")
    local texturePath = NivUI:GetTexturePath(textureName)
    frame.bar:SetStatusBarTexture(texturePath)
    frame.spark:ClearAllPoints()
    frame.spark:SetPoint("CENTER", frame.bar:GetStatusBarTexture(), "RIGHT", 0, 0)
end

local function ApplyBarColor(frame)
    local color = GetSetting("barColor")
    frame.bar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
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
    local db = NivUI.current.ignorePainBar
    local defaults = NivUI.ignorePainBarDefaults

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

    frame.text:SetFont(fontPath, fontSize, flags)
    frame.text:SetTextColor(r, g, b, 1)
end

local function ApplyLockState(frame)
    local locked = GetSetting("locked")
    if locked then
        frame.resizeHandle:Hide()
    else
        frame.resizeHandle:Show()
        local color = GetSetting("barColor")
        frame.bar:SetMinMaxValues(0, 1)
        frame.bar:SetValue(0.5)
        frame.bar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
        frame.bg:SetColorTexture(0, 0, 0, 0.8)
        frame.text:SetText("12345")
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
        local db = NivUI.current.ignorePainBar
        local point, _, _, x, y = self:GetPoint()
        db.point = point
        db.x = x
        db.y = y
        if NivUI.OnBarMoved then NivUI.OnBarMoved() end
    end)
end

local function CreateIgnorePainBarUI()
    local frame = CreateFrame("Frame", "NivUIIgnorePainBar", UIParent)
    frame:SetSize(394, 20)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -460)
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

    resizeHandle:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        local db = NivUI.current.ignorePainBar
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

    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    text:SetTextColor(1, 1, 1, 1)
    text:SetShadowOffset(0, 0)
    frame.text = text

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
    frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "player")

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
        elseif event == "UNIT_ABSORB_AMOUNT_CHANGED" then
            UpdateBar()
        end
    end)
end

local function OnEnable(frame)
    NivUI.IgnorePainBar = frame

    LoadPosition(frame)
    ApplyBarTexture(frame)
    ApplyBarColor(frame)
    ApplyBackground(frame)
    ApplyBorder(frame)
    ApplyFontSettings(frame)
    EnableDragging(frame)
    CheckSpec()

    NivUI:RegisterApplyCallback("barTexture", function() ApplyBarTexture(frame) end)
    NivUI:RegisterApplyCallback("barColor", function() ApplyBarColor(frame) end)
    NivUI:RegisterApplyCallback("background", function() ApplyBackground(frame) end)
    NivUI:RegisterApplyCallback("border", function() ApplyBorder(frame) end)
    NivUI:RegisterApplyCallback("visibility", UpdateVisibility)
    NivUI:RegisterApplyCallback("font", function() ApplyFontSettings(frame) end)
    NivUI:RegisterApplyCallback("locked", function() ApplyLockState(frame) end)
    NivUI:RegisterApplyCallback("position", function() LoadPosition(frame) end)
end

local function OnDisable()
    NivUI.IgnorePainBar = nil
end

NivUI:RegisterClassBar("ignorePain", {
    displayName = "Ignore Pain Bar",
    tabName = "IP",
    sortOrder = 9,
    globalRef = "IgnorePainBar",
    contentHeight = 700,

    defaults = {
        visibility = "combat",
        updateInterval = 0.1,
        width = 394,
        height = 20,
        point = "CENTER",
        x = 0,
        y = -460,
        locked = true,
        foregroundTexture = "Default",
        backgroundTexture = "Default",
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
        borderStyle = "thin",
        borderColor = { r = 0, g = 0, b = 0, a = 1 },
        barColor = { r = 1.0, g = 0.82, b = 0.0, a = 1.0 },
        font = "Friz Quadrata",
        fontSize = 12,
        fontColor = { r = 1, g = 1, b = 1 },
        fontShadow = true,
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
        { type = "color", key = "barColor", label = "Bar Color:", applySetting = "barColor" },
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
            barType = "ignorePain",
            createUI = CreateIgnorePainBarUI,
            registerEvents = RegisterEvents,
            onUpdate = OnUpdate,
            onEnable = OnEnable,
            onDisable = OnDisable,
        })
    end,
})

NivUI.UpdateVisibility = UpdateVisibility
