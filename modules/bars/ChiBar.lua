local lastUpdate = 0
local isWindwalker = false
local inCombat = false

local function GetSetting(key)
    local db = NivUI_DB and NivUI_DB.chiBar
    if db and db[key] ~= nil then
        return db[key]
    end
    return NivUI.chiBarDefaults[key]
end

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

local function SafeIsActive(index, chi)
    if chi == nil then return false end
    local ok, result = pcall(function() return index <= chi end)
    if not ok then return false end
    return result
end

local UpdateVisibility

local function ShouldShow()
    local visibility = GetSetting("visibility")

    if visibility == "never" then return false end

    if not GetSetting("locked") then return true end
    if not isWindwalker then return false end

    if visibility == "always" then return true end

    return inCombat
end

UpdateVisibility = function()
    local frame = NivUI.ChiBar
    if not frame then return end

    if ShouldShow() then
        frame:Show()
    else
        frame:Hide()
    end
end

local function CheckSpec()
    local _, class = UnitClass("player")
    if class ~= "MONK" then
        isWindwalker = false
        return
    end

    local spec = GetSpecialization()
    isWindwalker = (spec == 3)
    UpdateVisibility()

    if isWindwalker and NivUI.ChiBar then
        NivUI.ChiBar:RebuildSegments()
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

local function LoadPosition(frame)
    local db = NivUI_DB.chiBar or {}
    local defaults = NivUI.chiBarDefaults

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

local function ApplyColors(frame)
    local emptyColor = GetSetting("emptyColor")
    local filledColor = GetSetting("filledColor")

    for _, seg in ipairs(frame.segments) do
        seg.bg:SetColorTexture(emptyColor.r, emptyColor.g, emptyColor.b, emptyColor.a or 0.8)
        seg.bar:SetColorTexture(filledColor.r, filledColor.g, filledColor.b, filledColor.a or 1.0)
    end
end

local function ApplyBorder(frame)
    local borderColor = GetSetting("borderColor")
    frame.border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
end

local function ApplyLockState(frame)
    local locked = GetSetting("locked")
    if locked then
        frame.resizeHandle:Hide()
    else
        frame.resizeHandle:Show()
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
        local db = NivUI_DB.chiBar
        local point, _, _, x, y = self:GetPoint()
        db.point = point
        db.x = x
        db.y = y
        if NivUI.OnBarMoved then NivUI.OnBarMoved() end
    end)
end

local function CreateChiBarUI()
    local frame = CreateFrame("Frame", "NivUIChiBar", UIParent)
    frame:SetSize(200, 20)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -250)
    frame:SetResizable(true)
    frame:SetResizeBounds(60, 5, 400, 60)
    frame:Hide()

    local clickBg = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    clickBg:SetAllPoints()
    clickBg:SetColorTexture(0, 0, 0, 0)

    local segmentContainer = CreateFrame("Frame", nil, frame)
    segmentContainer:SetAllPoints()
    frame.segmentContainer = segmentContainer

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

    resizeHandle:SetScript("OnMouseUp", function(self, _button)
        frame:StopMovingOrSizing()
        local db = NivUI_DB.chiBar
        db.width = frame:GetWidth()
        db.height = frame:GetHeight()
        frame:RebuildSegments()
        if NivUI.OnBarMoved then NivUI.OnBarMoved() end
    end)

    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    border:SetBackdropBorderColor(0, 0, 0, 1)
    frame.border = border

    frame.segments = {}

    function frame:RebuildSegments()
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

    function frame:UpdateSegments()
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

    return frame
end

local function RegisterEvents(frame)
    frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UNIT_MAXPOWER")

    frame:SetScript("OnEvent", function(self, event, ...)
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
        elseif event == "UNIT_MAXPOWER" then
            local unit = ...
            if unit == "player" then
                self:RebuildSegments()
            end
        end
    end)
end

local function OnEnable(frame)
    NivUI.ChiBar = frame

    LoadPosition(frame)
    ApplyBorder(frame)
    EnableDragging(frame)
    CheckSpec()
    frame:RebuildSegments()
end

local function OnDisable(_frame)
    NivUI.ChiBar = nil
end

local ChiBarModule = NivUI.BarBase.CreateModule({
    barType = "chi",
    createUI = CreateChiBarUI,
    registerEvents = RegisterEvents,
    onUpdate = OnUpdate,
    onEnable = OnEnable,
    onDisable = OnDisable,
})

NivUI.ChiBarModule = ChiBarModule
NivUI.ChiBar = nil
NivUI.ChiBar_UpdateVisibility = UpdateVisibility
NivUI.ChiBar_ApplyColors = function() if NivUI.ChiBar then ApplyColors(NivUI.ChiBar) end end
NivUI.ChiBar_ApplyBorder = function() if NivUI.ChiBar then ApplyBorder(NivUI.ChiBar) end end
NivUI.ChiBar_ApplyLockState = function() if NivUI.ChiBar then ApplyLockState(NivUI.ChiBar) end end
NivUI.ChiBar_LoadPosition = function() if NivUI.ChiBar then LoadPosition(NivUI.ChiBar) end end
