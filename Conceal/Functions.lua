local addonName, addon = ...;
local P = "player";


-- Local Functions
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

local function isMouseOverActionBar()
    if ConcealDB["ActionBar1"] then
        for i=1,12 do 
            if _G["ActionButton" ..i]:IsMouseOver() then return true; end
        end
    end
    if ConcealDB["ActionBar2"] then if actionBar2:IsMouseOver() then return true; end end
    if ConcealDB["ActionBar3"] then if actionBar3:IsMouseOver() then return true; end end
    if ConcealDB["ActionBar4"] then if actionBar4:IsMouseOver() then return true; end end
    if ConcealDB["ActionBar5"] then if actionBar5:IsMouseOver() then return true; end end
    if ConcealDB["ActionBar6"] then if actionBar6:IsMouseOver() then return true; end end
    if ConcealDB["ActionBar7"] then if actionBar7:IsMouseOver() then return true; end end
    if ConcealDB["ActionBar8"] then if actionBar8:IsMouseOver() then return true; end end
    return false
end

-- Player Frame Functions
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

    -- show if action bars are moused over
    if isMouseOverActionBar() then return true; end

    -- otherwise, hide the player frame
    return false;
end


-- Action Bar Functions


local function showAllActionBars()

    actionBar2:SetAlpha(1);
    actionBar3:SetAlpha(1);
    actionBar4:SetAlpha(1);
    actionBar5:SetAlpha(1);
    actionBar6:SetAlpha(1);
    actionBar7:SetAlpha(1);
    actionBar8:SetAlpha(1);
    for i=1,12 do
        _G["ActionButton" ..i]:SetAlpha(1)
    end
end

local function hideAllActionBars()
    local frameAlpha = ConcealDB["alpha"]
    if frameAlpha > 1 then
        frameAlpha = frameAlpha / 100
    end
    if ConcealDB["ActionBar2"] then actionBar2:SetAlpha(frameAlpha); else actionBar2:SetAlpha(1); end
    if ConcealDB["ActionBar3"] then actionBar3:SetAlpha(frameAlpha); else actionBar3:SetAlpha(1); end
    if ConcealDB["ActionBar4"] then actionBar4:SetAlpha(frameAlpha); else actionBar4:SetAlpha(1); end
    if ConcealDB["ActionBar5"] then actionBar5:SetAlpha(frameAlpha); else actionBar5:SetAlpha(1); end
    if ConcealDB["ActionBar6"] then actionBar6:SetAlpha(frameAlpha); else actionBar6:SetAlpha(1); end
    if ConcealDB["ActionBar7"] then actionBar7:SetAlpha(frameAlpha); else actionBar7:SetAlpha(1); end
    if ConcealDB["ActionBar8"] then actionBar8:SetAlpha(frameAlpha); else actionBar8:SetAlpha(1); end
    if ConcealDB["ActionBar1"] then
        for i=1,12 do
            _G["ActionButton" ..i]:SetAlpha(frameAlpha)
        end
    else 
        for i=1,12 do
            _G["ActionButton" ..i]:SetAlpha(1)
        end
    end
    
end

local function shouldShowActionBars()
    local result = false
    -- show player frame if player has a target
    if UnitExists("target") then result = true; end

    -- show player frame if player is in combat
    if UnitAffectingCombat(P) then result = true; end

    -- show player frame if player health is < 100%
    if isHealthOutsideThreshold() then result = true; end

    -- show if player frame is moused over
    if isMouseOverPlayerFrame() then result = true; end

    -- show if action bars are moused over
    if isMouseOverActionBar() then result = true; end

    return result;
end


-- Global Addon Functions
addon.togglePlayerFrame = function()
    if shouldShowPlayerFrame() then
        showPlayerFrame();
    else
        hidePlayerFrame();
    end
    C_Timer.NewTicker(0.10, function()
        if shouldShowPlayerFrame() then
            showPlayerFrame();
        else
            hidePlayerFrame();
        end
    end)
end

addon.toggleActionBars = function()
    if shouldShowActionBars() then
        showAllActionBars();
    else
        hideAllActionBars();
    end
    C_Timer.NewTicker(0.10, function()
        if shouldShowActionBars() then
            showAllActionBars();
        else
            hideAllActionBars();
        end
    end)
end