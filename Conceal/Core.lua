-- Conceal: entry point, shared state, and lifecycle.
--
-- WoW addons have no `require`, so every file shares state through the single
-- global `Conceal` frame/table created here. Other files read and write fields
-- on it (Conceal.settingsDB, Conceal.defaults, Conceal.elements, ...) and hang
-- their methods off it. See Config.lua, Fade.lua, and Options.lua.
Conceal = CreateFrame("Frame")

-- Replaced by Conceal:LoadSettings() at init; start as an empty table so any
-- accidental early read is still a table.
Conceal.settingsDB = {}

function Conceal:OnInitialize()
    self:LoadSettings()

    Conceal:CreateSettingsWindow()
    QueueStatusButton:SetParent(UIParent)
    Conceal.tickerHandle = C_Timer.NewTicker(0.25, function()
        Conceal:TickUpdate()
    end)
    Conceal:TickUpdate()
end

function Conceal:PLAYER_ENTERING_WORLD(event, isInitialLogin, isReloadingUi)
    -- On a full login or reconnect the world becomes ready here; re-tick so frames
    -- reflect current combat/target state immediately. IsContextActive reads combat
    -- live, so no cached flag needs re-syncing.
    Conceal:UpdateUI()
end

function Conceal:OnEvent(event, ...)
	self[event](self, event, ...)
end

function Conceal:ADDON_LOADED(event, addOnName)
	if event == "ADDON_LOADED" and (addOnName == "Conceal") then
        Conceal:OnInitialize()
    end
end

Conceal:RegisterEvent("ADDON_LOADED")
Conceal:RegisterEvent("PLAYER_ENTERING_WORLD")

Conceal:SetScript("OnEvent", Conceal.OnEvent)
