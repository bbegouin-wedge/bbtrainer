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

1. **`size` vit dans la scène.** `arena.tscn` porte `size = Vector2i(26, 15)`
   sur le nœud `ArenaUnitGrid`. En `RefCounted`, cette propriété n'a plus où
   être écrite. Perdue, `unit_zone.gd:20` calcule `bounds = Rect2i(ZERO, ZERO)`
   et plus aucune case n'est valide — sans erreur, juste un `push_warning`.
2. **L'export est câblé par `NodePath`.** `arena.tscn` : `unit_grid =
   NodePath("ArenaUnitGrid")`. Un `RefCounted` ne peut pas être désigné ainsi ;
   ce câblage doit devenir du code. C'est le vrai coût, pas le `extends`.
3. **Trois consommateurs indirects** passent par `pitch.unit_grid` /
   `play_area.unit_grid` : `arena.gd`, `movement_range.gd`, `minimap.gd`. Le
   dernier écrit `if pitch and pitch.unit_grid:` — un `and` qui avale l'absence.

À corriger au passage : **la taille du terrain a deux sources de vérité**.
`arena_phase.gd:5-8` déclare `GRID_WIDTH := 26` / `GRID_HEIGHT := 15`, et
`arena.tscn` porte la même dimension, invisible depuis le code.

## Plan

**Étape 1 — poser `tests/unit/` et caractériser le comportement actuel.**
Les tests s'écrivent **avant** la conversion, sur le `UnitGrid` tel qu'il est.
Écrits après, ils décriraient le nouveau comportement et ne prouveraient rien.

Invariants à figer — ceux qui cassent sans bruit :

- `place_unit` sur une seconde case **déplace** au lieu de dupliquer : aucun
  fantôme sur l'ancienne case ;
- `is_tile_blocked_for` est faux pour la propre case de l'unité ;
- `clear()` vide **les deux** index — l'index inverse est ce qui pourrit ;
- `unit_grid_changed` part sur `place`, `remove` et `clear` ;
- `remove_unit` d'une unité absente ne fait rien et n'émet pas.

Ça demande une infrastructure que le harnais n'a pas : `tests/unit/`, un petit
assembleur d'assertions, une cible `make test-unit`, et `make test` devenant
« intégrité + unitaires ».

**Étape 2 — convertir et déplacer.** `extends RefCounted`, `size` et l'export
recâblés en code, `git mv` vers `core/rules/`. `make check-arch` cesse alors de
ne rien vérifier.

**Étape 3 — vérifier le câblage, que les tests unitaires ne voient pas.**
Un test d'intégration qui monte `arena.tscn` et vérifie que la zone de jeu
reçoit une grille de 26 × 15. Le harnais sait déjà instancier les scènes.

## Questions ouvertes

- **Qui construit la grille et la donne à `UnitZone`** ? `arena.gd` dans son
  `_ready()`, ou `UnitZone` qui la crée lui-même ? La première option garde une
  seule grille pour plusieurs zones, la seconde simplifie le câblage.
- **D'où vient `size`** ? Des constantes de `arena_phase.gd` — ce qui supprime
  la duplication mais fait dépendre le monde de son coordinateur — ou d'un
  `@export` porté par `UnitZone`, qui laisse la valeur dans la scène.
- **Les autres zones** (réserves, KO, blessés) déduisent leurs limites de leurs
  cases peintes et n'utilisent pas `size`. Vérifier qu'aucune ne casse.

## Terminé quand

- `core/rules/unit_grid.gd` existe, `make check-arch` le vérifie et passe ;
- `make test-unit` couvre les cinq invariants ci-dessus et passe ;
- `make check-integrity` passe ;
- le jeu lancé par `make run` permet toujours de déposer un joueur sur le
  terrain, de le déplacer, et la minimap suit.
