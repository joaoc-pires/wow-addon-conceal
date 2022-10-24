local addonName, addon = ...;
local P = "player";

local function isHealthOutsideThreshold()
    local threshold = ConcealDB["health"];
    if threshold then
        local hp = UnitHealth(P);
        local maxHP = UnitHealthMax(P);
        local pct = (hp / maxHP) * 100;
        return pct < threshold;
    else
        return false;
    end
end

local function isPowerOutsideThreshold()
    local threshold = ConcealDB["power"];
    if threshold then
        local power = UnitPower(P);
        local maxPower = UnitPowerMax(P);
        local pct = (power / maxPower) * 100;
        local powerId, powerType = UnitPowerType(P);
        local doesDecay = addon.decayPowerTypes[powerType];
        return (doesDecay and pct > threshold) or (not doesDecay and pct < threshold);
    else
        return false;
    end
end

local function isMouseOverPlayerFrame()
    local mouseover = ConcealDB["mouseover"] and true or false;
    if mouseover and PlayerFrame:IsMouseOver() then
        return true;
    else
        return false;
    end
end

local function showPlayerFrame()
    PlayerFrame:SetAlpha(1);
    if not PlayerFrame:IsMouseEnabled() then
        PlayerFrame:EnableMouse(true);
    end
end

local function hidePlayerFrame()
    local interactive = ConcealDB["interactive"] and true or false;
    if not InCombatLockdown() then
        PlayerFrame:EnableMouse(interactive);
    end
    local frameAlpha = ConcealDB["alpha"]
    if frameAlpha > 1 then
        frameAlpha = frameAlpha / 100
    end
    PlayerFrame:SetAlpha(frameAlpha);
end

local function shouldShowPlayerFrame()
    -- show player frame if player has a target
    if UnitExists("target") then return true; end

    -- show player frame if player is in combat
    if UnitAffectingCombat(P) then return true; end

    -- show player frame if player health is < 100%
    if isHealthOutsideThreshold() then return true; end

    -- show player frame if player power is < 100% (or > 0 if its a decaying power type, e.g. rage)
    if isPowerOutsideThreshold() then return true; end

    -- show player frame if it is moused over
    if isMouseOverPlayerFrame() then return true; end

    -- otherwise, hide the player frame
    return false;
end

addon.togglePlayerFrame = function()
    if shouldShowPlayerFrame() then
        showPlayerFrame();
    else
        hidePlayerFrame();
    end
    local mouseover = ConcealDB["mouseover"] and true or false;
    if mouseover then
        C_Timer.NewTicker(0.10, function()
            if shouldShowPlayerFrame() then
                showPlayerFrame();
            else
                hidePlayerFrame();
            end
        end)
    end
end

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
    Settings.RegisterAddOnCategory(category)
end