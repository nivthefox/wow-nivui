-- tests/test_overlay_classify.lua
-- Contract tests for NivUI.OverlayLogic.IsTransformative.

return {
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
