local _, assertions = ...
local assertNotNil = assertions.isNotNil

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

return {
    ["every Lua file in the addon manifest compiles"] = function()
        local manifest = io.open(addonRoot .. "/NivUI.toc", "r")
        assertNotNil(manifest, "addon manifest")

        for line in manifest:lines() do
            local luaPath = line:match("^%s*(.-%.lua)%s*$")
            if luaPath then
                luaPath = luaPath:gsub("\\", "/")
                local chunk, loadError = loadfile(addonRoot .. "/" .. luaPath)
                assertNotNil(chunk, luaPath .. ": " .. tostring(loadError))
            end
        end

        manifest:close()
    end,
}
