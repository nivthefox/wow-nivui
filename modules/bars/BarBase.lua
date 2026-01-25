NivUI.BarBase = {}

function NivUI.BarBase.CreateModule(config)
    local state = {
        barType = config.barType,
        frame = nil,
        enabled = false,
    }

    local module = {}

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
    end

    function module.Disable()
        if not state.enabled then return end

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
