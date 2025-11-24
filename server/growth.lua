-- ============================================
-- SERVER GROWTH - Système de croissance et nettoyage
-- ============================================

local activePlants = exports.zdrugs:GetActivePlants()

-- ============================================
-- SYSTÈME DE CROISSANCE
-- ============================================

--- Calcule le pourcentage de croissance d'une plante
---@param plant table Données de la plante
---@param drugConfig table Configuration de la drogue
---@return number, number Pourcentage total, état actuel (0-3)
local function calculateGrowth(plant, drugConfig)
    local currentTime = os.time()
    local timeSincePlanted = currentTime - plant.plantedAt
    local totalDuration = drugConfig.croissance.duree_totale

    -- Calculer le pourcentage de croissance brut
    local rawPercent = (timeSincePlanted / totalDuration) * 100
    rawPercent = math.min(rawPercent, 100)  -- Max 100%

    -- Déterminer l'état actuel (0, 1, 2, 3)
    local state = 0
    if rawPercent >= 100 then
        state = 3  -- 100% - prêt à récolter
    elseif rawPercent >= 66 then
        state = 2  -- 66-99%
    elseif rawPercent >= 33 then
        state = 1  -- 33-65%
    else
        state = 0  -- 0-32%
    end

    return rawPercent, state
end

--- Vérifie si une plante peut passer à l'état suivant
---@param plant table Données de la plante
---@param newState number Nouvel état
---@return boolean
local function canGrowToNextState(plant, newState)
    -- Pour passer à un nouvel état, il faut avoir été arrosé ET fertilisé
    if newState > plant.growthState then
        return plant.watered and plant.fertilized
    end
    return true
end

--- Met à jour la croissance d'une plante
---@param plantId number ID de la plante
---@param plant table Données de la plante
local function updatePlantGrowth(plantId, plant)
    local drugConfig = Config.Drogues[plant.drugType]
    if not drugConfig then return end

    local growthPercent, newState = calculateGrowth(plant, drugConfig)

    -- Si le nouvel état est différent, vérifier les conditions
    if newState > plant.growthState then
        -- Peut-on passer au nouvel état ?
        if canGrowToNextState(plant, newState) then
            -- Passer au nouvel état
            plant.growthState = newState
            plant.growthPercent = growthPercent

            -- Réinitialiser arrosage et engrais pour le prochain état
            plant.watered = false
            plant.fertilized = false

            -- Si état 3 (100%), marquer comme prêt à récolter
            if newState >= 3 then
                plant.readyForHarvest = true
            end

            -- Sauvegarder en DB
            MySQL.update('UPDATE zdrugs_plants SET growth_state = ?, growth_percent = ?, watered = 0, fertilized = 0, ready_for_harvest = ?, last_update = ? WHERE id = ?', {
                newState,
                growthPercent,
                plant.readyForHarvest and 1 or 0,
                os.time(),
                plantId
            })

            -- Sync avec les clients
            TriggerClientEvent('zdrugs:client:syncPlant', -1, plantId, plant)
        else
            -- Conditions non remplies, rester à l'état actuel
            -- Mais mettre à jour le pourcentage dans la limite de l'état actuel
            local maxPercentForState = {
                [0] = 32.99,
                [1] = 65.99,
                [2] = 99.99,
                [3] = 100
            }
            plant.growthPercent = math.min(growthPercent, maxPercentForState[plant.growthState])

            MySQL.update('UPDATE zdrugs_plants SET growth_percent = ?, last_update = ? WHERE id = ?', {
                plant.growthPercent,
                os.time(),
                plantId
            })
        end
    else
        -- Même état, juste mettre à jour le pourcentage
        plant.growthPercent = growthPercent
        plant.lastUpdate = os.time()

        MySQL.update('UPDATE zdrugs_plants SET growth_percent = ?, last_update = ? WHERE id = ?', {
            growthPercent,
            os.time(),
            plantId
        })
    end
end

-- Thread de mise à jour de croissance (toutes les 30 secondes)
CreateThread(function()
    while true do
        Wait(30000)  -- 30 secondes

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
