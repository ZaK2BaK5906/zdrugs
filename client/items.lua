-- ============================================
-- CLIENT ITEMS - Exports pour items utilisables
-- ============================================

-- ============================================
-- GRAINES (USABLE ITEMS)
-- ============================================

--- Utilisation de la graine de coca
---@param data table Données de l'item
---@param slot number Slot de l'item
exports('useGraineCoca', function(data, slot)
    TriggerEvent('zdrugs:client:plantSeed', 'cocaine', slot)
end)

--- Utilisation de la graine de weed
---@param data table Données de l'item
---@param slot number Slot de l'item
exports('useGraineWeed', function(data, slot)
    TriggerEvent('zdrugs:client:plantSeed', 'weed', slot)
end)

-- ============================================
-- DROGUES CONSOMMABLES (OPTIONNEL)
-- ============================================

--- Consommation de cocaïne
---@param data table Données de l'item
---@param slot number Slot de l'item
exports('useCocaine', function(data, slot)
    local playerPed = PlayerPedId()

    -- Animation
    RequestAnimDict('anim@amb@nightclub@peds@')
    while not HasAnimDictLoaded('anim@amb@nightclub@peds@') do
        Wait(10)
    end

    TaskPlayAnim(playerPed, 'anim@amb@nightclub@peds@', 'missfbi3_party_d', 8.0, -8.0, -1, 49, 0, false, false, false)

    if lib.progressBar({
        duration = 3000,
        label = 'Consommation de cocaïne...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true
        }
    }) then
        ClearPedTasks(playerPed)

        -- Effets (à personnaliser selon vos besoins)
        TriggerServerEvent('zdrugs:server:consumeDrug', 'cocaine')

        lib.notify({
            type = 'success',
            description = 'Vous avez consommé de la cocaïne'
        })

        -- Effets optionnels (vitesse, stamina, etc.)
        -- SetRunSprintMultiplierForPlayer(PlayerId(), 1.3)
        -- RestorePlayerStamina(PlayerId(), 100.0)
    else
        ClearPedTasks(playerPed)
    end
end)

--- Consommation de weed
---@param data table Données de l'item
---@param slot number Slot de l'item
exports('useWeed', function(data, slot)
    local playerPed = PlayerPedId()

    -- Animation de fumer
    RequestAnimDict('amb@world_human_aa_smoke@male@idle_a')
    while not HasAnimDictLoaded('amb@world_human_aa_smoke@male@idle_a') do
        Wait(10)
    end

    TaskPlayAnim(playerPed, 'amb@world_human_aa_smoke@male@idle_a', 'idle_c', 8.0, -8.0, -1, 49, 0, false, false, false)

    if lib.progressBar({
        duration = 5000,
        label = 'Fumer du cannabis...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true
        }
    }) then
        ClearPedTasks(playerPed)

        TriggerServerEvent('zdrugs:server:consumeDrug', 'weed')

        lib.notify({
            type = 'success',
            description = 'Vous avez fumé du cannabis'
        })

        -- Effets optionnels (ralentissement, vision floue, etc.)
        -- SetTimecycleModifier('spectator5')
        -- SetPedMotionBlur(playerPed, true)
    else
        ClearPedTasks(playerPed)
    end
end)

--- Consommation de meth
---@param data table Données de l'item
---@param slot number Slot de l'item
exports('useMeth', function(data, slot)
    local playerPed = PlayerPedId()

    -- Animation
    RequestAnimDict('anim@amb@nightclub@peds@')
    while not HasAnimDictLoaded('anim@amb@nightclub@peds@') do
        Wait(10)
    end

    TaskPlayAnim(playerPed, 'anim@amb@nightclub@peds@', 'missfbi3_party_d', 8.0, -8.0, -1, 49, 0, false, false, false)

    if lib.progressBar({
        duration = 3000,
        label = 'Consommation de méthamphétamine...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true
        }
    }) then
        ClearPedTasks(playerPed)

        TriggerServerEvent('zdrugs:server:consumeDrug', 'meth')

        lib.notify({
            type = 'success',
            description = 'Vous avez consommé de la méthamphétamine'
        })

        -- Effets optionnels (vitesse, force, vision, etc.)
        -- SetRunSprintMultiplierForPlayer(PlayerId(), 1.5)
        -- SetPlayerMeleeWeaponDamageModifier(PlayerId(), 1.5)
    else
        ClearPedTasks(playerPed)
    end
end)
