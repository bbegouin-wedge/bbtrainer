# Workflow « Carte du noyau »

Ce workflow gouverne toute carte qui touche `app/core/kernel/`. Il est
**automatique**, pas activé à la demande : le noyau est la seule partie du
projet dont une erreur ne se voit ni à l'écran, ni au chargement, ni dans un
diff — elle se voit une saison plus tard, dans une partie qui ne se rejoue pas.

Il ne s'applique pas au reste : `app/io/`, l'outillage, les corrections
d'affichage suivent la règle 3 de `CLAUDE.md`, plus légère.

**Il remplace la règle 3 pour les cartes concernées** — sa phase 1 en est une
version plus complète.

---

## Vue d'ensemble

| | Phase | Ce qu'elle produit | Gué |
|---|---|---|---|
| 1 | Le contexte et l'objectif | Le rappel de la carte et de ce qui la contraint | |
| 2 | Les règles métier | Une liste où chaque règle cite sa source | **validation** |
| 3 | La conception | Les types et les signatures, corps `todo!()` | **validation** |
| 4 | Les tests | Des tests qui échouent, et qu'on a vus échouer | |
| 5 | L'implémentation | Le vert, et rien de plus | |
| 6 | Les vérifications | Quatre commandes, toutes vertes | |
| 7 | Consigner | Ce qu'on a appris, écrit dans la carte | |
| 8 | Clore | Le commit, la carte en `done/` | **validation** |

Trois gués seulement. Entre eux, on avance sans demander.

---

## Phase 1 — Le contexte et l'objectif

**Entrée** : la carte.

Rappeler trois choses, dans cet ordre :

1. **Ce que la carte demande**, en quelques lignes — pas une paraphrase de son
   fichier, l'intention derrière.
2. **Ce que le noyau contient déjà** qui la concerne : les types existants
   qu'elle va toucher, ce qui est déjà couvert.
3. **Les cartes amont qui la contraignent**, avec ce qu'elles ont décidé. Une
   décision prise trois cartes plus tôt et oubliée ici est la manière la plus
   sûre de produire un noyau incohérent.

Pas de gué : c'est un rappel, pas un livrable.

---

## Phase 2 — Les règles métier, sourcées

**Sortie** : une liste des règles que le code devra satisfaire.

**Chaque règle cite sa source.** La section du livre de règles Blood Bowl 2025,
ou le champ de `data/*.json` d'où elle sort.

Ce n'est pas du zèle bibliographique. Les règles de Blood Bowl ne se déduisent
pas : elles se lisent. Une règle écrite de mémoire — par l'un ou l'autre — a
toutes les chances d'être *plausible* et fausse, et c'est le pire cas :

- la couverture ne la voit pas, elle mesure les lignes, pas leur justesse ;
- la mutation ne la voit pas, elle vérifie que les tests tiennent au code, pas
  que le code tient au livre ;
- l'intégrité ne la voit pas, le dépôt se charge parfaitement ;
- les tests ne la voient pas, ils ont été écrits d'après la même mémoire.

**Une règle sans source est une règle à vérifier avant d'écrire un test.** Il
vaut mieux une liste courte et sourcée qu'une liste complète et supposée : ce
qui manque se voit, ce qui est faux ne se voit pas.

Écrire aussi ce que la carte **ne couvre pas** — les cas connus, laissés à une
carte ultérieure. Un trou nommé n'est pas une dette, c'est une frontière.

> **Gué.** La liste est présentée et discutée. On ne conçoit rien avant.

---

## Phase 3 — La conception

**Sortie** : les types et les signatures, **compilables**, avec des corps
`todo!()`.

Ce qu'on décide ici :

- **Les structures de données** et leurs champs. Privé par défaut — c'est le
  défaut de Rust, il n'y a rien à faire pour l'obtenir.
- **Ce qui devient `pub`.** C'est la vraie décision de cette phase. Chaque `pub`
  est une promesse à tenir, et dans le noyau c'est aussi ce que la GDExtension
  et la boucle d'entraînement pourront voir. Un champ public est un invariant
  qu'on renonce à garantir.
- **Les méthodes**, avec leurs signatures exactes : ce qu'elles prennent, ce
  qu'elles rendent, et ce qu'elles rendent en cas d'échec.
- **Les patrons de conception applicables**, s'il y en a — et il n'y en a pas
  toujours. Nommer un patron qui ne sert à rien coûte plus qu'il ne rapporte.

Le livrable **compile**. C'est ce qui le distingue d'un texte : la forme est
vérifiée par le compilateur avant qu'on ait écrit une ligne de logique, et les
`todo!()` préparent la phase suivante.

> **Gué.** La conception est présentée et discutée. On ne code rien avant.

---

## Phase 4 — Les tests, contre le vide

**Sortie** : les tests des règles de la phase 2, écrits contre les `todo!()`.

L'ordre compte, et pour une raison mécanique : `todo!()` **panique**. Un test
écrit maintenant ne peut pas passer. S'il passe, c'est qu'il n'appelle rien,
donc qu'il ne vérifie rien.

C'est le filet contre l'échec le plus tenace de ce projet — trois « OK » qui ne
vérifiaient rien : un lanceur qui ne trouvait aucun test, un contrôle de
couverture derrière un tube, un test qui plantait avant sa première assertion.
Ici la panique le rend impossible sans qu'on ait rien à surveiller.

**On lance les tests, et on montre qu'ils échouent.** Le nombre d'échecs doit
égaler le nombre de tests écrits. Un test vert à cette phase est un test à
réécrire, pas à garder.

Une règle de la phase 2 sans test est un manquement, pas un arbitrage : si la
règle ne se teste pas, c'est la conception qu'il faut revoir.

---

## Phase 5 — L'implémentation

**Sortie** : les corps, et les tests au vert.

Rien de plus que ce que les tests demandent. Le surplus se paiera de toute
façon en phase 6 : une ligne que rien n'exerce fait tomber la couverture, et
c'est précisément à quoi sert l'exigence de 100 %.

Si l'implémentation révèle que la conception ne tient pas, on **revient à la
phase 3** et on repasse le gué. On ne rattrape pas une conception fausse dans
un corps de fonction.

---

## Phase 6 — Les vérifications

Les quatre, dans cet ordre :

```bash
make test-behaviour    # le code répond-il juste ? Rust ET GDScript
make check-arch        # les frontières tiennent-elles, et la couverture est-elle à 100 % ?
make check-integrity   # le dépôt tient-il ?
make check-mutations   # les tests peuvent-ils échouer ?
```

**`test-behaviour` d'abord**, comme le veut la règle 14 : il est le seul à
parler du comportement. `check-arch` lance `cargo llvm-cov`, pas `cargo test` —
un noyau couvert à 100 % dont toutes les assertions sont fausses y passerait au
vert.

**`check-mutations` en dernier**, parce qu'il ne sert à rien sur une suite qui
n'est pas déjà verte. Il casse le code volontairement, une mutation à la fois,
et vérifie qu'un test rougit. Une mutation qui survit est un test manquant : le
code fait quelque chose que rien ne vérifie. C'est la version mécanique de
*« un test qu'on n'a pas vu échouer ne protège rien »*.

Il est limité au module que la carte a touché (`--file`). Sans ce filtre il
recompile et relance la suite une fois par mutation sur tout le noyau, et une
vérification qui prend des minutes finit par se sauter. Le filtre a son prix,
écrit ici pour ne pas l'oublier : **une régression que la carte causerait
ailleurs y échapperait.** Une passe complète, sans filtre, vaut d'être lancée de
temps en temps — pas à chaque carte.

**Et si la carte ajoute de l'état au noyau : étendre le scénario d'empreinte**
de la carte 12. Ce contrôle compare deux processus et attrape n'importe quelle
source d'indéterminisme — mais seulement sur ce que son scénario exerce, et sa
propre carte l'écrit. De l'état ajouté sans que le scénario suive, et le
contrôle couvre une part décroissante du noyau **en restant vert**. C'est le
genre de délitement qu'on ne voit jamais commencer.

---

## Phase 7 — Consigner ce qu'on a appris

**Sortie** : la carte, complétée.

Les six phases précédentes *consomment* la carte. Celle-ci y écrit.

Ce qui mérite d'y figurer :

- **Les pièges rencontrés** et comment ils se sont manifestés. Pas « attention à
  X », mais ce qui a réellement échoué, et ce qui l'a révélé.
- **Les mutations vues rougir** : laquelle, et quel test l'a attrapée. Une
  mutation qui a survécu et le test ajouté pour elle.
- **Les mesures relevées** — un chiffre mesuré vaut mieux qu'une estimation, et
  se relit dans six mois.
- **Les limites assumées** : ce que la carte laisse ouvert, et pourquoi c'était
  le bon arbitrage.
- **Ce qui a démenti une hypothèse.** C'est le plus précieux et le plus vite
  oublié.

Les cartes 9 et 12 de `done/` sont l'étalon. Elles ne décrivent pas ce qu'il
fallait faire — elles racontent ce qu'on a découvert en le faisant : le nul
qu'aucun test ne voyait, le test qui passait sans rien vérifier, les trois
empreintes divergentes. Cette qualité était accidentelle ; cette phase existe
pour qu'elle cesse de l'être.

---

## Phase 8 — Clore

1. **Les quatre vérifications sont vertes.** Lire le compte, pas la dernière
   ligne : un lanceur qui ne trouve aucun test annonçait « OK ».
2. **La validation humaine** (règle 1). Ne jamais présumer qu'un travail est
   terminé.
3. **Le commit**, avec le numéro de carte entre crochets juste après le scope
   (règle 12), et `git diff --cached --stat` lu et montré avant (règle 10).
4. **La carte passe en `done/` dans le même commit que le code**, ou dans le
   commit immédiatement suivant. Jamais après un push.

> **Gué.** Rien n'est commité sans validation explicite.

---

## Ce que ce workflow ne garantit pas

Il garantit que le code fait ce que les tests disent, que les tests peuvent
échouer, que le noyau ne dépend de rien, et que deux exécutions se ressemblent.

**Il ne garantit pas que les règles sont les bonnes.** Aucune des quatre
vérifications ne lit le livre de règles. C'est le rôle de la phase 2, et c'est
la seule phase du workflow que rien ne rattrape en aval.
