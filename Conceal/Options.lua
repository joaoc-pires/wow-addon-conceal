-- Conceal: settings panel UI, built from the shared element descriptor (Fade.lua).

function Conceal:SetupSubCategoryCheckbox(key, name, tooltip, defaultValue, category)
    local setting = Settings.RegisterAddOnSetting(
        category,
        "conceal_" .. key,
        key,
        Conceal.settingsDB,
        type(defaultValue),
        name,
        defaultValue)

    local initializer = Settings.CreateCheckbox(category, setting, tooltip)

    setting:SetValueChangedCallback(function()
        -- Conceal.settingsDB[key] is already updated by the Settings system
        Conceal:UpdateUI()
    end)

    return setting, initializer
end

function Conceal:CreateSettingsWindow()
    -- This is an implementation detail for 2.1 when support for Action Target Mode was added
    if not (Conceal.settingsDB["actionTargetMode"]) then
        Conceal.settingsDB["actionTargetMode"] = false
    end

    -- Adds the main Category
    local concealOptions, concealLayout = Settings.RegisterVerticalLayoutCategory("Conceal")
    concealOptions.ID = "Conceal"
    Settings.RegisterAddOnCategory(concealOptions)

    -- Sliders stay hand-written: they're not checkboxes and don't fit the descriptor mold.
    do
        local name = "Opacity"
        local variable = "conceal_alpha"
        local variableKey = "alpha"
        local tooltip = "Opacity applied to UI elements while they are concealed."
        local defaultValue = Conceal.settingsDB["alpha"]
        local minValue = 0
        local maxValue = 100
        local step = 5

        local setting = Settings.RegisterAddOnSetting(concealOptions, variable, variableKey, Conceal.settingsDB, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(function(setting, value)
            -- Store the raw 0..100 value; GetConcealAlpha owns normalization at tick time.
            Conceal.settingsDB["alpha"] = value
            Conceal:UpdateUI()
        end)

        local options = Settings.CreateSliderOptions(minValue, maxValue, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        Settings.CreateSlider(concealOptions, setting, options, tooltip)
    end
    do
        local name = "Fade In Time"
        local variable = "conceal_animationDuration"
        local variableKey = "animationDuration"
        local tooltip = "Duration of the fade animation when an element becomes fully visible."
        local defaultValue = Conceal.settingsDB["animationDuration"]
        local minValue = 0
        local maxValue = 2
        local step = 0.25

        local setting = Settings.RegisterAddOnSetting(concealOptions, variable, variableKey, Conceal.settingsDB, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(function(setting, value)
            Conceal.settingsDB[setting.variableKey] = value
        end)

        local options = Settings.CreateSliderOptions(minValue, maxValue, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        Settings.CreateSlider(concealOptions, setting, options, tooltip)
    end
    do
        local name = "Fade Out Time"
        local variable = "conceal_fadeOutDuration"
        local variableKey = "fadeOutDuration"
        local tooltip = "Duration of the fade animation when an element returns to its concealed state."
        local defaultValue = Conceal.settingsDB[variableKey]
        local minValue = 0
        local maxValue = 2
        local step = 0.25

        local setting = Settings.RegisterAddOnSetting(concealOptions, variable, variableKey, Conceal.settingsDB, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(function(setting, value)
            Conceal.settingsDB[setting.variableKey] = value
        end)

        local options = Settings.CreateSliderOptions(minValue, maxValue, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
        Settings.CreateSlider(concealOptions, setting, options, tooltip)
    end

    -- Sub-categories, created + registered up front to preserve the panel's order.
    local framesCategory, framesLayout = Settings.RegisterVerticalLayoutSubcategory(concealOptions, "Combat Elements");
    Settings.RegisterAddOnCategory(framesCategory)
    local cdManagerCategory, cdManagerLayout = Settings.RegisterVerticalLayoutSubcategory(concealOptions, "Cooldown Manager");
    Settings.RegisterAddOnCategory(cdManagerCategory)
    local barsCategory, barLayout = Settings.RegisterVerticalLayoutSubcategory(concealOptions, "Action Bars");
    Settings.RegisterAddOnCategory(barsCategory)
    local extraCategory, extraLayout = Settings.RegisterVerticalLayoutSubcategory(concealOptions, "Extra Elements");
    Settings.RegisterAddOnCategory(extraCategory)

    local groups = {
        main     = { category = concealOptions,   layout = concealLayout },
        frames   = { category = framesCategory,    layout = framesLayout },
        cooldown = { category = cdManagerCategory, layout = cdManagerLayout },
        bars     = { category = barsCategory,      layout = barLayout },
        extra    = { category = extraCategory,     layout = extraLayout },
    }

    for _, e in ipairs(Conceal.elements) do
        if e.settings ~= false then
            local group = groups[e.cat]
            if e.header then
                group.layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(e.header[1], e.header[2] or ""));
            end
            local _, parentInitializer = Conceal:SetupSubCategoryCheckbox(e.key, e.name, e.tooltip, Conceal.settingsDB[e.key], group.category)
            if e.combat then
                local _, combatInitializer = Conceal:SetupSubCategoryCheckbox(e.combat.key, e.combat.name, e.combat.tooltip, Conceal.settingsDB[e.combat.key], group.category)
                local parentKey = e.key
                combatInitializer:Indent()
                combatInitializer:SetParentInitializer(parentInitializer, function() return Conceal.settingsDB[parentKey] end)
            end
        end
    end
end
