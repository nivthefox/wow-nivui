local _, NivUI = ...

local MissingRaidBuffs = {
    DEFINITIONS = {
        {
            name = "Arcane Intellect",
            providerClass = "MAGE",
            iconSpellID = 1459,
            spellIDs = { 1459, 432778 },
        },
        {
            name = "Skyfury",
            providerClass = "SHAMAN",
            iconSpellID = 462854,
            spellIDs = { 462854 },
        },
        {
            name = "Battle Shout",
            providerClass = "WARRIOR",
            iconSpellID = 6673,
            spellIDs = { 6673 },
        },
        {
            name = "Power Word: Fortitude",
            providerClass = "PRIEST",
            iconSpellID = 21562,
            spellIDs = { 21562 },
        },
        {
            name = "Mark of the Wild",
            providerClass = "DRUID",
            iconSpellID = 1126,
            spellIDs = { 1126, 432661 },
        },
        {
            name = "Blessing of the Bronze",
            providerClass = "EVOKER",
            iconSpellID = 364342,
            spellIDs = {
                381732, 381741, 381746, 381748, 381749, 381750, 381751,
                381752, 381753, 381754, 381756, 381757, 381758,
            },
        },
    },
}

function MissingRaidBuffs:GetDefinitionsForClasses(classes)
    if type(classes) ~= "table" then
        return {}
    end

    local definitions = {}
    for _, definition in ipairs(self.DEFINITIONS) do
        if classes[definition.providerClass] then
            definitions[#definitions + 1] = definition
        end
    end
    return definitions
end

NivUI.Filters.MissingRaidBuffs = MissingRaidBuffs
