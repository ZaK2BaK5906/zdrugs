-- ============================================
-- ITEMS OX_INVENTORY POUR LE SYSTÈME DE DROGUES
-- À copier dans ox_inventory/data/items.lua
-- ============================================

-- ============================================
-- ITEMS COMMUNS
-- ============================================

['water'] = {
    label = 'Eau',
    weight = 500,
    stack = true,
    close = true,
    description = 'De l\'eau pour arroser les plantes'
},

['fertilizer'] = {
    label = 'Engrais',
    weight = 200,
    stack = true,
    close = true,
    description = 'Engrais pour favoriser la croissance des plantes'
},

['plastic_bag'] = {
    label = 'Sachets plastique',
    weight = 10,
    stack = true,
    close = true,
    description = 'Sachets pour conditionner la drogue'
},

['small_bags'] = {
    label = 'Petits sachets',
    weight = 5,
    stack = true,
    close = true,
    description = 'Petits sachets pour conditionner les cristaux'
},

-- ============================================
-- COCAINE - ITEMS
-- ============================================

['graine_coca'] = {
    label = 'Graine de Coca',
    weight = 10,
    stack = true,
    close = true,
    description = 'Graine de plant de coca',
    buttons = {
        {
            label = 'Planter',
            action = function(slot)
                TriggerEvent('zdrugs:client:plantSeed', 'cocaine', slot)
            end
        }
    }
},

['feuille_coca'] = {
    label = 'Feuilles de Coca',
    weight = 100,
    stack = true,
    close = true,
    description = 'Feuilles de coca fraîchement récoltées'
},

['pate_coca'] = {
    label = 'Pâte de Coca',
    weight = 150,
    stack = true,
    close = true,
    description = 'Pâte de coca brute'
},

['acide_sulfurique'] = {
    label = 'Acide Sulfurique',
    weight = 500,
    stack = true,
    close = true,
    description = 'Produit chimique dangereux'
},

['cocaine_pure'] = {
    label = 'Cocaïne Pure',
    weight = 200,
    stack = true,
    close = true,
    description = 'Cocaïne pure non conditionnée'
},

['pochon_cocaine'] = {
    label = 'Pochon de Cocaïne',
    weight = 50,
    stack = true,
    close = true,
    description = 'Cocaïne conditionnée prête à la vente',
    client = {
        export = 'zdrugs.useCocaine'
    }
},

-- ============================================
-- WEED - ITEMS
-- ============================================

['graine_weed'] = {
    label = 'Graine de Cannabis',
    weight = 5,
    stack = true,
    close = true,
    description = 'Graine de plant de cannabis',
    buttons = {
        {
            label = 'Planter',
            action = function(slot)
                TriggerEvent('zdrugs:client:plantSeed', 'weed', slot)
            end
        }
    }
},

['tete_weed'] = {
    label = 'Têtes de Cannabis',
    weight = 80,
    stack = true,
    close = true,
    description = 'Têtes de cannabis fraîches'
},

['weed_sechee'] = {
    label = 'Cannabis Séché',
    weight = 60,
    stack = true,
    close = true,
    description = 'Cannabis séché'
},

['weed_trimmed'] = {
    label = 'Cannabis Préparé',
    weight = 50,
    stack = true,
    close = true,
    description = 'Cannabis coupé et nettoyé'
},

['pochon_weed'] = {
    label = 'Pochon de Weed',
    weight = 30,
    stack = true,
    close = true,
    description = 'Cannabis conditionné prêt à la vente',
    client = {
        export = 'zdrugs.useWeed'
    }
},

-- ============================================
-- METH - ITEMS
-- ============================================

['pseudoephedrine'] = {
    label = 'Pseudoéphédrine',
    weight = 100,
    stack = true,
    close = true,
    description = 'Médicament utilisé comme précurseur'
},

['acide_chlorhydrique'] = {
    label = 'Acide Chlorhydrique',
    weight = 500,
    stack = true,
    close = true,
    description = 'Produit chimique dangereux'
},

['base_meth'] = {
    label = 'Base de Méthamphétamine',
    weight = 200,
    stack = true,
    close = true,
    description = 'Base brute de méthamphétamine'
},

['acetone'] = {
    label = 'Acétone',
    weight = 300,
    stack = true,
    close = true,
    description = 'Solvant pour purification'
},

['meth_pure'] = {
    label = 'Méthamphétamine Pure',
    weight = 150,
    stack = true,
    close = true,
    description = 'Méthamphétamine purifiée'
},

['cristaux_meth'] = {
    label = 'Cristaux de Meth',
    weight = 100,
    stack = true,
    close = true,
    description = 'Cristaux de méthamphétamine'
},

['pochon_meth'] = {
    label = 'Pochon de Meth',
    weight = 40,
    stack = true,
    close = true,
    description = 'Méthamphétamine conditionnée prête à la vente',
    client = {
        export = 'zdrugs.useMeth'
    }
}
