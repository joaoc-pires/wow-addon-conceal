local addonName, addon = ...;

addon.defaults = {
    ["options"] = {
        ["interactive"] = true,
        ["health"] = 100,
        ["power"] = false,
        ["mouseover"] = true,
        ["alpha"] = 30
    }
};

addon.decayPowerTypes = {
    ["RAGE"] = true,
    ["COMBO_POINTS"] = true,
    ["RUNIC_POWER"] = true,
    ["SOUL_SHARDS"] = true,
    ["LUNAR_POWER"] = true,
    ["HOLY_POWER"] = true,
    ["MAELSTROM"] = true,
    ["CHI"] = true,
    ["INSANITY"] = true,
    ["ARCANE_CHARGES"] = true,
    ["FURY"] = true,
    ["PAIN"] = true
};
