# 9 — Brancher la grille Rust

## Objectif

Remplacer `app/core/rules/unit_grid.gd` par une classe exposée depuis le noyau
Rust, **sans que rien d'autre ne change**. Les neuf tests de comportement sont
le contrat : s'ils passent, le portage est juste.

## La décision : préserver l'API, pas amorcer `submit()`

`docs/noyau-et-apprenant.html` décrit une frontière en `submit()` /
`legal_mask()` / `snapshot()`. Ce n'est **pas** la forme à adopter ici, pour
trois raisons :

- **on perdrait le contrat.** Les neuf tests ne pourraient plus passer
  inchangés, et c'est la seule preuve dont on dispose que le Rust fait ce que
  faisait le GDScript ;
- **ce ne serait plus un portage** mais une refonte : `arena.gd`,
  `unit_zone.gd`, `movement_range.gd`, `drag_and_drop.gd` et `minimap.gd`
  devraient tous changer ;
- **on figerait le vocabulaire commandes/événements sur un seul cas d'usage.**
  Une grille n'est pas une commande de jeu. Le vocabulaire se dessinera quand il
  y aura de vraies commandes — déplacer, bloquer, passer.

`submit()` reste l'horizon. Il arrivera quand le noyau aura des règles à
arbitrer, pas une structure de données à exposer.

## La surface à reproduire

Relevée sur les consommateurs, pas devinée :

| Appelé par | Ce qu'il faut |
|---|---|
| `arena.gd:19` | `UnitGrid.new(Pitch.SIZE)` |
| `arena.gd:37,55,63` | `clear()`, `place_unit(tile, unit)`, `remove_unit(unit)` |
| `drag_and_drop.gd:134,136` | `remove_unit`, `place_unit` |
| `movement_range.gd:62,94` | `get_tile_of(unit)`, `is_tile_blocked_for(tile, unit)` |
| `minimap.gd:50` | signal `unit_grid_changed` |
| `unit_zone.gd:12,24` | type `UnitGrid`, propriété `size` |
| les tests | `get_unit_at`, `is_tile_occupied`, `has_unit`, `get_occupied_tiles` |

## L'inconnue levée

**Une classe GDExtension ne reçoit pas d'argument à `new()`** — mesuré :
`BbCore.new(5)` produit `Parse Error: Too many arguments for "new()" call`.
Ce n'est pas une limite de gdext mais le protocole d'instanciation de Godot :
`ClassDB.instantiate()` ne prend pas d'arguments, et les classes natives du
moteur n'en prennent pas non plus. Les méthodes, elles, en prennent autant qu'on
veut, en instance comme en statique — vérifié aussi.

D'où `UnitGrid.create(size)`, une fabrique statique. Trois lignes de
construction changent ; **aucune assertion**. Cette forme interdit qu'une grille
existe un instant sans sa taille, ce qui était précisément le piège de la
carte 1.

## Ce que le jeu a trouvé et que douze tests n'avaient pas vu

`arena.gd:49` demande « cette case est-elle libre ? » **avant** de créer le
jeton, donc avec une unité **nulle**. Le GDScript le tolérait ; la première
version Rust refusait la conversion, et déposer un joueur échouait — cinq fois
en quelques secondes de jeu.

Les tests de caractérisation avaient été écrits d'après l'usage du fichier de
test, **pas d'après les sites d'appel réels**. C'est la limite de la
caractérisation : elle fige ce qu'on pense observer.

Corrigé : les trois interrogations acceptent le nul. `place_unit` reste stricte,
délibérément — le GDScript y aurait rangé `null` dans ses deux index et corrompu
la grille en silence ; aucun appelant ne le fait, et échouer bruyamment vaut
mieux que continuer faux.

## Le trou du harnais, découvert en voulant prouver le correctif

Le test ajouté pour couvrir le nul **ne rougissait pas** contre la version
fautive. Un test qui s'interrompt à mi-parcours n'atteint jamais ses assertions,
n'enregistre donc aucun échec, et passe pour vert. Vérifié sur une sonde : un
test dont la première ligne plante était rapporté `[ok]`.

Troisième « OK » sans rien vérifier de la session, après le lanceur qui ne
trouvait aucun test et le contrôle de couverture derrière un tube. Deux verrous
posés, qui se recoupent : **chaque test doit avoir exécuté au moins une
assertion**, et **toute erreur moteur levée pendant les tests est un échec**.

## Une limite assumée

La table de correspondance ne se vide qu'au `clear()`. Un nœud placé puis retiré
garde son identifiant — voulu, pour qu'un joueur qui revient soit le même — mais
la table grandit avec chaque unité distincte jamais placée. `arena.gd` appelle
`clear()` à chaque début de match, donc c'est borné en pratique.

## Terminé quand

- [x] `app/core/rules/unit_grid.gd` n'existe plus ;
- [x] les tests de comportement passent, assertions inchangées — un treizième
  ajouté pour le cas du nul, vu échouer contre la version fautive ;
- [x] `make test-behaviour`, `make check-arch` (couverture comprise),
  `make check-integrity` passent ;
- [x] `make run` : déposer un joueur, le déplacer, la minimap suit — contrôlé à
  l'écran, zéro erreur contre cinq au lancement précédent.
