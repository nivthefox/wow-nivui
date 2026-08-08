local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}

local UnitFrameLifecycle = {}
NivUI.UnitFrames.Lifecycle = UnitFrameLifecycle

local adapters = {}

local function RequestRefresh(adapter)
    if not adapter.isEnabled() then
        return
    end

    adapter.refresh()
end

local function RefreshAll()
    for _, adapter in ipairs(adapters) do
        RequestRefresh(adapter)
    end
end

local function RefreshStyle(data)
    if not data or not data.styleName then
        return
    end

    for _, adapter in ipairs(adapters) do
        if adapter.usesStyle(data.styleName) then
            RequestRefresh(adapter)
        end
    end
end

function UnitFrameLifecycle.Register(adapter)
    if type(adapter) ~= "table" then
        return false
    end
    if type(adapter.isEnabled) ~= "function" then
        return false
    end
    if type(adapter.refresh) ~= "function" then
        return false
    end
    if type(adapter.usesStyle) ~= "function" then
        return false
    end

    adapters[#adapters + 1] = adapter
    return true
end

NivUI:RegisterCallback("CustomFiltersChanged", RefreshAll)
NivUI:RegisterCallback("OverlaysChanged", RefreshAll)
NivUI:RegisterCallback("OverlayModified", RefreshAll)
NivUI:RegisterCallback("StyleChanged", RefreshStyle)
