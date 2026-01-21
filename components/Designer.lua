NivUI = NivUI or {}
NivUI.Designer = {}

local PREVIEW_SCALE = 1.0
local SELECTION_COLOR = { r = 0.2, g = 0.6, b = 1, a = 0.8 }
local WidgetFactories = NivUI.WidgetFactories

function NivUI.Designer:Create(parent)
    local container = CreateFrame("Frame", nil, parent)

    local preview = CreateFrame("Frame", nil, container)
    preview:SetPoint("CENTER")
    preview:SetScale(PREVIEW_SCALE)
    preview:SetSize(200, 60)

    preview.debugBorder = CreateFrame("Frame", nil, preview, "BackdropTemplate")
    preview.debugBorder:SetAllPoints()
    preview.debugBorder:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    preview.debugBorder:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)

    local bg = container:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.9)

    container.preview = preview
    container.widgets = {}
    container.selectedWidget = nil

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
        self.selectionOverlay:Hide()

        if self.onSelectionChanged then
            self.onSelectionChanged(widgetType)
        end
    end

    return container
end

function NivUI.Designer:BuildPreview(container, styleName)
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

    local frameConfig = style.frame or {}
    local frameWidth = frameConfig.width or style.width or 200
    local frameHeight = frameConfig.height or style.height or 60
    container.preview:SetSize(frameWidth, frameHeight)

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

    if not NivUI.UnitFrames or not NivUI.UnitFrames.WIDGET_ORDER then
        print("NivUI Designer: WIDGET_ORDER not found!")
        return
    end

    local widgetCount = 0
    for _, widgetType in ipairs(NivUI.UnitFrames.WIDGET_ORDER) do
        if widgetType ~= "frame" then
            local config = style[widgetType]
            if config and config.enabled and WidgetFactories[widgetType] then
                local success, widget = pcall(WidgetFactories[widgetType], container.preview, config, style)
                if success and widget then
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

    for widgetType, widget in pairs(container.widgets) do
        local config = style[widgetType]
        local anchor = config and config.anchor
        if anchor then
            widget:ClearAllPoints()

            local anchorTarget
            if anchor.relativeTo == "frame" or anchor.relativeTo == nil then
                anchorTarget = container.preview
            else
                anchorTarget = container.widgets[anchor.relativeTo]
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

function NivUI.Designer:RefreshPreview(container, styleName)
    self:BuildPreview(container, styleName)
    if container.selectedWidget then
        container:SelectWidget(container.selectedWidget)
    end
end
