# 1 — Migrer UnitGrid vers `core/rules/`

## Objectif

Sortir `UnitGrid` de l'arbre de scènes pour en faire la première règle du noyau :
`class_name UnitGrid extends RefCounted`, dans `core/rules/`, vérifiable en
headless sans fenêtre.

C'est le meilleur candidat pour ouvrir `core/` — 67 lignes, deux dictionnaires,
aucune dépendance, aucun pixel. Aujourd'hui à `io/client/world/unit_grid.gd`,
où le lot B l'a laissé faute de pouvoir le convertir sans changer de
comportement.

## Ce qui rend la migration risquée

La logique n'est pas le risque. Le câblage l'est, et il échoue **en silence** :

1. ~~**`size` vit dans la scène.**~~ **Levé par la décision D2** : la taille
   monte dans `core/rules/pitch.gd`. Il n'y a plus de valeur dans la scène,
   donc plus de valeur à perdre.
2. **L'export est câblé par `NodePath`.** `arena.tscn` : `unit_grid =
   NodePath("ArenaUnitGrid")`. Un `RefCounted` ne peut pas être désigné ainsi ;
   ce câblage doit devenir du code. C'est le vrai coût, pas le `extends`.
3. **Trois consommateurs indirects** passent par `pitch.unit_grid` /
   `play_area.unit_grid` : `arena.gd`, `movement_range.gd`, `minimap.gd`. Le
   dernier écrit `if pitch and pitch.unit_grid:` — un `and` qui avale l'absence.

À corriger au passage : **la taille du terrain a deux sources de vérité**.
`arena_phase.gd:5-8` déclare `GRID_WIDTH := 26` / `GRID_HEIGHT := 15`, et
`arena.tscn` porte la même dimension, invisible depuis le code. La décision D2
les remplace toutes deux.

## Décisions

**D1 — `arena.gd` construit la grille et l'injecte dans `UnitZone`.**
Il en est déjà le seul mutateur : `place_unit` (l.54), `remove_unit` (l.62),
`clear` (l.36) — le propriétaire est désigné par l'usage. Laisser `UnitZone`
créer la sienne coûterait une ligne de moins et fermerait une porte :
`arena.gd:15` tient déjà `_drop_zones: Array[UnitZone] = [play_area]`, un
tableau d'un seul élément qui attend les réserves. Le jour où deux zones doivent
s'accorder sur qui occupe quoi, une grille par zone est ce qu'il ne faut pas.

**D2 — la taille du terrain monte dans `core/rules/pitch.gd`.**

```gdscript
const SIZE := Vector2i(26, 15)
```

26 × 15 est une **règle de Blood Bowl**, pas un réglage d'affichage.
`arena.gd` construira `UnitGrid.new(Pitch.SIZE)`, `arena_phase.gd` lira
`Pitch.SIZE` au lieu de redéclarer `GRID_WIDTH`/`GRID_HEIGHT`, et `arena.tscn`
cessera de porter `size`. Un fichier plutôt qu'une constante isolée : c'est là
qu'iront les zones d'en-but et les limites de placement.

`TILE_SIZE = 210` reste dans `io/` — c'est du pixel, pas de la règle.

**D3 — il n'y a pas d'autres zones.** `arena.tscn` ne contient qu'un seul
`UnitZone` (`PlayArea`) et une seule `UnitGrid`. Les calques latéraux
(`blue-reserves`, `red-KO`, `blue-injuries`…) sont de simples `TileMapLayer`
sans script, purement visuels : réserves et K.O. sont des états de `MatchState`
affichés par le HUD. La question ne se pose donc pas, et le drapeau
`use_painted_cells` qui la portait était du code mort — supprimé par la carte 2.

## Plan

**Étape 1 — poser `tests/unit/` et caractériser le comportement actuel. FAITE.**
Les tests s'écrivent **avant** la conversion, sur le `UnitGrid` tel qu'il est.
Écrits après, ils décriraient le nouveau comportement et ne prouveraient rien.

Invariants à figer — ceux qui cassent sans bruit :

- `place_unit` sur une seconde case **déplace** au lieu de dupliquer : aucun
  fantôme sur l'ancienne case ;
- `is_tile_blocked_for` est faux pour la propre case de l'unité ;
- `clear()` vide **les deux** index — l'index inverse est ce qui pourrit ;
- `unit_grid_changed` part sur `place`, `remove` et `clear` ;
- `remove_unit` d'une unité absente ne fait rien et n'émet pas.

L'infrastructure est en place : `tests/lib/test_case.gd`, `tests/run_unit.gd`,
`tests/unit/unit_grid_test.gd`, et les cibles `make test-unit` / `make test`.
Les six tests passent, et ont été éprouvés sur deux mutations volontaires du
code — sans quoi ils ne prouveraient rien.

Un comportement figé mérite d'être signalé parce qu'il surprend : **déplacer une
unité émet `unit_grid_changed` deux fois** — `place_unit` appelle `remove_unit`,
qui émet, puis émet à son tour. Constaté, pas approuvé : si la conversion le
change, le test le dira, et il faudra décider si c'est un progrès.

**Étape 2 — convertir et déplacer. FAITE.** `extends RefCounted`, `size` et l'export
recâblés en code, `git mv` vers `core/rules/`. `make check-arch` cesse alors de
ne rien vérifier.

**Étape 3 — vérifier le câblage, que les tests unitaires ne voient pas. FAITE.**
Un test d'intégration qui monte `arena.tscn` et vérifie que la zone de jeu
reçoit une grille de 26 × 15. Le harnais sait déjà instancier les scènes.

## Terminé quand

- `core/rules/unit_grid.gd` et `core/rules/pitch.gd` existent, `make check-arch`
  les vérifie et passe ;
- `arena_phase.gd` ne déclare plus `GRID_WIDTH`/`GRID_HEIGHT`, et `arena.tscn`
  ne porte plus `size` : une seule source de vérité pour la taille du terrain ;
- `make test-unit` couvre les cinq invariants ci-dessus et passe ;
- `make check-integrity` passe ;
- le jeu lancé par `make run` permet toujours de déposer un joueur sur le
  terrain, de le déplacer, et la minimap suit.

## Ce qui a été fait

`core/rules/pitch.gd` porte `SIZE := Vector2i(26, 15)` — et le commentaire qui
expliquait « 15 et non 16, l'écart faussait le zoom de 7 % », déménagé depuis
`arena_phase.gd` avec la valeur qu'il documente.

`core/rules/unit_grid.gd` : `extends RefCounted`, taille donnée au constructeur
plutôt que par un `@export` renseigné dans la scène.

`UnitZone.attach_grid()` pose la grille **et** recalcule les limites dans le
même geste. C'était le nœud du problème : en Godot, `_ready()` remonte des
enfants vers les parents, donc la zone était prête avant que l'arène puisse lui
donner sa grille. Une zone qui calcule ses limites dans son propre `_ready()`
démarre sans une seule case valide, sans erreur ni avertissement.

`arena.tscn` a perdu le nœud `ArenaUnitGrid`, son `ext_resource` et son câblage
par `NodePath`. `arena_phase.gd` ne déclare plus `GRID_WIDTH`/`GRID_HEIGHT`.

## Ce que l'épreuve a montré

L'injection retirée d'`arena.gd`, **les neuf tests unitaires sont restés verts**
et seuls les deux tests d'intégration ont rougi. C'est la démonstration que le
risque de câblage identifié par cette carte n'était couvert par aucun test
unitaire — et qu'il l'est maintenant.

Un trou du harnais a été rebouché au passage : le lanceur qui ne trouvait aucun
fichier de test annonçait « OK ». Il échoue désormais.
