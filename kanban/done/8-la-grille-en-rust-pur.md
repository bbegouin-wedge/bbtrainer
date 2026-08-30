# 8 — La grille en Rust pur

## Objectif

Porter la logique de `UnitGrid` dans un crate Rust **qui ne dépend pas de
Godot**, testé par `cargo test` sur les mêmes invariants que
`tests/unit/unit_grid_test.gd`.

Aucune liaison dans ce lot : rien de ce Rust n'est encore appelé par le jeu.
C'est la carte 9 qui branche la frontière, avec les neuf tests de comportement
existants comme contrat.

## Pourquoi un second crate

`app/core/src/lib.rs` dépend de `godot` — c'est lui qui porte la GDExtension. Y
mettre les règles ferait mentir la promesse du noyau : *« core … ignore
Godot »*.

La séparation en deux crates rend cette frontière **vérifiable par le
compilateur** et non par un `grep` : le crate des règles n'a pas `godot` dans
son `Cargo.toml`, donc il ne peut pas l'appeler. C'est la première frontière du
projet qui ne repose pas sur la discipline.

```
app/core/
  Cargo.toml         [workspace]
  kernel/            les règles — aucune dépendance godot
  gdextension/       la frontière — dépend de kernel et de godot
  rules/             le GDScript résiduel, qui s'efface
```

## Ce que la grille devient

Trois écarts avec la version GDScript, et chacun a une raison :

**Elle est indexée par des identifiants, pas par des nœuds.** `UnitGrid` utilise
aujourd'hui des `Node` comme clés de dictionnaire. Un noyau qui ferait pareil
connaîtrait Godot. Le Rust manipule un `UnitId` opaque ; c'est la liaison qui
traduira.

**Elle n'émet pas de signal — elle rend des événements.** C'est la forme que
décrit `docs/noyau-et-apprenant.html` : *« reçoit une commande … rend une liste
d'événements »*. Et ça résout un cas précis : déplacer une unité émet
aujourd'hui `unit_grid_changed` **deux fois**, parce que `place_unit` appelle
`remove_unit` qui émet, puis émet à son tour. Une méthode qui rend
`[Removed, Placed]` donne à la liaison exactement de quoi reproduire ce
comportement — au lieu de le deviner.

**Elle ne connaît pas `Vector2i`.** Un type `Tile` local, converti à la
frontière.

## Les invariants à couvrir

Les mêmes que `unit_grid_test.gd`, portés en `#[test]` :

- reposer une unité ailleurs la **déplace**, sans fantôme sur l'ancienne case ;
- une unité ne se bloque pas elle-même ;
- vider la grille vide **les deux** index ;
- les événements rendus : un à la pose, deux au déplacement, un au retrait ;
- retirer une unité absente ne fait rien et ne rend aucun événement.

## Décisions

**D1 — `cargo test` dans `make test-behaviour`.** Même question — « le code
répond-il juste ? » — dans les deux langues. La règle 14 reste à trois
commandes, et une cible séparée aurait découpé ce qui ne se découpe pas.

**D2 — `UnitId` opaque.** Reprendre `Object.get_instance_id()` aurait rendu la
liaison triviale, au prix d'un noyau portant la trace de son adaptateur. C'est
le genre de facilité qui, accumulée, transforme un noyau en adaptateur déguisé.
La table de correspondance vivra dans la liaison, là où elle doit vivre.

**D3 — `pitch.gd` reste en GDScript.** Sa place est bien ce crate, mais rien ne
l'appellerait avant la carte 9. `Grid::new(size)` prend sa taille en paramètre,
comme le GDScript aujourd'hui.

## La couverture du noyau

Chaque ligne de `kernel/` doit être couverte : `make check-arch` lance
`cargo llvm-cov --fail-under-lines 100`. Le contrôle vit dans les règles
d'architecture et non dans les tests, parce que la couvrabilité intégrale est
une conséquence de l'absence de dépendance au moteur — une ligne devenue
incouvrable signale que quelque chose d'extérieur s'est invité.

Mesure actuelle : **100 % des lignes, des régions et des fonctions**, en 0,74 s.

## Ce que les trois épreuves ont montré

**La frontière tient toute seule.** Un `use godot::prelude::*;` glissé dans
`kernel/src/grid.rs` produit `error[E0433]: use of unresolved module or unlinked
crate godot`. Aucun `grep`, aucune convention : le compilateur refuse.

**Les tests attrapent la régression.** `place()` privé de son retrait préalable
fait rougir deux tests sur six — et `make test-behaviour` sort en 2 avec
« NOYAU RUST : ÉCHEC », sans même atteindre les tests GDScript.

**Le contrôle de couverture attrape le trou, et il a fallu le corriger pour ça.**
Première version de la recette : `cargo llvm-cov … | grep … | sed …`, dont le
shell rend le code de sortie du **dernier maillon**. Une fonction délibérément
non testée faisait tomber la couverture à 94,55 % et `check-arch` annonçait
« ARCHITECTURE : OK », code 0. C'est exactement le piège déjà documenté pour
`check-integrity`, reproduit à l'identique. Corrigé par un journal intermédiaire :
94,55 % → échec code 2, 100 % → OK.

## Terminé quand

- [x] `app/core/kernel/` compile sans dépendance à `godot` — et le compilateur
  refuse qu'on l'y ajoute ;
- [x] `cargo test` couvre les invariants (6 tests), vus échouer sur une mutation ;
- [x] `make check-arch` exige 100 % de couverture du noyau — vu échouer à 94,55 % ;
- [x] les trois vérifications passent — le jeu n'a pas changé, ce Rust n'est pas
  encore appelé.
