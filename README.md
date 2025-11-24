# 🌿 zdrugs - Système de Drogues Complet ESX

Script FiveM ESX full configurable pour la gestion de drogues avec système de plantation, croissance, traitement et conditionnement.

## 📋 Caractéristiques

### 🌱 Système de Plantation
- **3 états de croissance** : 33% → 66% → 100%
- **Durée totale** : 30 minutes (configurable)
- **Conditions par état** : 1x arrosage + 1x engrais obligatoires
- **Props visuels** : Un prop différent pour chaque état de croissance
- **Persistence** : Les plantes sont sauvegardées en base de données
- **Limite** : Nombre maximum de plantes par joueur (configurable)

### 💊 Les 3 Drogues

#### 🍃 Cocaine (Feuilles de Coca)
- **Plantation** : Graine de coca
- **Récolte** : 5-10 feuilles de coca
- **Traitement** :
  - Étape 1 : 10x feuille_coca → 1x pate_coca (2 min)
  - Étape 2 : 5x pate_coca + 1x acide_sulfurique → 1x cocaine_pure (3 min)
- **Conditionnement** : 1x cocaine_pure + 10x pochon → 10x pochon_cocaine

#### 🌿 Weed (Cannabis)
- **Plantation** : Graine de cannabis
- **Récolte** : 8-15 têtes de weed
- **Traitement** :
  - Étape 1 : 15x tete_weed → 5x weed_sechee (5 min)
  - Étape 2 : 3x weed_sechee → 1x weed_trimmed (2 min)
- **Conditionnement** : 1x weed_trimmed + 5x pochon → 5x pochon_weed

#### ⚗️ Meth (Méthamphétamine)
- **PAS de plantation** (fabrication chimique uniquement)
- **Traitement** :
  - Étape 1 : 5x pseudoephedrine + 2x acide_chlorhydrique → 1x base_meth (10 min)
  - Étape 2 : 1x base_meth + 1x acetone → 1x meth_pure (8 min)
  - Étape 3 : 1x meth_pure → 3x cristaux_meth (5 min)
- **Conditionnement** : 1x cristaux_meth + 3x sachets → 3x pochon_meth

### 🎮 Interactions
- **ox_target** : Interactions avec les plantes et zones
- **ox_lib** : Menus, notifications, progress bars
- **Affichage d'état** : Menu détaillé montrant la croissance, arrosage, engrais et temps restant

## 🔧 Dépendances

- [es_extended](https://github.com/esx-framework/esx-legacy) (ESX Legacy)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)
- [oxmysql](https://github.com/overextended/oxmysql)

## 📥 Installation

### 1. Téléchargement
```bash
cd resources
git clone https://github.com/votre-repo/zdrugs.git
```

### 2. Base de données
Exécutez le fichier SQL pour créer les tables nécessaires :
```bash
mysql -u votre_user -p votre_database < zdrugs/sql/install.sql
```

### 3. Items ox_inventory
Copiez le contenu de `items.lua` dans votre fichier `ox_inventory/data/items.lua`.

**⚠️ IMPORTANT** : Vérifiez que les items suivants n'existent pas déjà dans votre inventory pour éviter les doublons :
- water, fertilizer, plastic_bag, small_bags

### 4. Configuration
Éditez `config.lua` pour personnaliser :
- Les coordonnées des zones de traitement et conditionnement
- Les durées de croissance
- Les quantités de récolte
- Les limites par joueur
- Les ratios input/output

### 5. server.cfg
Ajoutez à votre `server.cfg` :
```lua
ensure zdrugs
```

## ⚙️ Configuration

### Zones de Traitement
Dans `config.lua`, modifiez les coordonnées des zones :

```lua
traitement = {
    zones = {
        {
            coords = vector3(x, y, z),  -- Remplacez par vos coordonnées
            rayon = 2.0,
            label = "Table de traitement"
        }
    },
    -- ...
}
```

### Zones de Conditionnement
```lua
conditionnement = {
    zone = vector3(x, y, z),  -- Remplacez par vos coordonnées
    rayon = 1.5,
    label = "Table de conditionnement",
    -- ...
}
```

### Limites
```lua
Config.Limites = {
    max_plantes_par_joueur = 10,           -- Nombre max de plantes
    distance_min_entre_plantes = 2.0,      -- Distance minimum entre plantes
    suppression_auto_apres = 86400,        -- Suppression après 24h
}
```

## 🎯 Utilisation

### Pour les Joueurs

#### Planter
1. Avoir une `graine_coca` ou `graine_weed` dans l'inventaire
2. **Clic droit** sur l'item dans ox_inventory → Cliquer sur **"Utiliser"**
3. Choisir un emplacement pour planter (la graine apparaît en preview devant vous)
4. Appuyer sur `[E]` pour confirmer la plantation ou `[X]` pour annuler

**⚠️ Important** : Les graines sont des items **usables** (utilisables). Vous devez faire **clic droit → Utiliser** sur la graine dans votre inventaire pour lancer le mode plantation.

#### Entretenir
1. Viser la plante avec ox_target
2. Choisir "Arroser" (nécessite : eau)
3. Choisir "Mettre Engrais" (nécessite : engrais)
4. **Note** : Chaque état de croissance nécessite 1x arrosage ET 1x engrais

#### Voir l'État
1. Viser la plante avec ox_target
2. Choisir "Voir État"
3. Un menu affiche :
   - Pourcentage de croissance
   - État de l'arrosage
   - État de l'engrais
   - Temps restant

#### Récolter
1. Attendre que la plante soit à 100%
2. Viser la plante avec ox_target
3. Choisir "Récolter"
4. Récupérer les items dans votre inventaire

#### Traiter
1. Se rendre à une zone de traitement
2. Avoir les items nécessaires
3. Interagir avec ox_target
4. Choisir l'étape de traitement
5. Attendre la fin de la progress bar

#### Conditionner
1. Se rendre à une zone de conditionnement
2. Avoir les items nécessaires
3. Interagir avec ox_target
4. Confirmer le conditionnement
5. Attendre la fin de la progress bar

### Pour les Admins

#### Commandes
```
/zdrugs:stats      - Affiche les statistiques des plantes
/zdrugs:cleanup    - Nettoie les plantes anciennes manuellement
```

**Permissions** : Nécessite le rang `admin` ou `superadmin` dans ESX.

#### Logs
Toutes les actions sont enregistrées dans la table `zdrugs_logs` :
- Plantation
- Arrosage
- Engrais
- Récolte
- Traitement
- Conditionnement

## 🗂️ Structure des Fichiers

```
zdrugs/
├── client/
│   ├── main.lua           # Logique client principale (plantation, interactions)
│   ├── dui.lua            # Système d'affichage d'état (DUI/Menu)
│   └── processing.lua     # Zones de traitement et conditionnement
├── server/
│   ├── main.lua           # Logique serveur (plantes, sync)
│   ├── growth.lua         # Système de croissance et nettoyage
│   └── processing.lua     # Traitement et conditionnement
├── sql/
│   └── install.sql        # Script SQL d'installation
├── config.lua             # Configuration complète
├── fxmanifest.lua         # Manifest du script
├── items.lua              # Items ox_inventory
└── README.md              # Ce fichier
```

## 🔄 Système de Croissance

### Fonctionnement
1. **Plantation** : Le joueur plante une graine
2. **État 0 → 33%** : Nécessite 1x arrosage + 1x engrais
3. **État 33% → 66%** : Nécessite 1x arrosage + 1x engrais
4. **État 66% → 100%** : Nécessite 1x arrosage + 1x engrais
5. **Récolte** : À 100%, la plante peut être récoltée

### Timer
- Le timer de croissance continue même après un restart du serveur
- Un thread vérifie la croissance toutes les 30 secondes
- Les plantes ne passent au prochain état QUE si elles ont été arrosées ET fertilisées

### Nettoyage Automatique
- Un thread nettoie les plantes de plus de 24h toutes les 10 minutes
- Configurable dans `Config.Limites.suppression_auto_apres`

## 🐛 Dépannage

### Les plantes ne poussent pas
- Vérifiez que la plante a été arrosée ET fertilisée
- Utilisez "Voir État" pour vérifier le statut
- Vérifiez les logs serveur pour les erreurs

### Les zones ne fonctionnent pas
- Vérifiez que ox_target est bien démarré
- Vérifiez les coordonnées dans config.lua
- Assurez-vous d'être dans le rayon de la zone

### Items non trouvés
- Vérifiez que tous les items ont été ajoutés à ox_inventory
- Redémarrez ox_inventory après l'ajout des items
- Utilisez `/refreshitems` si disponible

### Erreurs SQL
- Vérifiez que les tables ont été créées
- Vérifiez que oxmysql est bien configuré
- Consultez les logs du serveur

## 📝 Notes Importantes

### Sécurité
- Toutes les vérifications d'items sont faites côté serveur
- Les coordonnées de plantation sont vérifiées
- Protection contre le spam et l'exploitation

### Performance
- Les threads sont optimisés (30 secondes pour la croissance)
- Nettoyage automatique des plantes anciennes
- Cache local pour les plantes côté client

### Personnalisation
- Tous les temps sont configurables
- Tous les ratios input/output sont configurables
- Props et animations personnalisables
- Messages personnalisables

## 🤝 Support

Pour toute question ou problème :
1. Vérifiez ce README
2. Consultez les logs serveur (`F8` ou console)
3. Vérifiez les dépendances
4. Ouvrez une issue sur GitHub

## 📜 Licence

Ce script est fourni tel quel, sans garantie. Utilisez-le à vos propres risques.

## 🎉 Crédits

- **Développé par** : Claude Code
- **Framework** : ESX Legacy
- **Librairies** : ox_lib, ox_inventory, ox_target

---

**Version** : 1.0.0
**Dernière mise à jour** : 2025
