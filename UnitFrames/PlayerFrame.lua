-- NivUI Unit Frames: Player Frame
-- Runtime player unit frame that replaces Blizzard's PlayerFrame

NivUI = NivUI or {}
NivUI.UnitFrames = NivUI.UnitFrames or {}

local PlayerFrameModule = {}
NivUI.UnitFrames.PlayerFrame = PlayerFrameModule

-- State
local customFrame = nil
local blizzardHidden = false
local pendingHide = false
local pendingRestore = false

--------------------------------------------------------------------------------
-- Blizzard Frame Management
--------------------------------------------------------------------------------

local function HideRegions(frame)
    if not frame then return end
    local regions = { frame:GetRegions() }
    for _, region in ipairs(regions) do
        if region then
            region:SetAlpha(0)
            region:Hide()
        end
    end
end

local function KillVisual(frame)
    if not frame then return end
    if frame.UnregisterAllEvents then frame:UnregisterAllEvents() end
    if frame.EnableMouse then frame:EnableMouse(false) end
    if frame.Hide then frame:Hide() end
    if frame.SetScript then
        frame:SetScript("OnShow", function(self) self:Hide() end)
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
    end
    if frame.SetAlpha then frame:SetAlpha(0) end
end

local function SoftHideBlizzardPlayerFrame()
    if not PlayerFrame then return end

    -- Don't touch protected UI while in combat; retry once we're out.
    if InCombatLockdown and InCombatLockdown() then
        pendingHide = true
        return
    end

    pendingHide = false

    -- Keep PlayerFrame alive as an anchor parent for third-party addons,
    -- but stop Blizzard logic + remove Blizzard visuals.
    if PlayerFrame.UnregisterAllEvents then
        PlayerFrame:UnregisterAllEvents()
    end
    if PlayerFrame.EnableMouse then
        PlayerFrame:EnableMouse(false)
    end
    if PlayerFrame.SetMouseClickEnabled then
        PlayerFrame:SetMouseClickEnabled(false)
    end
    if PlayerFrame.SetMouseMotionEnabled then
        PlayerFrame:SetMouseMotionEnabled(false)
    end

    -- Ensure the (now invisible) PlayerFrame cannot ever be a mouseover/click target.
    if PlayerFrame.SetHitRectInsets then
        PlayerFrame:SetHitRectInsets(10000, 10000, 10000, 10000)
    end

    -- Strip any regions on the root itself.
    HideRegions(PlayerFrame)

    -- Kill the known Blizzard visual containers on the PlayerFrame.
    KillVisual(PlayerFrame.PlayerFrameContainer)
    KillVisual(PlayerFrame.PlayerFrameContent)
    KillVisual(PlayerFrame.healthbar)
    KillVisual(PlayerFrame.manabar)
    KillVisual(PlayerFrame.powerBarAlt)

    -- Kill child frames that start with "PlayerFrame"
    local children = { PlayerFrame:GetChildren() }
    for _, child in ipairs(children) do
        local name = child:GetName()
        if name and name:find("^PlayerFrame") then
            KillVisual(child)
        end
    end

    blizzardHidden = true

    -- Hook OnShow to re-hide if something tries to show it
    if not PlayerFrame.NivUI_SoftHideHooked then
        PlayerFrame.NivUI_SoftHideHooked = true
        PlayerFrame:HookScript("OnShow", function()
            if blizzardHidden then
                SoftHideBlizzardPlayerFrame()
            end
        end)
    end
end

local function RestoreBlizzardPlayerFrame()
    if not PlayerFrame then return end

    -- Don't touch protected UI while in combat; retry once we're out.
    if InCombatLockdown and InCombatLockdown() then
        pendingRestore = true
        return
    end

    pendingRestore = false
    blizzardHidden = false

    -- Re-enable mouse interaction
    if PlayerFrame.EnableMouse then
        PlayerFrame:EnableMouse(true)
    end
    if PlayerFrame.SetMouseClickEnabled then
        PlayerFrame:SetMouseClickEnabled(true)
    end
    if PlayerFrame.SetMouseMotionEnabled then
        PlayerFrame:SetMouseMotionEnabled(true)
    end
    if PlayerFrame.SetHitRectInsets then
        PlayerFrame:SetHitRectInsets(0, 0, 0, 0)
    end

    -- Restore alpha on regions
    local regions = { PlayerFrame:GetRegions() }
    for _, region in ipairs(regions) do
        if region and region.SetAlpha then
            region:SetAlpha(1)
            region:Show()
        end
    end

    -- Show visual containers
    local function RestoreVisual(frame)
        if not frame then return end
        if frame.SetAlpha then frame:SetAlpha(1) end
        if frame.Show then frame:Show() end
        if frame.SetScript then
            frame:SetScript("OnShow", nil)
        end
    end

    RestoreVisual(PlayerFrame.PlayerFrameContainer)
    RestoreVisual(PlayerFrame.PlayerFrameContent)
    RestoreVisual(PlayerFrame.healthbar)
    RestoreVisual(PlayerFrame.manabar)

    -- Re-register events by calling Blizzard's initialization
    -- PlayerFrame_ToPlayerArt re-initializes the player frame
    if PlayerFrame_ToPlayerArt then
        PlayerFrame_ToPlayerArt(PlayerFrame)
    end

    -- Show children
    local children = { PlayerFrame:GetChildren() }
    for _, child in ipairs(children) do
        local name = child:GetName()
        if name and name:find("^PlayerFrame") then
            RestoreVisual(child)
        end
    end
end

--------------------------------------------------------------------------------
-- Custom Frame Creation
--------------------------------------------------------------------------------

local function DestroyCustomFrame()
    if customFrame then
        customFrame:Hide()
        customFrame:SetParent(nil)
        customFrame = nil
    end
end

local function BuildCustomFrame(styleName)
    DestroyCustomFrame()

    local style = NivUI:GetStyleWithDefaults(styleName)
    if not style then
        print("NivUI PlayerFrame: No style found for", styleName)
        return
    end

    local WF = NivUI.WidgetFactories
    if not WF then
        print("NivUI PlayerFrame: Widget factories not loaded")
        return
    end

    -- Create container frame
    local frameConfig = style.frame or {}
    local frameWidth = frameConfig.width or 200
    local frameHeight = frameConfig.height or 60

    customFrame = CreateFrame("Frame", "NivUI_PlayerFrame", UIParent)
    customFrame:SetSize(frameWidth, frameHeight)

    -- Anchor to Blizzard PlayerFrame's position
    customFrame:SetPoint("TOPLEFT", PlayerFrame, "TOPLEFT", 0, 0)

    -- Apply frame border if configured
    if frameConfig.showBorder then
        customFrame.border = CreateFrame("Frame", nil, customFrame, "BackdropTemplate")
        customFrame.border:SetAllPoints()
        local borderSize = frameConfig.borderSize or 1
        local borderColor = frameConfig.borderColor or { r = 0, g = 0, b = 0, a = 1 }
        customFrame.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = borderSize,
        })
        customFrame.border:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
    end

    -- Store widgets for later reference
    customFrame.widgets = {}

    -- Pass 1: Create all enabled widgets
    for _, widgetType in ipairs(NivUI.UnitFrames.WIDGET_ORDER) do
        if widgetType ~= "frame" then
            local config = style[widgetType]
            if config and config.enabled and WF[widgetType] then
                local success, widget = pcall(WF[widgetType], customFrame, config, style, "player")
                if success and widget then
                    customFrame.widgets[widgetType] = widget
                elseif not success then
                    print("NivUI PlayerFrame: Error creating", widgetType, "-", widget)
                end
            end
        end
    end

    -- Pass 2: Apply anchors
    for widgetType, widget in pairs(customFrame.widgets) do
        local config = style[widgetType]
        local anchor = config and config.anchor
        if anchor then
            widget:ClearAllPoints()

            local anchorTarget
            if anchor.relativeTo == "frame" or anchor.relativeTo == nil then
                anchorTarget = customFrame
            else
                anchorTarget = customFrame.widgets[anchor.relativeTo]
                if not anchorTarget then
                    anchorTarget = customFrame
                end
            end

            widget:SetPoint(anchor.point, anchorTarget, anchor.relativePoint or anchor.point, anchor.x or 0, anchor.y or 0)
        else
            widget:SetPoint("CENTER", customFrame, "CENTER", 0, 0)
        end
    end

    customFrame:Show()
end

--------------------------------------------------------------------------------
-- Enable/Disable Logic
--------------------------------------------------------------------------------

local function EnablePlayerFrame()
    local styleName = NivUI:GetAssignment("player")
    BuildCustomFrame(styleName)
    SoftHideBlizzardPlayerFrame()
end

local function DisablePlayerFrame()
    DestroyCustomFrame()
    RestoreBlizzardPlayerFrame()
end

local function RefreshPlayerFrame()
    if NivUI:IsFrameEnabled("player") then
        EnablePlayerFrame()
    end
end

--------------------------------------------------------------------------------
-- Event Handling
--------------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Check if player frame should be enabled on login
        if NivUI:IsFrameEnabled("player") then
            EnablePlayerFrame()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Handle pending operations after combat
        if pendingHide then
            SoftHideBlizzardPlayerFrame()
        end
        if pendingRestore then
            RestoreBlizzardPlayerFrame()
        end
    end
end)

-- Listen for enabled state changes
NivUI:RegisterCallback("FrameEnabledChanged", function(data)
    if data.frameType == "player" then
        if data.enabled then
            EnablePlayerFrame()
        else
            DisablePlayerFrame()
        end
    end
end)

-- Listen for style assignment changes
NivUI:RegisterCallback("AssignmentChanged", function(data)
    if data.frameType == "player" and NivUI:IsFrameEnabled("player") then
        RefreshPlayerFrame()
    end
end)

-- Listen for style changes (in case the assigned style is modified)
NivUI:RegisterCallback("StyleChanged", function(data)
    if NivUI:IsFrameEnabled("player") then
        local currentStyle = NivUI:GetAssignment("player")
        if data.styleName == currentStyle then
            RefreshPlayerFrame()
        end
    end
end)
