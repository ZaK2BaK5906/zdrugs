-- ============================================
-- CLIENT SHOP - Système de boutiques
-- ============================================

local shopPeds = {}
local shopBlips = {}

-- ============================================
-- SPAWN DES PEDS ET BLIPS
-- ============================================

CreateThread(function()
    for shopIndex, shop in ipairs(Config.Boutiques) do
        -- Créer le blip
        if shop.blip and shop.blip.enabled then
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, shop.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, shop.blip.scale)
            SetBlipColour(blip, shop.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(shop.blip.label)
            EndTextCommandSetBlipName(blip)

            table.insert(shopBlips, blip)
        end

        -- Spawn le PED
        local pedHash = GetHashKey(shop.ped)
        RequestModel(pedHash)

        while not HasModelLoaded(pedHash) do
            Wait(1)
        end

        local ped = CreatePed(4, pedHash, shop.coords.x, shop.coords.y, shop.coords.z - 1.0, shop.heading, false, true)

        SetEntityAsMissionEntity(ped, true, true)
        SetPedFleeAttributes(ped, 0, 0)
        SetPedDiesWhenInjured(ped, false)
        SetPedKeepTask(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)

        -- Ajouter ox_target
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'shop_' .. shopIndex,
                icon = 'fa-solid fa-shop',
                label = shop.nom,
                onSelect = function()
                    TriggerEvent('zdrugs:client:openShop', shopIndex)
                end
            }
        })

        table.insert(shopPeds, ped)

        print(('[ZDRUGS] Boutique #%s créée: %s'):format(shopIndex, shop.nom))
    end
end)

-- ============================================
-- OUVRIR LA BOUTIQUE
-- ============================================

RegisterNetEvent('zdrugs:client:openShop', function(shopIndex)
    local shop = Config.Boutiques[shopIndex]

    if not shop then
        print('[ZDRUGS] Boutique introuvable:', shopIndex)
        return
    end

    print('[ZDRUGS] Ouverture boutique:', shop.nom)

    -- Envoyer les données au NUI
    SendNUIMessage({
        type = 'openShop',
        shopIndex = shopIndex,
        shopData = {
            nom = shop.nom,
            items = shop.items
        }
    })

    SetNuiFocus(true, true)
end)

-- ============================================
-- NETTOYAGE
-- ============================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Supprimer les PEDs
    for _, ped in ipairs(shopPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end

    -- Supprimer les blips
    for _, blip in ipairs(shopBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end)
