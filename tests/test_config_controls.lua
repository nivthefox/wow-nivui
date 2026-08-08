local NivUI, assertions = ...

local assertEquals = assertions.equals
local assertFalse = assertions.isFalse
local assertTrue = assertions.isTrue

local function CreateFrameStub()
    local frame = {
        scripts = {},
    }

    function frame:EnableMouse(enabled)
        self.mouseEnabled = enabled
    end

    function frame:EnableMouseWheel(enabled)
        self.mouseWheelEnabled = enabled
    end

    function frame:SetScript(scriptName, callback)
        self.scripts[scriptName] = callback
    end

    return frame
end

local function CreateCheckboxStub()
    local checkBox = CreateFrameStub()
    checkBox.checked = false
    checkBox.enabled = true

    function checkBox:SetChecked(checked)
        self.checked = checked and true or false
    end

    function checkBox:GetChecked()
        return self.checked
    end

    function checkBox:IsEnabled()
        return self.enabled
    end

    function checkBox:Click()
        self.checked = not self.checked
        self.scripts.OnClick(self)
    end

    return checkBox
end

local function CreateSliderStub()
    local slider = CreateFrameStub()

    function slider:Init(value, min, max, steps)
        self.value = value
        self.min = min
        self.max = max
        self.steps = steps
    end

    function slider:RegisterCallback(_, callback)
        self.callback = callback
    end

    function slider:SetValue(value)
        self.value = value
        if self.callback then
            self.callback(self, value)
        end
    end

    function slider:ChangeValue(value)
        self.value = value
        self.callback(self, value)
    end

    return slider
end

local function CreateEditBoxStub()
    local editBox = CreateFrameStub()

    function editBox:SetText(text)
        self.text = text
    end

    function editBox:GetText()
        return self.text
    end

    function editBox:SetNumeric(numeric)
        self.numeric = numeric
    end

    function editBox:ClearFocus()
        self.focusCleared = true
    end

    return editBox
end

return {
    ["checkbox rows expose one full-row click target"] = function()
        local holder = CreateFrameStub()
        local checkBox = CreateCheckboxStub()
        local changes = {}
        local binding = NivUI.ConfigControls.BindCheckboxRow(holder, checkBox, {
            onChanged = function(value)
                changes[#changes + 1] = value
            end,
        })

        binding:SetValue(false)
        holder.scripts.OnMouseUp(holder, "LeftButton")

        assertTrue(holder.mouseEnabled, "row mouse input")
        assertTrue(binding:GetValue(), "binding value")
        assertTrue(checkBox:GetChecked(), "checkbox value")
        assertEquals(#changes, 1, "callback count")
        assertTrue(changes[1], "callback value")

        holder.scripts.OnMouseUp(holder, "RightButton")
        assertEquals(#changes, 1, "right click callback count")
    end,

    ["checkbox refresh and blocked changes do not notify"] = function()
        local holder = CreateFrameStub()
        local checkBox = CreateCheckboxStub()
        local canChange = false
        local callbackCount = 0
        local binding = NivUI.ConfigControls.BindCheckboxRow(holder, checkBox, {
            canChange = function() return canChange end,
            onChanged = function() callbackCount = callbackCount + 1 end,
        })

        binding:SetValue(true)
        assertEquals(callbackCount, 0, "refresh callback count")

        holder.scripts.OnMouseUp(holder, "LeftButton")
        assertTrue(binding:GetValue(), "blocked binding value")
        assertTrue(checkBox:GetChecked(), "blocked checkbox value")
        assertEquals(callbackCount, 0, "blocked callback count")

        canChange = true
        holder.scripts.OnMouseUp(holder, "LeftButton")
        assertFalse(binding:GetValue(), "changed binding value")
        assertEquals(callbackCount, 1, "changed callback count")
    end,

    ["slider refresh does not notify and wheel input is not registered"] = function()
        local slider = CreateSliderStub()
        local editBox = CreateEditBoxStub()
        local callbackCount = 0
        local binding = NivUI.ConfigControls.BindSlider(slider, editBox, {
            min = 0,
            max = 20,
            step = 1,
            value = 2,
            onChanged = function() callbackCount = callbackCount + 1 end,
        })

        binding:SetValue(8)

        assertEquals(binding:GetValue(), 8, "binding value")
        assertEquals(slider.value, 8, "slider value")
        assertEquals(editBox.text, "8", "input value")
        assertEquals(callbackCount, 0, "refresh callback count")
        assertFalse(slider.mouseWheelEnabled, "slider mouse wheel")
        assertFalse(editBox.mouseWheelEnabled, "input mouse wheel")
        assertEquals(slider.scripts.OnMouseWheel, nil, "slider wheel handler")
        assertEquals(editBox.scripts.OnMouseWheel, nil, "input wheel handler")
    end,

    ["slider input clamps snaps and notifies once"] = function()
        local slider = CreateSliderStub()
        local editBox = CreateEditBoxStub()
        local changes = {}
        local binding = NivUI.ConfigControls.BindSlider(slider, editBox, {
            min = 0,
            max = 10,
            step = 2,
            value = 0,
            onChanged = function(value)
                changes[#changes + 1] = value
            end,
        })

        slider:ChangeValue(5)
        assertEquals(binding:GetValue(), 6, "dragged snapped value")
        assertEquals(#changes, 1, "drag callback count")
        assertEquals(changes[1], 6, "drag callback value")

        editBox:SetText("99")
        editBox.scripts.OnEnterPressed(editBox)
        assertEquals(binding:GetValue(), 10, "clamped input value")
        assertEquals(#changes, 2, "input callback count")
        assertEquals(changes[2], 10, "input callback value")

        editBox:SetText("invalid")
        editBox.scripts.OnEditFocusLost(editBox)
        assertEquals(binding:GetValue(), 10, "invalid input binding value")
        assertEquals(editBox.text, "10", "invalid input restored text")
        assertEquals(#changes, 2, "invalid input callback count")
    end,

    ["decimal slider values retain step precision"] = function()
        local slider = CreateSliderStub()
        local editBox = CreateEditBoxStub()
        local binding = NivUI.ConfigControls.BindSlider(slider, editBox, {
            min = 0.05,
            max = 1,
            step = 0.05,
            value = 0.1,
            decimalPlaces = 2,
        })

        slider:ChangeValue(0.126)

        assertEquals(binding:GetValue(), 0.15, "normalized decimal value")
        assertEquals(editBox.text, "0.15", "formatted decimal value")
        assertFalse(editBox.numeric, "decimal numeric mode")
    end,
}
