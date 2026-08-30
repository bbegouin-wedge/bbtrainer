# 7 — Poser la tuyauterie Rust

## Objectif

Prouver que la chaîne tient de bout en bout : un crate Rust compilé en
bibliothèque dynamique, chargé par Godot au démarrage, appelable depuis
GDScript, construit par `make`, et vérifié par le harnais.

**Zéro règle de jeu dans ce lot.** C'est délibéré : toutes les surprises d'une
GDExtension sont dans la tuyauterie — compatibilité de version, chemins,
artefacts, l'éditeur qui garde la bibliothèque ouverte. Y mêler de la logique
métier rendrait l'échec indiscernable.

## Où ça vit

Le noyau reste `app/core/`, et cohabite transitoirement en deux langues : le
GDScript s'efface à mesure que le Rust le remplace. Un répertoire `rust/`
séparé aurait suggéré deux noyaux distincts — il n'y en a qu'un.

```
app/core/
  rules/                   pitch.gd  unit_grid.gd    ← le GDScript, qui s'efface
  Cargo.toml  src/                                   ← les règles, à venir
  bindings/                                          ← la GDExtension, seule porte
bin/                                                 ← le .so construit (ignoré par git)
.build/                                              ← CARGO_TARGET_DIR (ignoré)
```

**`CARGO_TARGET_DIR` hors de `app/`** : un `target/` sous `res://` casserait
trois choses à la fois — l'importeur de Godot le scannerait, le harnais le
parcourrait à chaque vérification (`DirAccess` voit les fichiers même sous un
`.gdignore`), et le test de fraîcheur du réimport se déclencherait à chaque
`cargo build`, faisant payer 2,76 s à chaque compilation.

Le `.so` construit va dans `bin/`, hors de `IMPORT_SCAN`, pour la même raison.

**Nom de dossier ≠ nom de crate** : le dossier est `core`, le paquet
`bbtrainer_core`. Mesuré : un paquet nommé `core` compile et n'entre pas en
collision avec la bibliothèque standard — mais l'ambiguïté ne coûte rien à
éviter.

## Ce que `make` doit faire

`make build-core` compile et dépose le `.so`. Il devient prérequis de **tout ce
qui démarre Godot** — `run`, `debug`, `editeur`, et les trois vérifications :
la GDExtension est chargée au démarrage, donc un `.so` manquant ne casse pas
seulement le jeu, il fait échouer le chargement des 23 scènes. C'est la leçon
du cache d'UID, sous une autre forme.

Pas de témoin daté cette fois : `cargo build` sans changement coûte 0,07 s.

## Ce que le harnais doit vérifier

Pas « le fichier existe » — **« Godot a chargé l'extension et la classe est
disponible »**. Une vérification qui interroge `ClassDB` : le `.so` peut être
présent et refuser de se charger, et c'est exactement le cas qu'on veut voir.

## Ce qui a été fait

- `app/core/Cargo.toml` — paquet `bbtrainer_core`, `crate-type = ["cdylib"]`,
  dépendance `godot = "0.5"` ;
- `app/core/src/lib.rs` — une classe `BbCore` exposant `version()`, rien
  d'autre ;
- `app/core/bbtrainer.gdextension` — la frontière ;
- `make build-core`, prérequis de `run`, `debug`, `editeur` et, par `import`,
  des trois vérifications ;
- `tests/checks/extension.gd` — une dixième vérification du harnais ;
- `.build/` et `bin/` ignorés par git.

## Les trois surprises, et elles étaient toutes dans la tuyauterie

**gdext vise Godot 4.6 par défaut.** L'extension se chargeait, son symbole
d'entrée se résolvait, et l'initialisation échouait. Le message de gdext était
parfaitement explicite et nommait la solution : `features = ["api-4-5"]`. Cette
ligne devra suivre chaque montée de version du moteur.

**Une GDExtension n'est pas découverte à la volée.** Tant que `make import`
n'avait pas tourné, `.godot/extension_list.cfg` n'existait pas et Godot ignorait
le fichier `.gdextension`. C'est déjà couvert : `build-core` est prérequis
d'`import`.

**La vérification ne doit pas nommer la classe.** Écrire `BbCore.version()` dans
le vérificateur produirait une **erreur de compilation du vérificateur lui-même**
le jour où l'extension ne charge pas — soit un échec illisible au lieu du
message attendu. Elle passe par `ClassDB.class_exists()` puis
`ClassDB.instantiate()`.

## Ce que l'épreuve a montré

`.so` retiré, la vérification échoue avec le bon message ; `.so` rétabli, elle
repasse. Une vérification qu'on n'a pas vue échouer ne protège rien.

Coût mesuré : `build-core` 0,05 s sans changement, `check-integrity` toujours
1,96 s.

## Terminé quand

- [x] `make build-core` produit le `.so` et le dépose dans `bin/` ;
- [x] une classe Rust est appelable depuis GDScript — `BbCore.version()` → 0.1.0 ;
- [x] une vérification du harnais échoue si l'extension n'est pas chargée — et
  on l'a vue échouer ;
- [x] `make test-behaviour`, `make check-arch`, `make check-integrity` passent ;
- [x] `make run` : le jeu démarre comme avant, extension chargée, zéro erreur.
