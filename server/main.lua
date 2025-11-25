-- ============================================
-- SERVER MAIN - Gestion des plantes et actions
-- ============================================

local activePlants = {}  -- Cache des plantes actives {plantId = plantData}
local playerPlants = {}  -- Cache du nombre de plantes par joueur {identifier = count}

-- ============================================
-- INITIALISATION AU DÉMARRAGE
-- ============================================

CreateThread(function()
    -- Charger toutes les plantes depuis la base de données
    local plants = MySQL.query.await('SELECT * FROM zdrugs_plants', {})

    for _, plant in ipairs(plants) do
        activePlants[plant.id] = {
            id = plant.id,
            owner = plant.owner,
            drugType = plant.drug_type,
            coords = json.decode(plant.coords),
            growthState = plant.growth_state,
            growthPercent = plant.growth_percent,
            watered = plant.watered == 1,
            fertilized = plant.fertilized == 1,
            plantedAt = plant.planted_at,
            lastUpdate = plant.last_update,
            readyForHarvest = plant.ready_for_harvest == 1
        }

        -- Compter les plantes par joueur
        playerPlants[plant.owner] = (playerPlants[plant.owner] or 0) + 1
    end

    print(('[^2zdrugs^0] %s plantes chargées depuis la base de données'):format(#plants))
end)

-- ============================================
-- FONCTIONS UTILITAIRES
-- ============================================

--- Vérifie si un joueur a l'item avec la quantité requise
---@param source number ID du joueur
---@param item string Nom de l'item
---@param quantity number Quantité requise
---@return boolean
local function hasItem(source, item, quantity)
    local count = exports.ox_inventory:Search(source, 'count', item)
    return count >= quantity
end

--- Retire des items de l'inventaire du joueur
---@param source number ID du joueur
---@param item string Nom de l'item
---@param quantity number Quantité à retirer
---@return boolean
local function removeItem(source, item, quantity)
    return exports.ox_inventory:RemoveItem(source, item, quantity)
end

--- Ajoute des items à l'inventaire du joueur
---@param source number ID du joueur
---@param item string Nom de l'item
---@param quantity number Quantité à ajouter
---@param metadata table|nil Métadonnées optionnelles
---@return boolean
local function addItem(source, item, quantity, metadata)
    return exports.ox_inventory:AddItem(source, item, quantity, metadata)
end

--- Enregistre une action dans les logs
---@param player string Identifiant du joueur
---@param action string Type d'action
---@param drugType string Type de drogue
---@param details table|nil Détails additionnels
local function logAction(player, action, drugType, details)
    MySQL.insert('INSERT INTO zdrugs_logs (player, action, drug_type, details, timestamp) VALUES (?, ?, ?, ?, ?)', {
        player,
        action,
        drugType,
        json.encode(details or {}),
        os.time()
    })
end

--- Compte le nombre de plantes d'un joueur
---@param identifier string Identifiant du joueur
---@return number
local function getPlayerPlantCount(identifier)
    return playerPlants[identifier] or 0
end

--- Vérifie la distance entre deux points
---@param coords1 vector3
---@param coords2 vector3
---@return number
local function getDistance(coords1, coords2)
    return #(coords1 - coords2)
end

-- ============================================
-- PLANTATION
-- ============================================

--- Vérifie si une plante peut être plantée à cet endroit
---@param coords vector3 Coordonnées de plantation
---@return boolean, string|nil
local function canPlantHere(coords)
    -- Vérifier la distance avec les autres plantes
    for _, plant in pairs(activePlants) do
        local plantCoords = vector3(plant.coords.x, plant.coords.y, plant.coords.z)
        if getDistance(coords, plantCoords) < Config.Limites.distance_min_entre_plantes then
            return false, Config.Messages.plante_trop_pres
        end
    end

    return true, nil
end

--- Plante une graine
RegisterNetEvent('zdrugs:server:plantSeed', function(drugType, coords, heading)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local drugConfig = Config.Drogues[drugType]
    if not drugConfig or drugConfig.type ~= 'plantable' then
        return
    end

    -- Vérifier si le joueur a atteint la limite de plantes
    local plantCount = getPlayerPlantCount(xPlayer.identifier)
    if plantCount >= Config.Limites.max_plantes_par_joueur then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Messages.limite_plantes:format(plantCount, Config.Limites.max_plantes_par_joueur)
        })
        return
    end

    -- Vérifier si le joueur a la graine
    if not hasItem(source, drugConfig.graine, 1) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Messages.pas_assez_items
        })
        return
    end

    -- Vérifier si on peut planter ici
    local canPlant, errorMsg = canPlantHere(coords)
    if not canPlant then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = errorMsg
        })
        return
    end

    -- Retirer la graine
    if not removeItem(source, drugConfig.graine, 1) then
        return
    end

    -- Enregistrer en base de données
    local plantId = MySQL.insert.await('INSERT INTO zdrugs_plants (owner, drug_type, coords, growth_state, growth_percent, planted_at, last_update) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        xPlayer.identifier,
        drugType,
        json.encode({x = coords.x, y = coords.y, z = coords.z, heading = heading}),
        0,
        0.0,
        os.time(),
        os.time()
    })

    -- Ajouter au cache
    activePlants[plantId] = {
        id = plantId,
        owner = xPlayer.identifier,
        drugType = drugType,
        coords = {x = coords.x, y = coords.y, z = coords.z, heading = heading},
        growthState = 0,
        growthPercent = 0.0,
        watered = false,
        fertilized = false,
        plantedAt = os.time(),
        lastUpdate = os.time(),
        readyForHarvest = false
    }

    -- Mettre à jour le compteur du joueur
    playerPlants[xPlayer.identifier] = plantCount + 1

    -- Logger l'action
    logAction(xPlayer.identifier, 'plant', drugType, {coords = coords})

    -- Informer tous les clients de la nouvelle plante
    TriggerClientEvent('zdrugs:client:syncPlant', -1, plantId, activePlants[plantId])

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = 'Graine plantée avec succès'
    })
end)

-- ============================================
-- ARROSAGE
-- ============================================

RegisterNetEvent('zdrugs:server:waterPlant', function(plantId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local plant = activePlants[plantId]
    if not plant then return end

    -- Vérifier si le joueur est le propriétaire
    if plant.owner ~= xPlayer.identifier then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Vous n\'êtes pas le propriétaire de cette plante'
        })
        return
    end

    -- NOUVEAU SYSTÈME: Si le pourcentage dépasse le palier du state actuel, reset eau/engrais
    local stageBases = {[0] = 0, [1] = 33, [2] = 66, [3] = 100}
    local currentStageBase = stageBases[plant.growthState] or 0

    -- Si la plante a atteint ou dépassé son palier (ex: 33% mais state=0), reset pour nouveau palier
    if plant.growthPercent >= currentStageBase + 33 and (plant.watered or plant.fertilized) then
        print(string.format('[ZDRUGS] Plante #%d atteint palier (%d%% >= %d%%) - RESET watered/fertilized',
            plantId, plant.growthPercent, currentStageBase + 33))
        plant.watered = false
        plant.fertilized = false
        plant.growthState = math.floor(plant.growthPercent / 33)
        MySQL.update('UPDATE zdrugs_plants SET watered = 0, fertilized = 0, growth_state = ? WHERE id = ?', {
            plant.growthState,
            plantId
        })
        TriggerClientEvent('zdrugs:client:syncPlant', -1, plantId, plant)
    end

    -- Vérifier si déjà arrosée
    if plant.watered then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Cette plante est déjà arrosée'
        })
        return
    end

    -- Vérifier si le joueur a de l'eau
    if not hasItem(source, Config.Items.eau, 1) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Messages.pas_assez_items
        })
        return
    end

    -- Retirer l'eau
    if not removeItem(source, Config.Items.eau, 1) then
        return
    end

    -- Mettre à jour la plante
    plant.watered = true
    plant.lastUpdate = os.time()  -- Démarrer/mettre à jour le compteur de croissance

    MySQL.update('UPDATE zdrugs_plants SET watered = 1, last_update = ? WHERE id = ?', {
        os.time(),
        plantId
    })

    -- Logger l'action
    logAction(xPlayer.identifier, 'water', plant.drugType, {plantId = plantId})

    -- Sync avec les clients
    TriggerClientEvent('zdrugs:client:syncPlant', -1, plantId, plant)

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = Config.Messages.plante_arrosee
    })
end)

-- ============================================
-- ENGRAIS
-- ============================================

RegisterNetEvent('zdrugs:server:fertilizePlant', function(plantId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local plant = activePlants[plantId]
    if not plant then return end

    -- Vérifier si le joueur est le propriétaire
    if plant.owner ~= xPlayer.identifier then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Vous n\'êtes pas le propriétaire de cette plante'
        })
        return
    end

    -- NOUVEAU SYSTÈME: Si le pourcentage dépasse le palier du state actuel, reset eau/engrais
    local stageBases = {[0] = 0, [1] = 33, [2] = 66, [3] = 100}
    local currentStageBase = stageBases[plant.growthState] or 0

    -- Si la plante a atteint ou dépassé son palier (ex: 33% mais state=0), reset pour nouveau palier
    if plant.growthPercent >= currentStageBase + 33 and (plant.watered or plant.fertilized) then
        print(string.format('[ZDRUGS] Plante #%d atteint palier (%d%% >= %d%%) - RESET watered/fertilized',
            plantId, plant.growthPercent, currentStageBase + 33))
        plant.watered = false
        plant.fertilized = false
        plant.growthState = math.floor(plant.growthPercent / 33)
        MySQL.update('UPDATE zdrugs_plants SET watered = 0, fertilized = 0, growth_state = ? WHERE id = ?', {
            plant.growthState,
            plantId
        })
        TriggerClientEvent('zdrugs:client:syncPlant', -1, plantId, plant)
    end

    -- Vérifier si déjà fertilisée
    if plant.fertilized then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Cette plante a déjà reçu de l\'engrais'
        })
        return
    end

    -- Vérifier si le joueur a de l'engrais
    if not hasItem(source, Config.Items.engrais, 1) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Messages.pas_assez_items
        })
        return
    end

    -- Retirer l'engrais
    if not removeItem(source, Config.Items.engrais, 1) then
        return
    end

    -- Mettre à jour la plante
    plant.fertilized = true
    plant.lastUpdate = os.time()  -- Démarrer/mettre à jour le compteur de croissance

    MySQL.update('UPDATE zdrugs_plants SET fertilized = 1, last_update = ? WHERE id = ?', {
        os.time(),
        plantId
    })

    -- Logger l'action
    logAction(xPlayer.identifier, 'fertilize', plant.drugType, {plantId = plantId})

    -- Sync avec les clients
    TriggerClientEvent('zdrugs:client:syncPlant', -1, plantId, plant)

    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = Config.Messages.engrais_ajoute
    })
end)

-- ============================================
-- RÉCOLTE
-- ============================================

RegisterNetEvent('zdrugs:server:harvestPlant', function(plantId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local plant = activePlants[plantId]
    if not plant then return end

    -- Vérifier si le joueur est le propriétaire
    if plant.owner ~= xPlayer.identifier then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Vous n\'êtes pas le propriétaire de cette plante'
        })
        return
    end

    -- Vérifier si la plante est prête
    if not plant.readyForHarvest then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Messages.plante_pas_prete
        })
        return
    end

    local drugConfig = Config.Drogues[plant.drugType]
    if not drugConfig then return end

    -- Quantité aléatoire de récolte
    local quantity = math.random(drugConfig.recolte.quantite.min, drugConfig.recolte.quantite.max)

    -- Ajouter les items récoltés
    if addItem(source, drugConfig.recolte.item, quantity) then
        -- Supprimer la plante
        MySQL.query('DELETE FROM zdrugs_plants WHERE id = ?', {plantId})
        activePlants[plantId] = nil

        -- Mettre à jour le compteur du joueur
        playerPlants[xPlayer.identifier] = math.max(0, (playerPlants[xPlayer.identifier] or 0) - 1)

        -- Logger l'action
        logAction(xPlayer.identifier, 'harvest', plant.drugType, {plantId = plantId, quantity = quantity})

        -- Informer les clients de la suppression
        TriggerClientEvent('zdrugs:client:removePlant', -1, plantId)

        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            description = Config.Messages.recolte_success:format(quantity, drugConfig.recolte.item)
        })
    end
end)

-- ============================================
-- SYNCHRONISATION
-- ============================================

--- Envoie toutes les plantes actives à un client
RegisterNetEvent('zdrugs:server:requestSync', function()
    local source = source
    TriggerClientEvent('zdrugs:client:syncAllPlants', source, activePlants)
end)

--- Récupère les données d'une plante (avec growthPercent à jour en temps réel)
lib.callback.register('zdrugs:getPlantData', function(source, plantId)
    local plant = activePlants[plantId]
    if not plant then return nil end

    -- Calculer le pourcentage en temps réel (pas attendre le thread)
    local drugConfig = Config.Drogues[plant.drugType]
    if drugConfig and not plant.readyForHarvest then
        local stageBases = {[0] = 0, [1] = 33, [2] = 66, [3] = 100}

        -- Si la plante n'a pas les 2 items, retourner le palier actuel
        if not plant.watered or not plant.fertilized then
            plant.growthPercent = stageBases[plant.growthState] or 0
        else
            -- Calculer la croissance en temps réel
            local currentTime = os.time()
            local timeGrowing = currentTime - plant.lastUpdate
            local totalDuration = drugConfig.croissance.duree_totale
            local stageDuration = totalDuration / 3
            local percentInStage = math.min((timeGrowing / stageDuration) * 33, 33)
            plant.growthPercent = (stageBases[plant.growthState] or 0) + percentInStage
        end
    end

    return plant
end)

-- ============================================
-- CONSOMMATION DE DROGUES (OPTIONNEL)
-- ============================================

--- Gère la consommation d'une drogue
RegisterNetEvent('zdrugs:server:consumeDrug', function(drugType)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    -- Logger la consommation
    logAction(xPlayer.identifier, 'consume', drugType, {
        timestamp = os.time()
    })

    -- Vous pouvez ajouter des effets ici si vous utilisez un système de status
    -- Par exemple: TriggerEvent('esx_status:add', source, 'drug', 100000)
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('GetActivePlants', function()
    return activePlants
end)

exports('GetPlayerPlantCount', function(identifier)
    return getPlayerPlantCount(identifier)
end)
