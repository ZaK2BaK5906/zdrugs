-- ============================================
-- CLIENT DUI - Interface 3D optimisée pour l'état des plantes
-- ============================================

local activeDUIs = {}  -- Cache des DUIs actifs {plantId = {dui, handle, object, txd}}

-- ============================================
-- GÉNÉRATION DU HTML POUR LE DUI
-- ============================================

--- Génère le HTML optimisé pour le DUI
---@param plant table Données de la plante
---@param drugConfig table Configuration de la drogue
---@return string HTML content
local function generateHTML(plant, drugConfig)
    local growthPercent = math.floor(plant.growthPercent or 0)
    local waterIcon = plant.watered and '✅' or '❌'
    local fertIcon = plant.fertilized and '✅' or '❌'

    -- Calcul du temps restant
    local totalDuration = drugConfig.croissance.duree_totale
    local remainingPercent = 100 - growthPercent
    local timeRemaining = (totalDuration * remainingPercent) / 100
    local minutes = math.floor(timeRemaining / 60)
    local seconds = math.floor(timeRemaining % 60)
    local timeText = plant.readyForHarvest and 'PRÊT !' or string.format('%02d:%02d', minutes, seconds)

    -- Couleur de la barre de progression
    local barColor = growthPercent >= 100 and '#4ade80' or growthPercent >= 66 and '#fbbf24' or growthPercent >= 33 and '#fb923c' or '#f87171'

    return string.format([[
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, system-ui, sans-serif;
            background: linear-gradient(135deg, #1e293b 0%%, #0f172a 100%%);
            color: white;
            width: 100vw;
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: rgba(30, 41, 59, 0.95);
            border: 2px solid #4ade80;
            border-radius: 12px;
            padding: 20px;
            width: 100%%;
            box-shadow: 0 8px 32px rgba(0,0,0,0.8);
        }
        .header {
            text-align: center;
            font-size: 20px;
            font-weight: 700;
            color: #4ade80;
            margin-bottom: 15px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .progress-container {
            background: rgba(0,0,0,0.4);
            border-radius: 8px;
            height: 30px;
            margin-bottom: 15px;
            overflow: hidden;
            border: 1px solid rgba(255,255,255,0.1);
        }
        .progress-bar {
            height: 100%%;
            background: %s;
            width: %d%%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 14px;
            transition: width 0.3s ease;
        }
        .stats {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-bottom: 15px;
        }
        .stat {
            background: rgba(0,0,0,0.3);
            padding: 10px;
            border-radius: 6px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            border: 1px solid rgba(255,255,255,0.05);
        }
        .stat-label {
            color: #94a3b8;
            font-size: 13px;
        }
        .stat-value {
            font-size: 18px;
            font-weight: 700;
        }
        .timer {
            background: linear-gradient(135deg, #4ade80 0%%, #22c55e 100%%);
            padding: 12px;
            border-radius: 8px;
            text-align: center;
            font-weight: 700;
            font-size: 18px;
            letter-spacing: 2px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">🌱 %s</div>
        <div class="progress-container">
            <div class="progress-bar">%d%%%%</div>
        </div>
        <div class="stats">
            <div class="stat">
                <span class="stat-label">💧 Arrosage</span>
                <span class="stat-value">%s</span>
            </div>
            <div class="stat">
                <span class="stat-label">🌱 Engrais</span>
                <span class="stat-value">%s</span>
            </div>
        </div>
        <div class="timer">⏱️ %s</div>
    </div>
</body>
</html>
    ]], barColor, growthPercent, drugConfig.label, growthPercent, waterIcon, fertIcon, timeText)
end

-- ============================================
-- GESTION DU DUI
-- ============================================

--- Crée et affiche un DUI pour une plante
---@param plantId number ID de la plante
---@param plant table Données de la plante
local function createDUI(plantId, plant)
    -- Nettoyer le DUI existant si présent
    if activeDUIs[plantId] then
        destroyDUI(plantId)
    end

    local drugConfig = Config.Drogues[plant.drugType]
    if not drugConfig then return end

    -- Générer le HTML
    local html = generateHTML(plant, drugConfig)

    -- Créer le DUI (512x512 pour bonne qualité)
    local dui = CreateDui(html, 512, 512)
    local handle = GetDuiHandle(dui)

    -- Créer le runtime TXD
    local txd = CreateRuntimeTxd('zdrugs_dui_' .. plantId)
    local txn = CreateRuntimeTextureFromDuiHandle(txd, 'dui_texture', handle)

    -- Créer un petit panneau 3D pour afficher le DUI
    local plantCoords = vector3(plant.coords.x, plant.coords.y, plant.coords.z)
    local displayCoords = plantCoords + vector3(0, 0, 1.5)  -- 1.5m au-dessus de la plante

    -- Créer un objet invisible pour le panneau (on dessine directement avec DrawSprite)
    -- Pas besoin d'objet physique, on va juste draw le DUI dans l'espace 3D

    activeDUIs[plantId] = {
        dui = dui,
        handle = handle,
        txd = txd,
        txn = txn,
        coords = displayCoords,
        plantData = plant
    }

    return true
end

--- Détruit un DUI
---@param plantId number ID de la plante
function destroyDUI(plantId)
    local duiData = activeDUIs[plantId]
    if not duiData then return end

    -- Détruire le DUI
    if duiData.dui then
        DestroyDui(duiData.dui)
    end

    activeDUIs[plantId] = nil
end

--- Met à jour le contenu d'un DUI existant
---@param plantId number ID de la plante
---@param plant table Nouvelles données de la plante
local function updateDUI(plantId, plant)
    local duiData = activeDUIs[plantId]
    if not duiData then return end

    local drugConfig = Config.Drogues[plant.drugType]
    if not drugConfig then return end

    -- Générer le nouveau HTML
    local html = generateHTML(plant, drugConfig)

    -- Mettre à jour le DUI avec SetDuiUrl en utilisant data URL
    SetDuiUrl(duiData.dui, 'data:text/html,' .. html)

    duiData.plantData = plant
end

-- ============================================
-- AFFICHAGE DU DUI (VIA MENU OX_LIB)
-- ============================================

--- Affiche l'état de la plante via un menu ox_lib (méthode simple et fiable)
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
        local totalDuration = drugConfig.croissance.duree_totale
        local remainingPercent = 100 - growthPercent
        local timeRemaining = (totalDuration * remainingPercent) / 100
        local minutes = math.floor(timeRemaining / 60)
        local seconds = math.floor(timeRemaining % 60)
        local nextStepText = plant.readyForHarvest and '✅ Prête à récolter !' or string.format('⏱️ %02d:%02d', minutes, seconds)

        lib.alertDialog({
            header = '🌱 État de la Plante',
            content = string.format(
                '**Type:** %s\n\n' ..
                '**Croissance:** %s%%%%\n\n' ..
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

-- Event principal pour afficher l'état
AddEventHandler('zdrugs:client:viewPlantState', function(plantId)
    -- Utiliser le menu ox_lib (simple et fiable)
    TriggerEvent('zdrugs:client:showPlantMenu', plantId)
end)

-- ============================================
-- NETTOYAGE
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Détruire tous les DUIs
    for plantId in pairs(activeDUIs) do
        destroyDUI(plantId)
    end
end)
