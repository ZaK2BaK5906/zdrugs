-- ============================================
-- SERVER PROCESSING - Traitement et conditionnement
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

-- ============================================
-- TRAITEMENT (PROCESSING)
-- ============================================

--- Démarre le traitement d'une drogue
RegisterNetEvent('zdrugs:server:startProcessing', function(drugType, etapeIndex)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local drugConfig = Config.Drogues[drugType]
    if not drugConfig or not drugConfig.traitement then
        return
    end

    local etape = drugConfig.traitement.etapes[etapeIndex]
    if not etape then
        return
    end

    -- Vérifier que le joueur a tous les items nécessaires
    for _, input in ipairs(etape.input) do
        if not hasItem(source, input.item, input.quantite) then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = Config.Messages.pas_assez_items
            })
            return
        end
    end

    -- Retirer tous les items nécessaires
    for _, input in ipairs(etape.input) do
        if not removeItem(source, input.item, input.quantite) then
            -- Si on ne peut pas retirer, rembourser ce qui a été retiré
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = 'Erreur lors du traitement'
            })
            return
        end
    end

    -- Informer le client que le traitement peut commencer
    TriggerClientEvent('zdrugs:client:doProcessing', source, drugType, etapeIndex, etape.temps)
end)

--- Finalise le traitement et donne les items
RegisterNetEvent('zdrugs:server:finishProcessing', function(drugType, etapeIndex)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local drugConfig = Config.Drogues[drugType]
    if not drugConfig or not drugConfig.traitement then
        return
    end

    local etape = drugConfig.traitement.etapes[etapeIndex]
    if not etape then
        return
    end

    -- Donner l'item de sortie
    if addItem(source, etape.output.item, etape.output.quantite) then
        -- Logger l'action
        logAction(xPlayer.identifier, 'process', drugType, {
            etape = etape.nom,
            output = etape.output
        })

        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            description = Config.Messages.traitement_success:format(etape.output.quantite, etape.output.item)
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Inventaire plein'
        })
    end
end)

-- ============================================
-- CONDITIONNEMENT (PACKAGING)
-- ============================================

--- Démarre le conditionnement d'une drogue
RegisterNetEvent('zdrugs:server:startPackaging', function(drugType)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local drugConfig = Config.Drogues[drugType]
    if not drugConfig or not drugConfig.conditionnement then
        return
    end

    local packaging = drugConfig.conditionnement

    -- Vérifier que le joueur a tous les items nécessaires
    for _, input in ipairs(packaging.input) do
        if not hasItem(source, input.item, input.quantite) then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = Config.Messages.pas_assez_items
            })
            return
        end
    end

    -- Retirer tous les items nécessaires
    for _, input in ipairs(packaging.input) do
        if not removeItem(source, input.item, input.quantite) then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = 'Erreur lors du conditionnement'
            })
            return
        end
    end

    -- Informer le client que le conditionnement peut commencer
    TriggerClientEvent('zdrugs:client:doPackaging', source, drugType, packaging.temps)
end)

--- Finalise le conditionnement et donne les items
RegisterNetEvent('zdrugs:server:finishPackaging', function(drugType)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local drugConfig = Config.Drogues[drugType]
    if not drugConfig or not drugConfig.conditionnement then
        return
    end

    local packaging = drugConfig.conditionnement

    -- Donner l'item de sortie
    if addItem(source, packaging.output.item, packaging.output.quantite) then
        -- Logger l'action
        logAction(xPlayer.identifier, 'package', drugType, {
            output = packaging.output
        })

        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            description = Config.Messages.conditionnement_success:format(packaging.output.quantite, packaging.output.item)
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Inventaire plein'
        })
    end
end)
