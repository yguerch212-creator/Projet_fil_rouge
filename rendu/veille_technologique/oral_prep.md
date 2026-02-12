# 🎤 Préparation Soutenance Orale — Veille Technologique

> ⚠️ **FICHIER PERSONNEL — NON LIVRABLE**
> Ce fichier t'aide à préparer les 10 min de présentation + 10 min de questions.

---

## 🎯 Rappel : ce que le jury évalue

| Critère | Ce qu'ils veulent voir | Comment y répondre |
|---------|----------------------|-------------------|
| **C30.1** | Fluidité, argumentation, vocabulaire spécialisé EN | Parler naturellement, pas lire. Utiliser le jargon cybersec. |
| **C30.2** | Qualité des supports (slides) | Slides visuelles, peu de texte, schémas |
| **C31.1** | Mise en perspective des apports | "Voilà ce que cette veille m'a appris et comment ça change ma vision" |
| **C31.2** | Recommandations et hypothèses d'application | Les 10 recommandations du rapport |

---

## 📊 Plan des slides (10 min = ~12 slides max)

### Slide 1 — Titre
```
Zero Trust Client Architecture 
and Addon Security in Multiplayer Games

[Ton nom] — B3 Cybersecurity, Efrei Bordeaux
February 2026
```

### Slide 2 — Problem Statement (1 min)
```
"How can game servers protect themselves against malicious addons?"
"Why should we NEVER trust the client?"

→ Image: Steam Workshop with millions of addons
→ Stat: 500,000+ GMod Workshop addons, 10+ known backdoor families
```

**Ce que tu dis** : "Today I'm going to talk about a critical security issue in online gaming. When you run a game server with community addons, you're essentially executing untrusted third-party code. This is a supply chain attack waiting to happen."

### Slide 3 — Real-world Incidents (1.5 min)
```
Timeline of attacks:
- 2014: GMod Workshop backdoors documented (will.io)
- 2018: Lua execution exploit patched by Valve
- 2022: KVacDoor widespread backdoor discovered
- 2023: Downfall mod malware on Steam (gHacks)
- 2025: People Playground Workshop shut down entirely

→ "This is not theoretical. This happens."
```

**Ce que tu dis** : "These are not hypothetical scenarios. In 2025, People Playground had to completely disable their Workshop because a malicious mod was destroying other players' content. In GMod, the KVacDoor backdoor allowed attackers to remotely execute code on thousands of servers."

### Slide 4 — Anatomy of a Backdoor (1.5 min)
```
Diagram showing:
1. Obfuscated code (string.char encoding)
2. http.Fetch to external server
3. RunString(response) 
4. Full server compromise

→ Real code snippet (sanitized)
```

**Ce que tu dis** : "Here's how a typical backdoor works. The addon looks normal, but hidden in the code is an obfuscated call. It contacts an external server, downloads Lua code, and runs it with full privileges. The attacker now controls your server."

### Slide 5 — Zero Trust Architecture (1.5 min)
```
NIST SP 800-207 — 7 tenets

"Never trust, always verify"

Traditional security:  Inside = Trusted ❌
Zero Trust:           Nothing is trusted ✅

→ Diagram: Traditional perimeter vs Zero Trust
```

**Ce que tu dis** : "NIST published SP 800-207 defining Zero Trust Architecture. The core idea is simple: never trust anything by default. In traditional security, being inside the network means you're trusted. In Zero Trust, every request is verified independently. This maps perfectly to game server security."

### Slide 6 — Zero Trust = Server Authoritative (1 min)
```
Client says: "I selected prop #42"
Server checks:
  ✓ IsValid(prop)?
  ✓ IsOwner(player, prop)?
  ✓ IsAllowedJob(player)?
  ✓ RateLimit OK?
  ✓ → Only THEN execute

"The client is in the hands of the enemy"
— Gabriel Gambetta
```

**Ce que tu dis** : "In game development, Zero Trust translates to server-authoritative architecture. The golden rule is: the client is in the hands of the enemy. Every single message from the client must be validated server-side. No exceptions."

### Slide 7 — Defense in Depth (1 min)
```
5 layers:
1. Network (Firewall, Docker isolation)
2. Protocol (Rate limiting, message validation)
3. Application (Input validation, whitelists)
4. Infrastructure (Containers, resource limits)
5. Monitoring (Logging, audit trail)
```

**Ce que tu dis** : "Zero Trust isn't a single measure, it's defense in depth. Five layers of protection, from network-level firewalls to application-level input validation to infrastructure-level containerization."

### Slide 8 — My Project: RP Construction System (1 min)
```
Real implementation of Zero Trust:
- 18 net messages, ALL validated server-side
- Entity whitelist + blacklist
- Rate limiting (60 req/min)
- Prepared statements (SQL injection prevention)
- Docker containerization
- No RunString, no http.Fetch for code

Published on Steam Workshop (ID 3664157203)
```

**Ce que tu dis** : "I applied all of these principles in my own project. The RP Construction System is a GMod addon published on the Workshop. Every single client action goes through server-side validation. There's no RunString, no external code fetching, and the entire infrastructure runs in Docker containers."

### Slide 9 — Hypotheses & Analysis (1 min)
```
H1: Most compromises come from INSIDE (trusted addons), not outside
H2: Server-side validation > client-side anti-cheat  
H3: Containerization limits blast radius significantly

→ Comparison table: Without ZT vs With ZT
```

**Ce que tu dis** : "Three key hypotheses from my research. First, the biggest threat is from the code you trust — your own addons. Second, server-side validation is fundamentally stronger than client-side anti-cheat. Third, Docker containers don't prevent compromise, but they contain it."

### Slide 10 — Dissemination Strategy (0.5 min)
```
Who    → Dev team, admins, community
How    → Wiki, Discord, email digest
When   → Critical: immediate / Monthly digest / Quarterly report
```

### Slide 11 — Top 5 Recommendations (1 min)
```
1. NEVER use RunString() with external data
2. Server-side validation for ALL client messages
3. Run servers in containers with resource limits
4. Audit addons before installation (no auto-update in prod)
5. Establish regular security watch cycle
```

### Slide 12 — Conclusion
```
"In gaming, as in enterprise security:
 Never trust. Always verify.
 The client is NOT your friend."

Questions?
```

---

## ❓ Questions probables du jury + réponses préparées

### Q1: "Why did you choose this topic?"
> "Because I built a GMod addon as my capstone project and discovered firsthand that the Workshop ecosystem has serious security issues. I wanted to understand how Zero Trust principles apply to game server architecture, and I found a direct parallel between NIST 800-207 and server-authoritative game design."

### Q2: "Can you give a concrete example of a backdoor?"
> "Yes. The KVacDoor backdoor was embedded in popular addons on the GMod Workshop. It used string.char encoding to hide an HTTP call to kvac.cz. When the server loaded the addon, it downloaded and executed arbitrary Lua code, giving the attacker full control — they could run commands, access files, even use the server as a DDoS relay."

### Q3: "How does your project specifically implement Zero Trust?"
> "Every net message — there are 18 of them — is validated server-side. When a client says 'select this prop,' the server checks: is the prop valid? Does the player own it? Are they the right job? Is the rate limit OK? Only then does it execute. The client never has authority over game state."

### Q4: "What are the limitations of your approach?"
> "Three main limitations. First, server-authoritative adds latency — the client must wait for server confirmation. Second, it increases server CPU load because all validation happens server-side. Third, it doesn't protect against vulnerabilities in the game engine itself — if Source Engine has a buffer overflow, server-side Lua validation can't help."

### Q5: "How do you ensure source reliability?"
> "I used a multi-tier approach. Tier 1: institutional sources like NIST and ANSSI. Tier 2: established technical references like Gabriel Gambetta and the Valve Developer Wiki. Tier 3: community sources like Stack Overflow and Reddit, cross-referenced with multiple reports. I never relied on a single source for any claim."

### Q6: "What tools do you recommend for ongoing monitoring?"
> "For addon security: Backdoor Shield on GitHub, which detects known patterns. For general security watch: Feedly for RSS feeds, NIST NVD for vulnerabilities, and GitHub Advisory Database. For the project specifically: Docker healthchecks, console logging, and MySQL audit trails."

### Q7: "How would you implement your recommendations in a professional environment?"
> "I'd start with the critical ones: ban RunString in code reviews, enforce server-side validation as a coding standard, and containerize all game servers. Then establish a monthly security digest for the team and quarterly full reviews. The key is making security a continuous process, not a one-time audit."

### Q8: "You mention German sources — can you elaborate?"
> "Yes, the BSI — Bundesamt für Sicherheit in der Informationstechnik — publishes the IT-Grundschutz Kompendium, which is the German equivalent of ANSSI guidelines. It covers server hardening and network security that applies directly to game server infrastructure. Using multilingual sources ensures a broader perspective and reduces bias from any single country's approach."

### Q9: "What surprised you most in your research?"
> "Two things. First, how widespread GMod backdoors actually are — there are entire GitHub repositories cataloging exploit scripts, and multiple dedicated detection tools exist just for GMod. Second, how perfectly NIST's Zero Trust framework maps onto game architecture. The seven tenets of SP 800-207 could have been written specifically for multiplayer game servers."

### Q10: "If you had more time, what would you research next?"
> "Automated static analysis of Lua addons — essentially building a CI/CD pipeline that scans Workshop addons for suspicious patterns before deployment. Also, runtime behavioral analysis: monitoring what addons actually do at runtime versus what they claim to do, similar to how sandboxes analyze malware."

---

## 🗣️ Vocabulaire technique EN à maîtriser

| Terme | Prononciation | Définition rapide |
|-------|--------------|-------------------|
| Zero Trust Architecture | /zɪəroʊ trʌst/ | Security model: never trust, always verify |
| Server-authoritative | /sɜːrvər ɔːˈθɒrɪtətɪv/ | Server controls all game state |
| Supply chain attack | /səˈplaɪ tʃeɪn/ | Compromising upstream dependencies |
| Backdoor | /bækdɔːr/ | Hidden unauthorized access method |
| RunString | — | GMod function that executes arbitrary Lua code |
| Rate limiting | /reɪt ˈlɪmɪtɪŋ/ | Restricting number of requests per time period |
| Prepared statement | — | Pre-compiled SQL query preventing injection |
| Blast radius | /blɑːst ˈreɪdiəs/ | Extent of damage from a security breach |
| Defense in depth | — | Multiple overlapping security layers |
| NIST SP 800-207 | /nɪst/ | US standard defining Zero Trust Architecture |
| Obfuscation | /ɒbfʌsˈkeɪʃən/ | Hiding code's true purpose |
| Containerization | /kənˌteɪnəraɪˈzeɪʃən/ | Running apps in isolated containers |
| Whitelisting | — | Only allowing explicitly approved items |
| Input validation | — | Checking all data before processing |

---

## ⏱️ Timing

| Section | Durée | Cumulé |
|---------|-------|--------|
| Intro + Problem | 1 min | 1 min |
| Real incidents | 1.5 min | 2.5 min |
| Backdoor anatomy | 1.5 min | 4 min |
| Zero Trust (NIST) | 1.5 min | 5.5 min |
| Server authoritative | 1 min | 6.5 min |
| Defense in depth | 1 min | 7.5 min |
| My project | 1 min | 8.5 min |
| Hypotheses | 1 min | 9.5 min |
| Recommendations + conclusion | 0.5 min | 10 min |

---

## ✅ Checklist avant le jour J

- [ ] Slides finalisées (Canva ou PowerPoint)
- [ ] Répétition chronométrée ×3 minimum
- [ ] Backup des slides (USB + cloud)
- [ ] Vocabulaire technique fluide
- [ ] Réponses aux 10 questions préparées
- [ ] Tenue correcte
- [ ] Arriver 15 min en avance
