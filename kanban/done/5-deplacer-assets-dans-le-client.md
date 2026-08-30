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

## Décisions

**D1 — ni avant, ni après : la donnée garde ses chemins, le client possède la
racine.** La carte posait le choix entre « déplacer puis découpler » et
l'inverse. Une troisième voie coûte bien moins cher : les JSON conservent
`assets/player_icons/Human/Lineman2B.png`, et seul le préfixe vit dans le code,
en `BloodBowlData.ASSETS_ROOT`. **Zéro chemin JSON réécrit**, et le couplage
disparaît quand même — la donnée cesse de savoir où les images vivent dans le
projet.

Le passage à des clés (`humans`, `Human/Lineman2B`) reste possible plus tard.
Il change l'API du catalogue, donc il appartient à la carte 6, qui décide où ce
catalogue vit.

**D2 — la résolution se fait en un seul endroit.** Elle était éparpillée sur
trois sites dont deux court-circuitaient l'accesseur : `bloodbowl_data.gd`
faisait `load("res://" + icon)`, tandis que `team_chooser.gd` et
`vertical_team_list.gd` faisaient `load(t.icon)` — ce qui marchait par
accident, Godot résolvant les chemins relatifs contre `res://`. Les deux appels
directs passent désormais par `get_icon_texture()`.

Les méthodes `get_*_texture()` restent dans `bloodbowl_data.gd` : charger une
`Texture2D` n'a rien à faire dans un catalogue de domaine, mais c'est la carte 6
qui scinde ce fichier. L'en sortir ici trancherait sa destination par la bande.

**D3 — `tileset (copie).png` est supprimé.** Zéro référence, nom explicite, et
il aurait suivi dans le client. C'est aussi lui qui avait cassé la première
version du réimport conditionnel du `Makefile`, les prérequis de make se
coupant sur les espaces.

## Ce qui a été fait

3 715 fichiers déplacés vers `app/io/client/assets/`, 96 références `res://`
réécrites dans 23 fichiers, **0 dans les JSON**. La vérification `data_assets`
résout les 452 chemins distincts et connaît la même racine que le code — c'est
précisément ce qu'elle atteste.

`assets/` disparaît de `IMPORT_SCAN` dans le `Makefile` : il vit désormais sous
`app`, déjà balayé.

## Terminé quand

- [x] `app/io/client/assets/` existe, la racine n'a plus de `assets/` ;
- [x] `make check-integrity` passe — `data_assets` résout les 452 chemins ;
- [x] `make run` : icônes d'équipe, jetons de joueurs et terrain s'affichent —
  contrôlé à l'écran.
