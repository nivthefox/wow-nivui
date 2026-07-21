-- tests/wow_stubs.lua
-- WoW API stubs for headless unit testing of NivUI pure-logic modules.
--
-- DO NOT stub CreateFrame or C_Timer here. Pure-logic modules must not
-- depend on UI/frame objects; leaving them nil causes accidental UI
-- dependencies to fail loudly and immediately rather than silently.
--
-- Tests can override any stub by assigning to the global directly before
-- the code-under-test runs, then restoring afterward if needed.

--------------------------------------------------------------------------------
-- String utilities
--------------------------------------------------------------------------------

-- strtrim(str) -> string  (trims leading and trailing whitespace)
function strtrim(str)
    return str:match("^%s*(.-)%s*$")
end

--------------------------------------------------------------------------------
-- NivUI namespace bootstrap
--------------------------------------------------------------------------------

NivUI = {}

-- DeepCopy(t) performs a recursive table copy. The real implementation lives
-- in NivUI.lua; this reimplements it simply for headless tests.
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
    -- no-op in tests
end

--------------------------------------------------------------------------------
-- Fake profile store
--------------------------------------------------------------------------------

NivUI.current = { overlays = {} }
