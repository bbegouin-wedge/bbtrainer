# Reprise de session — 30 août 2026

Écrit pour reprendre le chantier sur une autre machine. **À supprimer une fois
lu** : ce fichier périme vite, et rien ne le vérifie.

Tout ce qui compte est déjà dans le dépôt — cartes, documents, messages de
commit. Ce fichier ne les répète pas, il dit **où on en est** et **ce qui vient**.

---

## Où lire, dans l'ordre

| | |
|---|---|
| `CLAUDE.md` règles 13 à 15 | les vérifications, et le workflow obligatoire du noyau |
| `.claude/workflows/carte-du-noyau.md` | les huit phases, leurs trois gués |
| `docs/noyau-et-apprenant.html` | l'infrastructure d'auto-jeu et le rôle du noyau dedans |
| `docs/domaine-de-blood-bowl.html` | ce que le livre dit de la structure — **lire avant toute carte de règles** |
| `docs/noyau-interruptible.html` | l'automate à pile, les points d'ancrage, le pipeline de jet |
| `kanban/done/13-*.md` et `14-*.md` | ce que les deux dernières cartes ont appris |

Le livre de règles est dans `references/lrb.pdf` — **non versionné** (11 Mio,
ouvrage tiers). Il faut le remettre à la main sur la nouvelle machine, sinon la
phase 2 du workflow n'a plus de source.

## État à la reprise

- Branche `main`, 30 commits aujourd'hui, rien à pousser d'urgent.
- Noyau Rust : `app/core/kernel/src/{dice,game,grid}.rs`, 1 263 lignes tests
  compris, **couverture 100 %**, 70 mutants sans survivant, empreinte identique
  sur deux processus.
- Les quatre vérifications passent : `make test-behaviour`, `make check-arch`,
  `make check-integrity`, `make check-mutations`.
- Cartes closes : 1 à 14. Prêtes : **24** puis **15**. Neuf à raffiner.

### Ce qui traîne dans l'arbre et qui n'est pas de la dernière session

`project.godot` modifié, `app/io/client/widgets/skill_badge/skill_badge.tscn` et
`kanban/to_be_refined/23-*.md` non suivis. Ils viennent d'un chantier parallèle —
ne pas les commiter sans savoir ce qu'ils sont.

## Ce qui vient, et pourquoi dans cet ordre

L'ordre du kanban n'est plus celui qu'on avait posé : les deux passes de
conception du 30 août l'ont bousculé.

1. **Corriger la carte 13.** Deux réserves de dés sont fausses : le `D3` doit
   consommer un `D6` (`jetez un D6 et divisez par deux, arrondi au supérieur`),
   et le `D12` n'existe pas — zéro occurrence dans le livre ; désigner un joueur
   au hasard se fait au `D16`. Supprimer les flux 0 et 4 ne touche aucune suite
   déjà tirée : c'était la raison d'être des numéros de flux explicites.
2. **Deux cartes à créer**, révélées par la passe et sans carte aujourd'hui :
   - le module `roll` — la machinerie de jet que le livre décrit une seule fois
     et que toutes les règles réutilisent. Elle précède toute carte qui jette un
     dé, donc la 15 ;
   - le module `machine` — l'automate à pile lui-même.
3. **Carte 24** — le déroulement d'un match. Déjà réécrite sur le livre.
4. **Carte 15** — le déplacement. La première à contenir de vraies règles.

## Les décisions à ne pas redécouvrir

Elles sont argumentées dans les documents ; en voici la liste courte, pour ne pas
les rouvrir par distraction.

- **La pile ne contient que des conséquences ; les intentions vivent dans
  `legal_commands()`.** C'est ce qui fait qu'un turnover n'a rien à tronquer.
- **Le mot `Phase` ne s'emploie nulle part dans le code** — il désigne autre
  chose dans le livre. Dire `Drive`.
- **Un type de résolution existe parce que quelque chose s'y accroche.** 26 des
  135 intitulés du livre sont chargés.
- **Un point d'ancrage est un moment nommé à l'intérieur d'une résolution**, et
  les compétences datent le leur dans leur texte.
- **Le noyau demande toujours** ; la configuration « s'applique d'office » vit
  chez le client, pour que le journal se rejoue quelle qu'elle soit.
- **`Dice` n'est pas `Clone`**, délibérément : c'est ce qui interdit à un déroulé
  du stratège de voir les dés du match.

## Les trous connus, non refermés

- **Les astérisques manquent à `app/io/persistence/skills_fr.json`.** Le livre
  marque ainsi une douzaine de compétences **obligatoires** (`CERVEAU LENT*`,
  `IVROGNE*`, `PRENDRE RACINE*`, `SAUVAGERIE ANIMALE*`…). L'information est
  perdue à l'extraction, et sans elle le noyau laissera décliner des traits qui
  ne se déclinent pas.
- **Trois divergences de vocabulaire** entre le livre et le JSON, dont les cinq
  résultats du dé de blocage. À trancher avant d'écrire des noms dans le code.
- **L'ordre d'application** quand plusieurs compétences se disputent un moment
  n'est sourcé nulle part. C'est le seul endroit du projet où l'on invente ; la
  forme retenue est un défaut déterministe surchargeable, chaque surcharge
  portant sa justification.

## Pièges rencontrés, à ne pas repayer

- **`git mv` d'un fichier déjà modifié n'indexe pas ses modifications.** Une
  carte est partie en `done/` avec son contenu d'avant ; seul le
  `git diff --cached --stat` de la règle 10 l'a rattrapée.
- **`cd X && …` en tête de commande** : si le répertoire courant est déjà `X`, le
  `cd` échoue et emporte la suite de la chaîne. Trois fois aujourd'hui.
- **`#[should_panic]` nu ne vérifie rien** — il est satisfait par la panique d'un
  `todo!()`. Toujours `expected = "…"`.
- **`cargo llvm-cov` peut désigner une ligne non couverte que le rapport détaillé
  ne montre nulle part** : chercher une queue divergente (`panic!` en fin de
  fonction), et réécrire en expression.

## Skills à invoquer

| Skill | Quand |
|---|---|
| `handoff` | en fin de session, pour refaire ce fichier |
| `grilling` | avant toute décision de conception structurante — les deux passes du 30 août en sont sorties |
| `domain-modeling` | si le vocabulaire du domaine doit être arbitré (les trois divergences ci-dessus) |

**Le workflow `carte-du-noyau` n'est pas un skill : il est automatique** pour
toute carte touchant `app/core/kernel/`, par la règle 15 de `CLAUDE.md`. Le lire
avant de commencer, et ne pas sauter ses trois gués.
