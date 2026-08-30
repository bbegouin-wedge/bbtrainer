# 12 — Le déterminisme du noyau

## Le constat

Le noyau Rust **n'est pas déterministe**, et ça ne vient d'aucune dépendance
externe. Trois exécutions du même code, sur la même grille :

```
ORDRE=1,0 3,0 4,0 6,0 5,0 7,0 2,0 0,0
ORDRE=6,0 1,0 7,0 0,0 3,0 5,0 4,0 2,0
ORDRE=2,0 1,0 0,0 3,0 7,0 6,0 4,0 5,0
```

`Grid::occupied_tiles()` rend ses cases dans un ordre différent à chaque
processus, parce que `HashMap` de la bibliothèque standard utilise un hachage
**semé au hasard au démarrage**. C'est une protection contre les attaques par
collision, et c'est exactement ce dont un noyau rejouable ne veut pas.

## Pourquoi ça compte, alors que rien ne casse aujourd'hui

Personne ne dépend de cet ordre pour l'instant — le `Dictionary` GDScript avait
la même propriété. Mais `docs/noyau-et-apprenant.html` fonde toute
l'infrastructure d'entraînement sur la reproductibilité : *« dés semés »*,
*« exécution reproductible à graine fixée »*, et un journal qui écrit
*« graine + commandes »* et doit *« suffire à rejouer toute partie »*.

Le jour où l'on rejoue une partie depuis son journal et qu'elle diverge, la
cause sera invisible : aucun test ne rougira, aucune erreur ne sera levée. Deux
exécutions donneront simplement des résultats différents.

## Le correctif

`BTreeMap` au lieu de `HashMap` — l'ordre devient celui des clés, stable par
construction. Coût : `Tile` et `UnitId` doivent dériver `Ord`, et les recherches
passent de O(1) à O(log n) sur des grilles de 390 cases, ce qui ne se mesure
pas.

L'alternative — trier en sortie — laisse le piège en place pour la prochaine
structure qu'on ajoutera.

## La règle à écrire dans CLAUDE.md

Ce que le noyau a le droit de dépendre, et selon quels critères :

| Critère | Ce qu'il écarte |
|---|---|
| **Pureté** | aucune E/S, aucune horloge, aucun fil |
| **Déterminisme** | tout ce qui varie d'une exécution à l'autre à entrée égale |
| **Portabilité** | le noyau se compile dans la GDExtension, la boucle d'entraînement, et peut-être un serveur |

À cette aune, `nutype` et `serde` passent — du calcul pur. `serde_json` aussi,
c'est un format et non un accès disque. `rand` sera **nécessaire** pour les dés,
mais avec un générateur semé et épinglé (`ChaCha`), jamais celui du système.
Sont écartés le disque, l'horloge, les fils, et `burn` que le document nomme.

**Et la leçon du constat** : le danger ne vient pas d'abord des dépendances,
mais de la bibliothèque standard. Une règle qui ne parlerait que des crates
aurait laissé passer celui-ci.

## Questions ouvertes

- **Comment vérifier le déterminisme automatiquement ?** Un test qui compare
  deux exécutions dans le même processus ne verrait rien — le hachage n'est semé
  qu'une fois par processus. Il faut lancer deux processus et comparer, ou
  interdire `HashMap` dans le noyau par `check-arch`.
- **`check-arch` doit-il refuser `HashMap` ?** C'est le pendant de l'interdit
  sur `FileAccess` : un contrôle mécanique plutôt qu'une intention.

## Terminé quand

- deux exécutions du même scénario rendent la même sortie, prouvé par une
  vérification automatique ;
- la règle des dépendances admissibles est écrite dans `CLAUDE.md` ;
- `cargo test` couvre toujours 100 % du noyau.
