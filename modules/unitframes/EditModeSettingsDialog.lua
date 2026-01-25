NivUI = NivUI or {}
NivUI.EditMode = NivUI.EditMode or {}

local DIALOG_WIDTH = 320
local SETTING_HEIGHT = 32
local LABEL_WIDTH = 120

local SettingType = {
    Dropdown = "dropdown",
    Slider = "slider",
    Checkbox = "checkbox",
    TextInput = "textinput",
}

local DefaultVisibilityDrivers = {
    player = "show",
    target = "[@target,exists] show; [@softenemy,exists] show; [@softfriend,exists] show; hide",
    focus = "[@focus,exists] show; hide",
    pet = "[@pet,exists] show; hide",
    targettarget = "[@targettarget,exists] show; hide",
    party = "show",
    boss = "show",
    arena = "show",
    raid10 = "show",
    raid20 = "show",
    raid40 = "show",
}

local function CreateVisibilitySetting(frameType)
    return {
        key = "visibilityOverride",
        name = "Show States",
        type = SettingType.TextInput,
        width = 140,
        placeholder = DefaultVisibilityDrivers[frameType] or "show",
        get = function() return NivUI:GetVisibilityOverride(frameType) or "" end,
        set = function(value) NivUI:SetVisibilityOverride(frameType, value) end,
    }
end

local FrameSettings = {
    player = {
        CreateVisibilitySetting("player"),
    },

    target = {
        CreateVisibilitySetting("target"),
    },

    focus = {
        CreateVisibilitySetting("focus"),
    },

    pet = {
        CreateVisibilitySetting("pet"),
    },

    targettarget = {
        CreateVisibilitySetting("targettarget"),
    },

    party = {
        {
            key = "sortMode",
            name = "Sort Order",
            type = SettingType.Dropdown,
            options = {
                { value = "DEFAULT", text = "Default" },
                { value = "ROLE", text = "By Role" },
            },
            get = function() return NivUI:GetPartySortMode() end,
            set = function(value) NivUI:SetPartySortMode(value) end,
        },
        {
            key = "orientation",
            name = "Orientation",
            type = SettingType.Dropdown,
            options = {
                { value = "VERTICAL", text = "Vertical" },
                { value = "HORIZONTAL", text = "Horizontal" },
            },
            get = function() return NivUI:GetPartyOrientation() end,
            set = function(value)
                NivUI:SetPartyOrientation(value)
                if value == "VERTICAL" then
                    NivUI:SetPartyGrowthDirection("DOWN")
                else
                    NivUI:SetPartyGrowthDirection("RIGHT")
                end
            end,
        },
        {
            key = "growthDirection",
            name = "Growth Direction",
            type = SettingType.Dropdown,
            options = function()
                local orientation = NivUI:GetPartyOrientation()
                if orientation == "VERTICAL" then
                    return {
                        { value = "DOWN", text = "Down" },
                        { value = "UP", text = "Up" },
                    }
                else
                    return {
                        { value = "RIGHT", text = "Right" },
                        { value = "LEFT", text = "Left" },
                    }
                end
            end,
            get = function() return NivUI:GetPartyGrowthDirection() end,
            set = function(value) NivUI:SetPartyGrowthDirection(value) end,
        },
        {
            key = "spacing",
            name = "Spacing",
            type = SettingType.Slider,
            min = 0,
            max = 20,
            step = 1,
            get = function() return NivUI:GetPartySpacing() end,
            set = function(value) NivUI:SetPartySpacing(value) end,
        },
        {
            key = "includePlayer",
            name = "Include Player",
            type = SettingType.Checkbox,
            get = function() return NivUI:DoesPartyIncludePlayer() end,
            set = function(value) NivUI:SetPartyIncludePlayer(value) end,
        },
        {
            key = "showWhenSolo",
            name = "Show When Solo",
            type = SettingType.Checkbox,
            get = function() return NivUI:DoesPartyShowWhenSolo() end,
            set = function(value) NivUI:SetPartyShowWhenSolo(value) end,
        },
        CreateVisibilitySetting("party"),
    },

    boss = {
        {
            key = "orientation",
            name = "Orientation",
            type = SettingType.Dropdown,
            options = {
                { value = "VERTICAL", text = "Vertical" },
                { value = "HORIZONTAL", text = "Horizontal" },
            },
            get = function() return NivUI:GetBossOrientation() end,
            set = function(value)
                NivUI:SetBossOrientation(value)
                if value == "VERTICAL" then
                    NivUI:SetBossGrowthDirection("DOWN")
                else
                    NivUI:SetBossGrowthDirection("RIGHT")
                end
            end,
        },
        {
            key = "growthDirection",
            name = "Growth Direction",
            type = SettingType.Dropdown,
            options = function()
                local orientation = NivUI:GetBossOrientation()
                if orientation == "VERTICAL" then
                    return {
                        { value = "DOWN", text = "Down" },
                        { value = "UP", text = "Up" },
                    }
                else
                    return {
                        { value = "RIGHT", text = "Right" },
                        { value = "LEFT", text = "Left" },
                    }
                end
            end,
            get = function() return NivUI:GetBossGrowthDirection() end,
            set = function(value) NivUI:SetBossGrowthDirection(value) end,
        },
        {
            key = "spacing",
            name = "Spacing",
            type = SettingType.Slider,
            min = 0,
            max = 20,
            step = 1,
            get = function() return NivUI:GetBossSpacing() end,
            set = function(value) NivUI:SetBossSpacing(value) end,
        },
        CreateVisibilitySetting("boss"),
    },

    arena = {
        {
            key = "orientation",
            name = "Orientation",
            type = SettingType.Dropdown,
            options = {
                { value = "VERTICAL", text = "Vertical" },
                { value = "HORIZONTAL", text = "Horizontal" },
            },
            get = function() return NivUI:GetArenaOrientation() end,
            set = function(value)
                NivUI:SetArenaOrientation(value)
                if value == "VERTICAL" then
                    NivUI:SetArenaGrowthDirection("DOWN")
                else
                    NivUI:SetArenaGrowthDirection("RIGHT")
                end
            end,
        },
        {
            key = "growthDirection",
            name = "Growth Direction",
            type = SettingType.Dropdown,
            options = function()
                local orientation = NivUI:GetArenaOrientation()
                if orientation == "VERTICAL" then
                    return {
                        { value = "DOWN", text = "Down" },
                        { value = "UP", text = "Up" },
                    }
                else
                    return {
                        { value = "RIGHT", text = "Right" },
                        { value = "LEFT", text = "Left" },
                    }
                end
            end,
            get = function() return NivUI:GetArenaGrowthDirection() end,
            set = function(value) NivUI:SetArenaGrowthDirection(value) end,
        },
        {
            key = "spacing",
            name = "Spacing",
            type = SettingType.Slider,
            min = 0,
            max = 20,
            step = 1,
            get = function() return NivUI:GetArenaSpacing() end,
            set = function(value) NivUI:SetArenaSpacing(value) end,
        },
        CreateVisibilitySetting("arena"),
    },
}

local function CreateRaidSettings(raidSize)
    return {
        {
            key = "sortMode",
            name = "Sort Order",
            type = SettingType.Dropdown,
            options = {
                { value = "GROUP", text = "By Group" },
                { value = "GROUP_ROLE", text = "By Group Role" },
                { value = "ROLE", text = "By Role" },
            },
            get = function() return NivUI:GetRaidSortMode(raidSize) end,
            set = function(value) NivUI:SetRaidSortMode(raidSize, value) end,
        },
        {
            key = "groupOrientation",
            name = "Group Orientation",
            type = SettingType.Dropdown,
            options = {
                { value = "VERTICAL", text = "Vertical" },
                { value = "HORIZONTAL", text = "Horizontal" },
            },
            get = function() return NivUI:GetRaidGroupOrientation(raidSize) end,
            set = function(value)
                NivUI:SetRaidGroupOrientation(raidSize, value)
                if value == "VERTICAL" then
                    NivUI:SetRaidGroupGrowthDirection(raidSize, "DOWN")
                else
                    NivUI:SetRaidGroupGrowthDirection(raidSize, "RIGHT")
                end
            end,
        },
        {
            key = "groupGrowthDirection",
            name = "Group Growth",
            type = SettingType.Dropdown,
            options = function()
                local orientation = NivUI:GetRaidGroupOrientation(raidSize)
                if orientation == "VERTICAL" then
                    return {
                        { value = "DOWN", text = "Down" },
                        { value = "UP", text = "Up" },
                    }
                else
                    return {
                        { value = "RIGHT", text = "Right" },
                        { value = "LEFT", text = "Left" },
                    }
                end
            end,
            get = function() return NivUI:GetRaidGroupGrowthDirection(raidSize) end,
            set = function(value) NivUI:SetRaidGroupGrowthDirection(raidSize, value) end,
        },
        {
            key = "playerGrowthDirection",
            name = "Player Growth",
            type = SettingType.Dropdown,
            options = {
                { value = "DOWN", text = "Down" },
                { value = "UP", text = "Up" },
                { value = "RIGHT", text = "Right" },
                { value = "LEFT", text = "Left" },
            },
            get = function() return NivUI:GetRaidPlayerGrowthDirection(raidSize) end,
            set = function(value) NivUI:SetRaidPlayerGrowthDirection(raidSize, value) end,
        },
        {
            key = "spacing",
            name = "Spacing",
            type = SettingType.Slider,
            min = 0,
            max = 20,
            step = 1,
            get = function() return NivUI:GetRaidSpacing(raidSize) end,
            set = function(value) NivUI:SetRaidSpacing(raidSize, value) end,
        },
        CreateVisibilitySetting(raidSize),
    }
end

FrameSettings.raid10 = CreateRaidSettings("raid10")
FrameSettings.raid20 = CreateRaidSettings("raid20")
FrameSettings.raid40 = CreateRaidSettings("raid40")

local FrameNames = {
    player = "Player Frame",
    target = "Target Frame",
    focus = "Focus Frame",
    pet = "Pet Frame",
    targettarget = "Target of Target",
    party = "Party Frames",
    boss = "Boss Frames",
    arena = "Arena Frames",
    raid10 = "Raid Frames (10)",
    raid20 = "Raid Frames (20)",
    raid40 = "Raid Frames (40)",
}

local dialog = nil
local settingControls = {}
local currentFrameType = nil

local function CreateSettingControl(parent, settingDef, index)
    local control = CreateFrame("Frame", nil, parent)
    control:SetHeight(SETTING_HEIGHT)
    control:SetPoint("LEFT", 0, 0)
    control:SetPoint("RIGHT", 0, 0)
    control.layoutIndex = index
    control.settingDef = settingDef

    local label = control:CreateFontString(nil, "ARTWORK", "GameFontHighlightMedium")
    label:SetPoint("LEFT", 0, 0)
    label:SetWidth(LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetText(settingDef.name)
    control.label = label

    if settingDef.type == SettingType.Dropdown then
        local dropdown = CreateFrame("DropdownButton", nil, control, "WowStyle1DropdownTemplate")
        dropdown:SetPoint("LEFT", label, "RIGHT", 10, 0)
        dropdown:SetWidth(130)
        control.dropdown = dropdown

        function control:Refresh()
            local options = self.settingDef.options
            if type(options) == "function" then
                options = options()
            end

            self.dropdown:SetupMenu(function(_, rootDescription)
                for _, opt in ipairs(options) do
                    rootDescription:CreateRadio(
                        opt.text,
                        function() return self.settingDef.get() == opt.value end,
                        function()
                            self.settingDef.set(opt.value)
                            NivUI.EditMode:RefreshSettingsDialog()
                        end
                    )
                end
            end)
        end

    elseif settingDef.type == SettingType.Slider then
        local slider = CreateFrame("Slider", nil, control, "MinimalSliderWithSteppersTemplate")
        slider:SetPoint("LEFT", label, "RIGHT", 10, 0)
        slider:SetWidth(120)
        slider:SetHeight(20)

        local steps = math.floor((settingDef.max - settingDef.min) / (settingDef.step or 1))
        slider:Init(settingDef.get(), settingDef.min, settingDef.max, steps, {})

        control.slider = slider

        local valueText = control:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        valueText:SetPoint("LEFT", slider, "RIGHT", 8, 0)
        valueText:SetWidth(30)
        control.valueText = valueText

        local updating = false
        slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
            if updating then return end
            updating = true
            value = math.floor(value + 0.5)
            valueText:SetText(tostring(value))
            settingDef.set(value)
            updating = false
        end)

        function control:Refresh()
            local value = self.settingDef.get()
            self.slider:SetValue(value)
            self.valueText:SetText(tostring(value))
        end

    elseif settingDef.type == SettingType.Checkbox then
        local checkbox = CreateFrame("CheckButton", nil, control)
        checkbox:SetPoint("LEFT", label, "RIGHT", 10, 0)
        checkbox:SetSize(24, 24)
        checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
        checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
        checkbox:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")

        checkbox:SetScript("OnClick", function(self)
            settingDef.set(self:GetChecked())
        end)

        control.checkbox = checkbox

        function control:Refresh()
            self.checkbox:SetChecked(self.settingDef.get())
        end

    elseif settingDef.type == SettingType.TextInput then
        local editBox = CreateFrame("EditBox", nil, control, "InputBoxTemplate")
        editBox:SetPoint("LEFT", label, "RIGHT", 15, 0)
        editBox:SetWidth(settingDef.width or 140)
        editBox:SetHeight(20)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("ChatFontSmall")

        local placeholder = editBox:CreateFontString(nil, "ARTWORK", "ChatFontSmall")
        placeholder:SetPoint("LEFT", 5, 0)
        placeholder:SetPoint("RIGHT", -5, 0)
        placeholder:SetJustifyH("LEFT")
        placeholder:SetTextColor(0.5, 0.5, 0.5, 0.8)
        placeholder:SetWordWrap(false)
        if settingDef.placeholder then
            placeholder:SetText(settingDef.placeholder)
        end
        editBox.placeholder = placeholder

        local function UpdatePlaceholder()
            local text = editBox:GetText()
            local hasFocus = editBox:HasFocus()
            if (not text or text == "") and not hasFocus and settingDef.placeholder then
                placeholder:Show()
            else
                placeholder:Hide()
            end
        end

        editBox:SetScript("OnEnterPressed", function(self)
            settingDef.set(self:GetText())
            self:ClearFocus()
        end)

        editBox:SetScript("OnEscapePressed", function(self)
            self:SetText(settingDef.get() or "")
            self:ClearFocus()
        end)

        editBox:SetScript("OnEditFocusGained", function()
            UpdatePlaceholder()
        end)

        editBox:SetScript("OnEditFocusLost", function()
            UpdatePlaceholder()
        end)

        editBox:SetScript("OnTextChanged", function()
            UpdatePlaceholder()
        end)

        control.editBox = editBox

        function control:Refresh()
            self.editBox:SetText(self.settingDef.get() or "")
            UpdatePlaceholder()
        end
    end

    control:Show()
    return control
end

local function CreateDialog()
    local frame = CreateFrame("Frame", "NivUI_EditModeSettingsDialog", UIParent)
    frame:SetSize(DIALOG_WIDTH, 200)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(200)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:Hide()

    local border = CreateFrame("Frame", nil, frame, "DialogBorderTranslucentTemplate")
    border:SetAllPoints()
    frame.Border = border

    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -15)
    frame.title = title

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 2, 2)
    closeButton:SetScript("OnClick", function()
        frame:Hide()
        NivUI.EditMode:ClearSelection()
    end)

    local settingsContainer = CreateFrame("Frame", nil, frame)
    settingsContainer:SetPoint("TOPLEFT", 20, -45)
    settingsContainer:SetPoint("BOTTOMRIGHT", -20, 20)
    frame.settingsContainer = settingsContainer

    frame:SetScript("OnHide", function()
        currentFrameType = nil
    end)

    return frame
end

function NivUI.EditMode:GetSettingsDialog()
    if not dialog then
        dialog = CreateDialog()
    end
    return dialog
end

function NivUI.EditMode:RefreshSettingsDialog()
    if not dialog or not dialog:IsShown() or not currentFrameType then
        return
    end

    for _, control in ipairs(settingControls) do
        control:Refresh()
    end
end

function NivUI.EditMode:ShowSettingsDialog(frameType, targetFrame)
    local settings = FrameSettings[frameType]
    if not settings then
        return
    end

    local dlg = self:GetSettingsDialog()

    for _, control in ipairs(settingControls) do
        control:Hide()
        control:SetParent(nil)
    end
    wipe(settingControls)

    currentFrameType = frameType

    dlg.title:SetText(FrameNames[frameType] or frameType)

    local yOffset = 0
    for i, settingDef in ipairs(settings) do
        local control = CreateSettingControl(dlg.settingsContainer, settingDef, i)
        control:SetPoint("TOPLEFT", dlg.settingsContainer, "TOPLEFT", 0, -yOffset)
        control:SetPoint("TOPRIGHT", dlg.settingsContainer, "TOPRIGHT", 0, -yOffset)
        control:Refresh()
        table.insert(settingControls, control)
        yOffset = yOffset + SETTING_HEIGHT + 2
    end

    local contentHeight = yOffset + 65
    dlg:SetHeight(math.max(contentHeight, 120))

    if targetFrame then
        dlg:ClearAllPoints()
        local left = targetFrame:GetLeft()
        local right = targetFrame:GetRight()
        local screenWidth = GetScreenWidth()

        if left and right then
            if right + DIALOG_WIDTH + 20 < screenWidth then
                dlg:SetPoint("TOPLEFT", targetFrame, "TOPRIGHT", 10, 10)
            else
                dlg:SetPoint("TOPRIGHT", targetFrame, "TOPLEFT", -10, 10)
            end
        else
            dlg:SetPoint("CENTER")
        end
    end

    dlg:Show()
end

function NivUI.EditMode:HideSettingsDialog()
    if dialog then
        dialog:Hide()
    end
end

function NivUI.EditMode:IsSettingsDialogShown()
    return dialog and dialog:IsShown()
end

function NivUI.EditMode:HasSettings(frameType)
    return FrameSettings[frameType] ~= nil
end

local function OnSettingsChanged()
    if NivUI.EditMode:IsActive() then
        NivUI.EditMode:UpdateContainerSizes()
    end
end

NivUI:RegisterCallback("PartySettingsChanged", OnSettingsChanged)
NivUI:RegisterCallback("BossSettingsChanged", OnSettingsChanged)
NivUI:RegisterCallback("ArenaSettingsChanged", OnSettingsChanged)
NivUI:RegisterCallback("RaidSettingsChanged", OnSettingsChanged)
