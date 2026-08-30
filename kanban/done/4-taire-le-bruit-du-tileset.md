# 4 — Taire le bruit du TileSet

## Le constat

Chaque chargement de l'arène crachait **198 lignes d'erreur** sur trois motifs
répétés 66 fois :

```
ERROR: Cannot create tile. The tile is outside the texture or tiles are
       already present in the space the tile would cover.
ERROR: The TileSetAtlasSource atlas has no tile at (5, 0).
ERROR: TileSetAtlasSource has no tile at (5, 0).
```

Ce bruit a dicté la conception du harnais : le rapport de `check-integrity` est
préfixé et filtré **parce qu'il fallait bien distinguer un échec réel de ces
198 lignes**. Un journal où l'erreur est le régime normal ne sert plus à rien —
c'est exactement ce que l'épic d'observabilité appelle « journaliser dans le
vide », vu de l'autre côté.

## La cause

`arena.tscn` porte un `TileSetAtlasSource` inline sur
`assets/floor-tilemap.png`. La texture fait **1050 × 2310 px**, soit **5 × 11**
cases de 210. L'atlas en déclarait **11 × 11 = 121**.

121 − 55 = **66** — exactement le nombre d'erreurs de chaque motif. Quelqu'un a
déclaré une grille carrée là où la texture est haute et étroite.

## La vérification avant suppression

Les données de tuiles peintes des 11 calques ont été décodées depuis le
`PackedByteArray` de la scène : **9 coordonnées d'atlas distinctes**, toutes
comprises entre `x 0→4` et `y 0→3`. **Aucune tuile peinte n'utilise une
coordonnée supprimée** — elles ne le pouvaient pas, la texture n'ayant rien à
cet endroit.

## Ce qui a été fait

Les 66 déclarations dont la colonne dépasse la texture sont retirées du
`TileSetAtlasSource` d'`arena.tscn`. Les 55 valides restent, y compris celles
qu'aucun calque ne peint aujourd'hui : elles existent dans la texture, elles
sont légitimement disponibles.

## Mesure

| | avant | après |
|---|---|---|
| lignes `ERROR` au chargement complet | 199 | 1 |

La ligne restante vient du compilateur de shaders
(`!actions.custom_samplers.has(...)`), sur l'un des trois shaders de contour.
Autre cause, autre carte.

## Terminé quand

- [x] plus aucune erreur `TileSetAtlasSource` au chargement ;
- [x] les 9 coordonnées peintes sont intactes ;
- [x] `make test-behaviour`, `make check-arch`, `make check-integrity` verts ;
- [x] le terrain s'affiche à l'identique — contrôlé à l'œil via `make run`.
