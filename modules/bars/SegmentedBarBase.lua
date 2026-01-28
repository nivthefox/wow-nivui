NivUI.SegmentedBarBase = {}

function NivUI.SegmentedBarBase.CreateModule(config)
    local barType = config.barType
    local powerType = config.powerType
    local frameName = config.frameName
    local globalRef = config.globalRef
    local defaultY = config.defaultY or -250
    local checkResourceAvailable = config.checkResourceAvailable
    local supportsPartialFill = config.supportsPartialFill or false

    local dbKey = barType .. "Bar"
    local defaultsKey = barType .. "BarDefaults"

    local lastUpdate = 0
    local hasResource = false
    local inCombat = false

    local function GetSetting(key)
        local db = NivUI.current and NivUI.current[dbKey]
        if db and db[key] ~= nil then
            return db[key]
        end
        return NivUI[defaultsKey][key]
    end

    local function SafeGetPower()
        local ok, power = pcall(UnitPower, "player", powerType)
        if not ok then
            return nil
        end
        return power
    end

    local function SafeGetMaxPower()
        local ok, maxPower = pcall(UnitPowerMax, "player", powerType)
        if not ok then
            return nil
        end
        return maxPower
    end

    local function SafeGetPartialPower()
        if not supportsPartialFill then
            return 0
        end
        local ok, partial = pcall(UnitPartialPower, "player", powerType)
        if not ok then
            return 0
        end
        return partial or 0
    end

    local function SafeIsActive(index, power)
        if power == nil then
            return false
        end
        local ok, result = pcall(function() return index <= power end)
        if not ok then
            return false
        end
        return result
    end

    local UpdateVisibility

    local function ShouldShow()
        local visibility = GetSetting("visibility")

        if visibility == "never" then
            return false
        end

        if not GetSetting("locked") then
            return true
        end
        if not hasResource then
            return false
        end

        if visibility == "always" then
            return true
        end

        return inCombat
    end

    UpdateVisibility = function()
        local frame = NivUI[globalRef]
        if not frame then
            return
        end

        if ShouldShow() then
            frame:Show()
        else
            frame:Hide()
        end
    end

    local function CheckResource()
        hasResource = checkResourceAvailable()
        UpdateVisibility()

        if hasResource and NivUI[globalRef] then
            NivUI[globalRef]:RebuildSegments()
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
        local db = NivUI.current[dbKey] or {}
        local defaults = NivUI[defaultsKey]

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
            local db = NivUI.current[dbKey]
            local point, _, _, x, y = self:GetPoint()
            db.point = point
            db.x = x
            db.y = y
            if NivUI.OnBarMoved then
                NivUI.OnBarMoved()
            end
        end)
    end

    local function CreateSegmentedBarUI()
        local frame = CreateFrame("Frame", frameName, UIParent)
        frame:SetSize(200, 20)
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, defaultY)
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
            local db = NivUI.current[dbKey]
            db.width = frame:GetWidth()
            db.height = frame:GetHeight()
            frame:RebuildSegments()
            if NivUI.OnBarMoved then
                NivUI.OnBarMoved()
            end
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

            local maxPower = SafeGetMaxPower() or 5
            local width = self:GetWidth()
            local height = self:GetHeight()
            local spacing = GetSetting("spacing")

            local totalSpacing = spacing * (maxPower - 1)
            local segmentWidth = (width - totalSpacing) / maxPower

            local emptyColor = GetSetting("emptyColor")
            local filledColor = GetSetting("filledColor")

            for i = 1, maxPower do
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
                    segmentWidth = segmentWidth,
                    xOffset = xOffset,
                }
            end
        end

        if supportsPartialFill then
            function frame:UpdateSegments()
                local power = SafeGetPower()
                local maxPower = SafeGetMaxPower()

                if power == nil or maxPower == nil then
                    for _, seg in ipairs(self.segments) do
                        seg.bar:Hide()
                    end
                    return
                end

                if #self.segments ~= maxPower then
                    self:RebuildSegments()
                end

                local partialPower = SafeGetPartialPower()
                local fillingIndex = power + 1

                for i, seg in ipairs(self.segments) do
                    local isFull = SafeIsActive(i, power)
                    local isFilling = (i == fillingIndex) and (fillingIndex <= maxPower)

                    if isFull then
                        seg.bar:SetWidth(seg.segmentWidth)
                        seg.bar:Show()
                        seg.active = true
                    elseif isFilling and partialPower > 0 then
                        local fillPercent = partialPower / 1000
                        local fillWidth = seg.segmentWidth * fillPercent
                        if fillWidth < 1 then
                            fillWidth = 1
                        end
                        seg.bar:SetWidth(fillWidth)
                        seg.bar:Show()
                        seg.active = false
                    else
                        seg.bar:Hide()
                        seg.active = false
                    end
                end
            end
        else
            function frame:UpdateSegments()
                local power = SafeGetPower()
                local maxPower = SafeGetMaxPower()

                if power == nil or maxPower == nil then
                    for _, seg in ipairs(self.segments) do
                        seg.bar:Hide()
                    end
                    return
                end

                if #self.segments ~= maxPower then
                    self:RebuildSegments()
                end

                for i, seg in ipairs(self.segments) do
                    local shouldBeActive = SafeIsActive(i, power)
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
        end)
    end

    local function OnEnable(frame)
        NivUI[globalRef] = frame

        LoadPosition(frame)
        ApplyBorder(frame)
        EnableDragging(frame)
        CheckResource()
        frame:RebuildSegments()
    end

    local function OnDisable(_frame)
        NivUI[globalRef] = nil
    end

    local module = NivUI.BarBase.CreateModule({
        barType = barType,
        createUI = CreateSegmentedBarUI,
        registerEvents = RegisterEvents,
        onUpdate = OnUpdate,
        onEnable = OnEnable,
        onDisable = OnDisable,
    })

    NivUI[globalRef] = nil
    NivUI[globalRef .. "_UpdateVisibility"] = UpdateVisibility
    NivUI[globalRef .. "_ApplyColors"] = function()
        if NivUI[globalRef] then
            ApplyColors(NivUI[globalRef])
        end
    end
    NivUI[globalRef .. "_ApplyBorder"] = function()
        if NivUI[globalRef] then
            ApplyBorder(NivUI[globalRef])
        end
    end
    NivUI[globalRef .. "_ApplyLockState"] = function()
        if NivUI[globalRef] then
            ApplyLockState(NivUI[globalRef])
        end
    end
    NivUI[globalRef .. "_LoadPosition"] = function()
        if NivUI[globalRef] then
            LoadPosition(NivUI[globalRef])
        end
    end

    return module
end
