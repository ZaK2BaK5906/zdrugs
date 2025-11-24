-- ============================================
-- CLIENT DUI - Interface NUI pour l'état des plantes
-- ============================================

local nuiOpen = false

-- ============================================
-- GESTION DU NUI
-- ============================================

--- Affiche le NUI avec les données de la plante
---@param plant table Données de la plante
---@param drugConfig table Configuration de la drogue
local function showNUI(plant, drugConfig)
    local growthPercent = math.floor(plant.growthPercent or 0)

    -- Calculer le temps restant
    local totalDuration = drugConfig.croissance.duree_totale
    local remainingPercent = 100 - growthPercent
    local timeRemaining = (totalDuration * remainingPercent) / 100
    local minutes = math.floor(timeRemaining / 60)
    local seconds = math.floor(timeRemaining % 60)
    local timeText = plant.readyForHarvest and 'PRÊT !' or string.format('%02d:%02d', minutes, seconds)

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

    -- Auto-fermer après 15 secondes
    SetTimeout(15000, function()
        if nuiOpen then
            hideNUI()
        end
    end)
end

--- Cache le NUI
function hideNUI()
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
    hideNUI()
    cb('ok')
end)

-- ============================================
-- EVENTS
-- ============================================

--- Affiche l'état de la plante
RegisterNetEvent('zdrugs:client:showPlantMenu', function(plantId)
    lib.callback('zdrugs:getPlantData', false, function(plant)
        if not plant then return end

        local drugConfig = Config.Drogues[plant.drugType]
        if not drugConfig then return end

        showNUI(plant, drugConfig)
    end, plantId)
end)

--- Event principal pour afficher l'état
AddEventHandler('zdrugs:client:viewPlantState', function(plantId)
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
                hideNUI()
            end

            -- Fermer avec ESC
            if IsControlJustPressed(0, 322) then  -- ESC
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

    if nuiOpen then
        hideNUI()
    end
end)
