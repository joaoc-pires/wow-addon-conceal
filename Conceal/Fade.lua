-- Conceal: fade conditionals, the shared element descriptor, and the tick loop.

local lastDesired = {}   -- key -> last alpha applied (number, normalized 0..1)
local animCache = {}     -- frame -> { group, anim }, reused across fades to cut GC churn

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


-- Conditionals
function Conceal:FadeIn(frame, forced)
    if frame == nil then return end

    if forced then
        frame:SetAlpha(1) -- immediate show
        return
    end

    local duration = nonZeroDuration(Conceal.settingsDB["animationDuration"])

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

    local duration = nonZeroDuration(Conceal.settingsDB["fadeOutDuration"])

    -- If you want to avoid restarting the same transition, keep the guard:
    local currentAlpha = tonumber(string.format("%.2f", frame:GetAlpha()))
    if currentAlpha == tonumber(string.format("%.2f", frameAlpha)) then
        return
    end

    Conceal:AnimateToAlpha(frame, frameAlpha, duration)
end

function Conceal:GetConcealAlpha()
    local a = Conceal.settingsDB["alpha"] or 30
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
    if UnitExists("target") and not Conceal.settingsDB["actionTargetMode"] then return true end
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

-- Shared element descriptors: single source of truth for both the settings UI
-- (CreateSettingsWindow, in Options.lua) and the per-tick alpha updates
-- (TickUpdate, below).
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
--
-- Defined here (after IsActionBar1MouseOver) so the mouseOverFn reference below
-- already exists when this table literal is evaluated.
Conceal.elements = {
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

-- Jump straight to an alpha with no fade, stopping any in-flight animation first so
-- it can't keep running and override the value.
local function snapToAlpha(frame, alpha)
    local cached = animCache[frame]
    if cached then cached.group:Stop() end
    frame:SetAlpha(alpha)
end

-- instant: apply transitions with SetAlpha instead of animating. Used while dragging
-- the Opacity slider, where restarting a fade on every step tanks the frame rate.
function Conceal:TickUpdate(instant)
    local frameAlpha = Conceal:GetConcealAlpha()
    local contextActive = Conceal:IsContextActive()

    local function Apply(key, frame, concealDuringContextKey, mouseOverFn, revealOnFlyout)
        if frame == nil then return end
        if not Conceal.settingsDB[key] then
            -- if element is disabled, keep fully visible
            if lastDesired[key] ~= 1 then
                frame:SetAlpha(1)
                lastDesired[key] = 1
            end
            return
        end

        local hovered = false
        if Conceal.settingsDB["mouseover"] then
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
        elseif contextActive and not (concealDuringContextKey and Conceal.settingsDB[concealDuringContextKey]) then
            desired = 1
        else
            desired = frameAlpha
        end

        if lastDesired[key] == desired then
            return
        end

        -- animate only on transitions
        if instant then
            snapToAlpha(frame, desired)
        elseif desired == 1 then
            Conceal:AnimateToAlpha(frame, 1, nonZeroDuration(Conceal.settingsDB["animationDuration"]))
        else
            Conceal:AnimateToAlpha(frame, frameAlpha, nonZeroDuration(Conceal.settingsDB["fadeOutDuration"]))
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
    for _, e in ipairs(Conceal.elements) do
        if e.frame and not e.special then
            Apply(e.key, _G[e.frame], e.combat and e.combat.key, e.mouseOverFn, e.revealOnFlyout)
        end
    end

    -- Buff/Debuff: preserve your current “always show in context” behavior:
    -- if you want them to follow the same rule as others, remove this special-case.
    if Conceal.settingsDB["buffFrame"] then
        local desired = (contextActive or (Conceal.settingsDB["mouseover"] and BuffFrame:IsMouseOver())) and 1 or frameAlpha
        if lastDesired["buffFrame"] ~= desired then
            if instant then snapToAlpha(BuffFrame, desired)
            elseif desired == 1 then Conceal:FadeIn(BuffFrame) else Conceal:FadeOut(BuffFrame) end
            lastDesired["buffFrame"] = desired
        end
    else
        if lastDesired["buffFrame"] ~= 1 then BuffFrame:SetAlpha(1); lastDesired["buffFrame"] = 1 end
    end

    if Conceal.settingsDB["debuffFrame"] then
        local desired = (contextActive or (Conceal.settingsDB["mouseover"] and DebuffFrame:IsMouseOver())) and 1 or frameAlpha
        if lastDesired["debuffFrame"] ~= desired then
            if instant then snapToAlpha(DebuffFrame, desired)
            elseif desired == 1 then Conceal:FadeIn(DebuffFrame) else Conceal:FadeOut(DebuffFrame) end
            lastDesired["debuffFrame"] = desired
        end
    else
        if lastDesired["debuffFrame"] ~= 1 then DebuffFrame:SetAlpha(1); lastDesired["debuffFrame"] = 1 end
    end

    -- MinimapCluster is special: some of its pieces are only hidden by Hide(), not
    -- by alpha. So we always Show() before a transition (to fade in visibly), and
    -- only Hide() at the *end* of a fade whose concealed alpha is exactly 0.
    if MinimapCluster then
        if not Conceal.settingsDB["minimapCluster"] then
            if lastDesired["minimapCluster"] ~= 1 then
                MinimapCluster:Show()
                MinimapCluster:SetAlpha(1)
                lastDesired["minimapCluster"] = 1
            end
        else
            local hovered = Conceal.settingsDB["mouseover"] and MinimapCluster:IsMouseOver()

            local desired
            if hovered then
                desired = 1
            elseif contextActive and not Conceal.settingsDB["minimapClusterConcealDuringCombat"] then
                desired = 1
            else
                desired = frameAlpha
            end

            if lastDesired["minimapCluster"] ~= desired then
                -- Make the frame visible for the transition; Hide() is deferred to the
                -- fade-to-0 completion below.
                MinimapCluster:Show()
                lastDesired["minimapCluster"] = desired

                if instant then
                    -- No fade to complete, so hide right away instead of on OnFinished.
                    snapToAlpha(MinimapCluster, desired)
                    if desired == 0 then MinimapCluster:Hide() end
                elseif desired == 1 then
                    Conceal:AnimateToAlpha(MinimapCluster, 1, nonZeroDuration(Conceal.settingsDB["animationDuration"]))
                elseif frameAlpha == 0 then
                    Conceal:AnimateToAlpha(MinimapCluster, 0, nonZeroDuration(Conceal.settingsDB["fadeOutDuration"]), function()
                        -- Guard against a stale fade-out finishing after a newer fade-in:
                        -- only hide if the current intent is still fully concealed.
                        if lastDesired["minimapCluster"] == 0 then
                            MinimapCluster:Hide()
                        end
                    end)
                else
                    Conceal:AnimateToAlpha(MinimapCluster, frameAlpha, nonZeroDuration(Conceal.settingsDB["fadeOutDuration"]))
                end
            end
        end
    end

    -- cast bar policy remains separate
    if Conceal.settingsDB["castBar"] then PlayerCastingBarFrame:UnregisterAllEvents()
    else PlayerCastingBarFrame:RegisterAllEvents() end
end
