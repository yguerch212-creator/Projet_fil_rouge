# 📋 Cahier des Charges Fonctionnel — Projet Fil Rouge

> **Grille de notation n°5** — BC04 : Conduire la gestion de projets d'infrastructure systèmes et réseaux sécurisée
>
> **Objectif** : Rédaction d'une étude d'avant-projet — Analyse des besoins, étude de faisabilité et cahier des charges fonctionnel
>
> **Compétences validées** : C23, C24

---

## 📋 Table des matières

1. [Présentation du projet](#1-présentation-du-projet)
2. [Analyse des besoins](#2-analyse-des-besoins) — C23.1
3. [Objectifs fonctionnels](#3-objectifs-fonctionnels) — C23.2
4. [Contraintes techniques](#4-contraintes-techniques) — C23.3
5. [Spécifications fonctionnelles](#5-spécifications-fonctionnelles) — C24.3
6. [Spécifications techniques](#6-spécifications-techniques) — C24.2
7. [Analyse des risques et opportunités](#7-analyse-des-risques-et-opportunités) — C24.1
8. [Planning et livrables](#8-planning-et-livrables)
9. [Critères de recette](#9-critères-de-recette)
10. [Annexes](#annexes)

---

## Cartographie des compétences

| Critère | Intitulé | Section(s) |
|---------|----------|------------|
| **C23.1** | Pertinence et exhaustivité de la collecte des besoins | §2 |
| **C23.2** | Reformulation claire des objectifs fonctionnels | §3, §5 |
| **C23.3** | Alignement des besoins avec les contraintes techniques | §4, §6 |
| **C24.1** | Évaluation des risques et opportunités | §7 |
| **C24.2** | Justification des choix techniques | §6 |
| **C24.3** | Structuration d'un cahier des charges fonctionnel | Structure globale, §5, §9 |

---

## 1. Présentation du projet

### 1.1 Contexte

Le **Projet Fil Rouge** est le projet intégrateur du cursus B3 Cybersécurité. Il couvre l'ensemble du cycle de vie d'une infrastructure systèmes et réseaux : conception, déploiement, sécurisation, documentation et amélioration continue.

Le projet choisi est le développement et le déploiement d'un **addon Garry's Mod** (jeu Source Engine multijoueur) intitulé **RP Construction System**, hébergé sur une infrastructure Docker conteneurisée avec base de données MySQL.

### 1.2 Parties prenantes

| Rôle | Description |
|------|-------------|
| **Développeur / Administrateur** | Étudiant B3 — Conception, développement, déploiement, documentation |
| **Utilisateurs finaux** | Joueurs du serveur DarkRP (roleplay Garry's Mod) |
| **Évaluateurs** | Jury d'examen B3 Cybersécurité |
| **Communauté** | Steam Workshop — Utilisateurs standalone de l'addon |

### 1.3 Périmètre

Le projet couvre **trois axes** :

```
┌──────────────────────────────────────────────────────┐
│                  PROJET FIL ROUGE                    │
│                                                      │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐  │
│  │   AXE 1     │  │    AXE 2     │  │   AXE 3    │  │
│  │ ADDON LUA   │  │ INFRA DOCKER │  │   DOCS &   │  │
│  │             │  │  + MYSQL     │  │   RENDUS   │  │
│  │ - SWEP      │  │ - VPS        │  │ - DAT      │  │
│  │ - Entités   │  │ - Conteneurs │  │ - CdC      │  │
│  │ - UI/UX     │  │ - Réseau     │  │ - Guides   │  │
│  │ - Workshop  │  │ - Backup     │  │ - Journal  │  │
│  │ - Véhicules │  │ - Monitoring │  │ - Rendus   │  │
│  └─────────────┘  └──────────────┘  └────────────┘  │
└──────────────────────────────────────────────────────┘
```

### 1.4 Hors périmètre

- Développement d'un launcher ou client personnalisé
- Hébergement multi-serveurs ou load balancing
- Système de paiement réel ou monétisation
- Application web ou API REST externe
- Gestion d'un nom de domaine ou certificat SSL (serveur de jeu, pas web)

---

## 2. Analyse des besoins — C23.1

### 2.1 Besoins métier (addon)

L'addon répond à un besoin identifié dans la communauté DarkRP : **permettre la construction collaborative en roleplay** avec persistance des créations.

| ID | Besoin | Priorité | Source |
|----|--------|----------|--------|
| **B01** | Sauvegarder des constructions (blueprints) pour les réutiliser | 🔴 Critique | Communauté RP |
| **B02** | Charger un blueprint sous forme de fantômes transparents | 🔴 Critique | Gameplay RP |
| **B03** | Matérialiser les fantômes avec des ressources (caisses) | 🔴 Critique | Équilibre gameplay |
| **B04** | Intégrer le système au framework DarkRP (job Constructeur) | 🟠 Élevé | Immersion RP |
| **B05** | Supporter les véhicules dans les blueprints | 🟠 Élevé | Retour joueurs |
| **B06** | Interface utilisateur intuitive et ergonomique | 🟠 Élevé | Accessibilité |
| **B07** | Distribuer l'addon via Steam Workshop | 🟡 Moyen | Distribution |
| **B08** | Aucun coût en jeu pour sauvegarder/charger | 🟡 Moyen | Accessibilité |
| **B09** | Support AdvDupe2 comme format d'import | 🟡 Moyen | Interopérabilité |
| **B10** | L'addon doit être standalone (sans dépendances) | 🔴 Critique | Workshop |

### 2.2 Besoins infrastructure

| ID | Besoin | Priorité | Justification |
|----|--------|----------|---------------|
| **I01** | Serveur GMod accessible depuis Internet | 🔴 Critique | Tests et démonstration |
| **I02** | Infrastructure conteneurisée et reproductible | 🔴 Critique | Portabilité, versioning |
| **I03** | Base de données pour logs et futur partage | 🟠 Élevé | Traçabilité, évolution |
| **I04** | Sauvegarde automatisée des données | 🔴 Critique | Continuité d'activité |
| **I05** | Monitoring et observabilité | 🟡 Moyen | Maintenance proactive |
| **I06** | Sécurisation des accès (SSH, RCON, MySQL) | 🔴 Critique | Cybersécurité |
| **I07** | Gestion des images Docker versionnées | 🟠 Élevé | Rollback, traçabilité |
| **I08** | Limitation des ressources par conteneur | 🟠 Élevé | Stabilité VPS |

### 2.3 Besoins documentaires

| ID | Besoin | Priorité | Livrable |
|----|--------|----------|----------|
| **D01** | Dossier d'architecture technique | 🔴 Critique | `rendu/dat/` |
| **D02** | Cahier des charges fonctionnel | 🔴 Critique | `rendu/cdc/` (ce document) |
| **D03** | Plan de sauvegarde et restauration | 🔴 Critique | `rendu/backup/` |
| **D04** | Compte-rendu d'amélioration | 🔴 Critique | `rendu/amelioration/` |
| **D05** | Guide d'installation | 🟠 Élevé | `docs/GUIDE_INSTALLATION.md` |
| **D06** | Guide utilisateur | 🟠 Élevé | `docs/GUIDE_UTILISATEUR.md` |
| **D07** | Journal de développement | 🟠 Élevé | `docs/JOURNAL_DEV.md` |
| **D08** | Documentation d'architecture | 🟠 Élevé | `docs/ARCHITECTURE.md` |

### 2.4 Matrice de priorisation (MoSCoW)

| Must Have | Should Have | Could Have | Won't Have |
|-----------|------------|------------|------------|
| Blueprints save/load (B01) | Véhicules (B05) | Import AdvDupe2 (B09) | Système de paiement |
| Fantômes + matérialisation (B02-B03) | UI Derma (B06) | Monitoring Grafana (I05) | Multi-serveur |
| DarkRP intégration (B04) | Workshop publication (B07) | Chiffrement backups | API REST |
| Docker infra (I01-I02) | Backup auto (I04) | CI/CD pipeline | Load balancing |
| Standalone addon (B10) | Images versionnées (I07) | Réplication MySQL | Client personnalisé |
| Sécurisation (I06) | Docs complètes (D01-D08) | | |

---

## 3. Objectifs fonctionnels — C23.2

### 3.1 Axe Addon — RP Construction System

| Ref | Objectif fonctionnel | Description | Critère de validation |
|-----|---------------------|-------------|----------------------|
| **OF01** | Sauvegarder un blueprint | Le joueur sélectionne des props avec le SWEP et les sauvegarde localement | Blueprint créé dans `data/construction_blueprints/` |
| **OF02** | Charger un blueprint en fantômes | Le joueur charge un blueprint ; des entités transparentes apparaissent à la position choisie | Fantômes visibles, non-solides, positionnés correctement |
| **OF03** | Matérialiser un fantôme | Un joueur porte une caisse vers un fantôme ; celui-ci devient un prop solide | Prop réel créé, fantôme supprimé, caisse consommée |
| **OF04** | Gérer les véhicules | Les blueprints supportent les véhicules avec offsets spécifiques | Véhicule matérialisé, fonctionnel, utilisable |
| **OF05** | Interface de gestion | Menu Derma pour lister, charger, supprimer les blueprints | Menu accessible, responsive, fonctionnel |
| **OF06** | Attribution par job DarkRP | Le SWEP est attribué au job Constructeur | Seul le Constructeur possède l'outil par défaut |
| **OF07** | Compatibilité AdvDupe2 | Décodeur AD2 embarqué pour import de fichiers existants | Import fonctionnel sans dépendance externe |
| **OF08** | Distribution Workshop | L'addon est publié sur Steam Workshop, installable en un clic | Page Workshop publique, installation fonctionnelle |

### 3.2 Axe Infrastructure

| Ref | Objectif fonctionnel | Description | Critère de validation |
|-----|---------------------|-------------|----------------------|
| **OI01** | Déployer le serveur GMod | Serveur accessible en ligne, jouable | Connexion client réussie |
| **OI02** | Conteneuriser les services | GMod + MySQL dans Docker Compose | `docker compose up -d` démarre tout |
| **OI03** | Versionner les images Docker | Tags sémantiques pour chaque jalon | Images listables et restaurables |
| **OI04** | Automatiser les backups | Scripts cron pour MySQL + fichiers | Backups créés sans intervention |
| **OI05** | Sécuriser les accès | SSH par clé, RCON protégé, MySQL credentials | Aucun accès non autorisé |
| **OI06** | Limiter les ressources | GMod 3 Go RAM, MySQL 512 Mo | Pas de dépassement, VPS stable |

### 3.3 Axe Documentation

| Ref | Objectif fonctionnel | Description | Critère de validation |
|-----|---------------------|-------------|----------------------|
| **OD01** | Documenter l'architecture | DAT complet avec vues logique, physique, réseau | Grille n°1 validée |
| **OD02** | Rédiger le CdC | Analyse des besoins + spécifications | Grille n°5 validée (ce document) |
| **OD03** | Planifier les sauvegardes | Plan backup/restore avec tests | Grille n°4 validée |
| **OD04** | Proposer des améliorations | Analyse PCA, monitoring, incidents | Grille n°3 validée |
| **OD05** | Guider l'installation | Guide pas-à-pas reproductible | Serveur déployable par un tiers |
| **OD06** | Guider l'utilisation | Manuel utilisateur complet | Joueur autonome après lecture |

---

## 4. Contraintes techniques — C23.3

### 4.1 Contraintes matérielles

| Contrainte | Valeur | Impact |
|------------|--------|--------|
| **VPS** | Hostinger, 16 Go RAM, Ubuntu 22.04, IP fixe | Serveur unique, pas de cluster |
| **Allocation GMod** | Max 3 Go RAM, 2 CPUs | Limite le nombre de joueurs (~20) |
| **Allocation MySQL** | Max 512 Mo RAM, 0.5 CPU | Adapté aux logs, pas au Big Data |
| **Stockage** | ~80 Go SSD partagé | Rétention backup limitée |
| **Bande passante** | Partagée VPS | Pas de garantie de latence |

### 4.2 Contraintes logicielles

| Contrainte | Détail | Conséquence |
|------------|--------|-------------|
| **Image Docker** | `ceifa/garrysmod` (communautaire) | Pas de support officiel Valve |
| **Garry's Mod** | Source Engine, Lua 5.1 (GLua) | Pas de bibliothèques externes |
| **DarkRP** | Framework RP dominant | API spécifique (jobs, entités, shipments) |
| **Steam Workshop** | Format GMA, whitelist stricte | Certains fichiers interdits (.sw.vtx) |
| **gmad** | Compilateur GMA officiel | Nécessite `addon.json` + fichiers conformes |
| **MySQL 8.0** | Image Docker officielle | Compatible mysqldump, pas besoin de xtrabackup |

### 4.3 Contraintes architecturales

| Contrainte | Justification |
|------------|---------------|
| **Blueprints côté client** | Pas de base de données requise pour jouer ; résilience maximale |
| **SWEP (pas STOOL)** | Plus intuitif, attribution automatique par job |
| **Addon standalone** | Aucune dépendance pour la version Workshop |
| **Séparation client/serveur stricte** | Sécurité : le client ne peut pas tricher sur les actions serveur |
| **Net messages validés serveur** | Anti-exploit : chaque requête client est vérifiée |
| **Deux versions** | Dev (MySQL, logs, admin) vs Workshop (standalone, zéro config) |

### 4.4 Contraintes de sécurité

| Exigence | Implémentation |
|----------|---------------|
| Pas de données en clair dans le code | Credentials dans variables d'environnement Docker |
| Validation serveur de toute action | `net.Receive` avec vérifications (job, distance, ownership) |
| Accès SSH par clé uniquement | `PasswordAuthentication no` |
| Firewall restrictif | UFW : seuls ports 22, 27015 ouverts |
| RCON protégé | Mot de passe fort, non exposé publiquement |
| Rate limiting net messages | Protection flood côté serveur |

### 4.5 Contraintes de délai

| Jalon | Échéance | Statut |
|-------|----------|--------|
| Infrastructure Docker | Étape 1-2 | ✅ Terminé |
| Addon v1.0 (core) | Étape 3-4 | ✅ Terminé |
| Addon v2.0 (refonte SWEP) | Étape 5 | ✅ Terminé |
| Addon v2.1 (UI + AD2) | Étape 6 | ✅ Terminé |
| Addon v2.2 (véhicules) | Étape 7 | ✅ Terminé |
| Publication Workshop | Étape 8 | ✅ Terminé |
| Documentation complète | Étape 9-12 | ✅ Terminé |
| Rendus académiques | 22/02/2026 | 🔄 En cours |

---

## 5. Spécifications fonctionnelles — C24.3

### 5.1 Addon — Diagramme de cas d'utilisation

```
                        ┌─────────────────────────┐
                        │   RP Construction System │
                        │                         │
  ┌────────────┐        │  ┌───────────────────┐  │
  │            │───────→│  │ Sélectionner props │  │
  │ Constructeur│       │  └───────────────────┘  │
  │ (SWEP)     │───────→│  ┌───────────────────┐  │
  │            │        │  │ Sauvegarder        │  │
  │            │───────→│  │ blueprint          │  │
  │            │        │  └───────────────────┘  │
  │            │───────→│  ┌───────────────────┐  │
  └────────────┘        │  │ Charger blueprint  │  │
                        │  │ (fantômes)         │  │
                        │  └───────────────────┘  │
                        │                         │
  ┌────────────┐        │  ┌───────────────────┐  │
  │            │───────→│  │ Matérialiser       │  │
  │ Tout joueur │       │  │ fantôme (caisse)   │  │
  │            │        │  └───────────────────┘  │
  └────────────┘        │                         │
                        │  ┌───────────────────┐  │
  ┌────────────┐        │  │ Gérer menu        │  │
  │            │───────→│  │ blueprints         │  │
  │ Constructeur│       │  └───────────────────┘  │
  │            │───────→│  ┌───────────────────┐  │
  └────────────┘        │  │ Importer AD2       │  │
                        │  └───────────────────┘  │
                        └─────────────────────────┘
```

### 5.2 Spécifications détaillées par fonctionnalité

#### SF01 — Sélection de props

| Attribut | Valeur |
|----------|--------|
| **Acteur** | Joueur avec SWEP weapon_construction |
| **Déclencheur** | Clic gauche sur un prop/véhicule |
| **Pré-condition** | Joueur est Constructeur (TEAM_BUILDER) |
| **Action** | Le prop est ajouté à la sélection courante (highlight visuel) |
| **Post-condition** | Prop marqué visuellement, compteur de sélection mis à jour |
| **Règles métier** | Validation serveur du ownership CPPI, distance max configurable |

#### SF02 — Sauvegarde de blueprint

| Attribut | Valeur |
|----------|--------|
| **Acteur** | Constructeur avec sélection non vide |
| **Déclencheur** | Clic droit → menu → "Sauvegarder" |
| **Pré-condition** | Au moins 1 prop sélectionné |
| **Action** | Sérialisation des props (modèle, position relative, angles, skin, bodygroups) dans un fichier `.dat` |
| **Post-condition** | Fichier créé dans `data/construction_blueprints/<nom>.dat` côté client |
| **Stockage** | Local client uniquement — aucune donnée envoyée au serveur |

#### SF03 — Chargement de blueprint (fantômes)

| Attribut | Valeur |
|----------|--------|
| **Acteur** | Constructeur |
| **Déclencheur** | Menu → sélection blueprint → "Charger" |
| **Action** | Création d'entités `construction_ghost` sur le serveur, positionnées relativement au joueur |
| **Post-condition** | Fantômes transparents visibles par tous, non-solides |
| **Net messages** | `construction_load` (client→serveur), `construction_ghost_spawn` (serveur→clients) |

#### SF04 — Matérialisation

| Attribut | Valeur |
|----------|--------|
| **Acteur** | Tout joueur portant une caisse (`construction_crate` ou `construction_crate_small`) |
| **Déclencheur** | Approche d'un fantôme à distance < seuil |
| **Pré-condition** | Fantôme existe, caisse portée par le joueur |
| **Action** | Caisse consommée, fantôme remplacé par un prop/véhicule réel |
| **Post-condition** | Prop solide créé à la position du fantôme, caisse supprimée |
| **Règles** | Grosse caisse = props standard ; petite caisse = props petits. Max 2 véhicules par blueprint. |

#### SF05 — Gestion des véhicules

| Attribut | Valeur |
|----------|--------|
| **Spécificité** | Les véhicules nécessitent un traitement différent des props |
| **Détection** | `ent:IsVehicle()` ou vérification classe dans liste DarkRP |
| **Offsets** | Table de décalages par modèle (hardcodée) pour positionnement correct |
| **Limite** | Maximum 2 véhicules par blueprint |
| **Matérialisation** | Clic R (Reload) sur fantôme véhicule → net message → spawn serveur |

### 5.3 Infrastructure — Spécifications

#### SI01 — Docker Compose

| Attribut | Valeur |
|----------|--------|
| **Services** | 2 : `gmod` (serveur de jeu) + `mysql` (base de données) |
| **Orchestration** | Docker Compose v2 |
| **Réseau** | Bridge Docker par défaut, ports exposés : 27015 (GMod), 3306 (MySQL) |
| **Volumes** | Named volume (`gmod-server-data`) + bind mounts (addons, config) |
| **Restart policy** | `unless-stopped` pour les deux services |
| **Health check** | MySQL : `mysqladmin ping` toutes les 30s |

#### SI02 — Politique de versioning des images

| Tag | Contenu | Taille |
|-----|---------|--------|
| `v1.0-base` | GMod + DarkRP de base | ~2 Go |
| `v1.1-mysql` | + Configuration MySQL + lua-bin | ~2.1 Go |
| `v2-stable` | + Addon v2.0 (SWEP + entités) | ~2.1 Go |
| `v2.1-stable` | + UI Derma + décodeur AD2 | ~2.1 Go |
| `v2.2-vehicles` | + Support véhicules | ~2.1 Go |

#### SI03 — Backup automatisé

| Type | Cible | Fréquence | Rétention |
|------|-------|-----------|-----------|
| MySQL dump horaire | `gmod_construction` | 1h | 24 fichiers |
| Backup quotidien complet | MySQL + fichiers config | 24h | 7 jours |
| Backup mensuel | Tout + images Docker | 1 mois | 3 mois |

---

## 6. Spécifications techniques — C24.2

### 6.1 Stack technologique

| Couche | Technologie | Version | Justification |
|--------|-------------|---------|---------------|
| **Jeu** | Garry's Mod | Dernière stable | Plateforme cible |
| **Framework RP** | DarkRP | 2.7.0+ | Standard communautaire, API mature |
| **Langage addon** | GLua (Lua 5.1) | — | Seul langage supporté par GMod |
| **Conteneurisation** | Docker + Docker Compose | 24.x + v2 | Reproductibilité, isolation |
| **Image serveur** | `ceifa/garrysmod` | Latest | Seule image Docker GMod communautaire maintenue |
| **Base de données** | MySQL 8.0 | 8.0 | Robuste, compatible `mysqladmin`, image officielle |
| **OS hôte** | Ubuntu 22.04 LTS | 22.04 | LTS = stabilité + support long terme |
| **VCS** | Git + GitHub | — | Standard industrie, collaboration |
| **Distribution** | Steam Workshop | — | Canal natif GMod, installation automatique |

### 6.2 Justification des choix — C24.2

#### Docker vs installation native

| Critère | Docker | Natif (SteamCMD) |
|---------|--------|-------------------|
| Reproductibilité | ✅ Identique partout | ❌ Dépend de l'OS |
| Isolation | ✅ Conteneur isolé | ❌ Processus système |
| Versioning | ✅ Tags d'images | ❌ Snapshots manuels |
| Rollback | ✅ `docker run <ancien-tag>` | ❌ Réinstallation |
| Performance | ~95% natif | 100% natif |
| Complexité | Moyenne | Faible |

**Verdict** : Docker retenu pour la reproductibilité et le versioning, essentiels dans un contexte pédagogique et de démonstration.

#### MySQL vs SQLite vs fichiers plats

| Critère | MySQL 8.0 | SQLite | Fichiers plats |
|---------|-----------|--------|----------------|
| Requêtes complexes | ✅ | ✅ | ❌ |
| Concurrence | ✅ Multi-connexion | ⚠️ Limité | ❌ |
| Administration | Serveur dédié | Embarqué | Aucune |
| Backup | mysqldump | Copie fichier | Copie fichier |
| Scalabilité | ✅ Excellente | ❌ Limitée | ❌ |
| Complexité déploiement | Moyenne | Faible | Très faible |

**Verdict** : MySQL retenu pour la démonstration de compétences infrastructure (Docker, backup, monitoring). Les blueprints restent côté client (fichiers) pour la résilience.

#### SWEP vs STOOL

| Critère | SWEP | STOOL |
|---------|------|-------|
| Attribution par job | ✅ Automatique (DarkRP) | ❌ Accessible à tous |
| UI personnalisée | ✅ Totale liberté | ⚠️ Limitée au panel STOOL |
| Ergonomie | ✅ Clic gauche/droit/R | ⚠️ Panel + clic |
| Viewmodel | ✅ Modèle 3D personnalisable | ❌ Toolgun standard |

**Verdict** : SWEP retenu pour l'attribution automatique par job et l'ergonomie supérieure.

#### Version Workshop vs Dev

| Aspect | Workshop | Dev |
|--------|----------|-----|
| **Cible** | Tout serveur DarkRP | Infrastructure de développement |
| **MySQL** | ❌ Non requis | ✅ Logging + analytics |
| **sv_admin_setup** | ❌ Non inclus | ✅ Setup automatique |
| **Dépendances** | Aucune (standalone) | MySQL + configuration |
| **Installation** | 1 clic Workshop | Docker Compose |

**Justification** : Deux versions permettent de couvrir deux cas d'usage distincts sans compromis.

### 6.3 Architecture réseau

```
Internet
    │
    ▼
┌─────────────────────────────────────────┐
│  VPS Hostinger — 76.13.43.180           │
│                                          │
│  UFW Firewall                            │
│  ├── Port 22/tcp    → SSH (clé)          │
│  ├── Port 27015/udp → GMod (joueurs)     │
│  ├── Port 27015/tcp → GMod (RCON)        │
│  └── Port 3306/tcp  → MySQL (local only) │
│                                          │
│  Docker Network (bridge)                 │
│  ┌──────────────┐  ┌──────────────┐      │
│  │  gmod-server  │  │  gmod-mysql  │      │
│  │  :27015      │──│  :3306       │      │
│  │  3Go/2CPU    │  │  512Mo/0.5CPU│      │
│  └──────────────┘  └──────────────┘      │
│                                          │
│  Volumes                                 │
│  ├── gmod-server-data (named)            │
│  ├── ./addons (bind mount)               │
│  ├── ./gamemodes (bind mount)            │
│  ├── ./server-config (bind mount)        │
│  └── ./mysql-data (bind mount)           │
└─────────────────────────────────────────┘
```

### 6.4 Protocoles réseau

| Protocole | Port | Usage | Sécurité |
|-----------|------|-------|----------|
| SSH | 22/tcp | Administration VPS | Clé RSA, fail2ban |
| UDP Source Engine | 27015/udp | Trafic de jeu | Aucun (protocole Valve) |
| TCP RCON | 27015/tcp | Administration distante serveur | Mot de passe fort |
| MySQL | 3306/tcp | Communication inter-conteneurs | Réseau Docker interne uniquement |
| HTTPS | 443 | Steam Workshop API, GitHub | TLS natif |

---

## 7. Analyse des risques et opportunités — C24.1

### 7.1 Matrice des risques

| ID | Risque | Probabilité | Impact | Gravité | Mitigation |
|----|--------|-------------|--------|---------|------------|
| **R1** | Corruption base MySQL | Faible | Élevé | 🟠 | Dumps horaires, restauration testée |
| **R2** | Panne VPS Hostinger | Très faible | Critique | 🟠 | Code sur GitHub, backup local, procédure DR |
| **R3** | Vulnérabilité RCON | Moyenne | Élevé | 🔴 | Mot de passe fort, port filtré, rotation prévue |
| **R4** | Exploit via net messages | Moyenne | Élevé | 🔴 | Validation serveur systématique, rate limiting |
| **R5** | Image Docker obsolète | Moyenne | Moyen | 🟡 | Tags versionnés, rebuild possible |
| **R6** | Dépassement ressources | Faible | Moyen | 🟡 | Limites Docker (memory, cpus), monitoring |
| **R7** | Perte accidentelle de fichiers | Faible | Élevé | 🟠 | Git + backups quotidiens + `chattr +i` mensuels |
| **R8** | Incompatibilité mise à jour GMod | Faible | Élevé | 🟠 | Image Docker figée, test avant migration |
| **R9** | Suppression Workshop Valve | Très faible | Moyen | 🟡 | Code source complet sur GitHub |
| **R10** | Échec des backups silencieux | Moyenne | Élevé | 🔴 | Checksums, test_restore.sh mensuel, logs |

### 7.2 Matrice probabilité / impact

```
Impact ↑
Critique │        R2          │
         │                    │
Élevé    │  R7 R8    R1       │  R3 R4 R10
         │                    │
Moyen    │  R9       R5 R6    │
         │                    │
Faible   │                    │
         └────────────────────┘──→ Probabilité
           Très faible  Faible  Moyenne  Élevée
```

### 7.3 Opportunités

| ID | Opportunité | Bénéfice | Faisabilité | Priorité |
|----|------------|----------|-------------|----------|
| **O1** | Publication Workshop réussie | Visibilité communautaire, feedback réel | ✅ Réalisé | — |
| **O2** | Intégration CI/CD (GitHub Actions) | Automatisation tests + déploiement | 🟡 Moyenne | Future |
| **O3** | Monitoring Prometheus + Grafana | Dashboards temps réel, alertes | 🟡 Moyenne | Future |
| **O4** | Réplication MySQL | RPO quasi-nul | 🔴 Coût serveur | Future |
| **O5** | Partage de blueprints entre joueurs | Fonctionnalité communautaire | 🟢 Faisable | Future v3.0 |
| **O6** | Support multi-serveurs | Scalabilité | 🔴 Complexité | Hors scope |
| **O7** | Panel web d'administration | Gestion sans RCON | 🟡 Moyenne | Future |

### 7.4 Plan de traitement des risques

| Risque | Stratégie | Action | Responsable | Délai |
|--------|-----------|--------|-------------|-------|
| R3 (RCON) | Réduction | Rotation mot de passe trimestrielle | Admin | Continu |
| R4 (Net exploits) | Réduction | Audit code + rate limiting | Dev | Fait |
| R10 (Backup silencieux) | Détection | Script test_restore.sh + alertes | Admin | Mensuel |
| R1 (MySQL) | Transfert | Dumps horaires + tests | Auto (cron) | Continu |
| R2 (Panne VPS) | Acceptation | Procédure DR documentée | Admin | Fait |

---

## 8. Planning et livrables

### 8.1 Macro-planning

| Étape | Contenu | Durée estimée | Statut |
|-------|---------|---------------|--------|
| **1** | Setup VPS + Docker + DarkRP | 2-3 jours | ✅ |
| **2** | MySQL + intégration | 1-2 jours | ✅ |
| **3** | Addon v1.0 — STool + entités | 2-3 jours | ✅ |
| **4** | Tests et corrections | 1 jour | ✅ |
| **5** | Addon v2.0 — Refonte SWEP | 2-3 jours | ✅ |
| **6** | Addon v2.1 — UI Derma + AD2 | 2 jours | ✅ |
| **7** | Addon v2.2 — Véhicules | 1-2 jours | ✅ |
| **8** | Publication Workshop | 1 jour | ✅ |
| **9-12** | Documentation + rendus | 3-5 jours | 🔄 |

### 8.2 Livrables

| Livrable | Format | Localisation | Statut |
|----------|--------|-------------|--------|
| Addon Workshop | GMA (Steam) | [Workshop #3664157203](https://steamcommunity.com/sharedfiles/filedetails/?id=3664157203) | ✅ |
| Addon Dev | Lua source | `addon/rp_construction_system_dev/` | ✅ |
| Addon Workshop source | Lua source | `addon/rp_construction_system_workshop/` | ✅ |
| Infrastructure Docker | YAML + scripts | `docker/` | ✅ |
| DAT | Markdown | `rendu/dat/README.md` | ✅ |
| Plan de sauvegarde | Markdown | `rendu/backup/` | ✅ |
| Amélioration architecture | Markdown | `rendu/amelioration/` | ✅ |
| Cahier des charges | Markdown | `rendu/cdc/README.md` (ce document) | ✅ |
| Guides (installation, utilisateur) | Markdown | `docs/` | ✅ |
| Journal de développement | Markdown | `docs/JOURNAL_DEV.md` | ✅ |
| Documentation architecture | Markdown | `docs/ARCHITECTURE.md` | ✅ |

---

## 9. Critères de recette

### 9.1 Recette fonctionnelle — Addon

| ID | Test | Procédure | Résultat attendu | Validé |
|----|------|-----------|-------------------|--------|
| **RF01** | Sélection de props | Clic gauche SWEP sur prop | Prop surligné, compteur +1 | ✅ |
| **RF02** | Sauvegarde blueprint | Menu → Sauvegarder → Nommer | Fichier .dat créé localement | ✅ |
| **RF03** | Chargement blueprint | Menu → Charger blueprint | Fantômes apparaissent, transparents | ✅ |
| **RF04** | Matérialisation (grosse caisse) | Porter caisse vers fantôme | Fantôme → prop solide, caisse consommée | ✅ |
| **RF05** | Matérialisation (petite caisse) | Porter petite caisse vers fantôme | Idem RF04 avec petite caisse | ✅ |
| **RF06** | Véhicule dans blueprint | Sélectionner véhicule + sauvegarder | Véhicule inclus dans blueprint | ✅ |
| **RF07** | Matérialisation véhicule | R sur fantôme véhicule | Véhicule spawn, fonctionnel | ✅ |
| **RF08** | Import AdvDupe2 | Menu → Importer AD2 | Blueprint créé depuis fichier .txt | ✅ |
| **RF09** | Suppression blueprint | Menu → Supprimer | Fichier supprimé, liste mise à jour | ✅ |
| **RF10** | Attribution job | Devenir Constructeur | SWEP dans l'inventaire | ✅ |

### 9.2 Recette infrastructure

| ID | Test | Procédure | Résultat attendu | Validé |
|----|------|-----------|-------------------|--------|
| **RI01** | Docker Compose up | `docker compose up -d` | 2 services running | ✅ |
| **RI02** | Connexion joueur | Connexion Steam à 76.13.43.180:27015 | Map chargée, DarkRP fonctionnel | ✅ |
| **RI03** | MySQL accessible | `docker exec gmod-mysql mysql -u...` | Connexion réussie | ✅ |
| **RI04** | Backup automatique | Attendre exécution cron | Fichier backup créé | ✅ |
| **RI05** | Restauration MySQL | Exécuter restore_mysql.sh | Données restaurées | ✅ |
| **RI06** | Limites ressources | `docker stats` | GMod < 3Go, MySQL < 512Mo | ✅ |

### 9.3 Recette sécurité

| ID | Test | Procédure | Résultat attendu | Validé |
|----|------|-----------|-------------------|--------|
| **RS01** | SSH par mot de passe | `ssh root@IP` (password) | Connexion refusée | ✅ |
| **RS02** | Port scan | `nmap 76.13.43.180` | Seuls 22, 27015 ouverts | ✅ |
| **RS03** | Net message invalide | Envoi net message sans être Constructeur | Requête rejetée côté serveur | ✅ |
| **RS04** | Intégrité backup | `sha256sum -c checksums.sha256` | Tous les checksums valides | ✅ |

---

## Annexes

### A. Glossaire

| Terme | Définition |
|-------|-----------|
| **Blueprint** | Sauvegarde d'une construction (positions, modèles, angles des props) |
| **Fantôme (Ghost)** | Entité transparente représentant un prop à matérialiser |
| **SWEP** | Scripted Weapon — arme programmée en Lua pour GMod |
| **DarkRP** | Gamemode de roleplay pour Garry's Mod |
| **Prop** | Objet 3D physique dans le monde du jeu |
| **Net message** | Message réseau Lua entre client et serveur GMod |
| **GMA** | Garry's Mod Addon — format d'archive pour le Workshop |
| **RPO** | Recovery Point Objective — perte de données maximale acceptable |
| **RTO** | Recovery Time Objective — temps de remise en service |
| **CPPI** | Common Prop Protection Interface — API de propriété des props |
| **AD2** | Advanced Duplicator 2 — addon de sauvegarde/restauration de constructions |

### B. Références

- [Documentation DarkRP](https://darkrp.miraheze.org/wiki/Main_Page)
- [Wiki Garry's Mod (GLua)](https://wiki.facepunch.com/gmod/)
- [Docker Documentation](https://docs.docker.com/)
- [MySQL 8.0 Reference](https://dev.mysql.com/doc/refman/8.0/en/)
- [ANSSI — Guide d'hygiène informatique](https://www.ssi.gouv.fr/guide/guide-dhygiene-informatique/)
- [ISO 22301 — Continuité d'activité](https://www.iso.org/standard/75106.html)
- [Steam Workshop Documentation](https://partner.steamgames.com/doc/features/workshop)

### C. Arborescence du projet

```
Projet_fil_rouge/
├── addon/
│   ├── rp_construction_system_dev/        ← Version développement (MySQL)
│   └── rp_construction_system_workshop/   ← Version Workshop (standalone)
├── docker/
│   ├── addons/                            ← Bind mount → conteneur
│   │   ├── rp_construction_system/        ← Copie de travail addon
│   │   ├── darkrpmodification/            ← Config DarkRP
│   │   ├── advdupe2/                      ← AdvDupe2 extrait
│   │   ├── stand_pose_tool/               ← Stand Pose Tool
│   │   └── bodygroup_wardrobe/            ← Bodygroup Wardrobe
│   ├── gamemodes/darkrp/                  ← DarkRP gamemode
│   ├── server-config/server.cfg           ← Configuration serveur
│   ├── mysql-data/                        ← Données MySQL persistantes
│   ├── mysql-init/                        ← Scripts d'initialisation
│   └── docker-compose.yml                 ← Orchestration
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DOCKER_IMAGES.md
│   ├── GUIDE_INSTALLATION.md
│   ├── GUIDE_UTILISATEUR.md
│   └── JOURNAL_DEV.md
├── rendu/
│   ├── dat/README.md                      ← Grille n°1
│   ├── amelioration/                      ← Grille n°3
│   ├── backup/                            ← Grille n°4
│   └── cdc/README.md                      ← Grille n°5 (ce document)
└── README.md                              ← Présentation Projet Fil Rouge
```
