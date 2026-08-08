local _, NivUI = ...

-- UI APIs stay unstubbed so pure modules fail if they acquire UI dependencies.
local function strtrim(str)
    return str:match("^%s*(.-)%s*$")
end

function NivUI.DeepCopy(t)
    if type(t) ~= "table" then
        return t
    end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = NivUI.DeepCopy(v)
    end
    return copy
end

function NivUI:TriggerEvent()
end

NivUI.current = { overlays = {} }

return {
    strtrim = strtrim,
}
