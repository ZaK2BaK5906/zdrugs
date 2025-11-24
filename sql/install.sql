-- ============================================
-- Table des plantes de drogues
-- ============================================

CREATE TABLE IF NOT EXISTS `zdrugs_plants` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(60) NOT NULL,                -- Identifiant du joueur propriétaire
    `drug_type` VARCHAR(50) NOT NULL,            -- Type de drogue (cocaine, weed)
    `coords` TEXT NOT NULL,                      -- Coordonnées JSON {x, y, z, heading}
    `growth_state` INT(11) NOT NULL DEFAULT 0,   -- État de croissance (0 = planté, 1 = 33%, 2 = 66%, 3 = 100%)
    `growth_percent` FLOAT NOT NULL DEFAULT 0.0, -- Pourcentage de croissance exact
    `watered` TINYINT(1) NOT NULL DEFAULT 0,     -- Arrosé pour l'état actuel (0 = non, 1 = oui)
    `fertilized` TINYINT(1) NOT NULL DEFAULT 0,  -- Engrais ajouté pour l'état actuel (0 = non, 1 = oui)
    `planted_at` BIGINT(20) NOT NULL,            -- Timestamp de plantation
    `last_update` BIGINT(20) NOT NULL,           -- Dernier update de croissance
    `ready_for_harvest` TINYINT(1) NOT NULL DEFAULT 0, -- Prête à être récoltée (0 = non, 1 = oui)
    PRIMARY KEY (`id`),
    KEY `owner` (`owner`),
    KEY `drug_type` (`drug_type`),
    KEY `planted_at` (`planted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Table des logs d'actions
-- ============================================

CREATE TABLE IF NOT EXISTS `zdrugs_logs` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `player` VARCHAR(60) NOT NULL,
    `action` VARCHAR(100) NOT NULL,              -- Type d'action (plant, water, fertilize, harvest, process, package)
    `drug_type` VARCHAR(50) NOT NULL,
    `details` TEXT NULL,                         -- Détails additionnels en JSON
    `timestamp` BIGINT(20) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `player` (`player`),
    KEY `action` (`action`),
    KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
