-- ============================================
-- CLIENT MAIN - Gestion des plantes côté client
-- ============================================

local activePlants = {}  -- Cache local des plantes {plantId = {object, data}}
local isPlanting = false

-- ============================================
-- INITIALISATION
-- ============================================

CreateThread(function()
    -- Demander la sync des plantes au serveur
    TriggerServerEvent('zdrugs:server:requestSync')
end)

-- ============================================
-- FONCTIONS UTILITAIRES
-- ============================================

--- Charge un dictionnaire d'animation
---@param dict string Nom du dictionnaire
local function loadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
    end
end

--- Charge un modèle
---@param model string|number Nom ou hash du modèle
local function loadModel(model)
    local modelHash = type(model) == 'string' and GetHashKey(model) or model

    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(10)
        end
    end
end

-- ============================================
-- GESTION DES PROPS DE PLANTES
-- ============================================

--- Crée un prop de plante
---@param plantId number ID de la plante
---@param plant table Données de la plante
local function createPlantProp(plantId, plant)
    local drugConfig = Config.Drogues[plant.drugType]
    if not drugConfig then return end

    -- Déterminer le prop à utiliser selon l'état de croissance
    local propModel = drugConfig.croissance.props[plant.growthState + 1]
    if not propModel then return end

    loadModel(propModel)

    local coords = vector3(plant.coords.x, plant.coords.y, plant.coords.z)
    local heading = plant.coords.heading or 0.0

    -- Créer l'objet
    local obj = CreateObject(GetHashKey(propModel), coords.x, coords.y, coords.z, true, false, false)
    SetEntityHeading(obj, heading)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetEntityAsMissionEntity(obj, true, true)

    -- Attendre que l'objet soit créé
    local timeout = 0
    while not DoesEntityExist(obj) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    -- Stocker dans le cache
    activePlants[plantId] = {
        object = obj,
        data = plant
    }

    -- Ajouter les interactions ox_target
    setupPlantInteractions(plantId, obj, plant)
end

--- Supprime un prop de plante
---@param plantId number ID de la plante
local function removePlantProp(plantId)
    local plantCache = activePlants[plantId]
    if not plantCache then return end

    -- Supprimer l'objet
    if DoesEntityExist(plantCache.object) then
        exports.ox_target:removeLocalEntity(plantCache.object)
        DeleteEntity(plantCache.object)
    end

    activePlants[plantId] = nil
end

--- Met à jour le prop d'une plante
---@param plantId number ID de la plante
---@param plant table Nouvelles données de la plante
local function updatePlantProp(plantId, plant)
    local plantCache = activePlants[plantId]
    if not plantCache then
        -- La plante n'existe pas localement, la créer
        createPlantProp(plantId, plant)
        return
    end

    -- Vérifier si l'état de croissance a changé
    if plantCache.data.growthState ~= plant.growthState then
        -- État changé, recréer le prop
        removePlantProp(plantId)
        createPlantProp(plantId, plant)
    else
        -- Juste mettre à jour les données
        plantCache.data = plant
    end
end

-- ============================================
-- INTERACTIONS OX_TARGET
-- ============================================

--- Configure les interactions ox_target pour une plante
---@param plantId number ID de la plante
---@param obj number Handle de l'objet
---@param plant table Données de la plante
function setupPlantInteractions(plantId, obj, plant)
    local options = {}

    -- Option: Voir état (ouvre le NUI)
    table.insert(options, {
        name = 'view_state',
        icon = 'fa-solid fa-cannabis',
        label = 'Gérer la plante',
        onSelect = function()
            TriggerEvent('zdrugs:client:viewPlantState', plantId)
        end
    })

    -- Utiliser addLocalEntity pour les objets créés dynamiquement
    exports.ox_target:addLocalEntity(obj, options)
end

-- ============================================
-- PLANTATION
-- ============================================

--- Démarre le mode plantation
RegisterNetEvent('zdrugs:client:plantSeed', function(drugType, slot)
    if isPlanting then return end

    local drugConfig = Config.Drogues[drugType]
    if not drugConfig or drugConfig.type ~= 'plantable' then
        return
    end

    isPlanting = true

    lib.notify({
        type = 'info',
        description = 'Choisissez un emplacement pour planter. Appuyez sur [E] pour confirmer ou [X] pour annuler.'
    })

    -- Charger le modèle du prop
    local propModel = drugConfig.croissance.props[1]  -- Premier prop (graine)
    loadModel(propModel)

    local previewObj = nil

    CreateThread(function()
        while isPlanting do
            Wait(0)

            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local playerHeading = GetEntityHeading(playerPed)

            -- Calculer la position devant le joueur
            local forwardVector = GetEntityForwardVector(playerPed)
            local plantCoords = playerCoords + (forwardVector * 1.5)

            -- Créer ou mettre à jour le preview
            if not DoesEntityExist(previewObj) then
                previewObj = CreateObject(GetHashKey(propModel), plantCoords.x, plantCoords.y, plantCoords.z, false, false, false)
                SetEntityAlpha(previewObj, 150, false)
                SetEntityCollision(previewObj, false, false)
            else
                SetEntityCoords(previewObj, plantCoords.x, plantCoords.y, plantCoords.z, false, false, false, false)
            end

            SetEntityHeading(previewObj, playerHeading)
            PlaceObjectOnGroundProperly(previewObj)

            -- Afficher les instructions
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName('[~g~E~w~] Confirmer   [~r~X~w~] Annuler')
            EndTextCommandDisplayHelp(0, false, true, -1)

            -- Confirmer
            if IsControlJustPressed(0, 38) then  -- E
                local finalCoords = GetEntityCoords(previewObj)
                local finalHeading = GetEntityHeading(previewObj)

                -- Animation de plantation
                loadAnimDict(Config.Animations.planter.dict)
                TaskPlayAnim(playerPed, Config.Animations.planter.dict, Config.Animations.planter.anim, 8.0, -8.0, 3000, 1, 0, false, false, false)

                if lib.progressBar({
                    duration = 3000,
                    label = 'Plantation en cours...',
                    useWhileDead = false,
                    canCancel = false,
                }) then
                    TriggerServerEvent('zdrugs:server:plantSeed', drugType, finalCoords, finalHeading)
                end

                ClearPedTasks(playerPed)
                break
            end

            -- Annuler
            if IsControlJustPressed(0, 73) then  -- X
                lib.notify({
                    type = 'error',
                    description = 'Plantation annulée'
                })
                break
            end
        end

        -- Nettoyer le preview
        if DoesEntityExist(previewObj) then
            DeleteEntity(previewObj)
        end

        isPlanting = false
    end)
end)

-- ============================================
-- ARROSAGE
-- ============================================

RegisterNetEvent('zdrugs:client:waterPlant', function(plantId)
    local playerPed = PlayerPedId()

    loadAnimDict(Config.Animations.arroser.dict)
    TaskPlayAnim(playerPed, Config.Animations.arroser.dict, Config.Animations.arroser.anim, 8.0, -8.0, 3000, 1, 0, false, false, false)

    if lib.progressBar({
        duration = 3000,
        label = 'Arrosage en cours...',
        useWhileDead = false,
        canCancel = true,
    }) then
        TriggerServerEvent('zdrugs:server:waterPlant', plantId)
    end

    ClearPedTasks(playerPed)
end)

-- ============================================
-- ENGRAIS
-- ============================================

RegisterNetEvent('zdrugs:client:fertilizePlant', function(plantId)
    local playerPed = PlayerPedId()

    loadAnimDict(Config.Animations.engrais.dict)
    TaskPlayAnim(playerPed, Config.Animations.engrais.dict, Config.Animations.engrais.anim, 8.0, -8.0, 3000, 1, 0, false, false, false)

    if lib.progressBar({
        duration = 3000,
        label = 'Application d\'engrais...',
        useWhileDead = false,
        canCancel = true,
    }) then
        TriggerServerEvent('zdrugs:server:fertilizePlant', plantId)
    end

    ClearPedTasks(playerPed)
end)

-- ============================================
-- RÉCOLTE
-- ============================================

RegisterNetEvent('zdrugs:client:harvestPlant', function(plantId)
    local plantCache = activePlants[plantId]
    if not plantCache then return end

    local drugConfig = Config.Drogues[plantCache.data.drugType]
    if not drugConfig then return end

    local playerPed = PlayerPedId()

    if drugConfig.recolte.animation then
        loadAnimDict(drugConfig.recolte.animation.dict)
        TaskPlayAnim(playerPed, drugConfig.recolte.animation.dict, drugConfig.recolte.animation.anim, 8.0, -8.0, 5000, 1, 0, false, false, false)
    end

    if lib.progressBar({
        duration = 5000,
        label = 'Récolte en cours...',
        useWhileDead = false,
        canCancel = true,
    }) then
        TriggerServerEvent('zdrugs:server:harvestPlant', plantId)
    end

    ClearPedTasks(playerPed)
end)

-- ============================================
-- SYNCHRONISATION
-- ============================================

--- Sync toutes les plantes
RegisterNetEvent('zdrugs:client:syncAllPlants', function(plants)
    -- Supprimer toutes les plantes locales
    for plantId in pairs(activePlants) do
        removePlantProp(plantId)
    end

    -- Créer les nouvelles plantes
    for plantId, plant in pairs(plants) do
        createPlantProp(plantId, plant)
    end
end)

--- Sync une plante spécifique
RegisterNetEvent('zdrugs:client:syncPlant', function(plantId, plant)
    updatePlantProp(plantId, plant)
end)

--- Supprimer une plante
RegisterNetEvent('zdrugs:client:removePlant', function(plantId)
    removePlantProp(plantId)
end)

-- ============================================
-- NETTOYAGE À LA DÉCONNEXION
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Supprimer toutes les plantes
    for plantId in pairs(activePlants) do
        removePlantProp(plantId)
    end
end)
