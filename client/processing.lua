-- ============================================
-- CLIENT PROCESSING - Zones de traitement et conditionnement
-- ============================================

local processingZones = {}
local packagingZones = {}

-- ============================================
-- INITIALISATION DES ZONES
-- ============================================

CreateThread(function()
    -- Créer les zones de traitement pour chaque drogue
    for drugType, drugConfig in pairs(Config.Drogues) do
        if drugConfig.traitement and drugConfig.traitement.zones then
            for i, zone in ipairs(drugConfig.traitement.zones) do
                local zoneId = ('%s_processing_%s'):format(drugType, i)

                -- Créer la zone ox_target
                exports.ox_target:addSphereZone({
                    coords = zone.coords,
                    radius = zone.rayon or 2.0,
                    options = {
                        {
                            name = zoneId,
                            icon = 'fa-solid fa-flask',
                            label = zone.label or 'Traiter ' .. drugConfig.label,
                            onSelect = function()
                                openProcessingMenu(drugType)
                            end
                        }
                    }
                })

                processingZones[zoneId] = {
                    drugType = drugType,
                    coords = zone.coords
                }
            end
        end

        -- Créer les zones de conditionnement
        if drugConfig.conditionnement then
            local packaging = drugConfig.conditionnement
            local zoneId = ('%s_packaging'):format(drugType)

            exports.ox_target:addSphereZone({
                coords = packaging.zone,
                radius = packaging.rayon or 1.5,
                options = {
                    {
                        name = zoneId,
                        icon = 'fa-solid fa-box',
                        label = packaging.label or 'Conditionner ' .. drugConfig.label,
                        onSelect = function()
                            startPackaging(drugType)
                        end
                    }
                }
            })

            packagingZones[zoneId] = {
                drugType = drugType,
                coords = packaging.zone
            }
        end
    end
end)

-- ============================================
-- MENU DE TRAITEMENT
-- ============================================

--- Ouvre le menu de traitement pour une drogue
---@param drugType string Type de drogue
function openProcessingMenu(drugType)
    local drugConfig = Config.Drogues[drugType]
    if not drugConfig or not drugConfig.traitement then
        return
    end

    -- Préparer les données pour le NUI
    local steps = {}

    for i, etape in ipairs(drugConfig.traitement.etapes) do
        table.insert(steps, {
            nom = etape.nom,
            description = etape.description or '',
            temps = etape.temps,
            inputs = etape.input,
            output = etape.output
        })
    end

    -- Ouvrir le NUI
    SendNUIMessage({
        type = 'openProcessing',
        drugType = drugType,
        drugLabel = drugConfig.label,
        steps = steps
    })

    SetNuiFocus(true, true)
end

-- ============================================
-- TRAITEMENT (PROCESSING)
-- ============================================

--- Démarre le traitement d'une étape
---@param drugType string Type de drogue
---@param etapeIndex number Index de l'étape
function startProcessing(drugType, etapeIndex)
    local drugConfig = Config.Drogues[drugType]
    if not drugConfig or not drugConfig.traitement then
        return
    end

    local etape = drugConfig.traitement.etapes[etapeIndex]
    if not etape then
        return
    end

    -- Demander au serveur de vérifier et retirer les items
    TriggerServerEvent('zdrugs:server:startProcessing', drugType, etapeIndex)
end

--- Effectue l'animation et la progress bar de traitement
RegisterNetEvent('zdrugs:client:doProcessing', function(drugType, etapeIndex, duration)
    local drugConfig = Config.Drogues[drugType]
    if not drugConfig or not drugConfig.traitement then
        return
    end

    local etape = drugConfig.traitement.etapes[etapeIndex]
    if not etape then
        return
    end

    local playerPed = PlayerPedId()

    -- Charger et jouer l'animation
    if etape.animation then
        RequestAnimDict(etape.animation.dict)
        while not HasAnimDictLoaded(etape.animation.dict) do
            Wait(10)
        end
        TaskPlayAnim(playerPed, etape.animation.dict, etape.animation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    -- Progress bar
    local success = lib.progressBar({
        duration = duration * 1000,
        label = etape.nom,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        }
    })

    -- Arrêter l'animation
    ClearPedTasks(playerPed)

    if success then
        -- Informer le serveur que le traitement est terminé
        TriggerServerEvent('zdrugs:server:finishProcessing', drugType, etapeIndex)
    else
        lib.notify({
            type = 'error',
            description = 'Traitement annulé'
        })
    end
end)

-- ============================================
-- CONDITIONNEMENT (PACKAGING)
-- ============================================

--- Démarre le conditionnement
---@param drugType string Type de drogue
function startPackaging(drugType)
    local drugConfig = Config.Drogues[drugType]
    if not drugConfig or not drugConfig.conditionnement then
        return
    end

    local packaging = drugConfig.conditionnement

    -- Préparer les données pour le NUI
    local packagingData = {
        temps = packaging.temps,
        inputs = packaging.input,
        output = packaging.output
    }

    -- Ouvrir le NUI
    SendNUIMessage({
        type = 'openPackaging',
        drugType = drugType,
        drugLabel = drugConfig.label,
        packagingData = packagingData
    })

    SetNuiFocus(true, true)
end

--- Effectue l'animation et la progress bar de conditionnement
RegisterNetEvent('zdrugs:client:doPackaging', function(drugType, duration)
    local drugConfig = Config.Drogues[drugType]
    if not drugConfig or not drugConfig.conditionnement then
        return
    end

    local packaging = drugConfig.conditionnement
    local playerPed = PlayerPedId()

    -- Charger et jouer l'animation
    if packaging.animation then
        RequestAnimDict(packaging.animation.dict)
        while not HasAnimDictLoaded(packaging.animation.dict) do
            Wait(10)
        end
        TaskPlayAnim(playerPed, packaging.animation.dict, packaging.animation.anim, 8.0, -8.0, -1, 1, 0, false, false, false)
    end

    -- Progress bar
    local success = lib.progressBar({
        duration = duration * 1000,
        label = 'Conditionnement en cours...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        }
    })

    -- Arrêter l'animation
    ClearPedTasks(playerPed)

    if success then
        -- Informer le serveur que le conditionnement est terminé
        TriggerServerEvent('zdrugs:server:finishPackaging', drugType)
    else
        lib.notify({
            type = 'error',
            description = 'Conditionnement annulé'
        })
    end
end)

-- ============================================
-- NETTOYAGE
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Supprimer toutes les zones
    for zoneId in pairs(processingZones) do
        exports.ox_target:removeZone(zoneId)
    end

    for zoneId in pairs(packagingZones) do
        exports.ox_target:removeZone(zoneId)
    end
end)
