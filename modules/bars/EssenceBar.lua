local EssenceBar = CreateFrame("Frame", "NivUIEssenceBar", UIParent)
EssenceBar:SetSize(200, 20)
EssenceBar:SetPoint("CENTER", UIParent, "CENTER", 0, -280)
EssenceBar:SetResizable(true)
EssenceBar:SetResizeBounds(60, 5, 400, 60)
EssenceBar:Hide()

local clickBg = EssenceBar:CreateTexture(nil, "BACKGROUND", nil, -1)
clickBg:SetAllPoints()
clickBg:SetColorTexture(0, 0, 0, 0)

local segmentContainer = CreateFrame("Frame", nil, EssenceBar)
segmentContainer:SetAllPoints()
EssenceBar.segmentContainer = segmentContainer

local resizeHandle = CreateFrame("Button", nil, EssenceBar)
resizeHandle:SetSize(16, 16)
resizeHandle:SetPoint("BOTTOMRIGHT", EssenceBar, "BOTTOMRIGHT", 0, 0)
resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeHandle:Hide()
EssenceBar.resizeHandle = resizeHandle

resizeHandle:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        EssenceBar:StartSizing("BOTTOMRIGHT")
    end
end)

resizeHandle:SetScript("OnMouseUp", function(self, _button)
    EssenceBar:StopMovingOrSizing()
    local db = NivUI_DB.essenceBar
    db.width = EssenceBar:GetWidth()
    db.height = EssenceBar:GetHeight()
    EssenceBar:RebuildSegments()
    if NivUI.OnBarMoved then NivUI.OnBarMoved() end
end)

local border = CreateFrame("Frame", nil, EssenceBar, "BackdropTemplate")
border:SetPoint("TOPLEFT", -1, 1)
border:SetPoint("BOTTOMRIGHT", 1, -1)
border:SetBackdrop({
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
})
border:SetBackdropBorderColor(0, 0, 0, 1)
EssenceBar.border = border

EssenceBar.segments = {}

local lastUpdate = 0
local hasEssence = false
local inCombat = false

local defaults = {
    point = "CENTER",
    x = 0,
    y = -280,
    width = 200,
    height = 20,
    spacing = 2,
    locked = true,
    visibility = "combat",
    emptyColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 },
    filledColor = { r = 0.15, g = 0.75, b = 0.85, a = 1.0 },  -- Teal/cyan
    borderColor = { r = 0, g = 0, b = 0, a = 1 },
    updateInterval = 0.05,
    useBlizzardTexture = false,
}

local function GetSetting(key)
    local db = NivUI_DB and NivUI_DB.essenceBar
    if db and db[key] ~= nil then
        return db[key]
    end
    return defaults[key]
end

local function SafeGetEssence()
    local ok, essence = pcall(UnitPower, "player", Enum.PowerType.Essence)
    if not ok then return nil end
    return essence
end

local function SafeGetMaxEssence()
    local ok, maxEssence = pcall(UnitPowerMax, "player", Enum.PowerType.Essence)
    if not ok then return nil end
    return maxEssence
end

local function SafeIsActive(index, essence)
    if essence == nil then return false end
    local ok, result = pcall(function() return index <= essence end)
    if not ok then return false end
    return result
end

function EssenceBar:RebuildSegments()
    for _, seg in ipairs(self.segments) do
        seg.bg:Hide()
        seg.bar:Hide()
    end
    wipe(self.segments)

    local maxEssence = SafeGetMaxEssence() or 5
    local width = self:GetWidth()
    local height = self:GetHeight()
    local spacing = GetSetting("spacing")
    local useBlizzard = GetSetting("useBlizzardTexture")

    local totalSpacing = spacing * (maxEssence - 1)
    local segmentWidth = (width - totalSpacing) / maxEssence

    local emptyColor = GetSetting("emptyColor")
    local filledColor = GetSetting("filledColor")

    for i = 1, maxEssence do
        local xOffset = (i - 1) * (segmentWidth + spacing)

        local bg = self.segmentContainer:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", self.segmentContainer, "TOPLEFT", xOffset, 0)
        bg:SetSize(segmentWidth, height)

        local bar = self.segmentContainer:CreateTexture(nil, "ARTWORK")
        bar:SetPoint("TOPLEFT", self.segmentContainer, "TOPLEFT", xOffset, 0)
        bar:SetSize(segmentWidth, height)
        bar:Hide()

        if useBlizzard then
            bg:SetAtlas("UF-Essence-BG")
            bar:SetAtlas("UF-Essence-Icon-Active")
        else
            bg:SetColorTexture(emptyColor.r, emptyColor.g, emptyColor.b, emptyColor.a or 0.8)
            bar:SetColorTexture(filledColor.r, filledColor.g, filledColor.b, filledColor.a or 1.0)
        end

        self.segments[i] = {
            bg = bg,
            bar = bar,
            active = false,
        }
    end
end

function EssenceBar:UpdateSegments()
    local essence = SafeGetEssence()
    local maxEssence = SafeGetMaxEssence()

    if essence == nil or maxEssence == nil then
        for _, seg in ipairs(self.segments) do
            seg.bar:Hide()
        end
        return
    end

    if #self.segments ~= maxEssence then
        self:RebuildSegments()
    end

    for i, seg in ipairs(self.segments) do
        local shouldBeActive = SafeIsActive(i, essence)
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
    if not hasEssence then return false end

    if visibility == "always" then return true end

    return inCombat
end

local function UpdateVisibility()
    if ShouldShow() then
        EssenceBar:Show()
    else
        EssenceBar:Hide()
    end
end

local function CheckResource()
    local maxEssence = SafeGetMaxEssence()
    hasEssence = maxEssence and maxEssence > 0

    UpdateVisibility()

    if hasEssence then
        EssenceBar:RebuildSegments()
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
    EssenceBar:SetMovable(true)
    EssenceBar:EnableMouse(true)
    EssenceBar:RegisterForDrag("LeftButton")

    EssenceBar:SetScript("OnDragStart", function(self)
        if not GetSetting("locked") then
            self:StartMoving()
        end
    end)

    EssenceBar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local db = NivUI_DB.essenceBar
        local point, _, _, x, y = self:GetPoint()
        db.point = point
        db.x = x
        db.y = y
        if NivUI.OnBarMoved then NivUI.OnBarMoved() end
    end)
end

local function LoadPosition()
    local db = NivUI_DB.essenceBar or {}

    EssenceBar:ClearAllPoints()
    EssenceBar:SetPoint(
        db.point or defaults.point,
        UIParent,
        db.point or defaults.point,
        db.x or defaults.x,
        db.y or defaults.y
    )
    EssenceBar:SetSize(
        db.width or defaults.width,
        db.height or defaults.height
    )

    if GetSetting("locked") then
        EssenceBar.resizeHandle:Hide()
    else
        EssenceBar.resizeHandle:Show()
    end
end

local function ApplyColors()
    if GetSetting("useBlizzardTexture") then
        return
    end

    local emptyColor = GetSetting("emptyColor")
    local filledColor = GetSetting("filledColor")

    for _, seg in ipairs(EssenceBar.segments) do
        seg.bg:SetColorTexture(emptyColor.r, emptyColor.g, emptyColor.b, emptyColor.a or 0.8)
        seg.bar:SetColorTexture(filledColor.r, filledColor.g, filledColor.b, filledColor.a or 1.0)
    end
end

local function ApplyBorder()
    local borderColor = GetSetting("borderColor")
    EssenceBar.border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
end

local function ApplyLockState()
    local locked = GetSetting("locked")
    if locked then
        EssenceBar.resizeHandle:Hide()
    else
        EssenceBar.resizeHandle:Show()
        EssenceBar:Show()
    end
    UpdateVisibility()
end

local function InitializeDB()
    if not NivUI_DB then NivUI_DB = {} end
    if not NivUI_DB.essenceBar then NivUI_DB.essenceBar = {} end

    for k, v in pairs(defaults) do
        if NivUI_DB.essenceBar[k] == nil then
            if type(v) == "table" then
                NivUI_DB.essenceBar[k] = {}
                for k2, v2 in pairs(v) do
                    NivUI_DB.essenceBar[k][k2] = v2
                end
            else
                NivUI_DB.essenceBar[k] = v
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
            CheckResource()
            EssenceBar:RebuildSegments()
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        CheckResource()
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        UpdateVisibility()
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        UpdateVisibility()
    elseif event == "PLAYER_ENTERING_WORLD" then
        CheckResource()
        inCombat = UnitAffectingCombat("player")
        UpdateVisibility()
    elseif event == "UNIT_MAXPOWER" then
        local unit = ...
        if unit == "player" then
            CheckResource()
        end
    end
end

EssenceBar:RegisterEvent("ADDON_LOADED")
EssenceBar:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
EssenceBar:RegisterEvent("PLAYER_REGEN_DISABLED")
EssenceBar:RegisterEvent("PLAYER_REGEN_ENABLED")
EssenceBar:RegisterEvent("PLAYER_ENTERING_WORLD")
EssenceBar:RegisterEvent("UNIT_MAXPOWER")
EssenceBar:SetScript("OnEvent", OnEvent)
EssenceBar:SetScript("OnUpdate", OnUpdate)

NivUI = NivUI or {}
NivUI.EssenceBar = EssenceBar
NivUI.EssenceBar.defaults = defaults
NivUI.EssenceBar.UpdateVisibility = UpdateVisibility
NivUI.EssenceBar.ApplyColors = ApplyColors
NivUI.EssenceBar.ApplyBorder = ApplyBorder
NivUI.EssenceBar.ApplyLockState = ApplyLockState
NivUI.EssenceBar.LoadPosition = LoadPosition
