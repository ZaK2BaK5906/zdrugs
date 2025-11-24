-- ============================================
-- CLIENT DUI - Interface NUI pour l'état des plantes
-- ============================================

local nuiOpen = false
local maxDistance = 5.0  -- Distance maximum (5 mètres)

-- ============================================
-- GESTION DU NUI
-- ============================================

--- Affiche le NUI avec les données de la plante
---@param plant table Données de la plante
---@param drugConfig table Configuration de la drogue
local function showNUI(plant, drugConfig)
    print('[ZDRUGS] showNUI appelé')  -- DEBUG

    local growthPercent = math.floor(plant.growthPercent or 0)

    -- Calculer le temps restant
    local totalDuration = drugConfig.croissance.duree_totale
    local remainingPercent = 100 - growthPercent
    local timeRemaining = (totalDuration * remainingPercent) / 100
    local minutes = math.floor(timeRemaining / 60)
    local seconds = math.floor(timeRemaining % 60)
    local timeText = plant.readyForHarvest and 'PRÊT !' or string.format('%02d:%02d', minutes, seconds)

    print(('[ZDRUGS] Envoi NUI - Drug: %s, Growth: %d%%'):format(drugConfig.label, growthPercent))  -- DEBUG

    -- Envoyer les données au NUI
    SendNUIMessage({
        action = 'show',
        drugLabel = drugConfig.label,
        growthPercent = growthPercent,
        watered = plant.watered,
        fertilized = plant.fertilized,
        timeText = timeText
    })

    SetNuiFocus(false, false)  -- Pas de focus souris, juste affichage
    nuiOpen = true

    print('[ZDRUGS] NUI affiché')  -- DEBUG

    -- Auto-fermer après 15 secondes
    SetTimeout(15000, function()
        if nuiOpen then
            print('[ZDRUGS] Auto-close NUI')  -- DEBUG
            hideNUI()
        end
    end)
end

--- Cache le NUI
function hideNUI()
    print('[ZDRUGS] hideNUI appelé')  -- DEBUG

    SendNUIMessage({
        action = 'hide'
    })

    SetNuiFocus(false, false)
    nuiOpen = false
end

-- ============================================
-- CALLBACK NUI
-- ============================================

RegisterNUICallback('close', function(data, cb)
    print('[ZDRUGS] NUI callback close')  -- DEBUG
    hideNUI()
    cb('ok')
end)

-- ============================================
-- EVENTS
-- ============================================

--- Affiche l'état de la plante avec vérification de distance
RegisterNetEvent('zdrugs:client:showPlantMenu', function(plantId)
    print(('[ZDRUGS] showPlantMenu appelé pour plantId: %s'):format(plantId))  -- DEBUG

    lib.callback('zdrugs:getPlantData', false, function(plant)
        if not plant then
            print('[ZDRUGS] Pas de données de plante')  -- DEBUG
            return
        end

        print(('[ZDRUGS] Données reçues - Type: %s'):format(plant.drugType))  -- DEBUG

        local drugConfig = Config.Drogues[plant.drugType]
        if not drugConfig then
            print('[ZDRUGS] Config drogue introuvable')  -- DEBUG
            return
        end

        -- Vérifier la distance avec la plante
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local plantCoords = vector3(plant.coords.x, plant.coords.y, plant.coords.z)
        local distance = #(playerCoords - plantCoords)

        print(('[ZDRUGS] Distance plante: %.2fm (max: %.2fm)'):format(distance, maxDistance))  -- DEBUG

        if distance > maxDistance then
            lib.notify({
                type = 'error',
                description = 'Vous êtes trop loin de la plante !'
            })
            print('[ZDRUGS] Trop loin de la plante')  -- DEBUG
            return
        end

        -- Afficher le NUI
        showNUI(plant, drugConfig)
    end, plantId)
end)

--- Event principal pour afficher l'état
AddEventHandler('zdrugs:client:viewPlantState', function(plantId)
    print(('[ZDRUGS] viewPlantState appelé pour plantId: %s'):format(plantId))  -- DEBUG
    TriggerEvent('zdrugs:client:showPlantMenu', plantId)
end)

-- ============================================
-- GESTION DES TOUCHES
-- ============================================

CreateThread(function()
    while true do
        Wait(0)

        if nuiOpen then
            -- Fermer avec X
            if IsControlJustPressed(0, 73) then  -- X
                print('[ZDRUGS] Touche X pressée')  -- DEBUG
                hideNUI()
            end

            -- Fermer avec ESC
            if IsControlJustPressed(0, 322) then  -- ESC
                print('[ZDRUGS] Touche ESC pressée')  -- DEBUG
                hideNUI()
            end
        else
            Wait(500)  -- Réduire la charge CPU quand fermé
        end
    end
end)

-- ============================================
-- NETTOYAGE
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    print('[ZDRUGS] Resource stopping, closing NUI')  -- DEBUG
    if nuiOpen then
        hideNUI()
    end
end)

-- ============================================
-- COMMAND DEBUG
-- ============================================

RegisterCommand('testnui', function()
    print('[ZDRUGS] Test NUI command')
    SendNUIMessage({
        action = 'show',
        drugLabel = 'TEST',
        growthPercent = 75,
        watered = true,
        fertilized = false,
        timeText = '05:30'
    })
    nuiOpen = true
end, false)
