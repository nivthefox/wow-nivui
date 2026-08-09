local _, NivUI = ...

NivUI.Config = NivUI.Config or {}

local ConfigDeletion = {}
NivUI.ConfigDeletion = ConfigDeletion

local POPUP_NAME = "NIVUI_CONFIRM_DELETE"

local function GetNames(references, field)
    local names = {}
    for _, reference in ipairs(references) do
        names[#names + 1] = tostring(field and reference[field] or reference)
    end
    return names
end

local function DescribeNamedReferences(prefix, references, field)
    if #references == 0 then
        return ""
    end
    return prefix .. table.concat(GetNames(references, field), ", ") .. "."
end

function ConfigDeletion.DescribeProfile(database, profileName)
    local references = NivUI.ReferenceIntegrity.FindProfileReferences(database, profileName)
    if #references == 0 then
        return ""
    end

    local mappings = {}
    for _, reference in ipairs(references) do
        mappings[#mappings + 1] = string.format("%s (spec %s)",
            tostring(reference.characterKey), tostring(reference.specID))
    end
    return "This also clears specialization mappings: " .. table.concat(mappings, ", ") .. "."
end

function ConfigDeletion.DescribeStyle(profile, styleName)
    local references = NivUI.ReferenceIntegrity.FindStyleReferences(profile, styleName)
    local dependents = {}

    if #references.assignments > 0 then
        dependents[#dependents + 1] = "unit frames: " .. table.concat(references.assignments, ", ")
    end
    if #references.customRaidGroups > 0 then
        dependents[#dependents + 1] = "custom raid groups: "
            .. table.concat(GetNames(references.customRaidGroups), ", ")
    end
    if #dependents == 0 then
        return ""
    end

    local fallbackStyle = NivUI.ReferenceIntegrity.GetFallbackStyle(profile, styleName)
    return string.format("This also reassigns these references to style '%s': %s.",
        tostring(fallbackStyle), table.concat(dependents, "; "))
end

function ConfigDeletion.DescribeFilter(profile, filterName)
    local references = NivUI.ReferenceIntegrity.FindFilterReferences(profile, filterName)
    return DescribeNamedReferences("This also removes the filter from overlays: ",
        references, "overlayName")
end

function ConfigDeletion.DescribeOverlay(profile, overlayName)
    local references = NivUI.ReferenceIntegrity.FindOverlayReferences(profile, overlayName)
    return DescribeNamedReferences("This also removes the overlay from styles: ", references)
end

StaticPopupDialogs[POPUP_NAME] = {
    text = "Delete %s? This cannot be undone.%s",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function(_dialog, data)
        if type(data) == "table" and type(data.onAccept) == "function" then
            data.onAccept()
        end
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    showAlert = 1,
}

function ConfigDeletion.Request(objectType, name, consequences, onAccept)
    if type(objectType) ~= "string" or objectType == "" then
        return false
    end
    if type(name) ~= "string" or name == "" then
        return false
    end
    if type(onAccept) ~= "function" then
        return false
    end

    local details = ""
    if type(consequences) == "string" and consequences ~= "" then
        details = "\n\n" .. consequences
    end

    local target = string.format("%s '%s'", objectType, name)
    return StaticPopup_Show(POPUP_NAME, target, details, { onAccept = onAccept }) ~= nil
end

NivUI:RegisterConfigPopup(POPUP_NAME)
