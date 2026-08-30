# 22 — Extraire l'état de match

## Objectif

`autoload/match_state.gd` (216 l.) porte **où se trouve chaque joueur pendant un
match** : réserves, terrain, K.O., blessés, plus le banc et les conditions. Ce
qu'une autorité serveur posséderait. Sa place est le noyau.

C'est le dernier script d'`autoload/` qui ne soit pas un simple porteur.

## Pourquoi c'est le lot le plus coûteux du chantier

**Dix fichiers consommateurs** : `arena`, `unit_zone`, `movement_range`,
`roster_drag`, les quatre du dugout, le bandeau de joueurs, la minimap.

**Et le problème de `UnitGrid`, un étage au-dessus** : `Entry` tient un
`unit: Node`, et `get_entry_for_unit(unit: Node)` cherche par ce nœud. Un noyau
ne peut pas garder de nœud. La parade est connue — un identifiant opaque et une
table dans la coquille, comme la carte 9 l'a fait pour la grille — mais elle
porte ici sur un objet bien plus gros.

## Ce que les cartes précédentes ont préparé

- **le patron** : le noyau calcule, la coquille émet et tient les nœuds
  (cartes 9, 10, 11) ;
- **le catalogue est dans `core/`**, donc `Entry` peut référencer
  `BloodBowlData.Player` sans violer les couches (carte 10) ;
- **`TeamState.get_stars()`** remplace l'accès au champ privé que
  `build_from_team_state()` faisait (carte 11).

## Ce que la carte 14 a changé pour celle-ci

**Le réceptacle existe, en Rust.** `Match` porte le tour, l'équipe active, les
dés et l'état d'attente. Cette carte n'a plus à décider *où* va l'état de
match : elle déménage le contenu de `match_state.gd` **dedans**.

Les deux cartes visaient la même chose dans deux langages, dans le même dossier,
sans que rien ne le signale — chacune était cohérente prise seule. C'est la
phase 1 du workflow de la carte 14 qui l'a fait apparaître.

**Le patron est celui de la carte 9**, un étage au-dessus : identifiants opaques
dans le noyau, table des nœuds dans la coquille. Le `unit: Node` d'`Entry`
devient un identifiant, et `match_state.gd` devient une coquille mince qui tient
la correspondance et émet les signaux.

**Et une conséquence à ne pas manquer** : les trois signaux de `MatchState`
(`roster_changed`, `entry_location_changed`, `staff_changed`) ne deviennent pas
des `Event` du noyau. Le noyau rend des faits de jeu ; la coquille les traduit
en signaux d'interface. Les deux vocabulaires ne se confondent pas — c'est ce
que la carte 14 a fixé.

## La méthode, écrite

Caractériser d'abord, convertir ensuite, et un test d'intégration pour le
câblage que les tests unitaires ne voient pas.

Avec l'avertissement que la carte 9 a payé cher : **écrire les tests d'après les
sites d'appel réels, pas d'après l'usage qu'on imagine.** Ici, ça veut dire
partir des dix fichiers consommateurs.

## Questions ouvertes

- **Un lot ou plusieurs ?** 216 lignes et dix consommateurs, c'est beaucoup pour
  un commit. Le banc (`_staff`) et les localisations pourraient se séparer.
- **`MatchState` reste-t-il un autoload ?** Oui selon le patron — une coquille
  mince qui porte l'instance et émet. Mais ses trois signaux
  (`roster_changed`, `entry_location_changed`, `staff_changed`) sont déclarés
  sur lui : ils resteront côté coquille, le noyau rendant des événements.
- ~~**Le noyau Rust ?** Pas tant que `BloodBowlData` est du GDScript.~~
  **Tranché par la carte 14, et dans l'autre sens.** Cette contrainte n'en était
  pas une : `docs/noyau-et-apprenant.html` range le catalogue dans les
  adaptateurs — *« chargement JSON en lecture seule, injecté dans le noyau
  plutôt qu'appelé par lui »*. Un `Match` en Rust ne référence pas le
  catalogue : il tient des identifiants et des **valeurs simples** — MA, ST, AG,
  PA, AV, plus le masque de compétences en `u128`. `BloodBowlData` peut rester
  en GDScript indéfiniment sans rien empêcher.

## Terminé quand

- `autoload/` ne contient plus que des porteurs minces ;
- l'état de match vit dans `core/`, avec ses tests ;
- `make run` : le parcours complet, du choix d'équipe au déplacement d'un joueur
  sur le terrain, dugout compris.
