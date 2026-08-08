local _, NivUI = ...

local DEFAULT_FALLBACK_WIDTH = 600
local DEFAULT_ROW_HEIGHT = 24

local TabLayout = {}
NivUI.TabLayout = TabLayout

function TabLayout.LayoutRows(container, buttons, options)
    options = options or {}

    local startX = options.startX or 0
    local startY = options.startY or 0
    local rightInset = options.rightInset or 0
    local rowHeight = options.rowHeight or DEFAULT_ROW_HEIGHT
    local containerWidth = container:GetWidth()
    if containerWidth <= 0 then
        containerWidth = options.fallbackWidth or DEFAULT_FALLBACK_WIDTH
    end

    local rowRight = math.max(startX + 1, containerWidth - rightInset)
    local availableWidth = rowRight - startX
    local x = startX
    local y = startY
    local rows = 1

    for _, button in ipairs(buttons) do
        local currentWidth = button:GetWidth()
        local naturalWidth = button.nivuiNaturalTabWidth
        if not naturalWidth or currentWidth > naturalWidth then
            naturalWidth = currentWidth
            button.nivuiNaturalTabWidth = naturalWidth
        end

        local buttonWidth = math.min(naturalWidth, availableWidth)
        button.nivuiTabMaxWidth = availableWidth
        if currentWidth ~= buttonWidth then
            button:SetWidth(buttonWidth)
        end

        if x > startX and x + buttonWidth > rowRight then
            x = startX
            y = y - rowHeight
            rows = rows + 1
        end

        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", container, "TOPLEFT", x, y)
        x = x + buttonWidth
    end

    return rows
end
