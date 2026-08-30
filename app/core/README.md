# `app/core/` — le noyau

Les règles et le modèle du jeu. **Vide aujourd'hui** : son contenu est encore
mêlé aux scripts d'écran, et sera extrait au fil des chantiers (cf. CLAUDE.md,
« Organisation cible » et « Comment on y va »).

Deux interdits, vérifiés par `make check-arch` :

1. **Aucun `Node`.** C'est ce qui rend le noyau vérifiable sans fenêtre — et
   donc testable. Le contrôle porte sur le type natif résolu : hériter d'un
   script de `core/` qui hérite de `Node` est vu aussi.
2. **Aucune dépendance hors de `core/`.** Ni chemin `res://` extérieur, ni
   autoload, ni `class_name` déclaré ailleurs. GDScript n'ayant pas d'espace de
   noms, rien n'empêche ces appels : c'est le vérificateur qui les rend visibles.

Ce qui reste permis : les types natifs du moteur (`RefCounted`, `Resource`,
`Vector2i`, `Color`…). Ce sont des primitives, pas des dépendances de projet.

---

## Depuis le portage en Rust

Le noyau cohabite en deux langues : `rules/*.gd` s'efface à mesure que
`kernel/` le remplace.

```
Cargo.toml         [workspace]
kernel/            les règles — AUCUNE dépendance godot
gdextension/       la frontière — dépend de kernel et de godot
rules/             le GDScript résiduel
```

**La frontière est tenue par le compilateur**, et non par une convention :
`kernel` n'a pas `godot` dans son `Cargo.toml`, donc un `use godot::prelude::*;`
glissé dans le noyau produit `error[E0433]: use of unresolved module or unlinked
crate godot`. C'est ce que le vérificateur GDScript ne saura jamais faire — il
rend les violations visibles, il ne les empêche pas.

**Chaque ligne de `kernel/` doit être couverte par un test.** `make check-arch`
lance `cargo llvm-cov --fail-under-lines 100`. Ce n'est pas une exigence de
zèle : une ligne devenue incouvrable est le premier signe que quelque chose
d'extérieur s'est invité dans le noyau. La couverture ne dit rien de la justesse
des assertions — c'est la mise à l'épreuve par mutation qui s'en charge.

**Les artefacts sortent de `app/`** : `CARGO_TARGET_DIR=.build`, le `.so` déposé
dans `bin/`. Un `target/` sous `res://` serait scanné par l'importeur de Godot,
parcouru par le harnais à chaque vérification, et ferait se déclencher le
réimport à chaque `cargo build`.
