local _, NivUI = ...

local ReferenceIntegrity = {}
NivUI.ReferenceIntegrity = ReferenceIntegrity

local function SortedKeys(values, excludedKey)
    local keys = {}
    if type(values) ~= "table" then
        return keys
    end

    for key in pairs(values) do
        if key ~= excludedKey then
            keys[#keys + 1] = key
        end
    end
    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)
    return keys
end

local function BuildBuiltinFilterSet(entries)
    local builtins = {}
    if type(entries) ~= "table" then
        return builtins
    end

    for key, entry in pairs(entries) do
        if type(entry) == "table" and type(entry.token) == "string" then
            builtins[entry.token] = true
        elseif entry == true and type(key) == "string" then
            builtins[key] = true
        end
    end
    return builtins
end

function ReferenceIntegrity.GetFallbackStyle(profile, excludedName)
    local styles = type(profile) == "table" and profile.unitFrameStyles or nil
    return SortedKeys(styles, excludedName)[1]
end

function ReferenceIntegrity.FindStyleReferences(profile, styleName)
    local references = {
        assignments = {},
        customRaidGroups = {},
    }
    if type(profile) ~= "table" then
        return references
    end

    if type(profile.unitFrameAssignments) == "table" then
        for frameType, assignedStyle in pairs(profile.unitFrameAssignments) do
            if assignedStyle == styleName then
                references.assignments[#references.assignments + 1] = frameType
            end
        end
        table.sort(references.assignments)
    end

    if type(profile.customRaidGroups) == "table" then
        for groupId, group in pairs(profile.customRaidGroups) do
            if type(group) == "table" and group.styleName == styleName then
                references.customRaidGroups[#references.customRaidGroups + 1] = groupId
            end
        end
        table.sort(references.customRaidGroups)
    end

    return references
end

function ReferenceIntegrity.ReplaceStyleReferences(profile, oldName, newName)
    local references = ReferenceIntegrity.FindStyleReferences(profile, oldName)

    for _, frameType in ipairs(references.assignments) do
        profile.unitFrameAssignments[frameType] = newName
    end
    for _, groupId in ipairs(references.customRaidGroups) do
        profile.customRaidGroups[groupId].styleName = newName
    end

    return references
end

function ReferenceIntegrity.FindProfileReferences(database, profileName)
    local references = {}
    local charMeta = type(database) == "table" and database.charMeta or nil
    if type(charMeta) ~= "table" then
        return references
    end

    for characterKey, character in pairs(charMeta) do
        local mappings = type(character) == "table" and character.specProfileMap or nil
        if type(mappings) == "table" then
            for specID, mappedProfile in pairs(mappings) do
                if mappedProfile == profileName then
                    references[#references + 1] = {
                        characterKey = characterKey,
                        specID = specID,
                    }
                end
            end
        end
    end

    table.sort(references, function(left, right)
        if left.characterKey ~= right.characterKey then
            return tostring(left.characterKey) < tostring(right.characterKey)
        end
        return tostring(left.specID) < tostring(right.specID)
    end)
    return references
end

function ReferenceIntegrity.ReplaceProfileReferences(database, oldName, newName)
    local references = ReferenceIntegrity.FindProfileReferences(database, oldName)

    for _, reference in ipairs(references) do
        database.charMeta[reference.characterKey].specProfileMap[reference.specID] = newName
    end

    return references
end

function ReferenceIntegrity.FindFilterReferences(profile, filterName)
    local references = {}
    local overlays = type(profile) == "table" and profile.overlays or nil
    if type(overlays) ~= "table" then
        return references
    end

    for overlayName, overlay in pairs(overlays) do
        if type(overlay) == "table" then
            local usesAllow = type(overlay.allow) == "table" and overlay.allow[filterName] ~= nil
            local usesBlock = type(overlay.block) == "table" and overlay.block[filterName] ~= nil
            if usesAllow or usesBlock then
                references[#references + 1] = {
                    overlayName = overlayName,
                    allow = usesAllow,
                    block = usesBlock,
                }
            end
        end
    end

    table.sort(references, function(left, right)
        return left.overlayName < right.overlayName
    end)
    return references
end

function ReferenceIntegrity.RemoveFilterReferences(profile, filterName)
    local references = ReferenceIntegrity.FindFilterReferences(profile, filterName)

    for _, reference in ipairs(references) do
        local overlay = profile.overlays[reference.overlayName]
        if reference.allow then
            overlay.allow[filterName] = nil
        end
        if reference.block then
            overlay.block[filterName] = nil
        end
    end

    return references
end

function ReferenceIntegrity.FindOverlayReferences(profile, overlayName)
    local references = {}
    local styles = type(profile) == "table" and profile.unitFrameStyles or nil
    if type(styles) ~= "table" then
        return references
    end

    for styleName, style in pairs(styles) do
        local selections = type(style) == "table" and style.overlays or nil
        if type(selections) == "table" and selections[overlayName] ~= nil then
            references[#references + 1] = styleName
        end
    end

    table.sort(references)
    return references
end

function ReferenceIntegrity.RemoveOverlayReferences(profile, overlayName)
    local references = ReferenceIntegrity.FindOverlayReferences(profile, overlayName)

    for _, styleName in ipairs(references) do
        profile.unitFrameStyles[styleName].overlays[overlayName] = nil
    end

    return references
end

local function RepairStyleReferences(profile, fallbackStyle)
    local repaired = 0
    if type(profile.unitFrameAssignments) == "table" then
        for frameType, styleName in pairs(profile.unitFrameAssignments) do
            if profile.unitFrameStyles[styleName] == nil then
                profile.unitFrameAssignments[frameType] = fallbackStyle
                repaired = repaired + 1
            end
        end
    end

    if type(profile.customRaidGroups) == "table" then
        for _, group in pairs(profile.customRaidGroups) do
            if type(group) == "table" and profile.unitFrameStyles[group.styleName] == nil then
                group.styleName = fallbackStyle
                repaired = repaired + 1
            end
        end
    end
    return repaired
end

local function RepairFilterReferences(profile, builtinFilters)
    local repaired = 0
    for _, overlay in pairs(profile.overlays) do
        if type(overlay) == "table" then
            for _, field in ipairs({ "allow", "block" }) do
                local selections = overlay[field]
                if type(selections) == "table" then
                    for filterName in pairs(selections) do
                        if not builtinFilters[filterName] and profile.customFilters[filterName] == nil then
                            selections[filterName] = nil
                            repaired = repaired + 1
                        end
                    end
                end
            end
        end
    end
    return repaired
end

local function RepairOverlayReferences(profile)
    local repaired = 0
    for _, style in pairs(profile.unitFrameStyles) do
        local selections = type(style) == "table" and style.overlays or nil
        if type(selections) == "table" then
            for overlayName in pairs(selections) do
                if profile.overlays[overlayName] == nil then
                    selections[overlayName] = nil
                    repaired = repaired + 1
                end
            end
        end
    end
    return repaired
end

function ReferenceIntegrity.RepairProfile(profile, defaultStyle, builtinEntries)
    if type(profile) ~= "table" then
        return nil
    end

    if type(profile.unitFrameStyles) ~= "table" then
        profile.unitFrameStyles = {}
    end
    if next(profile.unitFrameStyles) == nil then
        profile.unitFrameStyles.Default = NivUI.DeepCopy(defaultStyle or {})
    end
    if type(profile.customFilters) ~= "table" then
        profile.customFilters = {}
    end
    if type(profile.overlays) ~= "table" then
        profile.overlays = {}
    end

    local fallbackStyle = ReferenceIntegrity.GetFallbackStyle(profile)
    local builtinFilters = BuildBuiltinFilterSet(builtinEntries)
    return {
        fallbackStyle = fallbackStyle,
        styles = RepairStyleReferences(profile, fallbackStyle),
        filters = RepairFilterReferences(profile, builtinFilters),
        overlays = RepairOverlayReferences(profile),
    }
end

function ReferenceIntegrity.RepairDatabase(database, defaultStyle, builtinEntries)
    if type(database) ~= "table" or type(database.profiles) ~= "table" then
        return nil
    end

    local report = {
        profiles = {},
        specializationMappings = 0,
    }
    for profileName, profile in pairs(database.profiles) do
        report.profiles[profileName] = ReferenceIntegrity.RepairProfile(profile, defaultStyle, builtinEntries)
    end

    if type(database.charMeta) ~= "table" then
        return report
    end

    for _, character in pairs(database.charMeta) do
        local mappings = type(character) == "table" and character.specProfileMap or nil
        if type(mappings) == "table" then
            for specID, profileName in pairs(mappings) do
                if type(profileName) ~= "string" or database.profiles[profileName] == nil then
                    mappings[specID] = nil
                    report.specializationMappings = report.specializationMappings + 1
                end
            end
        end
    end
    return report
end

function NivUI:RepairProfileReferences(profile)
    local defaultStyle = self.UnitFrames and self.UnitFrames.DEFAULT_STYLE or {}
    local builtinEntries = self.Filters and self.Filters.BUILTIN or {}
    return ReferenceIntegrity.RepairProfile(profile, defaultStyle, builtinEntries)
end

function NivUI:RepairReferenceIntegrity()
    if type(NivUI_DB) ~= "table" then
        return nil
    end

    local defaultStyle = self.UnitFrames and self.UnitFrames.DEFAULT_STYLE or {}
    local builtinEntries = self.Filters and self.Filters.BUILTIN or {}
    return ReferenceIntegrity.RepairDatabase(NivUI_DB, defaultStyle, builtinEntries)
end
