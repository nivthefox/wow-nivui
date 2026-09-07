local _, assertions = ...
local assertTrue = assertions.isTrue

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."
local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function readFile(relativePath)
    local file = assert(io.open(addonRoot .. "/" .. relativePath, "r"))
    local contents = file:read("*a")
    file:close()
    return contents
end

local function getRegisteredClassBarNames()
    local manifest = readFile("NivUI.toc")
    local names = {}

    for relativePath in manifest:gmatch("([^\r\n]+%.lua)") do
        relativePath = relativePath:gsub("\\", "/")
        if relativePath:match("^modules/bars/") then
            local source = readFile(relativePath)
            if source:find("RegisterClassBar", 1, true) then
                local displayName = source:match('displayName%s*=%s*"([^"]+)"')
                assert(displayName, "registered class bar has no displayName: " .. relativePath)
                names[#names + 1] = displayName
            end
        end
    end

    table.sort(names)
    return names
end

return {
    ["README lists every registered class bar"] = function()
        local readme = readFile("README.md")

        for _, displayName in ipairs(getRegisteredClassBarNames()) do
            assertTrue(readme:find(displayName, 1, true) ~= nil,
                "README is missing registered class bar " .. displayName)
        end
    end,

}
