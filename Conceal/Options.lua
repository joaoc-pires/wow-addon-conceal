local addonName, addon = ...;
local P = "player";

addon.setupOptionFrame = function()
    local category = Settings.RegisterVerticalLayoutCategory("Conceal")
    do
        local variable1 = "interactive"
        local name1 = "Interactive"
        local tooltip1 = "Toggle player frame interactivity when hidden."
        local defaultValue1 = true
    
        local interactive = Settings.RegisterProxySetting(category, variable1, ConcealDB, type(defaultValue1), name1, defaultValue1)
        Settings.CreateCheckBox(category, interactive, tooltip1)
    end
    do
        local variable2 = "mouseover"
        local name2 = "Mouse Over"
        local tooltip2 = "Show the player frame on mouseover."
        local defaultValue2 = true
        local mouseover = Settings.RegisterProxySetting(category, variable2, ConcealDB, type(defaultValue2), name2, defaultValue2)
        Settings.CreateCheckBox(category, mouseover, tooltip2)
    end
    do
        local variable3 = "alpha"
        local name3 = "Alpha"
        local tooltip3 = "The frame alpha when not selected."
        local defaultValue3 = 30
        local minValue3 = 0
        local maxValue3 = 100
        local step3 = 5
        local alpha = Settings.RegisterProxySetting(category, variable3, ConcealDB, type(defaultValue3), name3, defaultValue3)
        local options = Settings.CreateSliderOptions(minValue3, maxValue3, step3)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        Settings.CreateSlider(category, alpha, options, tooltip3)
    end
    do
        local variable4 = "health"
        local name4 = "Health Trashold"
        local tooltip4 = "The player health % below which the player frame will be shown."
        local defaultValue4 = 100
        local minValue4 = 10
        local maxValue4 = 100
        local step4 = 5
        local health = Settings.RegisterProxySetting(category, variable4, ConcealDB, type(defaultValue4), name4, defaultValue4)
        local healthOptions = Settings.CreateSliderOptions(minValue4, maxValue4, step4)
        healthOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        Settings.CreateSlider(category, health, healthOptions, tooltip4)
    end
    do
        local variable12 = "ActionBar1"
        local name12 = "Action Bar 1"
        local tooltip12 = "Apply Options to Action Bar 1"
        local defaultValue12 = true
    
        local actionBar1Option = Settings.RegisterProxySetting(category, variable12, ConcealDB, type(defaultValue12), name12, defaultValue12)
        Settings.CreateCheckBox(category, actionBar1Option, tooltip12)
    end
    do
        local variable5 = "ActionBar2"
        local name5 = "Action Bar 2"
        local tooltip5 = "Apply Options to Action Bar 2"
        local defaultValue5 = true
    
        local actionBar2Option = Settings.RegisterProxySetting(category, variable5, ConcealDB, type(defaultValue5), name5, defaultValue5)
        Settings.CreateCheckBox(category, actionBar2Option, tooltip5)
    end
    do
        local variable6 = "ActionBar3"
        local name6 = "Action Bar 3"
        local tooltip6 = "Apply Options to Action Bar 3"
        local defaultValue6 = true
    
        local actionBar3Option = Settings.RegisterProxySetting(category, variable6, ConcealDB, type(defaultValue6), name6, defaultValue6)
        Settings.CreateCheckBox(category, actionBar3Option, tooltip6)
    end
    do
        local variable7 = "ActionBar4"
        local name7 = "Action Bar 4"
        local tooltip7 = "Apply Options to Action Bar 4"
        local defaultValue7 = true
    
        local actionBar4Option = Settings.RegisterProxySetting(category, variable7, ConcealDB, type(defaultValue7), name7, defaultValue7)
        Settings.CreateCheckBox(category, actionBar4Option, tooltip7)
    end
    do
        local variable8 = "ActionBar5"
        local name8 = "Action Bar 5"
        local tooltip8 = "Apply Options to Action Bar 5"
        local defaultValue8 = true
    
        local actionBar5Option = Settings.RegisterProxySetting(category, variable8, ConcealDB, type(defaultValue8), name8, defaultValue8)
        Settings.CreateCheckBox(category, actionBar5Option, tooltip8)
    end
    do
        local variable9 = "ActionBar6"
        local name9 = "Action Bar 6"
        local tooltip9 = "Apply Options to Action Bar 6"
        local defaultValue9 = true
    
        local actionBar6Option = Settings.RegisterProxySetting(category, variable9, ConcealDB, type(defaultValue9), name9, defaultValue9)
        Settings.CreateCheckBox(category, actionBar6Option, tooltip9)
    end
    do
        local variable10 = "ActionBar7"
        local name10 = "Action Bar 7"
        local tooltip10 = "Apply Options to Action Bar 7"
        local defaultValue10 = true
    
        local actionBar7Option = Settings.RegisterProxySetting(category, variable10, ConcealDB, type(defaultValue10), name10, defaultValue10)
        Settings.CreateCheckBox(category, actionBar7Option, tooltip10)
    end
    do
        local variable11 = "ActionBar8"
        local name11 = "Action Bar 8"
        local tooltip11 = "Apply Options to Action Bar 8"
        local defaultValue11 = true
    
        local actionBar8Option = Settings.RegisterProxySetting(category, variable11, ConcealDB, type(defaultValue11), name11, defaultValue11)
        Settings.CreateCheckBox(category, actionBar8Option, tooltip11)
    end
    Settings.RegisterAddOnCategory(category)
end