local Conceal = CreateFrame("Frame")
local settingsDB = {}
local defaults = {
    interactive = true,
    health = 100,
    power = false,
    mouseover = true,
    alpha = 30,
    animationDuration = 0.25,
    fadeOutDuration = 0.25,
    buffFrame = false,
    debuffFrame = false,
    actionBar1 = true,
    actionBar1ConcealDuringCombat = false,
    actionBar2 = true,
    actionBar2ConcealDuringCombat = false,
    actionBar3 = true,
    actionBar3ConcealDuringCombat = false,
    actionBar4 = true,
    actionBar4ConcealDuringCombat = false,
    actionBar5 = true,
    actionBar5ConcealDuringCombat = false,
    actionBar6 = true,
    actionBar6ConcealDuringCombat = false,
    actionBar7 = true,
    actionBar7ConcealDuringCombat = false,
    actionBar8 = true,
    actionBar8ConcealDuringCombat = false,
    petActionBar = true,
    petActionBarConcealDuringCombat = false,
    stanceBar = true,
    stanceBarConcealDuringCombat = false,
    selfFrame = true,
    selfFrameConcealDuringCombat = false,
    targetFrame = false,
    targetFrameConcealDuringCombat = false,
    microBar = false,
    microBarConcealDuringCombat = false,
    experience = false,
    experienceConcealDuringCombat = false,
    focusFrame = false,
    focusFrameConcealDuringCombat = false,
    castBar = false;
    objectiveTracker = false;
}

local isInCombat = false

ActionBar1 = MainMenuBar
ActionBar2 = MultiBarBottomLeft
ActionBar3 = MultiBarBottomRight
ActionBar4 = MultiBarRight 
ActionBar5 = MultiBarLeft
ActionBar6 = MultiBar5
ActionBar7 = MultiBar6
ActionBar8 = MultiBar7


function Conceal:UpdateUI() 
    -- this method is used to update which parts of the addon changed when the settings were changed
    if settingsDB["selfFrame"] then
        Conceal:FadeIn(PlayerFrame, true) 
        Conceal:FadeIn(PetFrame, true)
    else
        Conceal:FadeOut(PlayerFrame, true) 
        Conceal:FadeOut(PetFrame, true)
    end
    if settingsDB["targetFrame"] then Conceal:FadeIn(TargetFrame, true) else Conceal:FadeOut(TargetFrame, true) end
    if settingsDB["buffFrame"] then Conceal:FadeIn(BuffFrame, true) else Conceal:FadeOut(BuffFrame, true) end
    if settingsDB["debuffFrame"] then Conceal:FadeIn(DebuffFrame, true) else Conceal:FadeOut(DebuffFrame, true) end

    if settingsDB["debuffFrame"] then Conceal:FadeIn(DebuffFrame, true) else Conceal:FadeOut(DebuffFrame, true) end
    if settingsDB["debuffFrame"] then Conceal:FadeIn(DebuffFrame, true) else Conceal:FadeOut(DebuffFrame, true) end

    if settingsDB["actionBar1"] then Conceal:FadeIn(ActionBar1, true) else Conceal:FadeOut(ActionBar1, true) end
    if settingsDB["actionBar2"] then Conceal:FadeIn(ActionBar2, true) else Conceal:FadeOut(ActionBar2, true) end
    if settingsDB["actionBar3"] then Conceal:FadeIn(ActionBar3, true) else Conceal:FadeOut(ActionBar3, true) end
    if settingsDB["actionBar4"] then Conceal:FadeIn(ActionBar4, true) else Conceal:FadeOut(ActionBar4, true) end
    if settingsDB["actionBar5"] then Conceal:FadeIn(ActionBar5, true) else Conceal:FadeOut(ActionBar5, true) end
    if settingsDB["actionBar6"] then Conceal:FadeIn(ActionBar6, true) else Conceal:FadeOut(ActionBar6, true) end
    if settingsDB["actionBar7"] then Conceal:FadeIn(ActionBar7, true) else Conceal:FadeOut(ActionBar7, true) end
    if settingsDB["actionBar8"] then Conceal:FadeIn(ActionBar8, true) else Conceal:FadeOut(ActionBar8, true) end

    Conceal:RefreshGUI()
end

function Conceal:SetupSubCategoryCheckbox(variable, name, tooltip, defaultValue, subCategory)
	local setting = Settings.RegisterAddOnSetting(subCategory, name, variable, type(defaultValue), defaultValue)
    local initializer = Settings.CreateCheckbox(subCategory, setting, tooltip)
	Settings.SetOnValueChangedCallback(variable, function() 
		settingsDB[variable] = setting:GetValue()
        Conceal:UpdateUI()
	end) 
    return setting, initializer;
end

function Conceal:CreateSettingsWindow()
	-- Adds the main Category
	local concealOptions, concealLayout = Settings.RegisterVerticalLayoutCategory("Conceal")
	concealOptions.ID = "Conceal"
	Settings.RegisterAddOnCategory(concealOptions)
	do
		local variable = "Opacity"
		local name = "Opacity"
		local tooltip = "Conceal Opacity"
		local defaultValue = settingsDB["alpha"]
		local minValue = 0
		local maxValue = 100
		local step = 5
	
		local setting = Settings.RegisterAddOnSetting(concealOptions, name, variable, type(defaultValue), defaultValue)
		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
		Settings.CreateSlider(concealOptions, setting, options, tooltip)
		Settings.SetOnValueChangedCallback(variable, function() 
            local frameAlpha = setting:GetValue();
			settingsDB["alpha"] = frameAlpha
            if frameAlpha > 1 then frameAlpha = frameAlpha / 100; end
            -- This is to prevent frame drops
            if frameAlpha == 1 then frameAlpha = 0.99 end
			Conceal:UpdateFramesToAlpha(frameAlpha)
		end) 
	end
	do
		local variable = "FadeIn"
		local name = "Fade In duration"
		local tooltip = "Controls the animations duration for the fade in"
		local defaultValue = settingsDB["animationDuration"]
		local minValue = 0
		local maxValue = 2
		local step = 0.25
	
		local setting = Settings.RegisterAddOnSetting(concealOptions, name, variable, type(defaultValue), defaultValue)
		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
		Settings.CreateSlider(concealOptions, setting, options, tooltip)
		Settings.SetOnValueChangedCallback(variable, function() 
			settingsDB["animationDuration"] = setting:GetValue()
		end) 
	end
	do
		local variable = "FadeOut"
		local name = "Fade Out duration"
		local tooltip = "Controls the animations duration for the fade out"
		local defaultValue = settingsDB["fadeOutDuration"]
		local minValue = 0
		local maxValue = 2
		local step = 0.25
	
		local setting = Settings.RegisterAddOnSetting(concealOptions, name, variable, type(defaultValue), defaultValue)
		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
		Settings.CreateSlider(concealOptions, setting, options, tooltip)
		Settings.SetOnValueChangedCallback(variable, function() 
			settingsDB["fadeOutDuration"] = setting:GetValue()
		end) 
	end
	do
		local variable = "HealthThreshold"
		local name = "Health Threshold"
		local tooltip = "Controls the threshold which will trigger Conceal to show affected elements"
		local defaultValue = settingsDB["health"]
		local minValue = 0
		local maxValue = 100
		local step = 1
	
		local setting = Settings.RegisterAddOnSetting(concealOptions, name, variable, type(defaultValue), defaultValue)
		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
		Settings.CreateSlider(concealOptions, setting, options, tooltip)
		Settings.SetOnValueChangedCallback(variable, function() 
			settingsDB["health"] = setting:GetValue()
		end) 
	end
    	
    -- Adds Frames sub Category
	local framesCategory, framesLayout = Settings.RegisterVerticalLayoutSubcategory(concealOptions, "Combat Elements");
	Settings.RegisterAddOnCategory(framesCategory)
	framesLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Player Frames", ""));
	
    local selfFrameSetting, selfFrameInitializer = Conceal:SetupSubCategoryCheckbox("selfFrame","Enable Player frame","Conceal Player frame", settingsDB["selfFrame"], framesCategory)
	local selfFrameCombatSetting, selfFrameCombatInitializer = Conceal:SetupSubCategoryCheckbox("selfFrameConcealDuringCombat","Hide Player frame in combat","Only shows the player frame when the mouse is hovering", settingsDB["selfFrameConcealDuringCombat"], framesCategory)
	local function canSetFrameInCombat()
        return settingsDB["selfFrame"]
    end
    selfFrameCombatInitializer:Indent()
    selfFrameCombatInitializer:SetParentInitializer(selfFrameInitializer, canSetFrameInCombat)

    local targetFrameSetting, targetFrameInitializer = Conceal:SetupSubCategoryCheckbox("targetFrame","Enable Target frame","Conceal Target frame", settingsDB["targetFrame"], framesCategory)
	local targetFrameCombatSetting, targetFrameCombatInitializer = Conceal:SetupSubCategoryCheckbox("targetFrameConcealDuringCombat","Hide Target frame in combat","Only shows the target frame when the mouse is hovering", settingsDB["targetFrameConcealDuringCombat"], framesCategory)
    local function canSetTargetInCombat()
        return settingsDB["targetFrame"]
    end
    targetFrameCombatInitializer:Indent()
    targetFrameCombatInitializer:SetParentInitializer(targetFrameInitializer, canSetTargetInCombat)
    
    Conceal:SetupSubCategoryCheckbox("buffFrame","Enable Buff List","Conceal Buffs", settingsDB["buffFrame"], framesCategory)
	Conceal:SetupSubCategoryCheckbox("debuffFrame","Debuff List","Conceal Debuffs", settingsDB["debuffFrame"], framesCategory)

	framesLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Cast Bar", "Selecting this option will ALWAYS hide your cast bar"));
	Conceal:SetupSubCategoryCheckbox("castBar","Cast Bar","Completly hides the Cast Bar", 	settingsDB["castBar"], framesCategory)

    -- Adds Action Bars sub Category
	local barsCategory, barLayout = Settings.RegisterVerticalLayoutSubcategory(concealOptions, "Action Bars");
	Settings.RegisterAddOnCategory(barsCategory)
	barLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Main Action Bars", "Action Bars from 1 to 3"));
    local actionBar1Setting, actionBar1Initializer = Conceal:SetupSubCategoryCheckbox("actionBar1","Enable on Action Bar 1","Conceal Action Bar 1", settingsDB["actionBar1"], barsCategory)
	local actionBar1CombatSetting, actionBar1CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar1ConcealDuringCombat","Hide Action Bar 1 in combat","Only shows the Action Bar 1 when the mouse is hovering", settingsDB["actionBar1ConcealDuringCombat"], barsCategory)
	local function canSetActionBar1InCombat()
        return settingsDB["actionBar1"]
    end
    actionBar1CombatInitializer:Indent()
    actionBar1CombatInitializer:SetParentInitializer(actionBar1Initializer, canSetActionBar1InCombat)

    local actionBar2Setting, actionBar2Initializer = Conceal:SetupSubCategoryCheckbox("actionBar2","Enable on Action Bar 2","Conceal Action Bar 2", settingsDB["actionBar2"], barsCategory)
	local actionBar2CombatSetting, actionBar2CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar2ConcealDuringCombat","Hide Action Bar 2 in combat","Only shows the Action Bar 2 when the mouse is hovering", settingsDB["actionBar2ConcealDuringCombat"], barsCategory)
	local function canSetActionBar2InCombat()
        return settingsDB["actionBar2"]
    end
    actionBar2CombatInitializer:Indent()
    actionBar2CombatInitializer:SetParentInitializer(actionBar2Initializer, canSetActionBar2InCombat)

    local actionBar3Setting, actionBar3Initializer = Conceal:SetupSubCategoryCheckbox("actionBar3","Enable on Action Bar 3","Conceal Action Bar 3", settingsDB["actionBar3"], barsCategory)
	local actionBar3CombatSetting, actionBar3CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar3ConcealDuringCombat","Hide Action Bar 3 in combat","Only shows the Action Bar 3 when the mouse is hovering", settingsDB["actionBar2ConcealDuringCombat"], barsCategory)
	local function canSetActionBar3InCombat()
        return settingsDB["actionBar3"]
    end
    actionBar3CombatInitializer:Indent()
    actionBar3CombatInitializer:SetParentInitializer(actionBar3Initializer, canSetActionBar3InCombat)

	barLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Extra Action Bars", "Action Bars from 4 to 8"));
    local actionBar4Setting, actionBar4Initializer = Conceal:SetupSubCategoryCheckbox("actionBar4","Enable on Action Bar 4","Conceal Action Bar 4", settingsDB["actionBar4"], barsCategory)
	local actionBar4CombatSetting, actionBar4CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar4ConcealDuringCombat","Hide Action Bar 4 in combat","Only shows the Action Bar 4 when the mouse is hovering", settingsDB["actionBar2ConcealDuringCombat"], barsCategory)
	local function canSetActionBar4InCombat()
        return settingsDB["actionBar4"]
    end
    actionBar4CombatInitializer:Indent()
    actionBar4CombatInitializer:SetParentInitializer(actionBar4Initializer, canSetActionBar4InCombat)

    local actionBar5Setting, actionBar5Initializer = Conceal:SetupSubCategoryCheckbox("actionBar5","Enable on Action Bar 5","Conceal Action Bar 5", settingsDB["actionBar5"], barsCategory)
    local actionBar5CombatSetting, actionBar5CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar5ConcealDuringCombat","Hide Action Bar 5 in combat","Only shows the Action Bar 5 when the mouse is hovering", settingsDB["actionBar2ConcealDuringCombat"], barsCategory)
    local function canSetActionBar5InCombat()
        return settingsDB["actionBar5"]
    end
    actionBar5CombatInitializer:Indent()
    actionBar5CombatInitializer:SetParentInitializer(actionBar5Initializer, canSetActionBar5InCombat)
    
    local actionBar6Setting, actionBar6Initializer = Conceal:SetupSubCategoryCheckbox("actionBar6","Enable on Action Bar 6","Conceal Action Bar 6", settingsDB["actionBar6"], barsCategory)
	local actionBar6CombatSetting, actionBar6CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar6ConcealDuringCombat","Hide Action Bar 6 in combat","Only shows the Action Bar 6 when the mouse is hovering", settingsDB["actionBar2ConcealDuringCombat"], barsCategory)
	local function canSetActionBar6InCombat()
        return settingsDB["actionBar6"]
    end
    actionBar6CombatInitializer:Indent()
    actionBar6CombatInitializer:SetParentInitializer(actionBar6Initializer, canSetActionBar6InCombat)
    
    local actionBar7Setting, actionBar7Initializer = Conceal:SetupSubCategoryCheckbox("actionBar7","Enable on Action Bar 7","Conceal Action Bar 7", settingsDB["actionBar7"], barsCategory)
	local actionBar7CombatSetting, actionBar7CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar7ConcealDuringCombat","Hide Action Bar 7 in combat","Only shows the Action Bar 7 when the mouse is hovering", settingsDB["actionBar2ConcealDuringCombat"], barsCategory)
	local function canSetActionBar7InCombat()
        return settingsDB["actionBar7"]
    end
    actionBar7CombatInitializer:Indent()
    actionBar7CombatInitializer:SetParentInitializer(actionBar7Initializer, canSetActionBar7InCombat)
    
    local actionBar8Setting, actionBar8Initializer = Conceal:SetupSubCategoryCheckbox("actionBar8","Enable on Action Bar 8","Conceal Action Bar 8", settingsDB["actionBar8"], barsCategory)
	local actionBar8CombatSetting, actionBar8CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar8ConcealDuringCombat","Hide Action Bar 8 in combat","Only shows the Action Bar 8 when the mouse is hovering", settingsDB["actionBar2ConcealDuringCombat"], barsCategory)
	local function canSetActionBar8InCombat()
        return settingsDB["actionBar8"]
    end
    actionBar8CombatInitializer:Indent()
    actionBar8CombatInitializer:SetParentInitializer(actionBar8Initializer, canSetActionBar8InCombat)

    -- Adds Extra Elements Category
	local extraCategory, extraLayout = Settings.RegisterVerticalLayoutSubcategory(concealOptions, "Extra Elements");
	Settings.RegisterAddOnCategory(extraCategory)
    	
    local petActionBarSetting, petActionBarInitializer = Conceal:SetupSubCategoryCheckbox("petActionBar","Enable Pet Action Bar","Conceal Pet Action Bar", settingsDB["petActionBar"], extraCategory)
	local selfFrameCombatSetting, selfFrameCombatInitializer = Conceal:SetupSubCategoryCheckbox("petActionBarConcealDuringCombat","Hide Pet Action Bar in combat","Only shows the pet action bar when the mouse is hovering", settingsDB["petActionBarConcealDuringCombat"], extraCategory)
	local function canSetPetActionBarInCombat()
        return settingsDB["petActionBar"]
    end
    selfFrameCombatInitializer:Indent()
    selfFrameCombatInitializer:SetParentInitializer(petActionBarInitializer, canSetPetActionBarInCombat)

    local stanceBarSetting, stanceBarInitializer = Conceal:SetupSubCategoryCheckbox("stanceBar","Enable Stance Action Bar","Conceal Stance Action Bar", settingsDB["stanceBar"], extraCategory)
	local selfFrameCombatSetting, selfFrameCombatInitializer = Conceal:SetupSubCategoryCheckbox("stanceBarConcealDuringCombat","Hide Stance Action Bar in combat","Only shows the stance action bar when the mouse is hovering", settingsDB["stanceBarConcealDuringCombat"], extraCategory)
	local function canSetstanceBarInCombat()
        return settingsDB["stanceBar"]
    end
    selfFrameCombatInitializer:Indent()
    selfFrameCombatInitializer:SetParentInitializer(stanceBarInitializer, canSetstanceBarInCombat)

    local microBarSetting, microBarInitializer = Conceal:SetupSubCategoryCheckbox("microBar","Enable Micro Bar","Conceal Micro Bar", settingsDB["microBar"], extraCategory)
	local selfFrameCombatSetting, selfFrameCombatInitializer = Conceal:SetupSubCategoryCheckbox("microBarConcealDuringCombat","Hide Micro Bar in combat","Only shows the micro bar when the mouse is hovering", settingsDB["microBarConcealDuringCombat"], extraCategory)
	local function canSetmicroBarInCombat()
        return settingsDB["microBar"]
    end
    selfFrameCombatInitializer:Indent()
    selfFrameCombatInitializer:SetParentInitializer(microBarInitializer, canSetmicroBarInCombat)

    
    local experienceSetting, experienceInitializer = Conceal:SetupSubCategoryCheckbox("experience","Enable Experience Bar","Conceal Experience Bar", settingsDB["experience"], extraCategory)
	local selfFrameCombatSetting, selfFrameCombatInitializer = Conceal:SetupSubCategoryCheckbox("experienceConcealDuringCombat","Hide Experience Bar in combat","Only shows the experience bar when the mouse is hovering", settingsDB["experienceConcealDuringCombat"], extraCategory)
	local function canSetexperienceInCombat()
        return settingsDB["experience"]
    end
    selfFrameCombatInitializer:Indent()
    selfFrameCombatInitializer:SetParentInitializer(experienceInitializer, canSetexperienceInCombat)
    
    local objectiveTrackerSetting, objectiveTrackerInitializer = Conceal:SetupSubCategoryCheckbox("objectiveTracker","Enable Objective Tracker","Conceal Objective Tracker", settingsDB["objectiveTracker"], extraCategory)
end


function Conceal:OnInitialize() 
    local savedSettingsDB = ConcealDataBase
    print(savedSettingsDB)
    if not savedSettingsDB then 
        print("Database is empty")
        settingsDB = defaults
        ConcealDataBase = defaults
    else 
        print("Database is not empty")
        settingsDB = savedSettingsDB
    end 
    print(settingsDB)

    Conceal:CreateSettingsWindow()
    Conceal:HideGcdFlash()
    QueueStatusButton:SetParent(UIParent);
    C_Timer.NewTicker(0.25, function()
        Conceal:ShowMouseOverElements()
        Conceal:RefreshGUI()
    end)
end

-- Conditionals
function Conceal:isHealthBelowThreshold()
    local threshold = settingsDB["health"];
    if threshold then
        local hp = UnitHealth("player");
        local maxHP = UnitHealthMax("player");

        -- This check is needed because in 11.0 beta, when loading into a new zone, maxHP returns 0
        if maxHP == 0 then
            return false
        end
        
        local pct = (hp / maxHP) * 100;
        return pct < threshold;
    else
        return false;
    end
end

function Conceal:FadeIn(frame, forced)
    local alphaTimer = settingsDB["animationDuration"];
    if alphaTimer == 0 then alphaTimer = 0.01; end
    local frameAlpha = settingsDB["alpha"];
    if frameAlpha > 1 then frameAlpha = frameAlpha / 100; end
    
    local currentAlpha = frame:GetAlpha()
    currentAlpha = tonumber(string.format("%.2f", currentAlpha))
    if (currentAlpha == frameAlpha) and not forced then 
    
        local animation = frame:CreateAnimationGroup();
        local fadeIn = animation:CreateAnimation("Alpha");
        fadeIn:SetFromAlpha(frameAlpha);
        fadeIn:SetToAlpha(1);
        fadeIn:SetDuration(alphaTimer);
        fadeIn:SetStartDelay(0);
        animation:SetToFinalAlpha(true)    
              
        animation:Play();
    end
    if forced then 
        frame:SetAlpha(frameAlpha)
    end
end

function Conceal:FadeOut(frame, forced)
    if frame == nil then return end
    local alphaTimer = settingsDB["fadeOutDuration"];
    if alphaTimer == 0 then alphaTimer = 0.01; end
    local frameAlpha = settingsDB["alpha"];
    if frameAlpha > 1 then frameAlpha = frameAlpha / 100; end

    local currentAlpha = frame:GetAlpha()
    currentAlpha = tonumber(string.format("%.2f", currentAlpha))

    if (currentAlpha == 1) and not forced then 
        local animation = frame:CreateAnimationGroup();
        local fadeIn = animation:CreateAnimation("Alpha");
        fadeIn:SetFromAlpha(1);
        fadeIn:SetToAlpha(frameAlpha);
        fadeIn:SetDuration(alphaTimer);
        fadeIn:SetStartDelay(0);
        
        animation:SetToFinalAlpha(true)      
        animation:Play();
    end
    if forced then 
        frame:SetAlpha(1)
    end
end

-- Actions
function Conceal:ShowCombatElements()

    if settingsDB["selfFrame"] and not settingsDB["selfFrameConcealDuringCombat"] then Conceal:FadeIn(PlayerFrame); Conceal:FadeIn(PetFrame) end
    if settingsDB["targetFrame"] and not settingsDB["targetFrameConcealDuringCombat"] then TargetFrame:SetAlpha(1) end
    if settingsDB["focusFrame"] and not settingsDB["focusFrameConcealDuringCombat"] then FocusFrame:SetAlpha(1) end
    BuffFrame:SetAlpha(1)
    DebuffFrame:SetAlpha(1)
    -- Action Bar 1
    local isActionBar1Concealable = settingsDB["actionBar1"] 
    local concealActionBar1InCombat = settingsDB["actionBar1ConcealDuringCombat"] 
    if isActionBar1Concealable and not concealActionBar1InCombat then ActionBar1:SetAlpha(1) end

    if settingsDB["actionBar2"] and not settingsDB["actionBar2ConcealDuringCombat"] then ActionBar2:SetAlpha(1) end
    if settingsDB["actionBar3"] and not settingsDB["actionBar3ConcealDuringCombat"] then ActionBar3:SetAlpha(1) end
    if settingsDB["actionBar4"] and not settingsDB["actionBar4ConcealDuringCombat"] then ActionBar4:SetAlpha(1) end
    if settingsDB["actionBar5"] and not settingsDB["actionBar5ConcealDuringCombat"] then ActionBar5:SetAlpha(1) end
    if settingsDB["actionBar6"] and not settingsDB["actionBar6ConcealDuringCombat"] then ActionBar6:SetAlpha(1) end
    if settingsDB["actionBar7"] and not settingsDB["actionBar7ConcealDuringCombat"] then ActionBar7:SetAlpha(1) end
    if settingsDB["actionBar8"] and not settingsDB["actionBar8ConcealDuringCombat"] then ActionBar8:SetAlpha(1) end
    if settingsDB["petActionBar"] and not settingsDB["petActionBarConcealDuringCombat"] then PetActionBar:SetAlpha(1) end

    -- Stance Bar
    if settingsDB["stanceBar"] and not settingsDB["stanceBarConcealDuringCombat"] then StanceBar:SetAlpha(1) end
    if settingsDB["microBar"] and not settingsDB["microBarConcealDuringCombat"] then MicroButtonAndBagsBar:SetAlpha(1) end
    if settingsDB["experience"] and not settingsDB["experienceConcealDuringCombat"] then StatusTrackingBarManager:SetAlpha(1) end
end

function Conceal:ShowMouseOverElements()
    local frameAlpha = settingsDB["alpha"];
    if frameAlpha > 1 then frameAlpha = frameAlpha / 100; end

    if settingsDB["selfFrame"] then 
        if PlayerFrame:IsMouseOver() or PetFrame:IsMouseOver() then 
            Conceal:FadeIn(PlayerFrame)
            Conceal:FadeIn(PetFrame)
        elseif settingsDB["selfFrameConcealDuringCombat"] then 
            Conceal:FadeOut(PlayerFrame)
            Conceal:FadeOut(PetFrame)
        end 
    end

    if settingsDB["targetFrame"] then 
        if TargetFrame:IsMouseOver() then 
            Conceal:FadeIn(TargetFrame)
        elseif settingsDB["targetFrameConcealDuringCombat"] then 
            Conceal:FadeOut(TargetFrame)
        end 
    end

    if settingsDB["buffFrame"] then
        if BuffFrame:IsMouseOver() then
            Conceal:FadeIn(BuffFrame)
        end
    end

    if settingsDB["debuffFrame"] then
        if DebuffFrame:IsMouseOver() then
            Conceal:FadeIn(DebuffFrame)
        end
    end

    if settingsDB["focusFrame"] then
        if FocusFrame:IsMouseOver() then
            Conceal:FadeIn(FocusFrame)
        end
    end

    -- Action Bar 1
    local isActionBar1Concealable = settingsDB["actionBar1"]
    if isActionBar1Concealable then
        local isMouseOverActionBar1 = false
        for i=1,12 do
            if _G["ActionButton" ..i]:IsMouseOver() then isMouseOverActionBar1 = true end
        end
        if isMouseOverActionBar1 then 
            Conceal:FadeIn(ActionBar1)
        elseif settingsDB["actionBar1ConcealDuringCombat"] then
            Conceal:FadeOut(ActionBar1)
        end
    end

    if settingsDB["actionBar2"] then 
        if ActionBar2:IsMouseOver() then 
            Conceal:FadeIn(ActionBar2)
        elseif settingsDB["actionBar2ConcealDuringCombat"] then 
            Conceal:FadeOut(ActionBar2)
        end 
    end 
    if settingsDB["actionBar3"] then 
        if ActionBar3:IsMouseOver() then 
            Conceal:FadeIn(ActionBar3)
        elseif settingsDB["actionBar3ConcealDuringCombat"] then 
            Conceal:FadeOut(ActionBar3)
        end 
    end
    if settingsDB["actionBar4"] then 
        if ActionBar4:IsMouseOver() then 
            Conceal:FadeIn(ActionBar4)
        elseif settingsDB["actionBar4ConcealDuringCombat"] then 
            Conceal:FadeOut(ActionBar4)
        end 
    end
    if settingsDB["actionBar5"] then 
        if ActionBar5:IsMouseOver() then 
            Conceal:FadeIn(ActionBar5)
        elseif settingsDB["actionBar5ConcealDuringCombat"] then 
            Conceal:FadeOut(ActionBar5)
        end 
    end
    if settingsDB["actionBar6"] then 
        if ActionBar6:IsMouseOver() then 
            Conceal:FadeIn(ActionBar6)
        elseif settingsDB["actionBar6ConcealDuringCombat"] then 
            Conceal:FadeOut(ActionBar6)
        end 
    end
    if settingsDB["actionBar7"] then 
        if ActionBar7:IsMouseOver() then 
            Conceal:FadeIn(ActionBar7)
        elseif settingsDB["actionBar7ConcealDuringCombat"] then 
            Conceal:FadeOut(ActionBar7)
        end 
    end
    if settingsDB["actionBar8"] then 
        if ActionBar8:IsMouseOver() then 
            Conceal:FadeIn(ActionBar8)
        elseif settingsDB["actionBar8ConcealDuringCombat"] then 
            Conceal:FadeOut(ActionBar8)
        end 
    end
    if settingsDB["petActionBar"] then 
        if PetActionBar:IsMouseOver() then 
            Conceal:FadeIn(PetActionBar)
        elseif settingsDB["petActionBarConcealDuringCombat"] then 
            Conceal:FadeOut(PetActionBar)
        end 
    end
    if settingsDB["stanceBar"] then 
        if StanceBar:IsMouseOver() then 
            Conceal:FadeIn(StanceBar)
        elseif settingsDB["stanceBarConcealDuringCombat"] then 
            Conceal:FadeOut(StanceBar)
        end 
    end
    if settingsDB["microBar"] then 
        if MicroButtonAndBagsBar:IsMouseOver() then 
            Conceal:FadeIn(MicroButtonAndBagsBar)
        elseif settingsDB["microBarConcealDuringCombat"] then 
            Conceal:FadeOut(MicroButtonAndBagsBar)
        end 
    end
    if settingsDB["experience"] then 
        if StatusTrackingBarManager:IsMouseOver() then 
            Conceal:FadeIn(StatusTrackingBarManager)
        elseif settingsDB["experienceConcealDuringCombat"] then 
            Conceal:FadeOut(StatusTrackingBarManager)
        end 
    end
    if settingsDB["objectiveTracker"] then
        if ObjectiveTrackerFrame:IsMouseOver() then
            Conceal:FadeIn(ObjectiveTrackerFrame)
        end
    end
end

function Conceal:HideElements()

    if isInCombat then return end

    local frameAlpha = settingsDB["alpha"];
    if frameAlpha > 1 then frameAlpha = frameAlpha / 100; end
    
    -- Player Frame
    if settingsDB["selfFrame"] and not (PlayerFrame:IsMouseOver() or PetFrame:IsMouseOver()) then 
        Conceal:FadeOut(PlayerFrame) 
        Conceal:FadeOut(PetFrame)
    end

    if settingsDB["targetFrame"] and not TargetFrame:IsMouseOver() then Conceal:FadeOut(TargetFrame); end
    if settingsDB["buffFrame"] and not BuffFrame:IsMouseOver() then Conceal:FadeOut(BuffFrame); end
    if settingsDB["debuffFrame"] and not DebuffFrame:IsMouseOver() then Conceal:FadeOut(DebuffFrame); end
    if settingsDB["focusFrame"] and not FocusFrame:IsMouseOver() then Conceal:FadeOut(FocusFrame); end

    -- Action Bar 1
    local isActionBar1Concealable = settingsDB["actionBar1"]
    local isMouseOverActionBar1 = false
    for i=1,12 do
        if _G["ActionButton" ..i]:IsMouseOver() then isMouseOverActionBar1 = true end
    end
    if isActionBar1Concealable and not isMouseOverActionBar1 then 
        Conceal:FadeOut(ActionBar1)
    end

    if settingsDB["actionBar2"] and not ActionBar2:IsMouseOver() then Conceal:FadeOut(ActionBar2); end
    if settingsDB["actionBar3"] and not ActionBar3:IsMouseOver() then Conceal:FadeOut(ActionBar3); end
    if settingsDB["actionBar4"] and not ActionBar4:IsMouseOver() then Conceal:FadeOut(ActionBar4); end
    if settingsDB["actionBar5"] and not ActionBar5:IsMouseOver() then Conceal:FadeOut(ActionBar5); end
    if settingsDB["actionBar6"] and not ActionBar6:IsMouseOver() then Conceal:FadeOut(ActionBar6); end
    if settingsDB["actionBar7"] and not ActionBar7:IsMouseOver() then Conceal:FadeOut(ActionBar7); end
    if settingsDB["actionBar8"] and not ActionBar8:IsMouseOver() then Conceal:FadeOut(ActionBar8); end
    if settingsDB["petActionBar"] and not PetActionBar:IsMouseOver() then Conceal:FadeOut(PetActionBar); end
    if settingsDB["stanceBar"] and not StanceBar:IsMouseOver() then Conceal:FadeOut(StanceBar); end
    if settingsDB["microBar"] and not MicroButtonAndBagsBar:IsMouseOver() then Conceal:FadeOut(MicroButtonAndBagsBar); end
    if settingsDB["experience"] and not StatusTrackingBarManager:IsMouseOver() then Conceal:FadeOut(StatusTrackingBarManager); end
    if settingsDB["objectiveTracker"] and not ObjectiveTrackerFrame:IsMouseOver() then Conceal:FadeOut(ObjectiveTrackerFrame); end
end

-- Event Handlers
function Conceal:DidEnterCombat() 
    Conceal:ShowCombatElements()
    isInCombat = true
end

function Conceal:DidExitCombat() 
    Conceal:HideElements()
    isInCombat = false
end

function Conceal:PLAYER_TARGET_CHANGED(info, value)
    if UnitExists("target") then 
         Conceal:ShowCombatElements();
    else
        Conceal:HideElements()
    end
end

function Conceal:PLAYER_ENTER_COMBAT(info, value)
    Conceal:DidEnterCombat()
end

function Conceal:PLAYER_REGEN_DISABLED(info, value)
    Conceal:DidEnterCombat()
end

function Conceal:PLAYER_LEAVE_COMBAT(info, value)
    Conceal:DidExitCombat()
end

function Conceal:PLAYER_REGEN_ENABLED(info, value)
    Conceal:DidExitCombat()
end
--credit https://www.mmo-champion.com/threads/2414999-How-do-I-disable-the-GCD-flash-on-my-bars
function Conceal:HideGcdFlash() 
    for i,v in pairs(_G) do
        if type(v)=="table" and type(v.SetDrawBling)=="function" then
            v:SetDrawBling(false)
        end
    end
end

function Conceal:ProfileHandler() 
    Conceal:loadConfig();
    Conceal:RefreshGUI();
end

function Conceal:RefreshGUI()
    local shouldShowCombatElement = false
    if UnitExists("target") then shouldShowCombatElement = shouldShowCombatElement or true; end
    if Conceal:isHealthBelowThreshold() then shouldShowCombatElement = shouldShowCombatElement or true; end
    if shouldShowCombatElement then 
        Conceal:ShowCombatElements();
    else
        Conceal:HideElements()
    end
    if settingsDB["castBar"] then PlayerCastingBarFrame:UnregisterAllEvents()
    else PlayerCastingBarFrame:RegisterAllEvents()  end
end

function Conceal:GetStatus(info)
    Conceal:RefreshGUI()
    Conceal:loadConfig()
    return settingsDB[info[#info]]
end

function Conceal:UpdateFramesToAlpha(alpha)
    if settingsDB["selfFrame"] then PlayerFrame:SetAlpha(alpha); PetFrame:SetAlpha(alpha); end
    if settingsDB["targetFrame"] then TargetFrame:SetAlpha(alpha); end
    if settingsDB["buffFrame"] then BuffFrame:SetAlpha(alpha); end
    if settingsDB["debuffFrame"] then DebuffFrame:SetAlpha(alpha); end
    if settingsDB["focusFrame"] then FocusFrame:SetAlpha(alpha); end
    if settingsDB["actionBar1"] then ActionBar1:SetAlpha(alpha) end
    if settingsDB["actionBar2"] then ActionBar2:SetAlpha(alpha); end
    if settingsDB["actionBar3"] then ActionBar3:SetAlpha(alpha); end
    if settingsDB["actionBar4"] then ActionBar4:SetAlpha(alpha); end
    if settingsDB["actionBar5"] then ActionBar5:SetAlpha(alpha); end
    if settingsDB["actionBar6"] then ActionBar6:SetAlpha(alpha); end
    if settingsDB["actionBar7"] then ActionBar7:SetAlpha(alpha); end
    if settingsDB["actionBar8"] then ActionBar8:SetAlpha(alpha); end
    if settingsDB["petActionBar"] then PetActionBar:SetAlpha(alpha); end
    if settingsDB["stanceBar"] then StanceBar:SetAlpha(alpha); end
    if settingsDB["microBar"] then MicroButtonAndBagsBar:SetAlpha(alpha); end
    if settingsDB["objectiveTracker"] then ObjectiveTrackerFrame:SetAlpha(alpha); end
end

function Conceal:SetStatus(info) 
    if settingsDB[info[#info]] then
        settingsDB[info[#info]] = false
        if info[#info] == "selfFrame"   then PlayerFrame:SetAlpha(1); PetFrame:SetAlpha(1); settingsDB["selfFrameConcealDuringCombat"] = false end
        if info[#info] == "targetFrame" then TargetFrame:SetAlpha(1); settingsDB["targetFrameConcealDuringCombat"] = false end
        if info[#info] == "buffFrame"   then BuffFrame:SetAlpha(1); end
        if info[#info] == "debuffFrame" then DebuffFrame:SetAlpha(1); end
        if info[#info] == "focusFrame"  then ActionBar1:SetAlpha(1); settingsDB["focusFrameConcealDuringCombat"] = false; end
        if info[#info] == "actionBar1"  then ActionBar1:SetAlpha(1); settingsDB["actionBar1ConcealDuringCombat"] = false; end
        if info[#info] == "actionBar2"  then ActionBar2:SetAlpha(1); settingsDB["actionBar2ConcealDuringCombat"] = false end
        if info[#info] == "actionBar3"  then ActionBar3:SetAlpha(1); settingsDB["actionBar3ConcealDuringCombat"] = false end
        if info[#info] == "actionBar4"  then ActionBar4:SetAlpha(1); settingsDB["actionBar4ConcealDuringCombat"] = false end
        if info[#info] == "actionBar5"  then ActionBar5:SetAlpha(1); settingsDB["actionBar5ConcealDuringCombat"] = false end
        if info[#info] == "actionBar6"  then ActionBar6:SetAlpha(1); settingsDB["actionBar6ConcealDuringCombat"] = false end
        if info[#info] == "actionBar7"  then ActionBar7:SetAlpha(1); settingsDB["actionBar7ConcealDuringCombat"] = false end
        if info[#info] == "actionBar8"  then ActionBar8:SetAlpha(1); settingsDB["actionBar8ConcealDuringCombat"] = false end
        if info[#info] == "petActionBar" then PetActionBar:SetAlpha(1); settingsDB["petActionBarConcealDuringCombat"] = false end
        if info[#info] == "stanceBar"   then StanceBar:SetAlpha(1); settingsDB["stanceBarConcealDuringCombat"] = false end
        if info[#info] == "microBar"    then MicroButtonAndBagsBar:SetAlpha(1); settingsDB["microBarConcealDuringCombat"] = false end
        if info[#info] == "experience"  then StatusTrackingBarManager:SetAlpha(1); settingsDB["experienceConcealDuringCombat"] = false end
        if info[#info] == "objectiveTracker" then ObjectiveTrackerFrame:SetAlpha(1); settingsDB["objectiveTracker"] = false end
    else 
        settingsDB[info[#info]] = true
        if info[#info] == "selfFrameConcealDuringCombat" then settingsDB["selfFrame"] = true end
        if info[#info] == "targetFrameConcealDuringCombat" then settingsDB["targetFrame"] = true end
        if info[#info] == "focusFrameConcealDuringCombat" then settingsDB["focusFrame"] = true end
        if info[#info] == "actionBar1ConcealDuringCombat" then settingsDB["actionBar1"] = true end
        if info[#info] == "actionBar2ConcealDuringCombat" then settingsDB["actionBar2"] = true end
        if info[#info] == "actionBar3ConcealDuringCombat" then settingsDB["actionBar3"] = true end
        if info[#info] == "actionBar4ConcealDuringCombat" then settingsDB["actionBar4"] = true end
        if info[#info] == "actionBar5ConcealDuringCombat" then settingsDB["actionBar5"] = true end
        if info[#info] == "actionBar6ConcealDuringCombat" then settingsDB["actionBar6"] = true end
        if info[#info] == "actionBar7ConcealDuringCombat" then settingsDB["actionBar7"] = true end
        if info[#info] == "actionBar8ConcealDuringCombat" then settingsDB["actionBar8"] = true end
        if info[#info] == "petActionBarConcealDuringCombat" then settingsDB["petActionBar"] = true end
        if info[#info] == "stanceBarConcealDuringCombat" then settingsDB["stanceBar"] = true end
        if info[#info] == "microBarConcealDuringCombat" then settingsDB["microBar"] = true end
        if info[#info] == "experienceConcealDuringCombat" then settingsDB["experience"] = true end
        Conceal:loadConfig()
    end
    Conceal:RefreshGUI()
end

function Conceal:GetSlider(info)
    return settingsDB[info[#info]]
end

function Conceal:SetSlider(info, value)
    settingsDB[info[#info]] = value
    if info[#info] == "alpha" then 
        local frameAlpha = value;
        if frameAlpha > 1 then frameAlpha = frameAlpha / 100; end
        Conceal:UpdateFramesToAlpha(frameAlpha)
    end
end

function Conceal:OnEvent(event, ...)
	self[event](self, event, ...)
    if event == "PLAYER_LOGOUT" then
		ConcealDataBase = settingsDB
	end
end

function Conceal:ADDON_LOADED(event, addOnName)
	if event == "ADDON_LOADED" and (addOnName == "Conceal") then
        Conceal:OnInitialize()
    end
end

Conceal:RegisterEvent("ADDON_LOADED")
Conceal:RegisterEvent("PLAYER_LOGOUT")
Conceal:RegisterEvent("PLAYER_ENTER_COMBAT")
Conceal:RegisterEvent("PLAYER_LEAVE_COMBAT")
Conceal:RegisterEvent("PLAYER_REGEN_DISABLED")
Conceal:RegisterEvent("PLAYER_REGEN_ENABLED")
Conceal:RegisterEvent("PLAYER_TARGET_CHANGED")
Conceal:SetScript("OnEvent", Conceal.OnEvent)