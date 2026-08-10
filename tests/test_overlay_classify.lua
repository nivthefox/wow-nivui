local NivUI, assertions = ...
local assertFalse = assertions.isFalse
local assertTrue = assertions.isTrue

return {
    ["FRAME and BORDER overlays target existing widgets"] = function()
        assertTrue(NivUI.OverlayLogic.IsTransformative("FRAME"))
        assertTrue(NivUI.OverlayLogic.IsTransformative("BORDER"))
    end,

    ["ICON and COLOR overlays remain additive"] = function()
        assertFalse(NivUI.OverlayLogic.IsTransformative("ICON"))
        assertFalse(NivUI.OverlayLogic.IsTransformative("COLOR"))
        assertFalse(NivUI.OverlayLogic.IsTransformative(nil))
        assertFalse(NivUI.OverlayLogic.IsTransformative("garbage"))
    end,
}
