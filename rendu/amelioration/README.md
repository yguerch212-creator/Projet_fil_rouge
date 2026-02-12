# 📈 Compte-rendu d'amélioration de l'architecture — Projet Fil Rouge

> **Grille de notation n°3** — BC01 : Administrer et optimiser les systèmes d'exploitation et la virtualisation pour la sécurité et la performance
>
> **Objectif** : Analyser l'architecture existante et son PCA pour proposer des améliorations et des outils de monitoring adaptés.

---

## 📋 Table des matières

1. [Redondance, réplication et clustering](redondance.md) — C5 : Matrice de risques, PCA, solutions de continuité
2. [Monitoring et performances](monitoring.md) — C6 : Outil de monitoring, SLA, PRA, données supervisées
3. [Gestion des incidents](incidents.md) — C7 : Procédures, réduction des interruptions de service
4. [Automatisation](automatisation.md) — C8 : Scripts d'administration, argumentation technologique

---

## Contexte de l'architecture

### Infrastructure analysée

Le projet **RP Construction System** repose sur une infrastructure conteneurisée déployée sur un VPS Hostinger (16 Go RAM, Ubuntu 22.04) :

| Service | Technologie | Rôle | Ressources |
|---------|-------------|------|------------|
| Serveur de jeu | Garry's Mod via Docker (`ceifa/garrysmod`) | Héberge le serveur DarkRP + addon | 3 Go RAM, 2 CPUs |
| Base de données | MySQL 8.0 (Docker) | Logs, futur partage de blueprints | 512 Mo RAM, 0.5 CPU |
| Orchestration | Docker Compose v2 | Gestion des deux services | — |
| Addon | RP Construction System v2.2 | Code métier (Lua) | Bind mount |
| Versioning | Git + GitHub | Code source, config, documentation | — |

### Compétences validées

| Compétence | Domaine | Document |
|------------|---------|----------|
| **C5** | Redondance, réplication, clustering | [redondance.md](redondance.md) |
| **C6** | Surveillance et optimisation des performances | [monitoring.md](monitoring.md) |
| **C7** | Gestion des incidents informatiques | [incidents.md](incidents.md) |
| **C8** | Automatisation des tâches d'administration | [automatisation.md](automatisation.md) |

### Méthodologie

L'approche suivie s'inspire du cycle **PDCA** (Plan-Do-Check-Act) et de la norme **ISO 27001** pour la gestion de la sécurité :

1. **Plan** — Identifier les risques via une matrice, définir le PCA et les SLA
2. **Do** — Mettre en place les solutions (scripts, configurations, procédures)
3. **Check** — Vérifier l'efficacité via monitoring, métriques et tests
4. **Act** — Ajuster et documenter les retours d'expérience (post-mortem)
