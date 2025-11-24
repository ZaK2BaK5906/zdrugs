let currentPlantId = null;
let currentPlantData = null;

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
            $('#processingMode').hide();
            $('#packagingMode').hide();
            $('#headerIcon').html('<i class="fas fa-seedling"></i>');
            $('#headerTitle').text('Gestion de Plante');
            $('#footerText').html('<i class="fas fa-info-circle"></i> La plante a besoin d\'eau et d\'engrais pour grandir');
            openPlantMenu(data.plantId, data.plantData);
            break;

        case 'openShop':
            console.log('[ZDrugs NUI] Ouverture du menu BOUTIQUE');
            $('#plantMode').hide();
            $('#shopMode').show();
            $('#processingMode').hide();
            $('#packagingMode').hide();
            $('#headerIcon').html('<i class="fas fa-shop"></i>');
            $('#headerTitle').text(data.shopData.nom);
            $('#footerText').html('<i class="fas fa-dollar-sign"></i> Cliquez sur un item pour l\'acheter');
            openShopMenu(data.shopIndex, data.shopData);
            break;

        case 'openProcessing':
            console.log('[ZDrugs NUI] Ouverture du menu TRAITEMENT');
            $('#plantMode').hide();
            $('#shopMode').hide();
            $('#processingMode').show();
            $('#packagingMode').hide();
            $('#headerIcon').html('<i class="fas fa-flask"></i>');
            $('#headerTitle').text('⚗️ Traitement - ' + data.drugLabel);
            $('#footerText').html('<i class="fas fa-info-circle"></i> Sélectionnez une étape de traitement');
            openProcessingMenu(data.drugType, data.drugLabel, data.steps);
            break;

        case 'openPackaging':
            console.log('[ZDrugs NUI] Ouverture du menu CONDITIONNEMENT');
            $('#plantMode').hide();
            $('#shopMode').hide();
            $('#processingMode').hide();
            $('#packagingMode').show();
            $('#headerIcon').html('<i class="fas fa-box"></i>');
            $('#headerTitle').text('📦 Conditionnement - ' + data.drugLabel);
            $('#footerText').html('<i class="fas fa-info-circle"></i> Confirmez pour conditionner');
            openPackagingMenu(data.drugType, data.drugLabel, data.packagingData);
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

    console.log('[ZDrugs NUI] Update display - Growth:', plantData.growthPercent, '%, State:', plantData.growthState);

    // Type de plante
    $('#plantType').text(plantData.label || 'Plante');

    // Progression - MISE À JOUR EN TEMPS RÉEL
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
    } else {
        $('#harvestBtn').prop('disabled', true);
    }
}

// Ouvrir le menu plante
function openPlantMenu(plantId, plantData) {
    currentPlantId = plantId;
    currentPlantData = plantData;

    console.log('[ZDrugs NUI] Open plant menu - ID:', plantId);

    // Mise à jour initiale
    updatePlantDisplay(plantData);

    // Afficher le menu
    $('#app').addClass('active');
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

// ============================================
// MODE TRAITEMENT (PROCESSING)
// ============================================

let currentDrugType = null;

function openProcessingMenu(drugType, drugLabel, steps) {
    currentDrugType = drugType;

    const container = $('#processingSteps');
    container.empty();

    steps.forEach(function(step, index) {
        // Créer la liste des inputs
        let inputsHtml = '';
        step.inputs.forEach(function(input) {
            inputsHtml += `<div class="recipe-item">${input.quantite}x ${input.item}</div>`;
        });

        // Créer la sortie
        const outputHtml = `<div class="recipe-item output">${step.output.quantite}x ${step.output.item}</div>`;

        const stepHtml = `
            <div class="processing-step">
                <div class="step-header">
                    <div class="step-icon">
                        <i class="fas fa-flask"></i>
                    </div>
                    <div class="step-info">
                        <div class="step-name">${step.nom}</div>
                        <div class="step-desc">${step.description || ''}</div>
                        <div class="step-time"><i class="fas fa-clock"></i> ${step.temps}s</div>
                    </div>
                </div>
                <div class="step-recipe">
                    <div class="recipe-section">
                        <div class="recipe-label">Nécessite:</div>
                        ${inputsHtml}
                    </div>
                    <div class="recipe-arrow">
                        <i class="fas fa-arrow-right"></i>
                    </div>
                    <div class="recipe-section">
                        <div class="recipe-label">Produit:</div>
                        ${outputHtml}
                    </div>
                </div>
                <button class="step-btn" data-step-index="${index}">
                    <i class="fas fa-play"></i> Commencer
                </button>
            </div>
        `;

        container.append(stepHtml);
    });

    // Event handler pour les boutons de traitement
    $('.step-btn').click(function() {
        const stepIndex = $(this).data('step-index');
        console.log('[ZDrugs NUI] Démarrage traitement:', currentDrugType, 'étape', stepIndex);

        post('processStep', {
            drugType: currentDrugType,
            stepIndex: stepIndex
        });

        closeMenu();
    });

    // Afficher le menu
    $('#app').addClass('active');
}

// ============================================
// MODE CONDITIONNEMENT (PACKAGING)
// ============================================

function openPackagingMenu(drugType, drugLabel, packagingData) {
    currentDrugType = drugType;

    const container = $('#packagingInfo');
    container.empty();

    // Créer la liste des inputs
    let inputsHtml = '';
    packagingData.inputs.forEach(function(input) {
        inputsHtml += `<div class="recipe-item">${input.quantite}x ${input.item}</div>`;
    });

    // Créer la sortie
    const outputHtml = `<div class="recipe-item output">${packagingData.output.quantite}x ${packagingData.output.item}</div>`;

    const packagingHtml = `
        <div class="packaging-card">
            <div class="step-header">
                <div class="step-icon packaging-icon">
                    <i class="fas fa-box"></i>
                </div>
                <div class="step-info">
                    <div class="step-name">Conditionnement</div>
                    <div class="step-desc">Préparez votre produit pour la vente</div>
                    <div class="step-time"><i class="fas fa-clock"></i> ${packagingData.temps}s</div>
                </div>
            </div>
            <div class="step-recipe">
                <div class="recipe-section">
                    <div class="recipe-label">Nécessite:</div>
                    ${inputsHtml}
                </div>
                <div class="recipe-arrow">
                    <i class="fas fa-arrow-right"></i>
                </div>
                <div class="recipe-section">
                    <div class="recipe-label">Produit:</div>
                    ${outputHtml}
                </div>
            </div>
            <button class="step-btn packaging-btn">
                <i class="fas fa-check"></i> Conditionner
            </button>
        </div>
    `;

    container.html(packagingHtml);

    // Event handler pour le bouton de conditionnement
    $('.packaging-btn').click(function() {
        console.log('[ZDrugs NUI] Démarrage conditionnement:', currentDrugType);

        post('packageDrug', {
            drugType: currentDrugType
        });

        closeMenu();
    });

    // Afficher le menu
    $('#app').addClass('active');
}

// Animation au chargement
$(document).ready(function() {
    console.log('[ZDrugs] NUI chargée avec succès');
});
