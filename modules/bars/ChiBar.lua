local SPEC_MONK_WINDWALKER = 269
local MAX_CHI = 6  -- Maximum possible with talents

local ChiBar = CreateFrame("Frame", "NivUIChiBar", UIParent)
ChiBar:SetSize(200, 20)
ChiBar:SetPoint("CENTER", UIParent, "CENTER", 0, -250)
ChiBar:SetResizable(true)
ChiBar:SetResizeBounds(60, 5, 400, 60)
ChiBar:Hide()

local clickBg = ChiBar:CreateTexture(nil, "BACKGROUND", nil, -1)
clickBg:SetAllPoints()
clickBg:SetColorTexture(0, 0, 0, 0)

local segmentContainer = CreateFrame("Frame", nil, ChiBar)
segmentContainer:SetAllPoints()
ChiBar.segmentContainer = segmentContainer

local resizeHandle = CreateFrame("Button", nil, ChiBar)
resizeHandle:SetSize(16, 16)
resizeHandle:SetPoint("BOTTOMRIGHT", ChiBar, "BOTTOMRIGHT", 0, 0)
resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeHandle:Hide()
ChiBar.resizeHandle = resizeHandle

resizeHandle:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        ChiBar:StartSizing("BOTTOMRIGHT")
    end
end)

resizeHandle:SetScript("OnMouseUp", function(self, button)
    ChiBar:StopMovingOrSizing()
    local db = NivUI_DB.chiBar
    db.width = ChiBar:GetWidth()
    db.height = ChiBar:GetHeight()
    ChiBar:RebuildSegments()
    if NivUI.OnBarMoved then NivUI.OnBarMoved() end
end)

local border = CreateFrame("Frame", nil, ChiBar, "BackdropTemplate")
border:SetPoint("TOPLEFT", -1, 1)
border:SetPoint("BOTTOMRIGHT", 1, -1)
border:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
border:SetBackdropBorderColor(0, 0, 0, 1)
ChiBar.border = border

ChiBar.segments = {}

local lastUpdate = 0
local isWindwalker = false
local inCombat = false

local defaults = {
    point = "CENTER",
    x = 0,
    y = -250,
    width = 200,
    height = 20,
    spacing = 2,
    locked = true,
    visibility = "combat",  -- "always", "combat", "never"
    emptyColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 },
    filledColor = { r = 0.0, g = 0.8, b = 0.6, a = 1.0 },  -- Jade green
    borderColor = { r = 0, g = 0, b = 0, a = 1 },
    updateInterval = 0.05,
}

local function GetSetting(key)
    local db = NivUI_DB and NivUI_DB.chiBar
    if db and db[key] ~= nil then
        return db[key]
    end
    return defaults[key]
end

-- Safe UnitPower call (defensive against secret values)
local function SafeGetChi()
    local ok, chi = pcall(UnitPower, "player", Enum.PowerType.Chi)
    if not ok then return nil end
    return chi
end

local function SafeGetMaxChi()
    local ok, maxChi = pcall(UnitPowerMax, "player", Enum.PowerType.Chi)
    if not ok then return nil end
    return maxChi
end

-- Safe comparison (defensive against secret values)
local function SafeIsActive(index, chi)
    if chi == nil then return false end
    local ok, result = pcall(function() return index <= chi end)
    if not ok then return false end
    return result
end

function ChiBar:RebuildSegments()
    for _, seg in ipairs(self.segments) do
        seg.bg:Hide()
        seg.bar:Hide()
    end
    wipe(self.segments)

    local maxChi = SafeGetMaxChi() or 5
    local width = self:GetWidth()
    local height = self:GetHeight()
    local spacing = GetSetting("spacing")

    local totalSpacing = spacing * (maxChi - 1)
    local segmentWidth = (width - totalSpacing) / maxChi

    local emptyColor = GetSetting("emptyColor")
    local filledColor = GetSetting("filledColor")

    for i = 1, maxChi do
        local xOffset = (i - 1) * (segmentWidth + spacing)

        local bg = self.segmentContainer:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", self.segmentContainer, "TOPLEFT", xOffset, 0)
        bg:SetSize(segmentWidth, height)
        bg:SetColorTexture(emptyColor.r, emptyColor.g, emptyColor.b, emptyColor.a or 0.8)

        local bar = self.segmentContainer:CreateTexture(nil, "ARTWORK")
        bar:SetPoint("TOPLEFT", self.segmentContainer, "TOPLEFT", xOffset, 0)
        bar:SetSize(segmentWidth, height)
        bar:SetColorTexture(filledColor.r, filledColor.g, filledColor.b, filledColor.a or 1.0)
        bar:Hide()

        self.segments[i] = {
            bg = bg,
            bar = bar,
            active = false,
        }
    end
end

function ChiBar:UpdateSegments()
    local chi = SafeGetChi()
    local maxChi = SafeGetMaxChi()

    if chi == nil or maxChi == nil then
        for _, seg in ipairs(self.segments) do
            seg.bar:Hide()
        end
        return
    end

    if #self.segments ~= maxChi then
        self:RebuildSegments()
    end

    for i, seg in ipairs(self.segments) do
        local shouldBeActive = SafeIsActive(i, chi)
        if shouldBeActive ~= seg.active then
            seg.active = shouldBeActive
            if shouldBeActive then
                seg.bar:Show()
            else
                seg.bar:Hide()
            end
        end
    end
end

local function ShouldShow()
    local visibility = GetSetting("visibility")

    if visibility == "never" then return false end

    if not GetSetting("locked") then return true end
    if not isWindwalker then return false end

    if visibility == "always" then return true end

    -- "combat" mode: show only in combat (chi doesn't decay like stagger)
    return inCombat
end

local function UpdateVisibility()
    if ShouldShow() then
        ChiBar:Show()
    else
        ChiBar:Hide()
    end
end

local function CheckSpec()
    local _, class = UnitClass("player")
    if class ~= "MONK" then
        isWindwalker = false
        return
    end

    local spec = GetSpecialization()
    isWindwalker = (spec == 3)  -- Windwalker is spec 3
    UpdateVisibility()

    -- Rebuild segments when spec changes (max chi might differ)
    if isWindwalker then
        ChiBar:RebuildSegments()
    end
end

local function OnUpdate(self, elapsed)
    lastUpdate = lastUpdate + elapsed

    local interval = GetSetting("updateInterval")

    if lastUpdate >= interval then
        lastUpdate = 0
        self:UpdateSegments()
    end
end

local function EnableDragging()
    ChiBar:SetMovable(true)
    ChiBar:EnableMouse(true)
    ChiBar:RegisterForDrag("LeftButton")

    ChiBar:SetScript("OnDragStart", function(self)
        if not GetSetting("locked") then
            self:StartMoving()
        end
    end)

    ChiBar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db = NivUI_DB.chiBar
        local point, _, _, x, y = self:GetPoint()
        db.point = point
        db.x = x
        db.y = y
        if NivUI.OnBarMoved then NivUI.OnBarMoved() end
    end)
end

local function LoadPosition()
    local db = NivUI_DB.chiBar or {}

    ChiBar:ClearAllPoints()
    ChiBar:SetPoint(
        db.point or defaults.point,
        UIParent,
        db.point or defaults.point,
        db.x or defaults.x,
        db.y or defaults.y
    )
    ChiBar:SetSize(
        db.width or defaults.width,
        db.height or defaults.height
    )

    if GetSetting("locked") then
        ChiBar.resizeHandle:Hide()
    else
        ChiBar.resizeHandle:Show()
    end
end

local function ApplyColors()
    local emptyColor = GetSetting("emptyColor")
    local filledColor = GetSetting("filledColor")

    for _, seg in ipairs(ChiBar.segments) do
        seg.bg:SetColorTexture(emptyColor.r, emptyColor.g, emptyColor.b, emptyColor.a or 0.8)
        seg.bar:SetColorTexture(filledColor.r, filledColor.g, filledColor.b, filledColor.a or 1.0)
    end
end

local function ApplyBorder()
    local borderColor = GetSetting("borderColor")
    ChiBar.border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
end

local function ApplyLockState()
    local locked = GetSetting("locked")
    if locked then
        ChiBar.resizeHandle:Hide()
    else
        ChiBar.resizeHandle:Show()
        ChiBar:Show()
    end
    UpdateVisibility()
end

local function InitializeDB()
    if not NivUI_DB then NivUI_DB = {} end
    if not NivUI_DB.chiBar then NivUI_DB.chiBar = {} end

    for k, v in pairs(defaults) do
        if NivUI_DB.chiBar[k] == nil then
            if type(v) == "table" then
                NivUI_DB.chiBar[k] = {}
                for k2, v2 in pairs(v) do
                    NivUI_DB.chiBar[k][k2] = v2
                end
            else
                NivUI_DB.chiBar[k] = v
            end
        end
    end
end

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == "NivUI" then
            InitializeDB()
            LoadPosition()
            ApplyBorder()
            EnableDragging()
            CheckSpec()
            ChiBar:RebuildSegments()
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
    elseif event == "UNIT_MAXPOWER" then
        local unit = ...
        if unit == "player" then
            ChiBar:RebuildSegments()
        end
    end
end

ChiBar:RegisterEvent("ADDON_LOADED")
ChiBar:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
ChiBar:RegisterEvent("PLAYER_REGEN_DISABLED")
ChiBar:RegisterEvent("PLAYER_REGEN_ENABLED")
ChiBar:RegisterEvent("PLAYER_ENTERING_WORLD")
ChiBar:RegisterEvent("UNIT_MAXPOWER")
ChiBar:SetScript("OnEvent", OnEvent)
ChiBar:SetScript("OnUpdate", OnUpdate)

NivUI = NivUI or {}
NivUI.ChiBar = ChiBar
NivUI.ChiBar.defaults = defaults
NivUI.ChiBar.UpdateVisibility = UpdateVisibility
NivUI.ChiBar.ApplyColors = ApplyColors
NivUI.ChiBar.ApplyBorder = ApplyBorder
NivUI.ChiBar.ApplyLockState = ApplyLockState
NivUI.ChiBar.LoadPosition = LoadPosition
