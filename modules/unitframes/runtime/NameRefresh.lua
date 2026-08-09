local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}
NivUI.UnitFrames.Runtime = NivUI.UnitFrames.Runtime or {}

local NameRefresh = {}
NivUI.UnitFrames.Runtime.NameRefresh = NameRefresh
--- Rolling name refresh for group members.
--- Outside of combat, cycles through all visible member states and refreshes
--- one name per tick. With a 1-second tick, a 20-person raid cycles every 20s.
function NameRefresh.Start(updateNameText)
    local refreshIndex = 0

    --- Collects all active member states across raid, party, and custom group frames.
    --- @return table memberStates A flat list of active member states
    local function CollectMemberStates()
        local result = {}
        local UF = NivUI.UnitFrames

        -- Raid frames (raid10, raid20, raid40)
        if UF.RaidFrame then
            for _, raidSize in ipairs({ "raid10", "raid20", "raid40" }) do
                local state = UF.RaidFrame.GetState(raidSize)
                if state and state.enabled and state.memberStates then
                    for _, memberState in pairs(state.memberStates) do
                        result[#result + 1] = memberState
                    end
                end
            end
        end

        if UF.CustomRaidGroup and UF.CustomRaidGroup.GetAllStates then
            for _, state in pairs(UF.CustomRaidGroup.GetAllStates()) do
                if state.enabled and state.memberStates then
                    for _, memberState in pairs(state.memberStates) do
                        result[#result + 1] = memberState
                    end
                end
            end
        end

        if UF.PartyFrame then
            local state = UF.PartyFrame.GetState()
            if state and state.enabled and state.memberStates then
                for _, memberState in pairs(state.memberStates) do
                    result[#result + 1] = memberState
                end
            end
        end

        return result
    end

    C_Timer.NewTicker(1, function()
        if InCombatLockdown() then return end

        local members = CollectMemberStates()
        if #members == 0 then return end

        refreshIndex = refreshIndex + 1
        if refreshIndex > #members then
            refreshIndex = 1
        end

        updateNameText(members[refreshIndex])
    end)
end
