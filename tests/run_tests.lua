-- tests/run_tests.lua
-- Headless test runner for NivUI pure-logic modules.
--
-- Invocation (from addon root):
--   luajit tests/run_tests.lua
--   C:\Users\kevin\AppData\Local\Programs\LuaJIT\bin\luajit.exe tests/run_tests.lua
--
-- Each tests/test_*.lua file must return a table of the form:
--   { ["test name"] = function() ... end }
-- Tests pass by returning normally; they fail by calling error().

local scriptPath = arg[0] or "tests/run_tests.lua"
local testsDir = scriptPath:match("^(.*)[/\\][^/\\]+$") or "."

local addonRoot = testsDir:match("^(.*)[/\\][^/\\]+$") or "."

local function serialize(v, depth)
    depth = depth or 0
    local t = type(v)
    if t == "nil" then
        return "nil"
    elseif t == "boolean" then
        return tostring(v)
    elseif t == "number" then
        return tostring(v)
    elseif t == "string" then
        return string.format("%q", v)
    elseif t == "table" then
        if depth > 4 then
            return "{...}"
        end
        local parts = {}
        local maxN = 0
        for i, _ in ipairs(v) do
            maxN = i
        end
        for i = 1, maxN do
            parts[#parts + 1] = serialize(v[i], depth + 1)
        end
        for k, val in pairs(v) do
            if type(k) ~= "number" or k < 1 or k > maxN then
                parts[#parts + 1] = string.format("[%s]=%s",
                    serialize(k, depth + 1), serialize(val, depth + 1))
            end
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        return "<" .. t .. ">"
    end
end

local function assertEquals(actual, expected, msg)
    if actual ~= expected then
        error(string.format("%sexpected %s, got %s",
            msg and (msg .. ": ") or "",
            serialize(expected),
            serialize(actual)), 2)
    end
end

local function assertNear(actual, expected, eps, msg)
    if math.abs(actual - expected) > eps then
        error(string.format("%sexpected %s near %s (eps %s), got %s",
            msg and (msg .. ": ") or "",
            serialize(expected),
            serialize(expected),
            serialize(eps),
            serialize(actual)), 2)
    end
end

local function assertTrue(v, msg)
    if not v then
        error(string.format("%sexpected true, got %s",
            msg and (msg .. ": ") or "",
            serialize(v)), 2)
    end
end

local function assertFalse(v, msg)
    if v then
        error(string.format("%sexpected false, got %s",
            msg and (msg .. ": ") or "",
            serialize(v)), 2)
    end
end

local function assertNil(v, msg)
    if v ~= nil then
        error(string.format("%sexpected nil, got %s",
            msg and (msg .. ": ") or "",
            serialize(v)), 2)
    end
end

local function assertNotNil(v, msg)
    if v == nil then
        error(string.format("%sexpected non-nil value%s",
            msg and (msg .. ": ") or "",
            ""), 2)
    end
end

local function tableEquals(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then
        return a == b
    end
    for k, v in pairs(a) do
        if not tableEquals(v, b[k]) then
            return false
        end
    end
    for k, _ in pairs(b) do
        if a[k] == nil then
            return false
        end
    end
    return true
end

local function assertTableEquals(actual, expected, msg)
    if not tableEquals(actual, expected) then
        error(string.format("%sexpected %s, got %s",
            msg and (msg .. ": ") or "",
            serialize(expected),
            serialize(actual)), 2)
    end
end

local function assertError(fn, msg)
    local ok = pcall(fn)
    if ok then
        error(string.format("%sexpected an error but none was raised",
            msg and (msg .. ": ") or ""), 2)
    end
end

local addonName = "NivUI"
local addonNamespace = {}

local function loadChunk(path, environment, ...)
    local chunk, loadErr = loadfile(path)
    if not chunk then
        error(loadErr, 0)
    end
    if environment then
        setfenv(chunk, environment)
    end
    return chunk(...)
end

local stubsPath = testsDir .. "/wow_stubs.lua"
local stubsOk, stubs = pcall(loadChunk, stubsPath, nil, addonName, addonNamespace)
if not stubsOk then
    io.stderr:write("FATAL: could not load wow_stubs.lua: " .. tostring(stubs) .. "\n")
    os.exit(1)
end

local assertions = {
    equals = assertEquals,
    near = assertNear,
    isTrue = assertTrue,
    isFalse = assertFalse,
    isNil = assertNil,
    isNotNil = assertNotNil,
    tablesEqual = assertTableEquals,
    raisesError = assertError,
}

local testEnvironment = setmetatable({
    MinimalSliderWithSteppersMixin = {
        Event = {
            OnValueChanged = "OnValueChanged",
        },
    },
    strtrim = stubs.strtrim,
}, { __index = _G })

local modules = {
    addonRoot .. "/modules/config/Controls.lua",
    addonRoot .. "/modules/config/TabLayout.lua",
    addonRoot .. "/modules/config/SettingsPanel.lua",
    addonRoot .. "/modules/filters/SpellFilters.lua",
    addonRoot .. "/modules/filters/MissingRaidBuffs.lua",
    addonRoot .. "/modules/overlays/OverlayLogic.lua",
    addonRoot .. "/modules/overlays/Overlays.lua",
    addonRoot .. "/modules/unitframes/Defaults.lua",
    addonRoot .. "/modules/unitframes/WidgetConfigs.lua",
    addonRoot .. "/modules/nicknames/Nicknames.lua",
}

for _, modulePath in ipairs(modules) do
    local loadOk, loadErr = pcall(loadChunk, modulePath, testEnvironment, addonName, addonNamespace)
    if not loadOk then
        io.stderr:write(string.format(
            "WARNING: could not load module %s: %s\n", modulePath, tostring(loadErr)))
    end
end

local function discoverTestFiles(dir)
    local files = {}
    local handle = io.popen('dir /b "' .. dir .. '" 2>nul')
    if handle then
        local output = handle:read("*a")
        handle:close()
        if output and output ~= "" then
            for name in output:gmatch("[^\r\n]+") do
                if name:match("^test_.*%.lua$") then
                    files[#files + 1] = name
                end
            end
        end
    end
    if #files == 0 then
        handle = io.popen('ls "' .. dir .. '"')
        if handle then
            local output = handle:read("*a")
            handle:close()
            for name in output:gmatch("[^\r\n]+") do
                if name:match("^test_.*%.lua$") then
                    files[#files + 1] = name
                end
            end
        end
    end
    table.sort(files)
    return files
end

local testFiles = discoverTestFiles(testsDir)

local function getSortedTestNames(tests)
    local names = {}
    for name in pairs(tests) do
        names[#names + 1] = name
    end
    table.sort(names)
    return names
end

local function runTestCase(filename, name, test)
    local ok, testErr = pcall(test)
    if not ok then
        print(string.format("FAIL %s:%s\n  %s", filename, name, tostring(testErr)))
        return false
    end

    print(string.format("PASS %s:%s", filename, name))
    return true
end

local function loadTests(filename)
    local filepath = testsDir .. "/" .. filename
    local chunk, loadErr = loadfile(filepath)
    if not chunk then
        return nil, "load error", loadErr
    end

    setfenv(chunk, testEnvironment)
    local ok, tests = pcall(chunk, addonNamespace, assertions)
    if not ok then
        return nil, "runtime error", tests
    end
    if type(tests) ~= "table" then
        return nil, "test file did not return a table"
    end
    return tests
end

local function runTestFile(filename)
    local tests, errorKind, testError = loadTests(filename)
    if not tests then
        local details = testError and (" " .. tostring(testError)) or ""
        print(string.format("FAIL %s: (%s)%s", filename, errorKind, details))
        return 0, 1
    end

    local passed = 0
    local failed = 0
    for _, name in ipairs(getSortedTestNames(tests)) do
        if runTestCase(filename, name, tests[name]) then
            passed = passed + 1
        else
            failed = failed + 1
        end
    end
    return passed, failed
end

local totalPassed = 0
local totalFailed = 0
for _, filename in ipairs(testFiles) do
    local passed, failed = runTestFile(filename)
    totalPassed = totalPassed + passed
    totalFailed = totalFailed + failed
end

print(string.format("\n%d passed, %d failed", totalPassed, totalFailed))

if totalFailed > 0 then
    os.exit(1)
end
os.exit(0)
