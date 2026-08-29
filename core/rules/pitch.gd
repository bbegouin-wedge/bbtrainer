class_name Pitch
extends RefCounted

## Le terrain de Blood Bowl, en cases.
##
## 26 × 15 est une règle du jeu, pas un réglage d'affichage : la dimension vit
## donc ici, et non dans une scène ni dans les constantes d'un coordinateur.
## Elle a porté les deux à la fois — le nœud ArenaUnitGrid d'arena.tscn et les
## constantes GRID_WIDTH/GRID_HEIGHT d'arena_phase.gd — sans que rien ne signale
## qu'elles devaient s'accorder.
##
## La taille des cases en pixels reste dans io/ : c'est de l'affichage.

## 15 et non 16 : c'est la hauteur réelle de la grille. L'écart faussait le
## calcul de zoom de 7 % — leçon conservée de arena_phase.gd, d'où la constante
## vient.
const SIZE := Vector2i(26, 15)
