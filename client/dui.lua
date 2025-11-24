-- ============================================
-- CLIENT NUI - Interface pour la gestion des plantes
-- ============================================

local nuiOpen = false

-- ============================================
-- FONCTIONS
-- ============================================

--- Ouvre le NUI avec les données de la plante
local function openNUI(plantId, plant)
    print('[ZDRUGS] Ouverture NUI pour plante:', plantId)

    local drugConfig = Config.Drogues[plant.drugType]
    if not drugConfig then
        print('[ZDRUGS] Config drogue introuvable')
        return
    end

    -- Calculer le temps restant
    local growthPercent = plant.growthPercent or 0
    local totalDuration = drugConfig.croissance.duree_totale
    local remainingPercent = 100 - growthPercent
    local timeRemaining = (totalDuration * remainingPercent) / 100
    local minutes = math.floor(timeRemaining / 60)
    local seconds = math.floor(timeRemaining % 60)
    local timeText = plant.readyForHarvest and 'PRÊT !' or string.format('%02d:%02d', minutes, seconds)

    -- Envoyer les données au NUI
    SendNUIMessage({
        type = 'openMenu',
        plantId = plantId,
        plantData = {
            label = drugConfig.label,
            growthPercent = growthPercent,
            watered = plant.watered,
            fertilized = plant.fertilized,
            readyForHarvest = plant.readyForHarvest,
            timeText = timeText
        }
    })

    SetNuiFocus(true, true)
    nuiOpen = true

    print('[ZDRUGS] NUI ouvert avec succès')
end

--- Ferme le NUI
local function closeNUI()
    print('[ZDRUGS] Fermeture NUI')

    SendNUIMessage({
        type = 'closeMenu'
    })

    SetNuiFocus(false, false)
    nuiOpen = false
end

-- ============================================
-- EVENTS
-- ============================================

--- Event pour afficher l'état de la plante
RegisterNetEvent('zdrugs:client:viewPlantState', function(plantId)
    print('[ZDRUGS] Demande d\'affichage état plante:', plantId)

    lib.callback('zdrugs:getPlantData', false, function(plant)
        if not plant then
            print('[ZDRUGS] Pas de données de plante')
            lib.notify({
                type = 'error',
                description = 'Impossible de récupérer les données de la plante'
            })
            return
        end

        print('[ZDRUGS] Données reçues, ouverture NUI')
        openNUI(plantId, plant)
    end, plantId)
end)

-- ============================================
-- CALLBACKS NUI
-- ============================================

--- Callback pour fermer le menu
RegisterNUICallback('closeMenu', function(data, cb)
    print('[ZDRUGS] Callback closeMenu')
    closeNUI()
    cb('ok')
end)

--- Callback pour arroser la plante
RegisterNUICallback('waterPlant', function(data, cb)
    print('[ZDRUGS] Callback waterPlant:', data.plantId)

    closeNUI()

    -- Lancer l'animation et envoyer au serveur
    local playerPed = PlayerPedId()
    local animDict = Config.Animations.arroser.dict
    local animName = Config.Animations.arroser.anim

    lib.requestAnimDict(animDict, 5000)

    if lib.progressBar({
        duration = 5000,
        label = 'Arrosage de la plante...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = animDict,
            clip = animName
        }
    }) then
        ClearPedTasks(playerPed)
        TriggerServerEvent('zdrugs:server:waterPlant', data.plantId)
        print('[ZDRUGS] Arrosage terminé')
    else
        ClearPedTasks(playerPed)
        print('[ZDRUGS] Arrosage annulé')
    end

    cb('ok')
end)

--- Callback pour mettre de l'engrais
RegisterNUICallback('fertilizePlant', function(data, cb)
    print('[ZDRUGS] Callback fertilizePlant:', data.plantId)

    closeNUI()

    -- Lancer l'animation et envoyer au serveur
    local playerPed = PlayerPedId()
    local animDict = Config.Animations.engrais.dict
    local animName = Config.Animations.engrais.anim

    lib.requestAnimDict(animDict, 5000)

    if lib.progressBar({
        duration = 5000,
        label = 'Application de l\'engrais...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = animDict,
            clip = animName
        }
    }) then
        ClearPedTasks(playerPed)
        TriggerServerEvent('zdrugs:server:fertilizePlant', data.plantId)
        print('[ZDRUGS] Engrais appliqué')
    else
        ClearPedTasks(playerPed)
        print('[ZDRUGS] Engrais annulé')
    end

    cb('ok')
end)

--- Callback pour récolter la plante
RegisterNUICallback('harvestPlant', function(data, cb)
    print('[ZDRUGS] Callback harvestPlant:', data.plantId)

    closeNUI()

    -- Lancer l'animation et envoyer au serveur
    local playerPed = PlayerPedId()
    local animDict = Config.Animations.recolte.dict
    local animName = Config.Animations.recolte.anim

    lib.requestAnimDict(animDict, 5000)

    if lib.progressBar({
        duration = 5000,
        label = 'Récolte de la plante...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = animDict,
            clip = animName
        }
    }) then
        ClearPedTasks(playerPed)
        TriggerServerEvent('zdrugs:server:harvestPlant', data.plantId)
        print('[ZDRUGS] Récolte terminée')
    else
        ClearPedTasks(playerPed)
        print('[ZDRUGS] Récolte annulée')
    end

    cb('ok')
end)

-- ============================================
-- NETTOYAGE
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    print('[ZDRUGS] Resource stopping, nettoyage NUI')

    if nuiOpen then
        closeNUI()
    end
end)

-- ============================================
-- COMMANDE DEBUG
-- ============================================

RegisterCommand('testnui', function()
    print('^2[ZDRUGS] Test NUI command^0')

    SendNUIMessage({
        type = 'openMenu',
        plantId = 9999,
        plantData = {
            label = 'Cannabis',
            growthPercent = 75,
            watered = true,
            fertilized = false,
            readyForHarvest = false,
            timeText = '05:30'
        }
    })

    SetNuiFocus(true, true)
    nuiOpen = true
end, false)
