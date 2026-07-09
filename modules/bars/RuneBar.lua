local NUM_RUNES = 6

local lastUpdate = 0
local isDeathKnight = false
local inCombat = false

local function GetSetting(key)
    local db = NivUI.current and NivUI.current.runeBar
    if db and db[key] ~= nil then
        return db[key]
    end
    return NivUI.runeBarDefaults[key]
end

local UpdateVisibility
local UpdateRunes

local function ShouldShow()
    if NivUI.EditMode and NivUI.EditMode:IsActive() then
        return true
    end

    local visibility = GetSetting("visibility")

    if visibility == "never" then
        return false
    end

    if not isDeathKnight then
        return false
    end

    if visibility == "always" then
        return true
    end

    return inCombat
end

UpdateVisibility = function()
    local frame = NivUI.RuneBar
    if not frame then
        return
    end

    if ShouldShow() then
        frame:Show()
    else
        frame:Hide()
    end
end

UpdateRunes = function()
    local frame = NivUI.RuneBar
    if not frame then
        return
    end

    local emptyColor = GetSetting("emptyColor")
    local filledColor = GetSetting("filledColor")
    local now = GetTime()

    for i = 1, NUM_RUNES do
        local seg = frame.segments[i]
        if seg then
            local start, duration, runeReady = GetRuneCooldown(i)

            if runeReady then
                seg.bar:SetWidth(seg.segmentWidth)
                seg.bar:Show()
                seg.bar:SetColorTexture(filledColor.r, filledColor.g, filledColor.b, filledColor.a or 1.0)
            elseif start and duration and duration > 0 then
                local elapsed = now - start
                local progress = elapsed / duration
                if progress < 0 then progress = 0 end
                if progress > 1 then progress = 1 end

                local fillWidth = seg.segmentWidth * progress
                if fillWidth < 1 then
                    fillWidth = 1
                end

                seg.bar:SetWidth(fillWidth)
                seg.bar:Show()
                seg.bar:SetColorTexture(filledColor.r, filledColor.g, filledColor.b, (filledColor.a or 1.0) * 0.6)
            else
                seg.bar:Hide()
            end

            seg.bg:SetColorTexture(emptyColor.r, emptyColor.g, emptyColor.b, emptyColor.a or 0.8)
        end
    end

    UpdateVisibility()
end

local function CheckClass()
    local _, class = UnitClass("player")
    isDeathKnight = (class == "DEATHKNIGHT")
    UpdateVisibility()

    if isDeathKnight and NivUI.RuneBar then
        NivUI.RuneBar:RebuildSegments()
    end
end

local function OnUpdate(self, elapsed)
    lastUpdate = lastUpdate + elapsed

    local interval = GetSetting("updateInterval")

    if lastUpdate >= interval then
        lastUpdate = 0
        UpdateRunes()
    end
end

local function LoadPosition(frame)
    local db = NivUI.current.runeBar or {}
    local defaults = NivUI.runeBarDefaults

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

local function CreateRuneBarUI()
    local frame = CreateFrame("Frame", "NivUIRuneBar", UIParent)
    frame:SetSize(240, 20)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, -430)
    frame:Hide()

    local segmentContainer = CreateFrame("Frame", nil, frame)
    segmentContainer:SetAllPoints()
    frame.segmentContainer = segmentContainer

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

        local width = self:GetWidth()
        local height = self:GetHeight()
        local spacing = GetSetting("spacing")

        local totalSpacing = spacing * (NUM_RUNES - 1)
        local segmentWidth = (width - totalSpacing) / NUM_RUNES

        local emptyColor = GetSetting("emptyColor")
        local filledColor = GetSetting("filledColor")

        for i = 1, NUM_RUNES do
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
                segmentWidth = segmentWidth,
                xOffset = xOffset,
            }
        end
    end

    return frame
end

local function RegisterEvents(frame)
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("RUNE_POWER_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")

    frame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_ENTERING_WORLD" then
            CheckClass()
            inCombat = UnitAffectingCombat("player")
            UpdateVisibility()
        elseif event == "RUNE_POWER_UPDATE" then
            UpdateRunes()
        elseif event == "PLAYER_REGEN_DISABLED" then
            inCombat = true
            UpdateVisibility()
        elseif event == "PLAYER_REGEN_ENABLED" then
            inCombat = false
            UpdateVisibility()
        end
    end)
end

local function OnEnable(frame)
    NivUI.RuneBar = frame

    LoadPosition(frame)
    ApplyBorder(frame)
    CheckClass()
    frame:RebuildSegments()
end

local function OnDisable(_frame)
    NivUI.RuneBar = nil
end

local RuneBarModule = NivUI.BarBase.CreateModule({
    barType = "rune",
    createUI = CreateRuneBarUI,
    registerEvents = RegisterEvents,
    onUpdate = OnUpdate,
    onEnable = OnEnable,
    onDisable = OnDisable,
})

NivUI.RuneBarModule = RuneBarModule
NivUI.RuneBar_UpdateVisibility = UpdateVisibility
NivUI.RuneBar_ApplyColors = function()
    if NivUI.RuneBar then
        ApplyColors(NivUI.RuneBar)
    end
end
NivUI.RuneBar_ApplyBorder = function()
    if NivUI.RuneBar then
        ApplyBorder(NivUI.RuneBar)
    end
end
NivUI.RuneBar_LoadPosition = function()
    if NivUI.RuneBar then
        LoadPosition(NivUI.RuneBar)
    end
end
NivUI.RuneBar_RebuildSegments = function()
    if NivUI.RuneBar then
        NivUI.RuneBar:RebuildSegments()
    end
end

NivUI:RegisterClassBar("rune", {
    displayName = "Rune Bar",
    tabName = "Runes",
    sortOrder = 8,
    globalRef = "RuneBar",

    defaults = {
        point = "CENTER",
        x = 0,
        y = -430,
        width = 240,
        height = 20,
        spacing = 2,
        visibility = "combat",
        emptyColor = { r = 0.2, g = 0.2, b = 0.2, a = 0.8 },
        filledColor = { r = 0.77, g = 0.12, b = 0.23, a = 1.0 },
        borderColor = { r = 0, g = 0, b = 0, a = 1 },
        updateInterval = 0.05,
    },

    configSections = {
        { type = "enable" },
        { type = "header", text = "General" },
        { type = "visibility" },
        { type = "header", text = "Appearance" },
        { type = "spacingSlider" },
        { type = "emptyColor" },
        { type = "filledColor" },
        { type = "borderColor" },
        { type = "header", text = "Position" },
        { type = "widthSlider", min = 120, max = 480 },
        { type = "heightSlider" },
        { type = "intervalSlider" },
    },

    createModule = function()
        return RuneBarModule
    end,
})
