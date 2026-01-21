-- NivUI Components: Designer
-- Platynator-style interactive preview for unit frame styles

NivUI = NivUI or {}
NivUI.Designer = {}

local PREVIEW_SCALE = 1.0
local SELECTION_COLOR = { r = 0.2, g = 0.6, b = 1, a = 0.8 }
local SNAP_THRESHOLD = 5

-- Use shared widget factories
local WidgetFactories = NivUI.WidgetFactories

--------------------------------------------------------------------------------
-- Designer Frame
--------------------------------------------------------------------------------

-- Create the designer preview area
function NivUI.Designer:Create(parent)
    local container = CreateFrame("Frame", nil, parent)

    -- Preview container (scaled)
    local preview = CreateFrame("Frame", nil, container)
    preview:SetPoint("CENTER")
    preview:SetScale(PREVIEW_SCALE)
    preview:SetSize(200, 60)  -- Default size, will be updated by BuildPreview

    -- Debug border around preview frame (so we can see where it is)
    preview.debugBorder = CreateFrame("Frame", nil, preview, "BackdropTemplate")
    preview.debugBorder:SetAllPoints()
    preview.debugBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    preview.debugBorder:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)

    -- Background for preview area
    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.9)

    container.preview = preview
    container.widgets = {}
    container.selectedWidget = nil

    -- Selection overlay
    container.selectionOverlay = CreateFrame("Frame", nil, container)
    container.selectionOverlay:SetFrameStrata("DIALOG")
    container.selectionOverlay:Hide()

    local selBorder = container.selectionOverlay:CreateTexture(nil, "OVERLAY")
    selBorder:SetAllPoints()
    selBorder:SetColorTexture(SELECTION_COLOR.r, SELECTION_COLOR.g, SELECTION_COLOR.b, SELECTION_COLOR.a)
    container.selectionOverlay.border = selBorder

    local selInner = container.selectionOverlay:CreateTexture(nil, "OVERLAY", nil, 1)
    selInner:SetPoint("TOPLEFT", 2, -2)
    selInner:SetPoint("BOTTOMRIGHT", -2, 2)
    selInner:SetColorTexture(0, 0, 0, 0)
    container.selectionOverlay.inner = selInner

    container.SelectWidget = function(self, widgetType)
        self.selectedWidget = widgetType
        -- Selection overlay disabled - was obscuring the preview
        self.selectionOverlay:Hide()

        if self.onSelectionChanged then
            self.onSelectionChanged(widgetType)
        end
    end

    return container
end

-- Build preview widgets from a style
function NivUI.Designer:BuildPreview(container, styleName)
    -- Clear existing widgets
    for _, widget in pairs(container.widgets) do
        widget:Hide()
        widget:SetParent(nil)
    end
    wipe(container.widgets)

    local style = NivUI:GetStyleWithDefaults(styleName)
    if not style then
        print("NivUI Designer: No style found for", styleName)
        return
    end

    -- Set preview frame size based on style.frame (with fallback for old styles)
    local frameConfig = style.frame or {}
    local frameWidth = frameConfig.width or style.width or 200
    local frameHeight = frameConfig.height or style.height or 60
    container.preview:SetSize(frameWidth, frameHeight)

    -- Apply frame border
    if frameConfig.showBorder then
        local borderSize = frameConfig.borderSize or 1
        local borderColor = frameConfig.borderColor or { r = 0, g = 0, b = 0, a = 1 }
        container.preview.debugBorder:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = borderSize,
        })
        container.preview.debugBorder:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
        container.preview.debugBorder:Show()
    else
        container.preview.debugBorder:Hide()
    end

    -- Check if WIDGET_ORDER exists
    if not NivUI.UnitFrames or not NivUI.UnitFrames.WIDGET_ORDER then
        print("NivUI Designer: WIDGET_ORDER not found!")
        return
    end

    -- Pass 1: Create all widgets (without positioning)
    local widgetCount = 0
    for _, widgetType in ipairs(NivUI.UnitFrames.WIDGET_ORDER) do
        -- Skip "frame" - it's not a widget, just config for the container
        if widgetType ~= "frame" then
            local config = style[widgetType]
            if config and config.enabled and WidgetFactories[widgetType] then
                local success, widget = pcall(WidgetFactories[widgetType], container.preview, config, style)
                if success and widget then
                    -- Click handler for selection
                    widget:EnableMouse(true)
                    widget:SetScript("OnMouseDown", function()
                        container:SelectWidget(widgetType)
                    end)

                    container.widgets[widgetType] = widget
                    widgetCount = widgetCount + 1
                elseif not success then
                    print("NivUI Designer: Error creating", widgetType, "-", widget)
                end
            end
        end
    end

    -- Pass 2: Apply anchors (now all widgets exist for cross-referencing)
    for widgetType, widget in pairs(container.widgets) do
        local config = style[widgetType]
        local anchor = config and config.anchor
        if anchor then
            widget:ClearAllPoints()

            -- Resolve the anchor target
            local anchorTarget
            if anchor.relativeTo == "frame" or anchor.relativeTo == nil then
                anchorTarget = container.preview
            else
                anchorTarget = container.widgets[anchor.relativeTo]
                -- Fallback to frame if target widget doesn't exist or isn't enabled
                if not anchorTarget then
                    anchorTarget = container.preview
                end
            end

            widget:SetPoint(anchor.point, anchorTarget, anchor.relativePoint or anchor.point, anchor.x or 0, anchor.y or 0)
        else
            widget:SetPoint("CENTER", container.preview, "CENTER", 0, 0)
        end
    end

    if widgetCount == 0 then
        print("NivUI Designer: No widgets created!")
    end
end

-- Refresh preview from live data
function NivUI.Designer:RefreshPreview(container, styleName)
    self:BuildPreview(container, styleName)
    if container.selectedWidget then
        container:SelectWidget(container.selectedWidget)
    end
end
