Conceal = LibStub("AceAddon-3.0"):NewAddon("Conceal", "AceConsole-3.0", "AceTimer-3.0", "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local defaults = {
    profile = {
        interactive = true,
        health = 100,
        power = false,
        mouseover = true,
        alpha = 30,
        actionBar1 = true,
        actionBar2 = true,
        actionBar3 = true,
        actionBar4 = true,
        actionBar5 = true,
        actionBar6 = true,
        actionBar7 = true,
        actionBar8 = true,
        petActionBar = true,
        stanceBar = true,
        selfFrame = true,
        microBar = false,
        bagBar = false
    }
}

local options = {
    name = "Conceal ",
    handler = Conceal,
    type = "group",
    args = {
            -- General Options
            GeneralHeader = {
                order = 0,
                name = "General",
                type = "header",              
            },
            alpha = {
                order = 1,
                name = "Opacity",
                desc = "Opacity of the elements when concealed.",
                width = 2,
                type = "range",
                get = "GetSlider",
                set = "SetSlider",
                min = 0,
                max = 100,   
                step = 5,
                disabled = false,
            },
            health = {
                order = 2,
                name = "Health Treshold",
                desc = "The treshold which will trigger the elements to show if the Health % is bellow.",
                width = 2,
                type = "range",
                get = "GetSlider",
                set = "SetSlider",
                min = 0,
                max = 100,   
                step = 5,
                disabled = false,
            },
            selfFrame = {
                order = 3,
                name = "Player Frame",
                desc = "Conceal Player Frame.",
                type = "toggle",
                get = "GetStatus",
                set = "SetStatus",
                width = 2,
                disabled = false,
            },
            -- Action Bar Options
            ActionBarHeader = {
                order = 4,
                name = "Action Bars",
                type = "header",              
            },
            actionBar1 = {
                order = 5,
                name = "Action Bar 1",
                desc = "Conceal Action Bar 1",
                type = "toggle",
                get = "GetStatus",
                set = "SetStatus",
                width = "full",
                disabled = false,
            },
            actionBar2 = {
                order = 6,
                name = "Action Bar 2",
                desc = "Conceal Action Bar 2",
                type = "toggle",
                get = "GetStatus",
                set = "SetStatus",
                width = "full",
                disabled = false,
            },
            actionBar3 = {
                order = 7,
                name = "Action Bar 3",
                desc = "Conceal Action Bar 3",
                type = "toggle",
                get = "GetStatus",
                set = "SetStatus",
                width = "full",
                disabled = false,
            },
            actionBar4 = {
                order = 8,
                name = "Action Bar 4",
                desc = "Conceal Action Bar 4",
                type = "toggle",
                get = "GetStatus",
                set = "SetStatus",
                width = "full",
                disabled = false,
            },
            actionBar5 = {
                order = 9,
                name = "Action Bar 5",
                desc = "Conceal Action Bar 5",
                type = "toggle",
                get = "GetStatus",
                set = "SetStatus",
                width = "full",
                disabled = false,
            },
            actionBar6 = {
                order = 10,
                name = "Action Bar 6",
                desc = "Conceal Action Bar 6",
                type = "toggle",
                get = "GetStatus",
                set = "SetStatus",
                width = "full",
                disabled = false,
            },
            actionBar7 = {
                order = 11,
                name = "Action Bar 7",
                desc = "Conceal Action Bar 7",
                type = "toggle",
                get = "GetStatus",
                set = "SetStatus",
                width = "full",
                disabled = false,
            },
            actionBar8 = {
                order = 12,
                name = "Action Bar 8",
                desc = "Conceal Action Bar 8",
                type = "toggle",
                get = "GetStatus",
                set = "SetStatus",
                width = "full",
                disabled = false,
            },
            -- Other Bar Options
            OtherBarsHeader = {
                order = 13,
                name = "Other Bars",
                type = "header",              
            },
            petActionBar = {
                order = 14,
                name = "Pet Action Bar",
                desc = "Conceal Pet Action Bar",
                type = "toggle",
                get = "GetStatus",
                set = "SetStatus",
                width = 1.5,
                disabled = false,
            },
            stanceBar = {
                order = 15,
                name = "Stance Bar",
                desc = "Conceal Stance Bar",
                type = "toggle",
                get = "GetStatus",
                set = "SetStatus",
                width = 1.5,
                disabled = false,
            },
            microBar = {
                order = 16,
                name = "Micro Bar and Bags",
                desc = "Conceal Blizzard's micro bar and Bags.",
                type = "toggle",
                get = "GetStatus",
                set = "SetStatus",
                width = 1.5,
                disabled = false,
            },
    }
}

ActionBar2 = MultiBarBottomLeft
ActionBar3 = MultiBarBottomRight
ActionBar4 = MultiBarRight 
ActionBar5 = MultiBarLeft
ActionBar6 = MultiBar5
ActionBar7 = MultiBar6
ActionBar8 = MultiBar7

function Conceal:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("ConcealDB", defaults, true) 
    self.db.RegisterCallback(self, "OnProfileChanged", "ProfileHandler")
    self.db.RegisterCallback(self, "OnProfileCopied", "ProfileHandler")
    self.db.RegisterCallback(self, "OnProfileReset", "ProfileHandler")
    AC:RegisterOptionsTable("Conceal_options", options) 
    self.optionsFrame = ACD:AddToBlizOptions("Conceal_options", "Conceal")  
    
    Conceal:RegisterEvent("ADDON_LOADED", "loadConfig");
    Conceal:RegisterEvent("PLAYER_ENTERING_WORLD", "refreshGUI");
    Conceal:RegisterEvent("PLAYER_LEAVING_WORLD", "refreshGUI");
    Conceal:RegisterEvent("PLAYER_ENTER_COMBAT", "refreshGUI");
    Conceal:RegisterEvent("PLAYER_LEAVE_COMBAT", "refreshGUI");
    Conceal:RegisterEvent("PLAYER_REGEN_ENABLED", "refreshGUI");
    Conceal:RegisterEvent("PLAYER_REGEN_DISABLED", "refreshGUI");
    Conceal:RegisterEvent("PLAYER_TARGET_CHANGED", "refreshGUI");
    
    Conceal:HideGcdFlash()
    
    C_Timer.NewTicker(0.10, function()
        if Conceal:shouldShowElements() then 
            Conceal:showPlayerFrame();
            Conceal:showAllActionBars();
        else
            Conceal:hidePlayerFrame();
            Conceal:hideAllActionBars();
        end
    end)
end

function Conceal:UpdateHealth(units)
    if units.player then
        Conceal:refreshGUI()
    end
end

-- Conditionals
function Conceal:isHealthOutsideThreshold()
    local threshold = self.db.profile["health"];
    if threshold then
        local hp = UnitHealth("player");
        local maxHP = UnitHealthMax("player");
        local pct = (hp / maxHP) * 100;
        return pct < threshold;
    else
        return false;
    end
end

function Conceal:isMouseOverPlayerFrame()
    local isPlayerFrameConcealable = self.db.profile["selfFrame"] 
    if isPlayerFrameConcealable then
        return PlayerFrame:IsMouseOver()
    else
        return false;
    end
end

function Conceal:isMouseOverActionBar()
    if self.db.profile["actionBar1"] then
        for i=1,12 do 
            if _G["ActionButton" ..i]:IsMouseOver() then return true; end
        end
    end
    if self.db.profile["actionBar2"] then if ActionBar2:IsMouseOver() then return true; end end
    if self.db.profile["actionBar3"] then if ActionBar3:IsMouseOver() then return true; end end
    if self.db.profile["actionBar4"] then if ActionBar4:IsMouseOver() then return true; end end
    if self.db.profile["actionBar5"] then if ActionBar5:IsMouseOver() then return true; end end
    if self.db.profile["actionBar6"] then if ActionBar6:IsMouseOver() then return true; end end
    if self.db.profile["actionBar7"] then if ActionBar7:IsMouseOver() then return true; end end
    if self.db.profile["actionBar8"] then if ActionBar8:IsMouseOver() then return true; end end
    if self.db.profile["petActionBar"] then if PetActionBar:IsMouseOver() then return true; end end
    if self.db.profile["stanceBar"] then if StanceBar:IsMouseOver() then return true; end end
    if self.db.profile["microBar"] then if MicroButtonAndBagsBar:IsMouseOver() then return true; end end
    return false
end

function Conceal:shouldShowElements()

    -- show elements if player has a target
    if UnitExists("target") then return true; end

    -- show elements if player is in combat
    if UnitAffectingCombat("player") then return true; end

    -- show player frame if player health is < 100%
    if Conceal:isHealthOutsideThreshold() then return true; end

    -- show player frame if it is moused over
    if Conceal:isMouseOverPlayerFrame() then return true; end

    -- show if action bars are moused over
    if Conceal:isMouseOverActionBar() then return true; end

    return false;
end

function Conceal:showPlayerFrame()
    PlayerFrame:SetAlpha(1);
    PlayerFrame:EnableMouse(true);
end

function Conceal:showAllActionBars()
    for i=1,12 do
        _G["ActionButton" ..i]:SetAlpha(1)
    end
    ActionBar2:SetAlpha(1);
    ActionBar3:SetAlpha(1);
    ActionBar4:SetAlpha(1);
    ActionBar5:SetAlpha(1);
    ActionBar6:SetAlpha(1);
    ActionBar7:SetAlpha(1);
    ActionBar8:SetAlpha(1);
    PetActionBar:SetAlpha(1);
    StanceBar:SetAlpha(1);
    MicroButtonAndBagsBar:SetAlpha(1); 
end

function Conceal:hidePlayerFrame()
    local finalAlpha = 1
    local isPlayerFrameConcealable = self.db.profile["selfFrame"] 
    if isPlayerFrameConcealable then 
        local frameAlpha = self.db.profile["alpha"] 
        if frameAlpha > 1 then
            finalAlpha = frameAlpha / 100
        end
    end
    PlayerFrame:SetAlpha(finalAlpha);
end

function Conceal:hideAllActionBars()
    local frameAlpha = self.db.profile["alpha"]
    if frameAlpha > 1 then
        frameAlpha = frameAlpha / 100
    end
    if self.db.profile["actionBar1"] then
        for i=1,12 do
            _G["ActionButton" ..i]:SetAlpha(frameAlpha)
        end
    else 
        for i=1,12 do
            _G["ActionButton" ..i]:SetAlpha(1)
        end
    end
    if self.db.profile["actionBar2"] then ActionBar2:SetAlpha(frameAlpha); else ActionBar2:SetAlpha(1); end
    if self.db.profile["actionBar3"] then ActionBar3:SetAlpha(frameAlpha); else ActionBar3:SetAlpha(1); end
    if self.db.profile["actionBar4"] then ActionBar4:SetAlpha(frameAlpha); else ActionBar4:SetAlpha(1); end
    if self.db.profile["actionBar5"] then ActionBar5:SetAlpha(frameAlpha); else ActionBar5:SetAlpha(1); end
    if self.db.profile["actionBar6"] then ActionBar6:SetAlpha(frameAlpha); else ActionBar6:SetAlpha(1); end
    if self.db.profile["actionBar7"] then ActionBar7:SetAlpha(frameAlpha); else ActionBar7:SetAlpha(1); end
    if self.db.profile["actionBar8"] then ActionBar8:SetAlpha(frameAlpha); else ActionBar8:SetAlpha(1); end
    if self.db.profile["petActionBar"] then PetActionBar:SetAlpha(frameAlpha); else PetActionBar:SetAlpha(1); end
    if self.db.profile["stanceBar"] then StanceBar:SetAlpha(frameAlpha); else StanceBar:SetAlpha(1); end
    if self.db.profile["microBar"] then 
        MicroButtonAndBagsBar:SetAlpha(frameAlpha);
    else
        MicroButtonAndBagsBar:SetAlpha(1); 
    end    
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

    Conceal:loadConfig()  
    Conceal:refreshGUI() 
end

function Conceal:loadConfig()
    -- Unused for now
end

function Conceal:refreshGUI()
    if Conceal:shouldShowElements() then 
        Conceal:showPlayerFrame();
        Conceal:showAllActionBars();
    else
        Conceal:hidePlayerFrame();
        Conceal:hideAllActionBars();
    end
end

function Conceal:GetStatus(info)
    Conceal:refreshGUI()
    Conceal:loadConfig()
    return self.db.profile[info[#info]]
end

function Conceal:SetStatus(info)
    if self.db.profile[info[#info]] then
        self.db.profile[info[#info]] = false
    else 
        self.db.profile[info[#info]] = true
        Conceal:loadConfig()
    end
    Conceal:refreshGUI()
end

function Conceal:GetSlider(info)
    return self.db.profile[info[#info]]
end

function Conceal:SetSlider(info, value)
    self.db.profile[info[#info]] = value
end