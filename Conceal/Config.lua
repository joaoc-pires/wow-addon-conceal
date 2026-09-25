-- Conceal: default settings and SavedVariables persistence.

Conceal.defaults = {
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
    bagsBarConcealDuringCombat = false,
    swingTimerMainHand = false,
    swingTimerMainHandConcealDuringCombat = false,
    swingTimerOffHand = false,
    swingTimerOffHandConcealDuringCombat = false,
    swingTimerRanged = false,
    swingTimerRangedConcealDuringCombat = false
}

-- Load persisted settings, seeding first-run defaults and merging any newly
-- added defaults into an existing (older) saved table so upgrades are safe.
function Conceal:LoadSettings()
    local savedSettingsDB = ConcealDataBase
    if not savedSettingsDB then
        self.settingsDB = self.defaults
        ConcealDataBase = self.defaults
    else
        self.settingsDB = savedSettingsDB
        -- Merge new defaults into existing saved variables (upgrade-safe)
        for k, v in pairs(self.defaults) do
            if self.settingsDB[k] == nil then
                self.settingsDB[k] = v
            end
        end
    end
end
