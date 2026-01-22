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
    castBar = false,
    objectiveTracker = false,
    actionTargetMode = false,
    buffIconCooldownViewer = false,
    buffIconCooldownViewerConcealDuringCombat = false,
    essentialCooldownViewer = false,
    essentialCooldownViewerConcealDuringCombat = false,
    utilityCooldownViewer = false,
    utilityCooldownViewerConcealDuringCombat = false
}

local isInCombat = false
local lastDesired = {}   -- key -> last alpha applied (number, normalized 0..1)
local tickerHandle = nil

local ActionBar1 = MainActionBar
local ActionBar2 = MultiBarBottomLeft
local ActionBar3 = MultiBarBottomRight
local ActionBar4 = MultiBarRight 
local ActionBar5 = MultiBarLeft
local ActionBar6 = MultiBar5
local ActionBar7 = MultiBar6
local ActionBar8 = MultiBar7

function Conceal:UpdateUI()
    wipe(lastDesired)
    Conceal:TickUpdate()
end

function Conceal:SetupSubCategoryCheckbox(key, name, tooltip, defaultValue, category)
    local setting = Settings.RegisterAddOnSetting(
        category,
        "conceal_" .. key,
        key,
        settingsDB,
        type(defaultValue),
        name,
        defaultValue)

    local initializer = Settings.CreateCheckbox(category, setting, tooltip)

    setting:SetValueChangedCallback(function()
        -- settingsDB[key] is already updated by the Settings system
        Conceal:UpdateUI()
    end)

    return setting, initializer
end

function Conceal:CreateSettingsWindow()
    -- This is an implementation detail for 2.1 when support for Action Target Mode was added
    if not (settingsDB["actionTargetMode"]) then 
        settingsDB["actionTargetMode"] = false
    end
	-- Adds the main Category
	local concealOptions, concealLayout = Settings.RegisterVerticalLayoutCategory("Conceal")
	concealOptions.ID = "Conceal"
	Settings.RegisterAddOnCategory(concealOptions)
	do
		local name = "Opacity"
        local variable = "conceal_alpha"
		local variableKey = "alpha"
		local tooltip = "Conceal Opacity"
		local defaultValue = settingsDB["alpha"]
		local minValue = 0
		local maxValue = 100
		local step = 5

        local setting = Settings.RegisterAddOnSetting(concealOptions, variable, variableKey, settingsDB, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(function(setting, value) 
            local frameAlpha = value;
			settingsDB["alpha"] = frameAlpha
            if frameAlpha > 1 then frameAlpha = frameAlpha / 100; end
            -- This is to prevent frame drops
            if frameAlpha == 1 then frameAlpha = 0.95 end
			Conceal:UpdateFramesToAlpha(frameAlpha)
        end)

		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
		Settings.CreateSlider(concealOptions, setting, options, tooltip)
	end
	do
		local name = "Fade In Time"
		local variable = "conceal_animationDuration"
		local variableKey = "animationDuration"
		local tooltip = "Controls the animations duration for the fade in"
		local defaultValue = settingsDB["animationDuration"]
		local minValue = 0
		local maxValue = 2
		local step = 0.25
	
		local setting = Settings.RegisterAddOnSetting(concealOptions, variable, variableKey, settingsDB, type(defaultValue), name, defaultValue)
		setting:SetValueChangedCallback(function(setting, value)
			settingsDB[setting.variableKey] = value
		end) 

		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
		Settings.CreateSlider(concealOptions, setting, options, tooltip)
	end
	do
		local name = "Fade Out Time"
		local variable = "conceal_fadeOutDuration"
		local variableKey = "fadeOutDuration"
		local tooltip = "Controls the animations duration for the fade out"
		local defaultValue = settingsDB[variableKey]
		local minValue = 0
		local maxValue = 2
		local step = 0.25
	
		local setting = Settings.RegisterAddOnSetting(concealOptions, variable, variableKey, settingsDB, type(defaultValue), name, defaultValue)
		setting:SetValueChangedCallback(function(setting, value)
			settingsDB[setting.variableKey] = value
		end) 

		local options = Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right);
		Settings.CreateSlider(concealOptions, setting, options, tooltip)
	end

    -- For Action Target Mode
    local selfFrameSetting, selfFrameInitializer = Conceal:SetupSubCategoryCheckbox("actionTargetMode","Action Target Mode","Will only show frames when entering combat", settingsDB["actionTargetMode"], concealOptions)

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

    -- Adds Cooldown Manager sub Category
	local cdManagerCategory, cdManagerLayout = Settings.RegisterVerticalLayoutSubcategory(concealOptions, "Cooldown Manager");
	Settings.RegisterAddOnCategory(cdManagerCategory)

    local bicvSetting, bicvInitializer = Conceal:SetupSubCategoryCheckbox(
        "buffIconCooldownViewer",
        "Buff Icon Cooldown Viewer",
        "Conceal BuffIconCooldownViewer",
        settingsDB["buffIconCooldownViewer"],
        cdManagerCategory
    )

    local bicvCombatSetting, bicvCombatInitializer = Conceal:SetupSubCategoryCheckbox(
        "buffIconCooldownViewerConcealDuringCombat",
        "Hide Buff Icon Cooldown Viewer in combat",
        "Only shows BuffIconCooldownViewer when the mouse is hovering",
        settingsDB["buffIconCooldownViewerConcealDuringCombat"],
        cdManagerCategory
    )

    local function canSetBICVInCombat()
        return settingsDB["buffIconCooldownViewer"]
    end

    bicvCombatInitializer:Indent()
    bicvCombatInitializer:SetParentInitializer(bicvInitializer, canSetBICVInCombat)

    local ecvSetting, ecvInitializer = Conceal:SetupSubCategoryCheckbox(
        "essentialCooldownViewer",
        "Essential Cooldown Viewer",
        "Conceal EssentialCooldownViewer",
        settingsDB["essentialCooldownViewer"],
        cdManagerCategory
    )

    local ecvCombatSetting, ecvCombatInitializer = Conceal:SetupSubCategoryCheckbox(
        "essentialCooldownViewerConcealDuringCombat",
        "Hide Essential Cooldown Viewer in combat",
        "Only shows EssentialCooldownViewer when the mouse is hovering",
        settingsDB["essentialCooldownViewerConcealDuringCombat"],
        cdManagerCategory
    )
    
    local function canSetECVInCombat()
        return settingsDB["essentialCooldownViewer"]
    end

    ecvCombatInitializer:Indent()
    ecvCombatInitializer:SetParentInitializer(ecvInitializer, canSetECVInCombat)

    local ucvSetting, ucvInitializer = Conceal:SetupSubCategoryCheckbox(
        "utilityCooldownViewer",
        "Utility Cooldown Viewer",
        "Conceal UtilityCooldownViewer",
        settingsDB["utilityCooldownViewer"],
        cdManagerCategory
    )

    local ucvCombatSetting, ucvCombatInitializer = Conceal:SetupSubCategoryCheckbox(
        "utilityCooldownViewerConcealDuringCombat",
        "Hide Utility Cooldown Viewer in combat",
        "Only shows UtilityCooldownViewer when the mouse is hovering",
        settingsDB["utilityCooldownViewerConcealDuringCombat"],
        cdManagerCategory
    )

    local function canSetUCVInCombat()
        return settingsDB["utilityCooldownViewer"]
    end

    ucvCombatInitializer:Indent()
    ucvCombatInitializer:SetParentInitializer(ucvInitializer, canSetUCVInCombat)

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
	local actionBar3CombatSetting, actionBar3CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar3ConcealDuringCombat","Hide Action Bar 3 in combat","Only shows the Action Bar 3 when the mouse is hovering", settingsDB["actionBar3ConcealDuringCombat"], barsCategory)
	local function canSetActionBar3InCombat()
        return settingsDB["actionBar3"]
    end
    actionBar3CombatInitializer:Indent()
    actionBar3CombatInitializer:SetParentInitializer(actionBar3Initializer, canSetActionBar3InCombat)

	barLayout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Extra Action Bars", "Action Bars from 4 to 8"));
    local actionBar4Setting, actionBar4Initializer = Conceal:SetupSubCategoryCheckbox("actionBar4","Enable on Action Bar 4","Conceal Action Bar 4", settingsDB["actionBar4"], barsCategory)
	local actionBar4CombatSetting, actionBar4CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar4ConcealDuringCombat","Hide Action Bar 4 in combat","Only shows the Action Bar 4 when the mouse is hovering", settingsDB["actionBar4ConcealDuringCombat"], barsCategory)
	local function canSetActionBar4InCombat()
        return settingsDB["actionBar4"]
    end
    actionBar4CombatInitializer:Indent()
    actionBar4CombatInitializer:SetParentInitializer(actionBar4Initializer, canSetActionBar4InCombat)

    local actionBar5Setting, actionBar5Initializer = Conceal:SetupSubCategoryCheckbox("actionBar5","Enable on Action Bar 5","Conceal Action Bar 5", settingsDB["actionBar5"], barsCategory)
    local actionBar5CombatSetting, actionBar5CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar5ConcealDuringCombat","Hide Action Bar 5 in combat","Only shows the Action Bar 5 when the mouse is hovering", settingsDB["actionBar5ConcealDuringCombat"], barsCategory)
    local function canSetActionBar5InCombat()
        return settingsDB["actionBar5"]
    end
    actionBar5CombatInitializer:Indent()
    actionBar5CombatInitializer:SetParentInitializer(actionBar5Initializer, canSetActionBar5InCombat)
    
    local actionBar6Setting, actionBar6Initializer = Conceal:SetupSubCategoryCheckbox("actionBar6","Enable on Action Bar 6","Conceal Action Bar 6", settingsDB["actionBar6"], barsCategory)
	local actionBar6CombatSetting, actionBar6CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar6ConcealDuringCombat","Hide Action Bar 6 in combat","Only shows the Action Bar 6 when the mouse is hovering", settingsDB["actionBar6ConcealDuringCombat"], barsCategory)
	local function canSetActionBar6InCombat()
        return settingsDB["actionBar6"]
    end
    actionBar6CombatInitializer:Indent()
    actionBar6CombatInitializer:SetParentInitializer(actionBar6Initializer, canSetActionBar6InCombat)
    
    local actionBar7Setting, actionBar7Initializer = Conceal:SetupSubCategoryCheckbox("actionBar7","Enable on Action Bar 7","Conceal Action Bar 7", settingsDB["actionBar7"], barsCategory)
	local actionBar7CombatSetting, actionBar7CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar7ConcealDuringCombat","Hide Action Bar 7 in combat","Only shows the Action Bar 7 when the mouse is hovering", settingsDB["actionBar7ConcealDuringCombat"], barsCategory)
	local function canSetActionBar7InCombat()
        return settingsDB["actionBar7"]
    end
    actionBar7CombatInitializer:Indent()
    actionBar7CombatInitializer:SetParentInitializer(actionBar7Initializer, canSetActionBar7InCombat)
    
    local actionBar8Setting, actionBar8Initializer = Conceal:SetupSubCategoryCheckbox("actionBar8","Enable on Action Bar 8","Conceal Action Bar 8", settingsDB["actionBar8"], barsCategory)
	local actionBar8CombatSetting, actionBar8CombatInitializer = Conceal:SetupSubCategoryCheckbox("actionBar8ConcealDuringCombat","Hide Action Bar 8 in combat","Only shows the Action Bar 8 when the mouse is hovering", settingsDB["actionBar8ConcealDuringCombat"], barsCategory)
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
    if not savedSettingsDB then
        settingsDB = defaults
        ConcealDataBase = defaults
    else
        settingsDB = savedSettingsDB
        -- Merge new defaults into existing saved variables (upgrade-safe)
        for k, v in pairs(defaults) do
            if settingsDB[k] == nil then
                settingsDB[k] = v
            end
        end
    end

    Conceal:CreateSettingsWindow()
    Conceal:HideGcdFlash()
    QueueStatusButton:SetParent(UIParent)
    tickerHandle = C_Timer.NewTicker(0.25, function()
        Conceal:TickUpdate()
    end)
    Conceal:TickUpdate()
end


-- Conditionals
function Conceal:FadeIn(frame, forced)
    if frame == nil then return end

    if forced then
        frame:SetAlpha(1) -- immediate show
        return
    end

    local duration = settingsDB["animationDuration"]
    if duration == 0 then duration = 0.01 end

    -- Optional guard to avoid restarting the same transition
    local currentAlpha = tonumber(string.format("%.2f", frame:GetAlpha()))
    if currentAlpha == 1 then
        return
    end

    Conceal:AnimateToAlpha(frame, 1, duration)
end


function Conceal:FadeOut(frame, forced)
    if frame == nil then return end

    local frameAlpha = Conceal:GetConcealAlpha()

    if forced then
        frame:SetAlpha(frameAlpha) -- immediate conceal
        return
    end

    local duration = settingsDB["fadeOutDuration"]
    if duration == 0 then duration = 0.01 end

    -- If you want to avoid restarting the same transition, keep the guard:
    local currentAlpha = tonumber(string.format("%.2f", frame:GetAlpha()))
    if currentAlpha == tonumber(string.format("%.2f", frameAlpha)) then
        return
    end

    Conceal:AnimateToAlpha(frame, frameAlpha, duration)
end

function Conceal:GetConcealAlpha()
    local a = settingsDB["alpha"] or 30
    if a > 1 then a = a / 100 end
    if a == 1 then a = 0.95 end
    return a
end

function Conceal:IsContextActive()
    if isInCombat then return true end
    if UnitExists("target") and not settingsDB["actionTargetMode"] then return true end
    return false
end

function Conceal:IsActionBar1MouseOver()
    for i = 1, 12 do
        local btn = _G["ActionButton" .. i]
        if btn and btn:IsMouseOver() then
            return true
        end
    end
    return false
end

-- Actions
-- Event Handlers

function Conceal:AnimateToAlpha(frame, toAlpha, duration)
    if frame == nil then return end
    local fromAlpha = frame:GetAlpha()

    if tonumber(string.format("%.2f", fromAlpha)) == tonumber(string.format("%.2f", toAlpha)) then
        return
    end

    local anim = frame:CreateAnimationGroup()
    local alphaAnim = anim:CreateAnimation("Alpha")
    alphaAnim:SetFromAlpha(fromAlpha)
    alphaAnim:SetToAlpha(toAlpha)
    alphaAnim:SetDuration(duration)
    alphaAnim:SetStartDelay(0)
    anim:SetToFinalAlpha(true)
    anim:Play()
end

function Conceal:TickUpdate()
    local frameAlpha = Conceal:GetConcealAlpha()
    local contextActive = Conceal:IsContextActive()

    local function Apply(key, frame, concealDuringContextKey, mouseOverFn)
        if frame == nil then return end
        if not settingsDB[key] then
            -- if element is disabled, keep fully visible
            if lastDesired[key] ~= 1 then
                frame:SetAlpha(1)
                lastDesired[key] = 1
            end
            return
        end

        local hovered = false
        if settingsDB["mouseover"] then
            if mouseOverFn then
                hovered = mouseOverFn()
            else
                hovered = frame:IsMouseOver()
            end
        end

        local desired
        if hovered then
            desired = 1
        elseif contextActive and not (concealDuringContextKey and settingsDB[concealDuringContextKey]) then
            desired = 1
        else
            desired = frameAlpha
        end

        if lastDesired[key] == desired then
            return
        end

        -- animate only on transitions
        if desired == 1 then
            Conceal:AnimateToAlpha(frame, 1, settingsDB["animationDuration"] == 0 and 0.01 or settingsDB["animationDuration"])
        else
            Conceal:AnimateToAlpha(frame, frameAlpha, settingsDB["fadeOutDuration"] == 0 and 0.01 or settingsDB["fadeOutDuration"])
        end
        lastDesired[key] = desired
    end

    -- Player + Pet (pet gated)
    Apply("selfFrame", PlayerFrame, "selfFrameConcealDuringCombat")
    if UnitExists("pet") then
        Apply("selfFrame", PetFrame, "selfFrameConcealDuringCombat")
    end

    Apply("targetFrame", TargetFrame, "targetFrameConcealDuringCombat")
    Apply("focusFrame", FocusFrame, "focusFrameConcealDuringCombat")

    -- Buff/Debuff: preserve your current “always show in context” behavior:
    -- if you want them to follow the same rule as others, remove this special-case.
    if settingsDB["buffFrame"] then
        local desired = (contextActive or (settingsDB["mouseover"] and BuffFrame:IsMouseOver())) and 1 or frameAlpha
        if lastDesired["buffFrame"] ~= desired then
            if desired == 1 then Conceal:FadeIn(BuffFrame) else Conceal:FadeOut(BuffFrame) end
            lastDesired["buffFrame"] = desired
        end
    else
        if lastDesired["buffFrame"] ~= 1 then BuffFrame:SetAlpha(1); lastDesired["buffFrame"] = 1 end
    end

    if settingsDB["debuffFrame"] then
        local desired = (contextActive or (settingsDB["mouseover"] and DebuffFrame:IsMouseOver())) and 1 or frameAlpha
        if lastDesired["debuffFrame"] ~= desired then
            if desired == 1 then Conceal:FadeIn(DebuffFrame) else Conceal:FadeOut(DebuffFrame) end
            lastDesired["debuffFrame"] = desired
        end
    else
        if lastDesired["debuffFrame"] ~= 1 then DebuffFrame:SetAlpha(1); lastDesired["debuffFrame"] = 1 end
    end

    Apply("buffIconCooldownViewer", BuffIconCooldownViewer, "buffIconCooldownViewerConcealDuringCombat")
    Apply("essentialCooldownViewer", EssentialCooldownViewer, "essentialCooldownViewerConcealDuringCombat")
    Apply("utilityCooldownViewer", UtilityCooldownViewer, "utilityCooldownViewerConcealDuringCombat")

    Apply("actionBar1", ActionBar1, "actionBar1ConcealDuringCombat", Conceal.IsActionBar1MouseOver)
    Apply("actionBar2", ActionBar2, "actionBar2ConcealDuringCombat")
    Apply("actionBar3", ActionBar3, "actionBar3ConcealDuringCombat")
    Apply("actionBar4", ActionBar4, "actionBar4ConcealDuringCombat")
    Apply("actionBar5", ActionBar5, "actionBar5ConcealDuringCombat")
    Apply("actionBar6", ActionBar6, "actionBar6ConcealDuringCombat")
    Apply("actionBar7", ActionBar7, "actionBar7ConcealDuringCombat")
    Apply("actionBar8", ActionBar8, "actionBar8ConcealDuringCombat")

    Apply("petActionBar", PetActionBar, "petActionBarConcealDuringCombat")
    Apply("stanceBar", StanceBar, "stanceBarConcealDuringCombat")
    Apply("microBar", MicroMenuContainer, "microBarConcealDuringCombat")
    Apply("experience", StatusTrackingBarManager, "experienceConcealDuringCombat")
    Apply("objectiveTracker", ObjectiveTrackerFrame, nil)

    -- cast bar policy remains separate
    if settingsDB["castBar"] then PlayerCastingBarFrame:UnregisterAllEvents()
    else PlayerCastingBarFrame:RegisterAllEvents() end
end

function Conceal:DidEnterCombat() 
    isInCombat = true
end

function Conceal:DidExitCombat() 
    isInCombat = false
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

function Conceal:GetStatus(info)
    return settingsDB[info[#info]]
end

function Conceal:UpdateFramesToAlpha(alpha)
    wipe(lastDesired)
    Conceal:TickUpdate()
end

function Conceal:SetStatus(info)
    local key = info[#info]

    if settingsDB[key] then
        settingsDB[key] = false

        if key == "selfFrame" then
            settingsDB["selfFrameConcealDuringCombat"] = false
        elseif key == "targetFrame" then
            settingsDB["targetFrameConcealDuringCombat"] = false
        elseif key == "focusFrame" then
            settingsDB["focusFrameConcealDuringCombat"] = false
        elseif key == "actionBar1" then
            settingsDB["actionBar1ConcealDuringCombat"] = false
        elseif key == "actionBar2" then
            settingsDB["actionBar2ConcealDuringCombat"] = false
        elseif key == "actionBar3" then
            settingsDB["actionBar3ConcealDuringCombat"] = false
        elseif key == "actionBar4" then
            settingsDB["actionBar4ConcealDuringCombat"] = false
        elseif key == "actionBar5" then
            settingsDB["actionBar5ConcealDuringCombat"] = false
        elseif key == "actionBar6" then
            settingsDB["actionBar6ConcealDuringCombat"] = false
        elseif key == "actionBar7" then
            settingsDB["actionBar7ConcealDuringCombat"] = false
        elseif key == "actionBar8" then
            settingsDB["actionBar8ConcealDuringCombat"] = false
        elseif key == "petActionBar" then
            settingsDB["petActionBarConcealDuringCombat"] = false
        elseif key == "stanceBar" then
            settingsDB["stanceBarConcealDuringCombat"] = false
        elseif key == "microBar" then
            settingsDB["microBarConcealDuringCombat"] = false
        elseif key == "experience" then
            settingsDB["experienceConcealDuringCombat"] = false
        elseif key == "objectiveTracker" then
            settingsDB["objectiveTracker"] = false
        elseif key == "buffIconCooldownViewer" then
            settingsDB["buffIconCooldownViewerConcealDuringCombat"] = false
        elseif key == "essentialCooldownViewer" then
            settingsDB["essentialCooldownViewerConcealDuringCombat"] = false
        elseif key == "utilityCooldownViewer" then
            settingsDB["utilityCooldownViewerConcealDuringCombat"] = false
        end
    else
        settingsDB[key] = true

        if key == "selfFrameConcealDuringCombat" then
            settingsDB["selfFrame"] = true
        elseif key == "targetFrameConcealDuringCombat" then
            settingsDB["targetFrame"] = true
        elseif key == "focusFrameConcealDuringCombat" then
            settingsDB["focusFrame"] = true
        elseif key == "actionBar1ConcealDuringCombat" then
            settingsDB["actionBar1"] = true
        elseif key == "actionBar2ConcealDuringCombat" then
            settingsDB["actionBar2"] = true
        elseif key == "actionBar3ConcealDuringCombat" then
            settingsDB["actionBar3"] = true
        elseif key == "actionBar4ConcealDuringCombat" then
            settingsDB["actionBar4"] = true
        elseif key == "actionBar5ConcealDuringCombat" then
            settingsDB["actionBar5"] = true
        elseif key == "actionBar6ConcealDuringCombat" then
            settingsDB["actionBar6"] = true
        elseif key == "actionBar7ConcealDuringCombat" then
            settingsDB["actionBar7"] = true
        elseif key == "actionBar8ConcealDuringCombat" then
            settingsDB["actionBar8"] = true
        elseif key == "petActionBarConcealDuringCombat" then
            settingsDB["petActionBar"] = true
        elseif key == "stanceBarConcealDuringCombat" then
            settingsDB["stanceBar"] = true
        elseif key == "microBarConcealDuringCombat" then
            settingsDB["microBar"] = true
        elseif key == "experienceConcealDuringCombat" then
            settingsDB["experience"] = true
        elseif key == "buffIconCooldownViewerConcealDuringCombat" then
            settingsDB["buffIconCooldownViewer"] = true
        elseif key == "essentialCooldownViewerConcealDuringCombat" then
            settingsDB["essentialCooldownViewer"] = true
        elseif key == "utilityCooldownViewerConcealDuringCombat" then
            settingsDB["utilityCooldownViewer"] = true
        end
    end
    Conceal:UpdateUI()  
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
end

function Conceal:ADDON_LOADED(event, addOnName)
	if event == "ADDON_LOADED" and (addOnName == "Conceal") then
        Conceal:OnInitialize()
    end
end

function Conceal:PLAYER_LOGOUT(event, addOnName)
	if event == "PLAYER_LOGOUT" and (addOnName == "Conceal") then
        ConcealDataBase = settingsDB
    end
end

Conceal:RegisterEvent("ADDON_LOADED")
Conceal:RegisterEvent("PLAYER_LOGOUT")
Conceal:RegisterEvent("PLAYER_ENTER_COMBAT")
Conceal:RegisterEvent("PLAYER_LEAVE_COMBAT")
Conceal:RegisterEvent("PLAYER_REGEN_DISABLED")
Conceal:RegisterEvent("PLAYER_REGEN_ENABLED")

Conceal:SetScript("OnEvent", Conceal.OnEvent)