local _, NivUI = ...

NivUI.Config = NivUI.Config or {}

local configWindows = {}
local configPopups = {}
local pendingOpen = false
local nivuiColorPickerOpen = false

local function IsCombatLocked()
    return InCombatLockdown and InCombatLockdown()
end

local function CloseConfigMenus()
    if not Menu or type(Menu.GetManager) ~= "function" then
        return
    end

    local manager = Menu.GetManager()
    if manager and type(manager.CloseMenus) == "function" then
        manager:CloseMenus()
    end
end

local function CloseConfigPopups()
    if type(StaticPopup_Hide) ~= "function" then
        return
    end

    for popupName in pairs(configPopups) do
        StaticPopup_Hide(popupName)
    end
end

local function CloseConfigColorPicker()
    if not nivuiColorPickerOpen then
        return
    end
    if ColorPickerFrame and ColorPickerFrame:IsShown() then
        ColorPickerFrame:Hide()
    end
end

function NivUI:RegisterConfigWindow(frame)
    if not frame then
        return false
    end

    configWindows[frame] = true
    return true
end

function NivUI:RegisterConfigPopup(popupName)
    if type(popupName) ~= "string" or popupName == "" then
        return false
    end

    configPopups[popupName] = true
    return true
end

function NivUI:ShowConfigColorPicker(info)
    if IsCombatLocked() then
        return false
    end
    if not ColorPickerFrame then
        return false
    end

    nivuiColorPickerOpen = true
    ColorPickerFrame:SetupColorPickerAndShow(info)
    return true
end

function NivUI:CanChangeConfig()
    return not IsCombatLocked()
end

function NivUI:CloseConfigUI()
    for frame in pairs(configWindows) do
        if frame:IsShown() then
            frame:Hide()
        end
    end

    CloseConfigPopups()
    CloseConfigColorPicker()
    CloseConfigMenus()
end

function NivUI:RequestConfigOpenAfterCombat()
    if pendingOpen then
        return
    end

    pendingOpen = true
    print("NivUI: Configuration will open when combat ends")
end

function NivUI:OpenConfigFrame()
    if not self.isInitialized then
        print("NivUI: Configuration is not ready yet")
        return false
    end
    if IsCombatLocked() then
        self:RequestConfigOpenAfterCombat()
        return false
    end
    if not self.ConfigFrame and self.CreateConfigFrame then
        self:CreateConfigFrame()
    end
    if not self.ConfigFrame then
        print("NivUI: Config frame not loaded")
        return false
    end

    self.ConfigFrame:Show()
    return true
end

function NivUI:ToggleConfigFrame()
    if not self.isInitialized then
        print("NivUI: Configuration is not ready yet")
        return
    end
    if IsCombatLocked() then
        self:CloseConfigUI()
        self:RequestConfigOpenAfterCombat()
        return
    end
    if self.ConfigFrame and self.ConfigFrame:IsShown() then
        self:CloseConfigUI()
        return
    end

    self:OpenConfigFrame()
end

if ColorPickerFrame and type(ColorPickerFrame.HookScript) == "function" then
    ColorPickerFrame:HookScript("OnHide", function()
        nivuiColorPickerOpen = false
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        NivUI:CloseConfigUI()
        return
    end
    if not pendingOpen then
        return
    end

    pendingOpen = false
    NivUI:OpenConfigFrame()
end)

SLASH_NIVUI1 = "/nivui"
SlashCmdList["NIVUI"] = function(msg)
    if msg and msg ~= "" then
        print("NivUI: Use /nivui to open the config panel")
        return
    end
    NivUI:ToggleConfigFrame()
end
