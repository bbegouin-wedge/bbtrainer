# 11 — Extraire l'état de partie

## Objectif

`match_state.gd` (220 l.) et `team_state.gd` (50 l.) portent de l'**état de
jeu** : où se trouve chaque joueur, ce que vaut la composition d'équipe. C'est
ce qu'une autorité serveur posséderait — leur place est le noyau.

## Pourquoi c'est le lot le plus coûteux

`match_state.gd` est le plus gros script hors interface du projet, et il est
consommé par `arena.gd`, `drag_and_drop.gd`, `roster_drag.gd`, le dugout, le
bandeau de joueurs. Ce n'est pas un déplacement : c'est la carte 1 en plus
grand.

**La méthode est écrite** : caractériser d'abord (`tests/unit/`), convertir
ensuite, et un test d'intégration pour le câblage que les tests unitaires ne
voient pas. La carte 9 a ajouté un avertissement — **écrire les tests d'après
les sites d'appel réels, pas d'après l'usage qu'on imagine** : c'est ce qui a
laissé passer le cas de l'unité nulle.

## Questions ouvertes

- **`MatchState` reste-t-il un autoload ?** Une fois sa donnée dans le noyau,
  quelqu'un doit porter l'instance courante — un autoload mince, ou un use case.
- **Passe-t-il en Rust directement**, ou d'abord en GDScript dans `core/` ?
  Le noyau Rust attend des commandes ; l'état de partie est précisément ce
  qu'elles muteront.
- **`team_state` suit-il ou précède-t-il ?** Il est cinq fois plus petit et sans
  doute le bon galop d'essai.

## Terminé quand

- `autoload/` n'existe plus ;
- l'état de partie vit dans le noyau, avec ses tests ;
- `make run` : le parcours complet, du choix d'équipe au dépôt d'un joueur.
