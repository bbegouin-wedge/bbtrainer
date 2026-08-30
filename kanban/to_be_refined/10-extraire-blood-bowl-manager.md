# 10 — Extraire `blood_bowl_manager`

## Objectif

`autoload/blood_bowl_manager.gd` fait **deux métiers en 97 lignes** : il lit les
JSON, et il expose le catalogue indexé. Les séparer.

| Moitié | Destination |
|---|---|
| lecture des fichiers | `app/io/persistence/` — un adaptateur |
| catalogue indexé | `app/core/` — 30 équipes, 111 compétences, 63 stars |

## Ce qui rend l'affaire délicate

**`data/bloodbowl_data.gd` fait 395 lignes et `extends Resource`.** Il porte les
classes de données *et* leur chargement *et* la résolution des chemins d'images
(`load(ASSETS_ROOT + icon)`) — cette dernière n'ayant rien à faire dans un
catalogue de domaine. La carte 5 l'a laissée là exprès, en notant que c'est cette
carte qui tranche.

**Un autoload est un nom global.** Retirer `BloodBowlManager` de
`project.godot` fait échouer d'un coup toutes ses utilisations. Bruyant, donc
sûr — mais pas fichier par fichier.

## Questions ouvertes

- **Le catalogue passe-t-il en Rust ?** C'est du domaine, donc oui à terme. Mais
  il lit du JSON, et le noyau Rust ne doit pas connaître le disque : c'est
  l'adaptateur de persistance qui le nourrirait.
- **Qui porte l'instance ?** Un autoload mince, ou un objet créé au démarrage et
  passé explicitement ?

## Terminé quand

- la lecture des fichiers et le catalogue ne sont plus dans le même objet ;
- les chemins d'images ne sont plus résolus par le catalogue ;
- les trois vérifications passent, et `make run` affiche les équipes.
