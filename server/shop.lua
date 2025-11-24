-- ============================================
-- SERVER SHOP - Gestion des achats
-- ============================================

-- ============================================
-- CALLBACK NUI - ACHETER UN ITEM
-- ============================================

RegisterNetEvent('zdrugs:server:buyItem', function(shopIndex, itemData, quantite)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end

    local shop = Config.Boutiques[shopIndex]
    if not shop then
        print('[ZDRUGS] Boutique introuvable:', shopIndex)
        return
    end

    -- Vérifier que l'item existe dans la boutique
    local itemConfig = nil
    for _, item in ipairs(shop.items) do
        if item.item == itemData.item then
            itemConfig = item
            break
        end
    end

    if not itemConfig then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Item introuvable dans la boutique'
        })
        return
    end

    -- Calculer le prix total
    local prixTotal = itemConfig.prix * quantite

    -- Vérifier l'argent
    local playerMoney = xPlayer.getAccount('money').money

    if playerMoney < prixTotal then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = Config.Messages.pas_assez_argent:format(prixTotal)
        })
        return
    end

    -- Vérifier l'espace dans l'inventaire
    local canCarry = exports.ox_inventory:CanCarryItem(source, itemData.item, quantite)

    if not canCarry then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Inventaire plein'
        })
        return
    end

    -- Retirer l'argent
    xPlayer.removeAccountMoney('money', prixTotal)

    -- Ajouter l'item
    exports.ox_inventory:AddItem(source, itemData.item, quantite)

    -- Notification de succès
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = Config.Messages.achat_success:format(quantite, itemConfig.label, prixTotal)
    })

    print(('[ZDRUGS] %s a acheté %sx %s pour $%s'):format(xPlayer.getName(), quantite, itemData.item, prixTotal))
end)
