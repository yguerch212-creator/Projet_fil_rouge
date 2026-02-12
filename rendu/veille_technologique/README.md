# 🔍 Veille Technologique Multilingue — Notes de préparation

> ⚠️ **FICHIER PERSONNEL — NON LIVRABLE**
>
> Ce fichier sert de notes de préparation. Le livrable final sera un PDF en anglais (15-20 pages).

---

## 📅 Deadlines

- **1er avril 2026** : Livrable PDF sur Moodle (15-20 pages, anglais)
- **22-23 avril 2026** : Soutenance orale (10 min présentation + 10 min questions, anglais)

---

## 📋 Ce qui est demandé

### Rapport écrit (50% de la note)
- **Langue** : Anglais intégral
- **Format** : PDF unique, 15-20 pages hors annexes
- **Structure attendue** : Introduction → Contexte → Problématique → Développement → Solution → Évaluation → Conclusion
- **Sources** : Multilingues, vérifiables, datées
- **IA générative** : Usage autorisé mais doit être explicité (prompts, finalités, limites)

### Soutenance orale (50% de la note)
- **Durée** : 20 min (10 présentation + 10 questions)
- **Langue** : Anglais
- **Jury** : Professionnels du secteur
- **Support** : Slides de présentation
- **Évalué** : Problématique, hypothèses, outils de diffusion, fréquence, argumentation, recul critique

---

## 📊 Grille de notation (8 critères × 5 pts = /55 × 0.36 = /20)

| Critère | Intitulé | Ce qu'il faut montrer |
|---------|----------|-----------------------|
| **C28.1** | Sélection pertinente des sources et outils | Sources variées (EN, FR, DE, etc.), outils de veille (Feedly, Google Scholar, RSS, Reddit, HN), justifier chaque source |
| **C28.2** | Synthèse claire et contextualisée | Résumer les infos de manière structurée, les relier au contexte projet |
| **C29.1** | Structure, clarté et adaptation au public visé | Document bien structuré, anglais clair, adapté à une équipe technique |
| **C29.2** | Exploitation concrète des données dans un contexte projet | Montrer comment la veille s'applique concrètement à notre projet/infra |
| **C30.1** | Fluidité, argumentation et maîtrise du vocabulaire spécialisé | Anglais technique fluide, arguments solides, vocabulaire cybersécurité |
| **C30.2** | Qualité des supports de communication | Slides pro, schémas, tableaux comparatifs |
| **C31.1** | Mise en perspective des apports de la veille | Prise de recul, impact sur les décisions techniques |
| **C31.2** | Recommandations et hypothèses d'application | Proposer des actions concrètes basées sur la veille |

---

## 🎯 Choix du sujet

### Pistes possibles (à choisir)

1. **Container Security in Gaming Infrastructure** — Sécurisation des serveurs de jeux conteneurisés (Docker), attaques récentes, bonnes pratiques
2. **Zero Trust Architecture for Self-Hosted Game Servers** — Appliquer le Zero Trust à un serveur de jeu auto-hébergé
3. **The Evolution of Anti-Cheat in Multiplayer Games: From Server-Side Validation to AI-Based Detection** — Lien direct avec notre validation serveur des net messages
4. **Infrastructure as Code for Game Server Deployment** — Docker, Terraform, Ansible pour le déploiement de serveurs de jeu

> **Recommandation** : Sujet 1 ou 3 — lien direct avec le Projet Fil Rouge, assez de littérature disponible, angle cybersécurité B3.

---

## 📐 Structure type du rapport

```
1. Introduction (1 page)
   - Context: Game server hosting, containerization trend
   - Problem statement
   - Scope and objectives

2. Research Methodology (1-2 pages)
   - Sources selection (multilingual: EN, FR, + others)
   - Tools used (Feedly, Google Scholar, Reddit, HN, CVE databases...)
   - Collection and organization method
   - AI tools usage disclosure

3. State of the Art (4-5 pages)
   - Current landscape
   - Key technologies
   - Comparative analysis (tables)

4. Analysis & Hypotheses (4-5 pages)
   - Data analysis from collected sources
   - Hypothesis 1: ...
   - Hypothesis 2: ...
   - Hypothesis 3: ...
   - Comparative scenarios

5. Application to Project (2-3 pages)
   - How findings apply to our Docker/GMod infrastructure
   - Concrete improvements proposed
   - Implementation feasibility

6. Dissemination Strategy (1-2 pages)
   - Tools for sharing (wiki, Slack, email digest)
   - Recommended frequency
   - Target audience adaptation

7. Conclusion (1 page)
   - Key takeaways
   - Recommendations
   - Future work

Annexes
   - Full source list with dates
   - AI prompts used
   - Raw data/screenshots
```

---

## 🔧 Outils de veille à mentionner

| Outil | Usage | Gratuit |
|-------|-------|---------|
| Feedly | Agrégation RSS tech | Oui (limité) |
| Google Scholar | Articles académiques | Oui |
| NIST NVD / CVE | Vulnérabilités | Oui |
| Reddit (r/netsec, r/docker, r/gmod) | Communautés | Oui |
| Hacker News | Tech news | Oui |
| GitHub Advisory Database | Vulnérabilités code | Oui |
| ANSSI alerts | Veille sécu FR | Oui |
| arxiv.org | Papiers de recherche | Oui |
| Twitter/X (#infosec) | Veille temps réel | Oui |
| Notion / Obsidian | Organisation base de connaissances | Oui |

---

## 🗣️ Préparation orale

### Points clés à préparer
- [ ] Slides (10-12 max, visuelles, peu de texte)
- [ ] Script de présentation (~10 min, chronométré)
- [ ] Anticiper les questions du jury
- [ ] Vocabulaire technique en anglais (glossary card)
- [ ] Démonstration concrète de l'application au projet

### Questions probables du jury
- Why did you choose this topic?
- How does this relate to your project?
- What were the most surprising findings?
- How would you implement your recommendations?
- What are the limitations of your research?
- How do you ensure source reliability?
- What tools would you recommend for ongoing monitoring?

---

## 📝 TODO

- [ ] Choisir le sujet définitif
- [ ] Commencer la collecte de sources (min 15-20 sources variées)
- [ ] Créer la base de connaissances (Notion/Obsidian)
- [ ] Rédiger le rapport (anglais)
- [ ] Relire / corriger l'anglais
- [ ] Préparer les slides
- [ ] Répéter la soutenance
- [ ] Exporter en PDF final
- [ ] Upload sur Moodle avant le 1er avril
