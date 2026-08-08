local NivUI, assertions = ...

local assertEquals = assertions.equals
local assertTrue = assertions.isTrue

local function CreateContainer(width)
    return {
        GetWidth = function()
            return width
        end,
    }
end

local function CreateButton(width)
    local button = {
        width = width,
    }

    function button:GetWidth()
        return self.width
    end

    function button:SetWidth(newWidth)
        self.width = newWidth
    end

    function button:ClearAllPoints()
        self.point = nil
    end

    function button:SetPoint(_, _, _, x, y)
        self.point = { x = x, y = y }
    end

    return button
end

return {
    ["twenty long tabs and the add control remain within the panel width"] = function()
        local containerWidth = 525
        local buttons = {}
        for _ = 1, 20 do
            buttons[#buttons + 1] = CreateButton(240)
        end
        local addButton = CreateButton(70)
        buttons[#buttons + 1] = addButton

        local rows = NivUI.TabLayout.LayoutRows(CreateContainer(containerWidth), buttons, {
            startX = 4,
            rightInset = 4,
        })

        assertEquals(rows, 11, "row count")
        for index, button in ipairs(buttons) do
            assertTrue(button.point.x + button:GetWidth() <= containerWidth - 4,
                "button " .. index .. " stays within the panel")
        end
        assertTrue(addButton.point ~= nil, "add control is positioned")
    end,

    ["a single oversized tab is capped to the available row width"] = function()
        local button = CreateButton(900)

        local rows = NivUI.TabLayout.LayoutRows(CreateContainer(525), { button }, {
            startX = 4,
            rightInset = 4,
        })

        assertEquals(rows, 1, "row count")
        assertEquals(button:GetWidth(), 517, "capped tab width")
        assertEquals(button.point.x, 4, "tab x position")
        assertEquals(button.point.y, 0, "tab y position")

        NivUI.TabLayout.LayoutRows(CreateContainer(1000), { button }, {
            startX = 4,
            rightInset = 4,
        })

        assertEquals(button:GetWidth(), 900, "natural width is restored when space is available")
    end,
}
