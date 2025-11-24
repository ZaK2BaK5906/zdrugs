let currentPlantId = null;
let currentPlantData = null;
let updateInterval = null;
let startTime = null;

// Fonction pour envoyer des messages au client Lua
function post(url, data) {
    return $.post(`https://${GetParentResourceName()}/${url}`, JSON.stringify(data));
}

// Fonction pour obtenir le nom de la ressource
function GetParentResourceName() {
    return 'zdrugs';
}

// Fermer le menu visuellement
function closeMenuVisual() {
    $('#app').removeClass('active');
    $('#plantMode').hide();
    $('#shopMode').hide();

    // Arrêter le timer
    if (updateInterval) {
        clearInterval(updateInterval);
        updateInterval = null;
    }
}

// Fermer le menu et notifier Lua
function closeMenu() {
    closeMenuVisual();
    post('closeMenu', {});
}

// Écouter les messages du client
window.addEventListener('message', function(event) {
    const data = event.data;
    console.log('[ZDrugs NUI] Message reçu:', data);

    switch(data.type) {
        case 'openMenu':
            console.log('[ZDrugs NUI] Ouverture du menu PLANTE');
            $('#plantMode').show();
            $('#shopMode').hide();
            $('#headerIcon').html('<i class="fas fa-seedling"></i>');
            $('#headerTitle').text('Gestion de Plante');
            $('#footerText').html('<i class="fas fa-info-circle"></i> La plante a besoin d\'eau et d\'engrais pour grandir');
            openPlantMenu(data.plantId, data.plantData);
            break;

        case 'openShop':
            console.log('[ZDrugs NUI] Ouverture du menu BOUTIQUE');
            $('#plantMode').hide();
            $('#shopMode').show();
            $('#headerIcon').html('<i class="fas fa-shop"></i>');
            $('#headerTitle').text(data.shopData.nom);
            $('#footerText').html('<i class="fas fa-dollar-sign"></i> Cliquez sur un item pour l\'acheter');
            openShopMenu(data.shopIndex, data.shopData);
            break;

        case 'updatePlant':
            console.log('[ZDrugs NUI] Mise à jour plante en temps réel');
            updatePlantDisplay(data.plantData);
            break;

        case 'closeMenu':
            console.log('[ZDrugs NUI] Fermeture du menu (depuis Lua)');
            closeMenuVisual();
            break;
    }
});

// ============================================
// MODE PLANTE
// ============================================

// Calculer la couleur de la barre en fonction du pourcentage
function getProgressColor(percent) {
    if (percent >= 100) {
        return 'linear-gradient(90deg, #22c55e, #16a34a)';
    } else if (percent >= 66) {
        return 'linear-gradient(90deg, #fbbf24, #f59e0b)';
    } else if (percent >= 33) {
        return 'linear-gradient(90deg, #fb923c, #f97316)';
    } else {
        return 'linear-gradient(90deg, #ef4444, #dc2626)';
    }
}

// Mettre à jour l'affichage de la plante
function updatePlantDisplay(plantData) {
    currentPlantData = plantData;

    // Type de plante
    $('#plantType').text(plantData.label || 'Plante');

    // Progression
    const percent = Math.floor(plantData.growthPercent || 0);
    $('#progressBar').css('width', percent + '%');
    $('#progressBar').css('background', getProgressColor(percent));
    $('#progressText').text(percent + '%');

    // Statuts
    if (plantData.watered) {
        $('#waterValue').text('Oui').addClass('yes').removeClass('no');
        $('#waterBtn').prop('disabled', true);
    } else {
        $('#waterValue').text('Non').addClass('no').removeClass('yes');
        $('#waterBtn').prop('disabled', false);
    }

    if (plantData.fertilized) {
        $('#fertValue').text('Oui').addClass('yes').removeClass('no');
        $('#fertBtn').prop('disabled', true);
    } else {
        $('#fertValue').text('Non').addClass('no').removeClass('yes');
        $('#fertBtn').prop('disabled', false);
    }

    // Activer récolte seulement si prêt
    if (plantData.readyForHarvest) {
        $('#harvestBtn').prop('disabled', false);
        $('#timeRemaining').text('PRÊT !').css('background', 'linear-gradient(135deg, #22c55e 0%, #16a34a 100%)');
    } else {
        $('#harvestBtn').prop('disabled', true);
    }
}

// Ouvrir le menu plante
function openPlantMenu(plantId, plantData) {
    currentPlantId = plantId;
    currentPlantData = plantData;
    startTime = Date.now();

    // Mise à jour initiale
    updatePlantDisplay(plantData);

    // Afficher le menu
    $('#app').addClass('active');

    // Démarrer le timer live (mise à jour toutes les secondes)
    if (updateInterval) {
        clearInterval(updateInterval);
    }

    updateInterval = setInterval(function() {
        if (!currentPlantData || currentPlantData.readyForHarvest) {
            return;
        }

        // Calculer le temps écoulé depuis l'ouverture
        const elapsed = Math.floor((Date.now() - startTime) / 1000);

        // Parser le temps restant initial (format MM:SS)
        const timeStr = currentPlantData.timeText || '00:00';
        const parts = timeStr.split(':');
        const initialMinutes = parseInt(parts[0]) || 0;
        const initialSeconds = parseInt(parts[1]) || 0;
        const initialTotalSeconds = (initialMinutes * 60) + initialSeconds;

        // Calculer le nouveau temps restant
        let remainingSeconds = initialTotalSeconds - elapsed;

        if (remainingSeconds < 0) {
            remainingSeconds = 0;
        }

        const minutes = Math.floor(remainingSeconds / 60);
        const seconds = remainingSeconds % 60;
        const timeText = String(minutes).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');

        $('#timeRemaining').text(timeText);

    }, 1000); // Mise à jour toutes les secondes
}

// ============================================
// MODE BOUTIQUE
// ============================================

function openShopMenu(shopIndex, shopData) {
    const container = $('#shopItems');
    container.empty();

    shopData.items.forEach(function(item, index) {
        const itemHtml = `
            <div class="shop-item" data-item-index="${index}">
                <div class="shop-item-icon">
                    <i class="fas fa-cannabis"></i>
                </div>
                <div class="shop-item-name">${item.label}</div>
                <div class="shop-item-price">$${item.prix}</div>
                <div class="shop-item-quantity">
                    <button class="qty-btn qty-minus" data-item-index="${index}">-</button>
                    <input type="number" class="qty-input" id="qty-${index}" value="1" min="1" max="999">
                    <button class="qty-btn qty-plus" data-item-index="${index}">+</button>
                </div>
                <button class="shop-item-buy" data-item-index="${index}" data-shop-index="${shopIndex}">
                    <i class="fas fa-shopping-cart"></i> Acheter
                </button>
            </div>
        `;

        container.append(itemHtml);
    });

    // Event handlers pour les boutons +/-
    $('.qty-minus').click(function() {
        const index = $(this).data('item-index');
        const input = $(`#qty-${index}`);
        let val = parseInt(input.val()) || 1;
        if (val > 1) {
            input.val(val - 1);
        }
    });

    $('.qty-plus').click(function() {
        const index = $(this).data('item-index');
        const input = $(`#qty-${index}`);
        let val = parseInt(input.val()) || 1;
        if (val < 999) {
            input.val(val + 1);
        }
    });

    // Event handler pour le bouton Acheter
    $('.shop-item-buy').click(function() {
        const itemIndex = $(this).data('item-index');
        const shopIdx = $(this).data('shop-index');
        const quantity = parseInt($(`#qty-${itemIndex}`).val()) || 1;
        const item = shopData.items[itemIndex];

        console.log('[ZDrugs NUI] Achat:', item.item, 'x', quantity);

        post('buyItem', {
            shopIndex: shopIdx,
            item: item.item,
            quantity: quantity
        });
    });

    // Afficher le menu
    $('#app').addClass('active');
}

// ============================================
// EVENT HANDLERS
// ============================================

// Bouton de fermeture
$('#closeBtn').click(function() {
    closeMenu();
});

// Touche ESC pour fermer
$(document).keyup(function(e) {
    if (e.key === 'Escape') {
        closeMenu();
    }
});

// Bouton Arroser
$('#waterBtn').click(function() {
    console.log('[ZDrugs NUI] Arroser plante', currentPlantId);
    post('waterPlant', {
        plantId: currentPlantId
    });
    closeMenu();
});

// Bouton Engrais
$('#fertBtn').click(function() {
    console.log('[ZDrugs NUI] Mettre engrais', currentPlantId);
    post('fertilizePlant', {
        plantId: currentPlantId
    });
    closeMenu();
});

// Bouton Récolter
$('#harvestBtn').click(function() {
    console.log('[ZDrugs NUI] Récolter plante', currentPlantId);
    post('harvestPlant', {
        plantId: currentPlantId
    });
    closeMenu();
});

// Animation au chargement
$(document).ready(function() {
    console.log('[ZDrugs] NUI chargée avec succès');
});
