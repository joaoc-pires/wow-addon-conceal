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
    utilityCooldownViewerConcealDuringCombat = false,
    socialButton = false,
    minimapCluster = false,
    minimapClusterConcealDuringCombat = false,
    bagsBar = false,
    bagsBarConcealDuringCombat = false
}

local lastDesired = {}   -- key -> last alpha applied (number, normalized 0..1)
local tickerHandle = nil
local animCache = {}     -- frame -> { group, anim }, reused across fades to cut GC churn

-- Shared element descriptors: single source of truth for both the settings UI
-- (CreateSettingsWindow) and the per-tick alpha updates (TickUpdate). Assigned
-- below, once IsActionBar1MouseOver exists to be referenced.
-- Fields:
--   key            setting key (the enable checkbox)
--   name, tooltip  checkbox label + tooltip (omit when settings == false)
--   combat         { key, name, tooltip } => indented "in combat" child + gating
--   cat            settings group: "main" | "frames" | "cooldown" | "bars" | "extra"
--   header         { title, subtitle } section header emitted before this item
--   frame          global NAME resolved lazily via _G each tick for the standard Apply
--   mouseOverFn    custom mouseover predicate (defaults to frame:IsMouseOver())
--   revealOnFlyout stay visible while a spell flyout is open
--   settings       false => skip the settings loop (applied but not user-configurable)
--   special        true  => skip the standard Apply loop (hand-written in TickUpdate)
local elements

-- Force a duration away from exactly 0: a 0s animation never fires OnFinished,
-- so callers relying on the completion hook (e.g. MinimapCluster's Hide-at-zero)
-- would stall. 0.01s is effectively instant while still completing.
local function nonZeroDuration(d)
    return (d == 0) and 0.01 or d
end


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

    -- Sliders stay hand-written: they're not checkboxes and don't fit the descriptor mold.
    do
        local name = "Opacity"
        local variable = "conceal_alpha"
        local variableKey = "alpha"
        local tooltip = "Opacity applied to UI elements while they are concealed."
        local defaultValue = settingsDB["alpha"]
        local minValue = 0
        local maxValue = 100
        local step = 5

        local setting = Settings.RegisterAddOnSetting(concealOptions, variable, variableKey, settingsDB, type(defaultValue), name, defaultValue)
        setting:SetValueChangedCallback(function(setting, value)
            -- Store the raw 0..100 value; GetConcealAlpha owns normalization at tick time.
            settingsDB["alpha"] = value
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
        local tooltip = "Duration of the fade animation when an element returns to its concealed state."
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

    for _, e in ipairs(elements) do
        if e.settings ~= false then
            local group = groups[e.cat]
            if e.header then
                group.layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(e.header[1], e.header[2] or ""));
            end
            local _, parentInitializer = Conceal:SetupSubCategoryCheckbox(e.key, e.name, e.tooltip, settingsDB[e.key], group.category)
            if e.combat then
                local _, combatInitializer = Conceal:SetupSubCategoryCheckbox(e.combat.key, e.combat.name, e.combat.tooltip, settingsDB[e.combat.key], group.category)
                local parentKey = e.key
                combatInitializer:Indent()
                combatInitializer:SetParentInitializer(parentInitializer, function() return settingsDB[parentKey] end)
            end
        end
    end
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

    local duration = nonZeroDuration(settingsDB["animationDuration"])

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

    local duration = nonZeroDuration(settingsDB["fadeOutDuration"])

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
    -- Clamp a full 1.0 down to 0.95: a truly opaque "concealed" alpha causes frame drops.
    if a == 1 then a = 0.95 end
    return a
end

function Conceal:IsContextActive()
    -- Read combat state live each tick rather than trusting a cached flag: on a
    -- reconnect mid-fight no combat-transition event fires and the server sends
    -- combat state slightly after login, so a live read here self-heals within one
    -- tick once that state arrives.
    if InCombatLockdown() or UnitAffectingCombat("player") then return true end
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

-- Descriptor table (see the field notes near the top). Defined here so mouseOverFn
-- references (IsActionBar1MouseOver) already exist; CreateSettingsWindow and
-- TickUpdate close over the `elements` upvalue and only run after full load.
elements = {
    { cat = "main", key = "actionTargetMode",
      name = "Action Target Mode",
      tooltip = "UI elements are considered inactive unless you are in combat. Target presence alone will not reveal concealed elements." },

    -- Player Frames
    { cat = "frames", header = { "Player Frames", "" }, key = "selfFrame", frame = "PlayerFrame", special = true,
      name = "Enable Player frame",
      tooltip = "Allow the player frame to fade when inactive. It becomes fully visible on combat, target activity, or mouseover.",
      combat = { key = "selfFrameConcealDuringCombat", name = "Hide Player frame in combat",
                 tooltip = "While in combat, the player frame remains concealed unless hovered with the mouse." } },
    { cat = "frames", key = "targetFrame", frame = "TargetFrame",
      name = "Enable Target frame",
      tooltip = "Allow the target frame to fade when inactive. It becomes fully visible on combat, target activity, or mouseover.",
      combat = { key = "targetFrameConcealDuringCombat", name = "Conceal Target Frame During Combat",
                 tooltip = "While in combat, the target frame remains concealed unless hovered with the mouse." } },
    -- Focus frame has no settings UI but is still concealed like the others.
    { key = "focusFrame", frame = "FocusFrame", settings = false,
      combat = { key = "focusFrameConcealDuringCombat" } },
    { cat = "frames", key = "buffFrame", special = true,
      name = "Enable Buff List",
      tooltip = "Allow the buff list to fade when inactive. Buffs become fully visible on combat, target activity, or mouseover." },
    { cat = "frames", key = "debuffFrame", special = true,
      name = "Enable Debuff List",
      tooltip = "Allow the debuff list to fade when inactive. Debuffs become fully visible on combat, target activity, or mouseover." },
    { cat = "frames", header = { "Cast Bar", "This option disables the cast bar entirely and ignores all conceal rules." },
      key = "castBar", special = true,
      name = "Disable Cast Bar",
      tooltip = "Completely disables the player cast bar. This is not a fade effect." },

    -- Cooldown Manager
    { cat = "cooldown", key = "buffIconCooldownViewer", frame = "BuffIconCooldownViewer",
      name = "Buff Icon Cooldown Viewer",
      tooltip = "Allow the Buff Icon Cooldown Viewer to fade when inactive. It becomes fully visible on combat, target activity, or mouseover.",
      combat = { key = "buffIconCooldownViewerConcealDuringCombat", name = "Conceal Buff Icon Cooldown Viewer During Combat",
                 tooltip = "While in combat, the Buff Icon Cooldown Viewer remains concealed unless hovered." } },
    { cat = "cooldown", key = "essentialCooldownViewer", frame = "EssentialCooldownViewer",
      name = "Essential Cooldown Viewer",
      tooltip = "Allow the Essential Cooldown Viewer to fade when inactive. It becomes fully visible on combat, target activity, or mouseover.",
      combat = { key = "essentialCooldownViewerConcealDuringCombat", name = "Conceal Essential Cooldown Viewer During Combat",
                 tooltip = "While in combat, the Essential Cooldown Viewer remains concealed unless hovered." } },
    { cat = "cooldown", key = "utilityCooldownViewer", frame = "UtilityCooldownViewer",
      name = "Utility Cooldown Viewer",
      tooltip = "Allow the Utility Cooldown Viewer to fade when inactive. It becomes fully visible on combat, target activity, or mouseover.",
      combat = { key = "utilityCooldownViewerConcealDuringCombat", name = "Conceal Utility Cooldown Viewer During Combat",
                 tooltip = "While in combat, the Utility Cooldown Viewer remains concealed unless hovered." } },

    -- Action Bars
    { cat = "bars", header = { "Main Action Bars", "Action Bars from 1 to 3" },
      key = "actionBar1", frame = "MainActionBar", mouseOverFn = Conceal.IsActionBar1MouseOver, revealOnFlyout = true,
      name = "Enable on Action Bar 1", tooltip = "Conceal Action Bar 1",
      combat = { key = "actionBar1ConcealDuringCombat", name = "Hide Action Bar 1 in combat",
                 tooltip = "Only shows the Action Bar 1 when the mouse is hovering" } },
    { cat = "bars", key = "actionBar2", frame = "MultiBarBottomLeft", revealOnFlyout = true,
      name = "Enable on Action Bar 2", tooltip = "Conceal Action Bar 2",
      combat = { key = "actionBar2ConcealDuringCombat", name = "Hide Action Bar 2 in combat",
                 tooltip = "Only shows the Action Bar 2 when the mouse is hovering" } },
    { cat = "bars", key = "actionBar3", frame = "MultiBarBottomRight", revealOnFlyout = true,
      name = "Enable on Action Bar 3", tooltip = "Conceal Action Bar 3",
      combat = { key = "actionBar3ConcealDuringCombat", name = "Hide Action Bar 3 in combat",
                 tooltip = "Only shows the Action Bar 3 when the mouse is hovering" } },
    { cat = "bars", header = { "Extra Action Bars", "Action Bars from 4 to 8" },
      key = "actionBar4", frame = "MultiBarRight", revealOnFlyout = true,
      name = "Enable on Action Bar 4", tooltip = "Conceal Action Bar 4",
      combat = { key = "actionBar4ConcealDuringCombat", name = "Hide Action Bar 4 in combat",
                 tooltip = "Only shows the Action Bar 4 when the mouse is hovering" } },
    { cat = "bars", key = "actionBar5", frame = "MultiBarLeft", revealOnFlyout = true,
      name = "Enable on Action Bar 5", tooltip = "Conceal Action Bar 5",
      combat = { key = "actionBar5ConcealDuringCombat", name = "Hide Action Bar 5 in combat",
                 tooltip = "Only shows the Action Bar 5 when the mouse is hovering" } },
    { cat = "bars", key = "actionBar6", frame = "MultiBar5", revealOnFlyout = true,
      name = "Enable on Action Bar 6", tooltip = "Conceal Action Bar 6",
      combat = { key = "actionBar6ConcealDuringCombat", name = "Hide Action Bar 6 in combat",
                 tooltip = "Only shows the Action Bar 6 when the mouse is hovering" } },
    { cat = "bars", key = "actionBar7", frame = "MultiBar6", revealOnFlyout = true,
      name = "Enable on Action Bar 7", tooltip = "Conceal Action Bar 7",
      combat = { key = "actionBar7ConcealDuringCombat", name = "Hide Action Bar 7 in combat",
                 tooltip = "Only shows the Action Bar 7 when the mouse is hovering" } },
    { cat = "bars", key = "actionBar8", frame = "MultiBar7", revealOnFlyout = true,
      name = "Enable on Action Bar 8", tooltip = "Conceal Action Bar 8",
      combat = { key = "actionBar8ConcealDuringCombat", name = "Hide Action Bar 8 in combat",
                 tooltip = "Only shows the Action Bar 8 when the mouse is hovering" } },

    -- Extra Elements
    { cat = "extra", key = "petActionBar", frame = "PetActionBar", revealOnFlyout = true,
      name = "Enable Pet Action Bar", tooltip = "Conceal Pet Action Bar",
      combat = { key = "petActionBarConcealDuringCombat", name = "Hide Pet Action Bar in combat",
                 tooltip = "Only shows the pet action bar when the mouse is hovering" } },
    { cat = "extra", key = "stanceBar", frame = "StanceBar", revealOnFlyout = true,
      name = "Enable Stance Action Bar", tooltip = "Conceal Stance Action Bar",
      combat = { key = "stanceBarConcealDuringCombat", name = "Hide Stance Action Bar in combat",
                 tooltip = "Only shows the stance action bar when the mouse is hovering" } },
    { cat = "extra", key = "microBar", frame = "MicroMenuContainer",
      name = "Enable Micro Bar", tooltip = "Conceal Micro Bar",
      combat = { key = "microBarConcealDuringCombat", name = "Hide Micro Bar in combat",
                 tooltip = "Only shows the micro bar when the mouse is hovering" } },
    { cat = "extra", key = "experience", frame = "StatusTrackingBarManager",
      name = "Enable Experience Bar", tooltip = "Conceal Experience Bar",
      combat = { key = "experienceConcealDuringCombat", name = "Hide Experience Bar in combat",
                 tooltip = "Only shows the experience bar when the mouse is hovering" } },
    { cat = "extra", key = "minimapCluster", frame = "MinimapCluster", special = true,
      name = "Enable Minimap", tooltip = "Conceal the Minimap",
      combat = { key = "minimapClusterConcealDuringCombat", name = "Hide Minimap in combat",
                 tooltip = "Only shows the minimap when the mouse is hovering" } },
    { cat = "extra", key = "bagsBar", frame = "BagsBar",
      name = "Enable Bags Bar", tooltip = "Conceal the Bags Bar",
      combat = { key = "bagsBarConcealDuringCombat", name = "Hide Bags Bar in combat",
                 tooltip = "Only shows the bags bar when the mouse is hovering" } },
    { cat = "extra", key = "objectiveTracker", frame = "ObjectiveTrackerFrame",
      name = "Enable Objective Tracker", tooltip = "Conceal Objective Tracker" },
    { cat = "extra", key = "socialButton", frame = "QuickJoinToastButton",
      name = "Enable Social Button", tooltip = "Conceal Social Button" },
}

-- Actions
-- Event Handlers

function Conceal:AnimateToAlpha(frame, toAlpha, duration, onFinished)
    if frame == nil then return end
    local fromAlpha = frame:GetAlpha()

    if tonumber(string.format("%.2f", fromAlpha)) == tonumber(string.format("%.2f", toAlpha)) then
        -- Already at the target; still run the completion hook so callers relying
        -- on it (e.g. MinimapCluster's Hide-at-zero) aren't skipped.
        if onFinished then onFinished() end
        return
    end

    -- Reuse one animation group + Alpha animation per frame instead of building a
    -- fresh CreateAnimationGroup() on every fade; over a long session that churn adds
    -- up. Re-set (or clear) the OnFinished each call so a stale hook can't leak onto
    -- a later, unrelated transition.
    local cached = animCache[frame]
    if not cached then
        local group = frame:CreateAnimationGroup()
        local anim = group:CreateAnimation("Alpha")
        anim:SetStartDelay(0)
        group:SetToFinalAlpha(true)
        cached = { group = group, anim = anim }
        animCache[frame] = cached
    end

    local group, anim = cached.group, cached.anim
    group:Stop()
    anim:SetFromAlpha(fromAlpha)
    anim:SetToAlpha(toAlpha)
    anim:SetDuration(duration)
    if onFinished then
        group:SetScript("OnFinished", function() onFinished() end)
    else
        group:SetScript("OnFinished", nil)
    end
    group:Play()
end

function Conceal:TickUpdate()
    local frameAlpha = Conceal:GetConcealAlpha()
    local contextActive = Conceal:IsContextActive()

    local function Apply(key, frame, concealDuringContextKey, mouseOverFn, revealOnFlyout)
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
            -- A spell flyout (e.g. a teleport/portal list) can't be reliably attributed to the
            -- specific bar that opened it, so any bar/action-adjacent element opted in here
            -- stays visible while any flyout is open.
            if not hovered and revealOnFlyout and SpellFlyout and SpellFlyout:IsShown() then
                hovered = true
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
            Conceal:AnimateToAlpha(frame, 1, nonZeroDuration(settingsDB["animationDuration"]))
        else
            Conceal:AnimateToAlpha(frame, frameAlpha, nonZeroDuration(settingsDB["fadeOutDuration"]))
        end
        lastDesired[key] = desired
    end

    -- Player + Pet (pet gated). Both deliberately share the "selfFrame" key/state, so
    -- they're applied here as an adjacent pair rather than via the descriptor loop.
    Apply("selfFrame", PlayerFrame, "selfFrameConcealDuringCombat")
    if UnitExists("pet") then
        Apply("selfFrame", PetFrame, "selfFrameConcealDuringCombat")
    end

    -- Standard, data-driven elements (everything not flagged special).
    for _, e in ipairs(elements) do
        if e.frame and not e.special then
            Apply(e.key, _G[e.frame], e.combat and e.combat.key, e.mouseOverFn, e.revealOnFlyout)
        end
    end

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

    -- MinimapCluster is special: some of its pieces are only hidden by Hide(), not
    -- by alpha. So we always Show() before a transition (to fade in visibly), and
    -- only Hide() at the *end* of a fade whose concealed alpha is exactly 0.
    if MinimapCluster then
        if not settingsDB["minimapCluster"] then
            if lastDesired["minimapCluster"] ~= 1 then
                MinimapCluster:Show()
                MinimapCluster:SetAlpha(1)
                lastDesired["minimapCluster"] = 1
            end
        else
            local hovered = settingsDB["mouseover"] and MinimapCluster:IsMouseOver()

            local desired
            if hovered then
                desired = 1
            elseif contextActive and not settingsDB["minimapClusterConcealDuringCombat"] then
                desired = 1
            else
                desired = frameAlpha
            end

            if lastDesired["minimapCluster"] ~= desired then
                -- Make the frame visible for the transition; Hide() is deferred to the
                -- fade-to-0 completion below.
                MinimapCluster:Show()
                lastDesired["minimapCluster"] = desired

                if desired == 1 then
                    Conceal:AnimateToAlpha(MinimapCluster, 1, nonZeroDuration(settingsDB["animationDuration"]))
                elseif frameAlpha == 0 then
                    Conceal:AnimateToAlpha(MinimapCluster, 0, nonZeroDuration(settingsDB["fadeOutDuration"]), function()
                        -- Guard against a stale fade-out finishing after a newer fade-in:
                        -- only hide if the current intent is still fully concealed.
                        if lastDesired["minimapCluster"] == 0 then
                            MinimapCluster:Hide()
                        end
                    end)
                else
                    Conceal:AnimateToAlpha(MinimapCluster, frameAlpha, nonZeroDuration(settingsDB["fadeOutDuration"]))
                end
            end
        end
    end

    -- cast bar policy remains separate
    if settingsDB["castBar"] then PlayerCastingBarFrame:UnregisterAllEvents()
    else PlayerCastingBarFrame:RegisterAllEvents() end
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
