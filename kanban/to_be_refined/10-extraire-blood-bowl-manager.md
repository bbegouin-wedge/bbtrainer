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

## Découpage retenu

La carte s'est révélée plus fine que prévu à la lecture du code :
`blood_bowl_manager.gd` est surtout **une façade**. Sur ses 97 lignes, 30 lisent
quatre JSON et les 14 méthodes restantes délèguent — seules `get_all_teams`
(qui trie), `search_teams`, `get_affordable_players` et `get_stars_for_team`
portent une logique. Le catalogue lui-même vit dans `bloodbowl_data.gd`,
395 lignes.

D'où trois lots :

**10a — sortir `data/` de la racine. FAIT.** Vers `app/io/persistence/`, six
références réécrites dont les quatre chemins JSON du chargeur. La racine ne
contient plus que `addons app autoload bin docs kanban tests`.

**10b — sortir la résolution des images du catalogue. FAIT.** Voir ci-dessous.

**10c — séparer le chargeur du catalogue**, et boucher la fuite de
`skill_list.gd:18,40`, qui fait `BloodBowlManager.data.skills` et traverse la
façade pour atteindre la donnée brute.

## Ce que 10b a débloqué

Le blocage était précis : `BloodBowlData` chargeait des textures
(`load(ASSETS_ROOT + icon)`). Un chemin `res://` dans `core/` est refusé par
`check-arch` — à raison. Ce n'est pas `extends Resource` qui gênait, la règle 8
autorisant les types natifs : **c'était la résolution d'images**.

Elle vit désormais dans `app/io/client/icons.gd`, avec le polymorphisme qui va
avec — un joueur porte une icône, un duo deux, une équipe un chemin nu. C'est de
la présentation, pas du modèle. Treize sites d'appel basculés.

**Deux fuites bouchées que la carte n'avait pas prévues :**

`MatchState.Entry.get_icon()` rendait une `Texture2D` — de l'état de partie qui
produisait de l'affichage. C'est un morceau de la carte 11 qui traînait ici.

Et le catalogue portait `ASSETS_ROOT`, donc **la donnée savait où vivent les
images**. La carte 5 avait déplacé le problème en le rendant visible ; il est
résolu.

**Conséquence** : plus rien dans le catalogue ne charge de `res://`. Il peut
désormais viser `core/`, ce qui était la question que cette carte posait sans
pouvoir y répondre.

## Terminé quand

- [ ] la lecture des fichiers et le catalogue ne sont plus dans le même objet
  — **lot 10c** ;
- [x] les chemins d'images ne sont plus résolus par le catalogue ;
- [x] les trois vérifications passent, et `make run` affiche les équipes,
  jetons et écussons — contrôlé à l'écran.
