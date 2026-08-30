# 5 — Déplacer `assets/` dans le client

## Objectif

`assets/` devient `app/io/client/assets/`. Ce sont des ressources de rendu —
images, polices, shaders, tuiles : `core/` n'y touchera jamais, et l'autorité
serveur décrite par `docs/noyau-et-adaptateurs.html`, qui tournera en
`--headless`, n'en aura aucun besoin.

## Ce qui rend ce lot différent des précédents

Les références ne sont pas où on les attend :

| Où | Combien |
|---|---|
| `.json` | **480** |
| `.tscn` | 79 |
| `.tres` | 12 |
| `.gd` | 5 |

**Les quatre cinquièmes vivent dans `data/teams_fr.json` et
`star_players_fr.json`.** Déplacer `assets/` revient donc à réécrire des
fichiers de **données**, et à graver `app/io/client/assets/…` dans le catalogue
du jeu.

Ce n'est plus un déménagement de code : c'est une migration de données, avec le
risque qui va avec. La vérification `data_assets` du harnais couvre exactement
ça — elle résout les 452 chemins distincts — mais elle ne dira rien de la
question de fond.

## La question de fond

**Le catalogue devrait-il citer un chemin de fichier du tout ?**

Aujourd'hui `bloodbowl_data.gd` fait `load("res://" + icon)` : le domaine
transporte des chemins d'affichage, et les JSON connaissent l'arborescence du
client. Déplacer `assets/` sans traiter ça ne fait que déplacer le problème —
en le rendant plus voyant, puisque le chemin gravé dans la donnée contiendra
alors `io/client/`.

L'alternative : la donnée porte une **clé** (`amazon/blitzer`), et le client la
résout en chemin. Le catalogue cesse de savoir où vivent les images, et un
changement d'arborescence redevient un changement de code.

## Questions ouvertes

- **Traiter les deux en un lot ou en deux ?** Déplacer d'abord et découpler
  ensuite double la réécriture des JSON. Découpler d'abord rend le déplacement
  trivial, mais demande d'inventer le schéma de clés avant d'en avoir besoin.
- **Où vit la résolution clé → chemin ?** Dans le client, forcément — mais dans
  un adaptateur dédié, ou dans le chargeur de catalogue de `io/persistence/` ?
- **Que faire de `tileset (copie).png`** et des autres fichiers dont le nom
  contient une espace ? Ils ont déjà cassé une première version du réimport
  conditionnel du `Makefile`.

## Terminé quand

- `app/io/client/assets/` existe, la racine n'a plus de `assets/` ;
- `make check-integrity` passe — la vérification `data_assets` résout les 452
  chemins distincts ;
- `make run` : les icônes d'équipe, les jetons de joueurs et le terrain
  s'affichent.
