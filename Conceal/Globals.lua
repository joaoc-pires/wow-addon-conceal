local addonName, addon = ...;

addon.defaults = {
    ["options"] = {
        ["interactive"] = true,
        ["health"] = 100,
        ["power"] = false,
        ["mouseover"] = true,
        ["alpha"] = 30,
        ["ActionBar1"] = true,
        ["ActionBar2"] = true,
        ["ActionBar3"] = true,
        ["ActionBar4"] = true,
        ["ActionBar5"] = true,
        ["ActionBar6"] = true,
        ["ActionBar7"] = true,
        ["ActionBar8"] = true
    }
};

actionBar2 = MultiBarBottomLeft
actionBar3 = MultiBarBottomRight
actionBar4 = MultiBarRight 
actionBar5 = MultiBarLeft
actionBar6 = MultiBar5
actionBar7 = MultiBar6
actionBar8 = MultiBar7

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
