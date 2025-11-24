Config = {}

-- ============================================
-- CONFIGURATION GÉNÉRALE
-- ============================================

Config.Limites = {
    max_plantes_par_joueur = 10,           -- Nombre maximum de plantes par joueur
    distance_min_entre_plantes = 2.0,      -- Distance minimum entre deux plantes (mètres)
    suppression_auto_apres = 86400,        -- Suppression automatique après 24h (secondes)
    rayon_plantation = 50.0                -- Rayon maximum autour du joueur pour planter
}

-- Items communs
Config.Items = {
    eau = "arrosoir",             -- Item pour arroser
    engrais = "fertilizer",       -- Item pour mettre de l'engrais
    pochon = "plastic_bag",       -- Sachets pour cocaine et weed
    sachets = "small_bags"        -- Sachets pour meth
}

-- ============================================
-- CONFIGURATION DES DROGUES
-- ============================================

Config.Drogues = {

    -- ============================================
    -- 🍃 COCAINE (Feuilles de Coca)
    -- ============================================
    cocaine = {
        type = "plantable",
        label = "Cocaïne",
        graine = "graine_coca",

        -- Configuration de la croissance
        croissance = {
            duree_totale = 30,  -- 30 SECONDES (MODE TEST!)
            etats = 3,          -- 3 états de croissance (33%, 66%, 100%)

            -- Props visuels pour chaque état (0%, 33%, 66%, 100%)
            props = {
                "h4_prop_bush_cocaplant_01",  -- 0% (graine plantée)
                "h4_prop_bush_cocaplant_01",  -- 33%
                "h4_prop_bush_cocaplant_01",  -- 66%
                "h4_prop_bush_cocaplant_01"   -- 100%
            },

            -- Chaque état nécessite 1x arrosage et 1x engrais
            besoin_arrosage = true,
            besoin_engrais = true
        },

        -- Configuration de la récolte
        recolte = {
            item = "feuille_coca",
            quantite = {min = 5, max = 10},  -- Quantité aléatoire par plante
            animation = {
                dict = "amb@prop_human_bum_bin@idle_b",
                anim = "idle_d"
            }
        },

        -- Configuration du traitement
        traitement = {
            zones = {
                {
                    coords = vector3(1093.29, -3195.68, -38.99),
                    rayon = 2.0,
                    label = "Table de traitement Coca"
                }
            },

            etapes = {
                -- Étape 1: Feuilles → Pâte
                {
                    nom = "Création pâte de coca",
                    description = "Transformer les feuilles en pâte de coca",
                    input = {
                        {item = "feuille_coca", quantite = 10}
                    },
                    output = {item = "pate_coca", quantite = 1},
                    temps = 10,  -- 10 secondes (MODE TEST!)
                    animation = {
                        dict = "anim@amb@business@coc@coc_unpack_cut@",
                        anim = "fullcut_cycle_v1_cokecutter"
                    }
                },

                -- Étape 2: Pâte → Cocaïne pure
                {
                    nom = "Raffinage en cocaïne pure",
                    description = "Raffiner la pâte avec de l'acide sulfurique",
                    input = {
                        {item = "pate_coca", quantite = 5},
                        {item = "acide_sulfurique", quantite = 1}
                    },
                    output = {item = "cocaine_pure", quantite = 1},
                    temps = 10,  -- 10 secondes (MODE TEST!)
                    animation = {
                        dict = "anim@amb@business@coc@coc_unpack_cut@",
                        anim = "fullcut_cycle_v6_cokecutter"
                    }
                }
            }
        },

        -- Configuration du conditionnement
        conditionnement = {
            zone = vector3(1101.52, -3198.97, -38.99),
            rayon = 1.5,
            label = "Table de conditionnement",

            input = {
                {item = "cocaine_pure", quantite = 1},
                {item = "pochon", quantite = 10}
            },
            output = {item = "pochon_cocaine", quantite = 10},
            temps = 10,  -- 10 secondes (MODE TEST!)
            animation = {
                dict = "anim@amb@business@coc@coc_packing_hi@",
                anim = "full_cycle_v1_pressoperator"
            }
        }
    },

    -- ============================================
    -- 🌿 WEED (Cannabis)
    -- ============================================
    weed = {
        type = "plantable",
        label = "Cannabis",
        graine = "graine_weed",

        croissance = {
            duree_totale = 30,  -- 30 SECONDES (MODE TEST!)
            etats = 3,

            props = {
                "prop_weed_01",           -- 0% (graine plantée)
                "prop_weed_01",           -- 33%
                "prop_weed_01",           -- 66%
                "prop_weed_01"            -- 100%
            },

            besoin_arrosage = true,
            besoin_engrais = true
        },

        recolte = {
            item = "tete_weed",
            quantite = {min = 8, max = 15},
            animation = {
                dict = "amb@prop_human_bum_bin@idle_b",
                anim = "idle_d"
            }
        },

        traitement = {
            zones = {
                {
                    coords = vector3(1038.89, -3205.48, -38.17),
                    rayon = 2.0,
                    label = "Table de séchage"
                }
            },

            etapes = {
                -- Étape 1: Séchage
                {
                    nom = "Séchage des têtes",
                    description = "Faire sécher les têtes de cannabis",
                    input = {
                        {item = "tete_weed", quantite = 15}
                    },
                    output = {item = "weed_sechee", quantite = 5},
                    temps = 10,  -- 10 secondes (MODE TEST!)
                    animation = {
                        dict = "anim@amb@business@weed@weed_sorting_seated@",
                        anim = "sorter_right_sort_v3_sorter02"
                    }
                },

                -- Étape 2: Coupe et nettoyage
                {
                    nom = "Coupe et nettoyage",
                    description = "Couper et nettoyer le cannabis séché",
                    input = {
                        {item = "weed_sechee", quantite = 3}
                    },
                    output = {item = "weed_trimmed", quantite = 1},
                    temps = 10,  -- 10 secondes (MODE TEST!)
                    animation = {
                        dict = "anim@amb@business@weed@weed_sorting_seated@",
                        anim = "sorter_right_sort_v3_sorter02"
                    }
                }
            }
        },

        conditionnement = {
            zone = vector3(1045.32, -3198.43, -38.17),
            rayon = 1.5,
            label = "Table de conditionnement",

            input = {
                {item = "weed_trimmed", quantite = 1},
                {item = "pochon", quantite = 5}
            },
            output = {item = "pochon_weed", quantite = 5},
            temps = 10,  -- 10 secondes (MODE TEST!)
            animation = {
                dict = "anim@amb@business@weed@weed_packing_hi@",
                anim = "pack_full_cycle_v3_pressoperator"
            }
        }
    },

    -- ============================================
    -- ⚗️ METH (Méthamphétamine)
    -- PAS de plantation - Fabrication chimique uniquement
    -- ============================================
    meth = {
        type = "craftable",  -- PAS PLANTABLE !
        label = "Méthamphétamine",

        traitement = {
            zones = {
                {
                    coords = vector3(1005.72, -3200.50, -38.52),
                    rayon = 3.0,
                    label = "Laboratoire de Méthamphétamine"
                }
            },

            etapes = {
                -- Étape 1: Création base meth
                {
                    nom = "Création base méthamphétamine",
                    description = "Combiner pseudoéphédrine et acide chlorhydrique",
                    input = {
                        {item = "pseudoephedrine", quantite = 5},
                        {item = "acide_chlorhydrique", quantite = 2}
                    },
                    output = {item = "base_meth", quantite = 1},
                    temps = 10,  -- 10 secondes (MODE TEST!)
                    animation = {
                        dict = "anim@amb@business@meth@meth_monitoring_cooking@cooking@",
                        anim = "chemical_pour_long_v3_cooker"
                    }
                },

                -- Étape 2: Purification
                {
                    nom = "Purification",
                    description = "Purifier la base avec de l'acétone",
                    input = {
                        {item = "base_meth", quantite = 1},
                        {item = "acetone", quantite = 1}
                    },
                    output = {item = "meth_pure", quantite = 1},
                    temps = 10,  -- 10 secondes (MODE TEST!)
                    animation = {
                        dict = "anim@amb@business@meth@meth_monitoring_cooking@cooking@",
                        anim = "chemical_pour_long_v3_cooker"
                    }
                },

                -- Étape 3: Cristallisation
                {
                    nom = "Cristallisation",
                    description = "Cristalliser la méthamphétamine pure",
                    input = {
                        {item = "meth_pure", quantite = 1}
                    },
                    output = {item = "cristaux_meth", quantite = 3},
                    temps = 10,  -- 10 secondes (MODE TEST!)
                    animation = {
                        dict = "anim@amb@business@meth@meth_monitoring_cooking@cooking@",
                        anim = "chemical_pour_short_v1_cooker"
                    }
                }
            }
        },

        conditionnement = {
            zone = vector3(1012.85, -3194.32, -38.99),
            rayon = 1.5,
            label = "Table de conditionnement",

            input = {
                {item = "cristaux_meth", quantite = 1},
                {item = "sachets", quantite = 3}
            },
            output = {item = "pochon_meth", quantite = 3},
            temps = 30,
            animation = {
                dict = "anim@amb@business@meth@meth_smash_weight_check@",
                anim = "break_weigh_v3_char01"
            }
        }
    }
}

-- ============================================
-- CONFIGURATION DU DUI (Interface 3D)
-- ============================================

Config.DUI = {
    enabled = true,
    width = 512,
    height = 512,
    url = "nui://zdrugs/html/dui.html",  -- Interface HTML pour le DUI
    distance_affichage = 2.0  -- Distance max pour voir le DUI
}

-- ============================================
-- ANIMATIONS PAR DÉFAUT
-- ============================================

Config.Animations = {
    planter = {
        dict = "amb@world_human_gardener_plant@male@base",
        anim = "base"
    },
    arroser = {
        dict = "amb@world_human_gardener_plant@male@base",
        anim = "base"
    },
    engrais = {
        dict = "amb@world_human_gardener_plant@male@base",
        anim = "base"
    },
    recolte = {
        dict = "amb@prop_human_bum_bin@idle_b",
        anim = "idle_d"
    }
}

-- ============================================
-- BOUTIQUES DE MATIÈRES PREMIÈRES
-- ============================================

Config.Boutiques = {
    {
        nom = "Vendeur de Graines",
        coords = vector3(100.0, -100.0, 30.0),  -- TODO: Changer les coordonnées
        heading = 90.0,
        ped = "a_m_m_farmer_01",
        blip = {
            enabled = true,
            sprite = 496,
            color = 2,
            scale = 0.8,
            label = "Matières Premières"
        },
        items = {
            {item = "graine_coca", label = "Graine de Coca", prix = 50},
            {item = "graine_weed", label = "Graine de Cannabis", prix = 50},
            {item = "arrosoir", label = "Arrosoir", prix = 50},
            {item = "fertilizer", label = "Engrais", prix = 50},
            {item = "pseudoephedrine", label = "Pseudoéphédrine", prix = 50},
            {item = "acide_chlorhydrique", label = "Acide Chlorhydrique", prix = 50},
            {item = "acetone", label = "Acétone", prix = 50},
            {item = "acide_sulfurique", label = "Acide Sulfurique", prix = 50}
        }
    }
}

-- ============================================
-- MESSAGES & NOTIFICATIONS
-- ============================================

Config.Messages = {
    plante_trop_pres = "Une plante est déjà présente à proximité",
    limite_plantes = "Vous avez atteint la limite de plantes (%s/%s)",
    pas_assez_items = "Vous n'avez pas les items nécessaires",
    plante_arrosee = "Plante arrosée avec succès",
    engrais_ajoute = "Engrais ajouté avec succès",
    recolte_success = "Vous avez récolté %sx %s",
    plante_pas_prete = "La plante n'est pas prête à être récoltée",
    traitement_success = "Traitement terminé: %sx %s",
    conditionnement_success = "Conditionnement terminé: %sx %s",
    plante_supprimee = "Plante supprimée (trop ancienne)",
    achat_success = "Vous avez acheté %sx %s pour $%s",
    pas_assez_argent = "Vous n'avez pas assez d'argent ($%s requis)"
}
