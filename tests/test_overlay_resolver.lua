-- tests/test_overlay_resolver.lua
-- Contract tests for NivUI.OverlayLogic.ResolveTransformative and IsTransformative.
--
-- ResolveTransformative(claims) -> { FRAME = { [targetWidget] = winner },
--                                    BORDER = { [targetWidget] = winner } }
-- Each claim: { name, priority, targetWidget, kind ("FRAME"|"BORDER"), active,
--               plus arbitrary passthrough fields (config, widget, ...) }.
-- Active-only; higher priority wins; equal priority breaks alphabetically by
-- name (string < wins); missing priority treated as 1; result is independent of
-- input array order; the returned winner is the exact claim table passed in.

local function Resolve(claims)
    return NivUI.OverlayLogic.ResolveTransformative(claims)
end

return {
    ["single active claim wins"] = function()
        local claim = { name = "A", priority = 1, targetWidget = "healthBar", kind = "FRAME", active = true }
        local result = Resolve({ claim })
        assertEquals(result.FRAME.healthBar, claim, "single active claim should win its target")
    end,

    ["higher priority wins"] = function()
        local low = { name = "Low", priority = 1, targetWidget = "healthBar", kind = "FRAME", active = true }
        local high = { name = "High", priority = 5, targetWidget = "healthBar", kind = "FRAME", active = true }
        local result = Resolve({ low, high })
        assertEquals(result.FRAME.healthBar, high, "higher priority should win")
    end,

    ["equal priority breaks alphabetically by name"] = function()
        local alpha = { name = "Alpha", priority = 3, targetWidget = "healthBar", kind = "FRAME", active = true }
        local zeta = { name = "Zeta", priority = 3, targetWidget = "healthBar", kind = "FRAME", active = true }
        local r1 = Resolve({ alpha, zeta })
        local r2 = Resolve({ zeta, alpha })
        assertEquals(r1.FRAME.healthBar, alpha, "Alpha wins the tie when passed first")
        assertEquals(r2.FRAME.healthBar, alpha, "Alpha wins the tie when passed last")
    end,

    ["three-way tie always resolves to alphabetically first name"] = function()
        local alpha = { name = "Alpha", priority = 3, targetWidget = "healthBar", kind = "FRAME", active = true }
        local mu = { name = "Mu", priority = 3, targetWidget = "healthBar", kind = "FRAME", active = true }
        local zeta = { name = "Zeta", priority = 3, targetWidget = "healthBar", kind = "FRAME", active = true }

        local r1 = Resolve({ alpha, mu, zeta })
        local r2 = Resolve({ zeta, mu, alpha })
        local r3 = Resolve({ mu, alpha, zeta })

        assertEquals(r1.FRAME.healthBar, alpha, "three-way tie, Alpha first in input")
        assertEquals(r2.FRAME.healthBar, alpha, "three-way tie, Alpha last in input")
        assertEquals(r3.FRAME.healthBar, alpha, "three-way tie, Alpha in the middle")
    end,

    ["inactive claim never wins even at higher priority"] = function()
        local active = { name = "Active", priority = 1, targetWidget = "healthBar", kind = "FRAME", active = true }
        local inactive = { name = "Inactive", priority = 99, targetWidget = "healthBar", kind = "FRAME", active = false }
        local result = Resolve({ inactive, active })
        assertEquals(result.FRAME.healthBar, active, "inactive high-priority claim must not win")
    end,

    ["no active claims for a target yields no entry"] = function()
        local inactive = { name = "A", priority = 1, targetWidget = "healthBar", kind = "FRAME", active = false }
        local result = Resolve({ inactive })
        assertNil(result.FRAME.healthBar, "target with no active claims must have no entry")
    end,

    ["FRAME and BORDER on same target resolve independently"] = function()
        local frame = { name = "F", priority = 1, targetWidget = "healthBar", kind = "FRAME", active = true }
        local border = { name = "B", priority = 1, targetWidget = "healthBar", kind = "BORDER", active = true }
        local result = Resolve({ frame, border })
        assertEquals(result.FRAME.healthBar, frame, "FRAME winner independent of BORDER")
        assertEquals(result.BORDER.healthBar, border, "BORDER winner independent of FRAME")
    end,

    ["claims on different targets are independent"] = function()
        local health = { name = "H", priority = 1, targetWidget = "healthBar", kind = "FRAME", active = true }
        local power = { name = "P", priority = 1, targetWidget = "powerBar", kind = "FRAME", active = true }
        local result = Resolve({ health, power })
        assertEquals(result.FRAME.healthBar, health, "healthBar winner")
        assertEquals(result.FRAME.powerBar, power, "powerBar winner")
    end,

    ["result identical regardless of input array order"] = function()
        local a = { name = "Alpha", priority = 3, targetWidget = "healthBar", kind = "FRAME", active = true }
        local b = { name = "Beta", priority = 5, targetWidget = "healthBar", kind = "FRAME", active = true }
        local c = { name = "Gamma", priority = 5, targetWidget = "healthBar", kind = "FRAME", active = false }
        local expectedWinner = b

        local r1 = Resolve({ a, b, c })
        local r2 = Resolve({ c, b, a })
        local r3 = Resolve({ b, a, c })

        assertEquals(r1.FRAME.healthBar, expectedWinner, "order permutation 1")
        assertEquals(r2.FRAME.healthBar, expectedWinner, "order permutation 2")
        assertEquals(r3.FRAME.healthBar, expectedWinner, "order permutation 3")
    end,

    ["missing priority treated as 1"] = function()
        local noPriority = { name = "Zeta", targetWidget = "healthBar", kind = "FRAME", active = true }
        local one = { name = "Alpha", priority = 1, targetWidget = "healthBar", kind = "FRAME", active = true }
        local result = Resolve({ noPriority, one })
        assertEquals(result.FRAME.healthBar, one, "missing priority treated as 1; alphabetical tie-break selects Alpha")
    end,

    ["missing priority loses to explicit higher priority"] = function()
        local noPriority = { name = "Alpha", targetWidget = "healthBar", kind = "FRAME", active = true }
        local two = { name = "Zeta", priority = 2, targetWidget = "healthBar", kind = "FRAME", active = true }
        local result = Resolve({ noPriority, two })
        assertEquals(result.FRAME.healthBar, two, "missing priority (1) must lose to priority 2")
    end,

    ["winner is the exact claim table with passthrough intact"] = function()
        local config = { color = { r = 1, g = 0, b = 0, a = 1 } }
        local widget = {}
        local claim = {
            name = "A", priority = 1, targetWidget = "healthBar", kind = "FRAME", active = true,
            config = config, widget = widget,
        }
        local winner = Resolve({ claim }).FRAME.healthBar
        assertEquals(winner, claim, "winner must be the exact table passed in")
        assertEquals(winner.config, config, "passthrough config field must be intact")
        assertEquals(winner.widget, widget, "passthrough widget field must be intact")
    end,

    ["IsTransformative true for FRAME and BORDER"] = function()
        assertTrue(NivUI.OverlayLogic.IsTransformative("FRAME"), "FRAME is transformative")
        assertTrue(NivUI.OverlayLogic.IsTransformative("BORDER"), "BORDER is transformative")
    end,

    ["IsTransformative false for additive, nil, and garbage"] = function()
        assertFalse(NivUI.OverlayLogic.IsTransformative("ICON"), "ICON is not transformative")
        assertFalse(NivUI.OverlayLogic.IsTransformative("COLOR"), "COLOR is not transformative")
        assertFalse(NivUI.OverlayLogic.IsTransformative(nil), "nil is not transformative")
        assertFalse(NivUI.OverlayLogic.IsTransformative("garbage"), "garbage string is not transformative")
    end,
}
