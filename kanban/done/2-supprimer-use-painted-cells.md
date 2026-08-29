# 2 — Supprimer `use_painted_cells`, configuration morte

## Le constat

`UnitZone` portait `@export var use_painted_cells: bool = false`, lu à deux
endroits — le repli de `_ready()` et la branche de `is_tile_in_bounds()`.

**Aucune scène du dépôt ne le posait à `true`.** Le chemin « limites déduites
des tuiles peintes » n'a donc jamais été emprunté. Le commentaire de classe
décrivait une intention — « sert aussi bien au terrain qu'aux boîtes de
réserve » — que le code ne réalisait pas : les calques latéraux d'`arena.tscn`
(`blue-reserves`, `red-KO`, `blue-injuries`…) sont de simples `TileMapLayer`
sans script, purement visuels. Réserves et K.O. sont des états de `MatchState`
affichés par le HUD, pas des lieux du monde.

Même forme que les six signaux morts relevés par l'audit : du code qui se lit
comme une capacité disponible, et n'en est pas une.

## Ce qui a été fait

- `@export var use_painted_cells` supprimé, avec son commentaire ;
- `_ready()` : `elif not use_painted_cells:` devient `else:` ;
- `is_tile_in_bounds()` : la branche disparaît, la fonction se réduit à
  `return bounds.has_point(tile)` ;
- le commentaire de classe dit désormais ce qui est vrai — une seule zone
  existe, le terrain.

## Comment la suppression a été prouvée

Trois tests de caractérisation ont été écrits **avant** la suppression
(`tests/unit/unit_zone_test.gd`) : limites issues de la taille de la grille,
coordonnées hors terrain, zone sans grille. Ils passaient avant, ils passent
après — c'est ce qui établit qu'on n'a retiré que du code mort, et non un
comportement que personne ne regardait.

Recensement exhaustif des consommateurs avant suppression (règle 4) : trois
sites, tous dans `unit_zone.gd`, zéro scène.

## Terminé quand

- [x] plus aucune occurrence de `use_painted_cells` dans le code ;
- [x] `make test` passe — 127 vérifications d'intégrité, 9 tests unitaires ;
- [x] les tests de `UnitZone` passent à l'identique avant et après.
