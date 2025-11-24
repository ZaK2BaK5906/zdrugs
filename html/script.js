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
            console.log('[ZDrugs NUI] Ouverture du menu avec:', data.plantData);
            openMenu(data.plantId, data.plantData);
            break;

        case 'closeMenu':
            console.log('[ZDrugs NUI] Fermeture du menu (depuis Lua)');
            closeMenuVisual();  // Juste fermer visuellement, PAS de callback!
            break;
    }
});

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

// Ouvrir le menu
function openMenu(plantId, plantData) {
    currentPlantId = plantId;
    currentPlantData = plantData;

    // Type de plante
    $('#plantType').text(plantData.label || 'Plante');

    // Progression
    const percent = Math.floor(plantData.growthPercent || 0);
    $('#progressBar').css('width', percent + '%');
    $('#progressBar').css('background', getProgressColor(percent));
    $('#progressText').text(percent + '%');

    // Temps restant
    $('#timeRemaining').text(plantData.timeText || '--:--');

    // Statuts
    if (plantData.watered) {
        $('#waterValue').text('Oui').addClass('yes').removeClass('no');
    } else {
        $('#waterValue').text('Non').addClass('no').removeClass('yes');
    }

    if (plantData.fertilized) {
        $('#fertValue').text('Oui').addClass('yes').removeClass('no');
    } else {
        $('#fertValue').text('Non').addClass('no').removeClass('yes');
    }

    // Gestion des boutons
    // Désactiver arrosage si déjà arrosé
    if (plantData.watered) {
        $('#waterBtn').prop('disabled', true);
    } else {
        $('#waterBtn').prop('disabled', false);
    }

    // Désactiver engrais si déjà mis
    if (plantData.fertilized) {
        $('#fertBtn').prop('disabled', true);
    } else {
        $('#fertBtn').prop('disabled', false);
    }

    // Activer récolte seulement si prêt
    if (plantData.readyForHarvest) {
        $('#harvestBtn').prop('disabled', false);
    } else {
        $('#harvestBtn').prop('disabled', true);
    }

    // Afficher le menu
    $('#app').addClass('active');
}

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
