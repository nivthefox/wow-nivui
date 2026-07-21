-- tests/test_overlay_condition.lua
-- Contract tests for NivUI.OverlayLogic.EvaluateCondition(cond, value).
--
-- nil cond          -> always true (no condition means always visible).
-- equality shape    -> { key = "x", value = "A" }: true when value == cond.value.
-- anyOf shape       -> { key = "x", anyOf = { "A", "B" } }: true when value is in the set.
-- The existing showIf schemas compare against boolean values, so boolean
-- equality must work as well.

local function Eval(cond, value)
    return NivUI.OverlayLogic.EvaluateCondition(cond, value)
end

return {
    ["nil condition is always true"] = function()
        assertTrue(Eval(nil, "anything"), "nil cond is true regardless of value")
        assertTrue(Eval(nil, nil), "nil cond is true even for nil value")
    end,

    ["equality matches when equal"] = function()
        assertTrue(Eval({ key = "x", value = "A" }, "A"), "equal string values match")
    end,

    ["equality fails when not equal"] = function()
        assertFalse(Eval({ key = "x", value = "A" }, "B"), "different string values do not match")
        assertFalse(Eval({ key = "x", value = "A" }, nil), "nil value does not match a string")
    end,

    ["equality with boolean true"] = function()
        assertTrue(Eval({ key = "showDuration", value = true }, true), "true == true")
        assertFalse(Eval({ key = "showDuration", value = true }, false), "false does not equal true")
    end,

    ["anyOf matches any listed value"] = function()
        local cond = { key = "displayType", anyOf = { "A", "B" } }
        assertTrue(Eval(cond, "A"), "first anyOf member matches")
        assertTrue(Eval(cond, "B"), "second anyOf member matches")
    end,

    ["anyOf fails for unlisted and nil values"] = function()
        local cond = { key = "displayType", anyOf = { "A", "B" } }
        assertFalse(Eval(cond, "C"), "value outside anyOf set does not match")
        assertFalse(Eval(cond, nil), "nil value does not match anyOf set")
    end,
}
