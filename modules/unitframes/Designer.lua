NivUI = NivUI or {}
NivUI.Designer = {}

local PREVIEW_SCALE = 1.0
local SELECTION_COLOR = { r = 0.2, g = 0.6, b = 1, a = 0.8 }

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

    local Base = NivUI.UnitFrames.Base
    if not Base then
        print("NivUI Designer: UnitFrameBase not loaded!")
        return
    end

    container.widgets = Base.CreateWidgets(container.preview, style, nil, { forPreview = true })

    -- Add mouse interactivity for selection
    for widgetType, widget in pairs(container.widgets) do
        widget:EnableMouse(true)
        widget:SetScript("OnMouseDown", function()
            container:SelectWidget(widgetType)
        end)
    end

    Base.ApplyAnchors(container.preview, container.widgets, style)
end

function NivUI.Designer:RefreshPreview(container, styleName)
    self:BuildPreview(container, styleName)
    if container.selectedWidget then
        container:SelectWidget(container.selectedWidget)
    end
end
