-- ============================================
-- CLIENT DUI - Interface 3D pour l'état des plantes
-- ============================================

local activeDUI = nil  -- DUI actuellement affichée
local duiObject = nil  -- Objet 3D pour afficher le DUI
local duiTexture = nil -- Texture DUI

-- ============================================
-- FONCTIONS DUI
-- ============================================

--- Crée le HTML pour le DUI
---@param plant table Données de la plante
---@param drugConfig table Configuration de la drogue
---@return string HTML content
local function generateDUIHTML(plant, drugConfig)
    local growthPercent = math.floor(plant.growthPercent or 0)
    local waterIcon = plant.watered and '✅' or '❌'
    local fertIcon = plant.fertilized and '✅' or '❌'

    -- Calculer le temps restant
    local currentTime = os.time()
    local timeSincePlanted = currentTime - plant.plantedAt
    local totalDuration = drugConfig.croissance.duree_totale
    local timeRemaining = math.max(0, totalDuration - timeSincePlanted)

    local minutes = math.floor(timeRemaining / 60)
    local seconds = timeRemaining % 60

    local nextStepText = plant.readyForHarvest and 'Prête à récolter !' or string.format('%d min %d sec', minutes, seconds)

    local html = [[
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #ffffff;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            width: 100vw;
        }

        .container {
            background: rgba(30, 30, 50, 0.95);
            border: 2px solid #4ecca3;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
            width: 400px;
            backdrop-filter: blur(10px);
        }

        .header {
            text-align: center;
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 20px;
            color: #4ecca3;
            text-shadow: 0 2px 10px rgba(78, 204, 163, 0.5);
        }

        .divider {
            height: 2px;
            background: linear-gradient(90deg, transparent, #4ecca3, transparent);
            margin: 15px 0;
        }

        .info-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            font-size: 18px;
        }

        .info-label {
            color: #b8b8b8;
            font-weight: 500;
        }

        .info-value {
            color: #ffffff;
            font-weight: bold;
        }

        .growth-bar-container {
            width: 100%;
            height: 30px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            overflow: hidden;
            margin: 15px 0;
            border: 2px solid #4ecca3;
        }

        .growth-bar {
            height: 100%;
            background: linear-gradient(90deg, #4ecca3, #2ecc71);
            transition: width 0.3s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 14px;
        }

        .status-icon {
            font-size: 24px;
        }

        .next-step {
            text-align: center;
            margin-top: 20px;
            padding: 15px;
            background: rgba(78, 204, 163, 0.1);
            border-radius: 10px;
            border: 1px solid #4ecca3;
        }

        .next-step-label {
            color: #4ecca3;
            font-size: 14px;
            margin-bottom: 5px;
        }

        .next-step-value {
            color: #ffffff;
            font-size: 18px;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">🌱 État de la Plante</div>
        <div class="divider"></div>

        <div class="info-row">
            <span class="info-label">Type:</span>
            <span class="info-value">]] .. drugConfig.label .. [[</span>
        </div>

        <div class="growth-bar-container">
            <div class="growth-bar" style="width: ]] .. growthPercent .. [[%">
                ]] .. growthPercent .. [[%
            </div>
        </div>

        <div class="info-row">
            <span class="info-label">Arrosage:</span>
            <span class="status-icon">]] .. waterIcon .. [[</span>
        </div>

        <div class="info-row">
            <span class="info-label">Engrais:</span>
            <span class="status-icon">]] .. fertIcon .. [[</span>
        </div>

        <div class="next-step">
            <div class="next-step-label">Prochaine étape dans:</div>
            <div class="next-step-value">]] .. nextStepText .. [[</div>
        </div>
    </div>
</body>
</html>
    ]]

    return html
end

--- Affiche le DUI pour une plante
---@param plantId number ID de la plante
RegisterNetEvent('zdrugs:client:showDUI', function(plantId)
    if not Config.DUI.enabled then
        -- Mode fallback avec notification simple
        lib.callback('zdrugs:getPlantData', false, function(plant)
            if not plant then return end

            local drugConfig = Config.Drogues[plant.drugType]
            if not drugConfig then return end

            local growthPercent = math.floor(plant.growthPercent or 0)
            local waterStatus = plant.watered and 'Oui' or 'Non'
            local fertStatus = plant.fertilized and 'Oui' or 'Non'

            lib.notify({
                type = 'info',
                title = 'État de la plante',
                description = string.format(
                    'Type: %s\nCroissance: %s%%\nArrosage: %s\nEngrais: %s',
                    drugConfig.label,
                    growthPercent,
                    waterStatus,
                    fertStatus
                ),
                duration = 5000
            })
        end, plantId)
        return
    end

    -- Fermer le DUI précédent si existant
    if activeDUI then
        hideDUI()
    end

    -- Récupérer les données de la plante
    lib.callback('zdrugs:getPlantData', false, function(plant)
        if not plant then return end

        local drugConfig = Config.Drogues[plant.drugType]
        if not drugConfig then return end

        -- Générer le HTML
        local html = generateDUIHTML(plant, drugConfig)

        -- Créer le DUI
        local duiUrl = 'https://cfx-nui-' .. GetCurrentResourceName() .. '/dui.html'
        duiTexture = CreateDui(html, Config.DUI.width, Config.DUI.height)
        local duiHandle = GetDuiHandle(duiTexture)

        -- Créer un objet invisible pour afficher le DUI
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local forwardVector = GetEntityForwardVector(playerPed)
        local duiCoords = playerCoords + (forwardVector * 2.0) + vector3(0, 0, 1.0)

        -- Utiliser un prop invisible
        local propModel = 'prop_cs_tablet_01'
        RequestModel(GetHashKey(propModel))
        while not HasModelLoaded(GetHashKey(propModel)) do
            Wait(10)
        end

        duiObject = CreateObject(GetHashKey(propModel), duiCoords.x, duiCoords.y, duiCoords.z, false, false, false)
        SetEntityAlpha(duiObject, 0, false)  -- Invisible
        FreezeEntityPosition(duiObject, true)

        -- Appliquer la texture DUI (note: ceci est une simplification, GTA V ne supporte pas directement DUI sur objets)
        -- Dans une implémentation réelle, vous devriez utiliser un NUI plein écran ou un système de scaleform

        activeDUI = {
            texture = duiTexture,
            object = duiObject,
            plantId = plantId
        }

        -- Auto-fermer après 10 secondes
        SetTimeout(10000, function()
            hideDUI()
        end)

        lib.notify({
            type = 'success',
            description = 'Appuyez sur [X] pour fermer'
        })

        -- Thread pour fermer avec X
        CreateThread(function()
            while activeDUI do
                Wait(0)
                if IsControlJustPressed(0, 73) then  -- X
                    hideDUI()
                    break
                end
            end
        end)
    end, plantId)
end)

--- Cache le DUI
function hideDUI()
    if not activeDUI then return end

    if activeDUI.texture then
        DestroyDui(activeDUI.texture)
    end

    if activeDUI.object and DoesEntityExist(activeDUI.object) then
        DeleteEntity(activeDUI.object)
    end

    activeDUI = nil
    duiObject = nil
    duiTexture = nil
end

-- ============================================
-- ALTERNATIVE: MENU OX_LIB (Plus simple et fiable)
-- ============================================

--- Affiche l'état de la plante via un menu ox_lib
---@param plantId number ID de la plante
RegisterNetEvent('zdrugs:client:showPlantMenu', function(plantId)
    lib.callback('zdrugs:getPlantData', false, function(plant)
        if not plant then return end

        local drugConfig = Config.Drogues[plant.drugType]
        if not drugConfig then return end

        local growthPercent = math.floor(plant.growthPercent or 0)
        local waterStatus = plant.watered and '✅ Oui' or '❌ Non'
        local fertStatus = plant.fertilized and '✅ Oui' or '❌ Non'

        -- Calculer le temps restant
        local currentTime = os.time()
        local timeSincePlanted = currentTime - plant.plantedAt
        local totalDuration = drugConfig.croissance.duree_totale
        local timeRemaining = math.max(0, totalDuration - timeSincePlanted)

        local minutes = math.floor(timeRemaining / 60)
        local seconds = timeRemaining % 60
        local nextStepText = plant.readyForHarvest and '✅ Prête à récolter !' or string.format('⏱️ %d min %d sec', minutes, seconds)

        lib.alertDialog({
            header = '🌱 État de la Plante',
            content = string.format(
                '**Type:** %s\n\n' ..
                '**Croissance:** %s%%\n\n' ..
                '**Arrosage:** %s\n\n' ..
                '**Engrais:** %s\n\n' ..
                '**Prochaine étape:** %s',
                drugConfig.label,
                growthPercent,
                waterStatus,
                fertStatus,
                nextStepText
            ),
            centered = true,
            cancel = true
        })
    end, plantId)
end)

-- Remplacer l'événement viewPlantState pour utiliser le menu au lieu du DUI
AddEventHandler('zdrugs:client:viewPlantState', function(plantId)
    -- Utiliser le menu au lieu du DUI car plus fiable
    TriggerEvent('zdrugs:client:showPlantMenu', plantId)
end)
