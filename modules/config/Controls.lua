local _, NivUI = ...

NivUI.Config = NivUI.Config or {}

local ConfigControls = {}

local function GetDecimalPlaces(step)
    local text = string.format("%.10f", step):gsub("0+$", "")
    local decimal = text:match("%.(%d+)$")
    return decimal and #decimal or 0
end

local function Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function ConfigControls.NormalizeSliderValue(value, min, max, step)
    if type(value) ~= "number" then
        return nil
    end

    step = type(step) == "number" and step > 0 and step or 1
    value = Clamp(value, min, max)

    local stepCount = math.floor(((value - min) / step) + 0.5)
    local normalized = Clamp(min + stepCount * step, min, max)
    local decimalPlaces = GetDecimalPlaces(step)
    local factor = 10 ^ decimalPlaces

    return math.floor(normalized * factor + 0.5) / factor
end

function ConfigControls.FormatSliderValue(value, decimalPlaces)
    if decimalPlaces <= 0 then
        return tostring(math.floor(value + 0.5))
    end

    return string.format("%." .. decimalPlaces .. "f", value)
end

function ConfigControls.BindCheckboxRow(holder, checkBox, options)
    options = options or {}

    local binding = {}
    local currentValue = false

    local function CanChange()
        return not options.canChange or options.canChange()
    end

    local function ApplyClick()
        local checked = checkBox:GetChecked() and true or false
        if not CanChange() then
            checkBox:SetChecked(currentValue)
            return
        end

        currentValue = checked
        if options.onChanged then
            options.onChanged(checked)
        end
    end

    checkBox:SetScript("OnClick", ApplyClick)

    holder:EnableMouse(true)
    holder:SetScript("OnEnter", function()
        if checkBox.OnEnter then
            checkBox:OnEnter()
        end
    end)
    holder:SetScript("OnLeave", function()
        if checkBox.OnLeave then
            checkBox:OnLeave()
        end
    end)
    holder:SetScript("OnMouseUp", function(_, mouseButton)
        if mouseButton ~= "LeftButton" then
            return
        end
        if checkBox.IsEnabled and not checkBox:IsEnabled() then
            return
        end

        checkBox:Click()
    end)

    function binding:SetValue(value)
        currentValue = value and true or false
        checkBox:SetChecked(currentValue)
    end

    function binding:GetValue()
        return currentValue
    end

    return binding
end

function ConfigControls.BindSlider(slider, editBox, options)
    options = options or {}

    local min = options.min
    local max = options.max
    local step = type(options.step) == "number" and options.step > 0 and options.step or 1
    local decimalPlaces = options.decimalPlaces
    if decimalPlaces == nil then
        decimalPlaces = GetDecimalPlaces(step)
    end

    local binding = {}
    local changing = false
    local currentValue = ConfigControls.NormalizeSliderValue(options.value, min, max, step)
        or ConfigControls.NormalizeSliderValue(min, min, max, step)

    if slider.EnableMouseWheel then
        slider:EnableMouseWheel(false)
    end
    if editBox.EnableMouseWheel then
        editBox:EnableMouseWheel(false)
    end

    local function CanChange()
        return not options.canChange or options.canChange()
    end

    local function UpdateInput()
        editBox:SetText(ConfigControls.FormatSliderValue(currentValue, decimalPlaces))
    end

    local function SyncSlider()
        changing = true
        slider:SetValue(currentValue)
        changing = false
        UpdateInput()
    end

    local function SetFromUser(value)
        local normalized = ConfigControls.NormalizeSliderValue(value, min, max, step)
        if not normalized or not CanChange() then
            SyncSlider()
            return false
        end

        local previousValue = currentValue
        currentValue = normalized
        SyncSlider()

        if currentValue ~= previousValue and options.onChanged then
            options.onChanged(currentValue)
        end

        return true
    end

    local numSteps = math.floor(((max - min) / step) + 0.5)
    slider:Init(currentValue, min, max, numSteps, {})
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if changing then
            return
        end

        SetFromUser(value)
    end)

    if editBox.SetNumeric then
        editBox:SetNumeric(decimalPlaces == 0 and min >= 0)
    end

    editBox:SetScript("OnEnterPressed", function(self)
        SetFromUser(tonumber(self:GetText()))
        self:ClearFocus()
    end)
    editBox:SetScript("OnEscapePressed", function(self)
        UpdateInput()
        self:ClearFocus()
    end)
    editBox:SetScript("OnEditFocusLost", function()
        SetFromUser(tonumber(editBox:GetText()))
    end)

    function binding:SetValue(value)
        local normalized = ConfigControls.NormalizeSliderValue(value, min, max, step)
        if not normalized then
            return false
        end

        currentValue = normalized
        SyncSlider()
        return true
    end

    function binding:GetValue()
        return currentValue
    end

    UpdateInput()

    return binding
end

NivUI.ConfigControls = ConfigControls
