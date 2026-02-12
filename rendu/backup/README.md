# 🔒 Plan de sauvegarde et restauration — Projet Fil Rouge

> **Grille de notation n°4** — BC03 : Élaborer et mettre en œuvre des stratégies de Cybersécurité pour la protection des données
>
> **Objectif** : Mise en place d'un plan de sauvegarde avec analyse et soutenance des choix techniques
>
> **Compétences validées** : C20, C21, C22

---

## 📋 Table des matières

1. [Plan de sauvegarde](backup.md) — C20 : Stratégie, politique, adéquation au SI et continuité d'activité
2. [Plan de restauration](restore.md) — C21 : Sécurité des données sauvegardées et tests de restauration
3. [Scénario de test complet](example.md) — Démonstration end-to-end avec preuves

---

## Contexte du système d'information

### Architecture du SI

Le projet **RP Construction System** repose sur une infrastructure conteneurisée déployée sur un VPS Hostinger :

| Composant | Technologie | Données critiques | Volume estimé |
|-----------|-------------|-------------------|---------------|
| Serveur de jeu | Garry's Mod (Docker) | Addons Lua, configuration serveur, maps | ~500 Mo |
| Base de données | MySQL 8.0 (Docker) | Logs de construction, données joueurs | ~50 Mo |
| Configuration | Docker Compose + fichiers cfg | docker-compose.yml, server.cfg, DarkRP config | ~2 Mo |
| Code source | Git + GitHub | Addon complet, documentation, rendus | ~5 Mo |
| Images Docker | Docker Engine | Images taguées (v1.0 → v2.2) | ~8 Go |

### Enjeux identifiés

| Enjeu | Impact | Priorité |
|-------|--------|----------|
| Perte de la base de données MySQL | Perte des logs de construction et données joueurs | 🔴 Critique |
| Corruption de l'addon Lua | Serveur non fonctionnel, blueprints perdus | 🔴 Critique |
| Perte de la configuration DarkRP | Jobs, entités, véhicules à reconfigurer manuellement | 🟠 Élevé |
| Perte des images Docker | Rebuild complet nécessaire (plusieurs heures) | 🟠 Élevé |
| Perte du docker-compose.yml | Orchestration à réécrire | 🟡 Moyen |

### Contraintes du SI

- **Budget** : VPS mutualisé, pas de serveur de backup dédié → stockage local + distant (GitHub)
- **Fenêtre de maintenance** : Serveur de dev, pas de contrainte horaire stricte
- **Réglementation** : Pas de données personnelles sensibles (pseudonymes Steam uniquement), mais bonnes pratiques RGPD appliquées
- **Disponibilité cible** : 95% (serveur de développement/test)

---

## Cartographie des compétences

| Critère | Intitulé | Document | Section |
|---------|----------|----------|---------|
| **C20.1** | Adéquation aux contraintes et enjeux du SI | [backup.md](backup.md) | §1-3 |
| **C20.2** | Conformité aux exigences de continuité d'activité | [backup.md](backup.md) | §4-5 |
| **C21.1** | Sécurité physique et logique des données sauvegardées | [restore.md](restore.md) | §1-2 |
| **C21.2** | Tests de restauration fonctionnels | [restore.md](restore.md) | §3-4 + [example.md](example.md) |
| **C22.1** | Clarté, rigueur et structure du propos | Ensemble du dossier | Structure, TdM, schémas |
| **C22.2** | Argumentation des choix techniques | [backup.md](backup.md) §6 + [restore.md](restore.md) §5 | Tableaux comparatifs |
| **C22.3** | Capacité à répondre aux questions du jury | Préparation orale | — |

---

## Méthodologie

Le plan suit la norme **ISO 22301** (Continuité d'activité) et s'inspire des bonnes pratiques **ANSSI** pour la sauvegarde des systèmes d'information :

1. **Identification** des actifs et classification par criticité
2. **Définition** de la politique de sauvegarde (RPO, RTO, rétention)
3. **Implémentation** des scripts et automatisations
4. **Vérification** par tests de restauration documentés
5. **Sécurisation** des sauvegardes (chiffrement, contrôle d'accès, intégrité)

---

## Synthèse des indicateurs

| Indicateur | Valeur cible | Justification |
|------------|-------------|---------------|
| **RPO** (Recovery Point Objective) | < 1 heure | Sauvegarde MySQL horaire + Git push régulier |
| **RTO** (Recovery Time Objective) | < 30 minutes | Scripts automatisés de restauration |
| **Rétention** | 7 jours glissants + 1 mensuelle | Équilibre espace disque / historique |
| **Fréquence backup MySQL** | Toutes les heures | Cron automatisé |
| **Fréquence backup fichiers** | Quotidien | Cron automatisé à 03h00 |
| **Stockage distant** | GitHub (code) + copie chiffrée locale | Règle 3-2-1 adaptée au budget |

---

*Chaque document ci-dessous détaille un aspect du plan et référence explicitement les critères de la grille.*
