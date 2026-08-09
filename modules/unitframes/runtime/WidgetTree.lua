local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Runtime = NivUI.UnitFrames.Runtime or {}

local WidgetTree = {}
NivUI.UnitFrames.Runtime.WidgetTree = WidgetTree
--- Creates all enabled widgets for a unit frame based on its style configuration.
--- @param parent Frame The parent frame to attach widgets to
--- @param style table The style configuration table
--- @param unit string The unit ID (e.g., "player", "target")
--- @param options table|nil Optional settings: forPreview strips strata/frameLevel
--- @return table widgets A table mapping widget type names to widget frames
function WidgetTree.CreateWidgets(parent, style, unit, options)
    options = options or {}
    local WF = NivUI.WidgetFactories
    if not WF then return {} end

    local widgets = {}

    for _, widgetType in ipairs(NivUI.UnitFrames.WIDGET_ORDER) do
        if widgetType ~= "frame" then
            local config = style[widgetType]
            if config and config.enabled and WF[widgetType] then
                local widgetConfig = config
                if options.forPreview then
                    widgetConfig = {}
                    for k, v in pairs(config) do
                        if k ~= "strata" and k ~= "frameLevel" then
                            widgetConfig[k] = v
                        end
                    end
                end

                local success, widget = pcall(WF[widgetType], parent, widgetConfig, style, unit, options)
                if success and widget then
                    widgets[widgetType] = widget
                elseif not success then
                    print("NivUI: Error creating", widgetType, "-", widget)
                end
            end
        end
    end

    if style.overlays and NivUI.Overlays and WF.overlay then
        for name, applied in pairs(style.overlays) do
            local config = applied and NivUI.Overlays:Get(name)
            if config then
                local overlayConfig = config
                if options.forPreview then
                    overlayConfig = {}
                    for k, v in pairs(config) do
                        if k ~= "strata" and k ~= "frameLevel" then
                            overlayConfig[k] = v
                        end
                    end
                end

                local success, widget = pcall(WF.overlay, parent, overlayConfig, style, unit, options)
                if success and widget then
                    widget.overlayName = name
                    widgets["overlay:" .. name] = widget
                elseif not success then
                    print("NivUI: Error creating overlay", name, "-", widget)
                end
            end
        end
    end

    return widgets
end

--- Applies anchor positions to all widgets based on style configuration.
--- Widgets anchored to missing/disabled widgets will be hidden.
--- @param parent Frame The parent frame
--- @param widgets table The widget table from CreateWidgets
--- @param style table The style configuration table
function WidgetTree.ApplyAnchors(parent, widgets, style)
    for widgetType, widget in pairs(widgets) do
        -- Transformative overlays retain stale anchor data by design; the resolver
        -- positions their holders, so ApplyAnchors must never apply their anchors
        -- (nor let the anchor-missing Hide fallback fight the resolution pass).
        if not widget.skipAnchor then
            local config = style[widgetType] or widget.config
            local anchor = config and config.anchor
            if anchor then
                widget:ClearAllPoints()

                local anchorTarget
                if anchor.relativeTo == "frame" or anchor.relativeTo == nil then
                    anchorTarget = parent
                else
                    anchorTarget = widgets[anchor.relativeTo]
                    if not anchorTarget then
                        widget:Hide()
                        widget.anchorMissing = true
                    end
                end

                if anchorTarget then
                    widget:SetPoint(anchor.point, anchorTarget, anchor.relativePoint or anchor.point, anchor.x or 0, anchor.y or 0)
                    widget.anchorMissing = nil
                end
            else
                widget:SetPoint("CENTER", parent, "CENTER", 0, 0)
            end
        end
    end
end

function WidgetTree.ClearFrameWidgets(frame)
    if frame.widgets then
        for _, widget in pairs(frame.widgets) do
            if widget.Hide then widget:Hide() end
            if widget.SetParent then widget:SetParent(nil) end
        end
        wipe(frame.widgets)
    end
    if frame.border then
        frame.border:Hide()
        frame.border:SetParent(nil)
        frame.border = nil
    end
end
