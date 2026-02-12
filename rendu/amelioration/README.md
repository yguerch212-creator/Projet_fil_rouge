# 📈 Compte-rendu d'amélioration — Projet Fil Rouge

> **Grille de notation n°3** — Amélioration continue de l'infrastructure et du service

Ce document présente les axes d'amélioration mis en place et envisagés pour le projet RP Construction System, autour de quatre piliers : la redondance, le monitoring, la gestion d'incidents et l'automatisation.

---

## 📋 Table des matières

- [Contexte](#contexte)
- [Redondance](redondance.md) — Disponibilité et résilience de l'infrastructure
- [Monitoring](monitoring.md) — Supervision et alertes
- [Gestion d'incidents](incidents.md) — Procédures de réponse et retour d'expérience
- [Automatisation](automatisation.md) — Scripts, CI/CD et déploiement

---

## Contexte

### Infrastructure concernée

Le projet repose sur une infrastructure conteneurisée déployée sur un VPS Hostinger (16 Go RAM, Ubuntu) :

| Service | Technologie | Rôle | Ressources |
|---------|-------------|------|------------|
| Serveur de jeu | Garry's Mod (Docker) | Héberge le serveur DarkRP + addon | 3 Go RAM, 2 CPUs |
| Base de données | MySQL 8.0 (Docker) | Logs, futur partage de blueprints | 512 Mo RAM, 0.5 CPU |
| Orchestration | Docker Compose | Gestion des deux services | — |
| Addon | RP Construction System v2.2 | Code métier (Lua) | Bind mount |

### Enjeux

En tant que projet B3 Cybersécurité, l'amélioration continue de cette infrastructure touche directement aux compétences suivantes :

- **Disponibilité** : Assurer que le serveur de jeu reste accessible pour les joueurs
- **Intégrité** : Protéger les données (blueprints, logs, configuration) contre la corruption ou la perte
- **Traçabilité** : Pouvoir diagnostiquer les problèmes et retracer les actions
- **Automatisation** : Réduire les interventions manuelles et les erreurs humaines

### Méthodologie

L'approche suivie s'inspire du cycle PDCA (Plan-Do-Check-Act) :

1. **Plan** — Identifier les risques et les axes d'amélioration
2. **Do** — Mettre en place les solutions (scripts, configurations, procédures)
3. **Check** — Vérifier l'efficacité via monitoring et tests
4. **Act** — Ajuster et documenter les retours d'expérience

Chaque sous-document détaille les mesures en place, les améliorations réalisées au fil du projet, et les perspectives d'évolution.
