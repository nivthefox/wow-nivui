NivUI.BarBase = {}

function NivUI.BarBase.CreateModule(config)
    local state = {
        barType = config.barType,
        frame = nil,
        enabled = false,
    }

    local module = {}

    local function RegisterWithEditMode(frame)
        if not NivUI.EditMode then return end

        local barConfig = NivUI.classBarRegistry[state.barType]
        if not barConfig then return end

        local frameType = "classBar_" .. state.barType
        local selection = NivUI.EditMode:CreateSelectionFrame(frameType, frame)

        if not selection.barDragHooked then
            selection.barDragHooked = true
            local origDragStop = selection:GetScript("OnDragStop")
            selection:SetScript("OnDragStop", function(self)
                origDragStop(self)
                self.customFrame:SetMovable(true)
            end)
        end

        if NivUI.EditMode:IsActive() then
            if not frame:IsShown() then
                frame:Show()
            end
            NivUI.EditMode:ShowHighlighted(frameType)
            NivUI.EditMode:RegisterFrameForMagnetism(frame)
        end
    end

    function module.Enable()
        if state.enabled then return end

        state.frame = config.createUI()

        if config.registerEvents then
            config.registerEvents(state.frame)
        end

        if config.onUpdate then
            state.frame:SetScript("OnUpdate", config.onUpdate)
        end

        state.enabled = true

        if config.onEnable then
            config.onEnable(state.frame)
        end

        RegisterWithEditMode(state.frame)
    end

    function module.Disable()
        if not state.enabled then return end

        local frameType = "classBar_" .. state.barType
        if NivUI.EditMode then
            NivUI.EditMode:HideSelection(frameType)
            if state.frame then
                NivUI.EditMode:UnregisterFrameFromMagnetism(state.frame)
            end
        end

        if state.frame then
            state.frame:UnregisterAllEvents()
            state.frame:SetScript("OnUpdate", nil)
            state.frame:SetScript("OnEvent", nil)
            state.frame:Hide()
        end

        state.enabled = false

        if config.onDisable then
            config.onDisable(state.frame)
        end

        state.frame = nil
    end

    function module.IsEnabled()
        return state.enabled
    end

    function module.GetFrame()
        return state.frame
    end

    function module.Refresh()
        if state.enabled and config.onRefresh then
            config.onRefresh(state.frame)
        end
    end

    NivUI:RegisterCallback("ClassBarEnabledChanged", function(data)
        if data.barType == state.barType then
            if data.enabled then
                module.Enable()
            else
                module.Disable()
            end
        end
    end)

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_LOGIN" then
            NivUI:InitializeDB()
            if NivUI:IsClassBarEnabled(state.barType) then
                module.Enable()
            end
        end
    end)

    return module
end
