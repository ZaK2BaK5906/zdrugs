-- ============================================
-- SERVER GROWTH - Système de croissance et nettoyage
-- ============================================

-- Fonction pour récupérer activePlants dynamiquement
local function getActivePlants()
    return exports.zdrugs:GetActivePlants()
end

-- ============================================
-- SYSTÈME DE CROISSANCE
-- ============================================

--- Calcule le pourcentage de croissance d'une plante (SYSTÈME PAR PALIERS)
---@param plant table Données de la plante
---@param drugConfig table Configuration de la drogue
---@return number Pourcentage actuel
local function calculateGrowth(plant, drugConfig)
    -- Paliers: 0%, 33%, 66%, 100%
    -- growthState: 0 (0%), 1 (33%), 2 (66%), 3 (100%)

    local stageBases = {
        [0] = 0,    -- État 0 → 0%
        [1] = 33,   -- État 1 → 33%
        [2] = 66,   -- État 2 → 66%
        [3] = 100   -- État 3 → 100%
    }

    -- Si la plante n'a pas les 2 items (eau + engrais), elle ne grandit pas
    if not plant.watered or not plant.fertilized then
        -- Retourner le pourcentage du palier actuel
        return stageBases[plant.growthState] or 0
    end

    -- La plante a les 2 items, elle peut grandir vers le palier suivant
    local currentTime = os.time()
    local timeGrowing = currentTime - plant.lastUpdate  -- Temps depuis l'ajout des 2 items
    local totalDuration = drugConfig.croissance.duree_totale
    local stageDuration = totalDuration / 3  -- Chaque palier prend 1/3 du temps total

    -- Calculer le pourcentage dans le palier actuel (0 à 33)
    local percentInStage = (timeGrowing / stageDuration) * 33
    percentInStage = math.min(percentInStage, 33)  -- Max 33% par palier

    -- Pourcentage total = base du palier + progression dans le palier
    local totalPercent = stageBases[plant.growthState] + percentInStage

    return totalPercent
end

--- Met à jour la croissance d'une plante (SYSTÈME PAR PALIERS)
---@param plantId number ID de la plante
---@param plant table Données de la plante
local function updatePlantGrowth(plantId, plant)
    local drugConfig = Config.Drogues[plant.drugType]
    if not drugConfig then return end

    -- Si la plante est déjà à 100%, ne rien faire
    if plant.growthState >= 3 then
        return
    end

    -- Calculer le pourcentage actuel
    local growthPercent = calculateGrowth(plant, drugConfig)

    -- Vérifier si la plante a atteint le palier suivant (33, 66, ou 100)
    local nextStagePercent = {
        [0] = 33,   -- De 0 → 33%
        [1] = 66,   -- De 33 → 66%
        [2] = 100   -- De 66 → 100%
    }

    local targetPercent = nextStagePercent[plant.growthState]

    if growthPercent >= targetPercent and plant.watered and plant.fertilized then
        -- PALIER ATTEINT! Passer au stade suivant
        plant.growthState = plant.growthState + 1
        plant.growthPercent = targetPercent

        -- Réinitialiser eau + engrais pour le prochain palier
        plant.watered = false
        plant.fertilized = false
        plant.lastUpdate = os.time()

        -- Si on atteint 100%, marquer comme prêt à récolter
        if plant.growthState >= 3 then
            plant.readyForHarvest = true
        end

        -- Sauvegarder en DB
        MySQL.update('UPDATE zdrugs_plants SET growth_state = ?, growth_percent = ?, watered = 0, fertilized = 0, ready_for_harvest = ?, last_update = ? WHERE id = ?', {
            plant.growthState,
            plant.growthPercent,
            plant.readyForHarvest and 1 or 0,
            os.time(),
            plantId
        })

        print(string.format('[ZDRUGS] Plante #%d → Palier %d atteint (%d%%)', plantId, plant.growthState, targetPercent))
    else
        -- Palier non atteint, mettre à jour le pourcentage
        plant.growthPercent = growthPercent

        MySQL.update('UPDATE zdrugs_plants SET growth_percent = ? WHERE id = ?', {
            growthPercent,
            plantId
        })
    end

    -- Sync avec les clients (toujours)
    TriggerClientEvent('zdrugs:client:syncPlant', -1, plantId, plant)
end

-- Thread de mise à jour de croissance (toutes les 5 secondes en mode test)
CreateThread(function()
    while true do
        Wait(5000)  -- 5 secondes (MODE TEST!)

        local activePlants = getActivePlants()
        for plantId, plant in pairs(activePlants) do
            if not plant.readyForHarvest then
                updatePlantGrowth(plantId, plant)
            end
        end
    end
end)

-- ============================================
-- SYSTÈME DE NETTOYAGE AUTOMATIQUE
-- ============================================

--- Supprime les plantes trop anciennes
local function cleanupOldPlants()
    local currentTime = os.time()
    local maxAge = Config.Limites.suppression_auto_apres
    local activePlants = getActivePlants()

    for plantId, plant in pairs(activePlants) do
        local age = currentTime - plant.plantedAt

        if age > maxAge then
            -- Supprimer de la DB
            MySQL.query('DELETE FROM zdrugs_plants WHERE id = ?', {plantId})

            -- Retirer du cache
            activePlants[plantId] = nil

            -- Informer les clients
            TriggerClientEvent('zdrugs:client:removePlant', -1, plantId)

            print(('[^3zdrugs^0] Plante #%s supprimée (trop ancienne: %s heures)'):format(plantId, math.floor(age / 3600)))
        end
    end
end

-- Thread de nettoyage (toutes les 10 minutes)
CreateThread(function()
    while true do
        Wait(600000)  -- 10 minutes
        cleanupOldPlants()
    end
end)

-- ============================================
-- COMMANDE ADMIN DE NETTOYAGE MANUEL
-- ============================================

RegisterCommand('zdrugs:cleanup', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        cleanupOldPlants()  -- Commande console
        return
    end

    -- Vérifier les permissions admin
    if xPlayer.getGroup() ~= 'admin' and xPlayer.getGroup() ~= 'superadmin' then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Vous n\'avez pas la permission'
        })
        return
    end

    cleanupOldPlants()

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = 'Nettoyage des plantes anciennes effectué'
    })
end, false)

-- ============================================
-- COMMANDE ADMIN POUR VOIR LES STATS
-- ============================================

RegisterCommand('zdrugs:stats', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then
        -- Console
        local totalPlants = 0
        for _ in pairs(activePlants) do
            totalPlants = totalPlants + 1
        end
        print(('[^2zdrugs^0] Total de plantes actives: %s'):format(totalPlants))
        return
    end

    -- Vérifier les permissions admin
    if xPlayer.getGroup() ~= 'admin' and xPlayer.getGroup() ~= 'superadmin' then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Vous n\'avez pas la permission'
        })
        return
    end

    local stats = {
        total = 0,
        cocaine = 0,
        weed = 0,
        ready = 0
    }

    for _, plant in pairs(activePlants) do
        stats.total = stats.total + 1

        if plant.drugType == 'cocaine' then
            stats.cocaine = stats.cocaine + 1
        elseif plant.drugType == 'weed' then
            stats.weed = stats.weed + 1
        end

        if plant.readyForHarvest then
            stats.ready = stats.ready + 1
        end
    end

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'info',
        title = 'Statistiques zdrugs',
        description = ('Total: %s | Cocaine: %s | Weed: %s | Prêtes: %s'):format(
            stats.total,
            stats.cocaine,
            stats.weed,
            stats.ready
        )
    })
end, false)

-- ============================================
-- EXPORTS
-- ============================================

exports('CleanupOldPlants', cleanupOldPlants)
exports('UpdatePlantGrowth', updatePlantGrowth)
