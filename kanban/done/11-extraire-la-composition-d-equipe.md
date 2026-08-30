# 11 — Extraire la composition d'équipe

## Objectif

`match_state.gd` (220 l.) et `team_state.gd` (50 l.) portent de l'**état de
jeu** : où se trouve chaque joueur, ce que vaut la composition d'équipe. C'est
ce qu'une autorité serveur posséderait — leur place est le noyau.

## La carte s'est resserrée

Elle portait `match_state` (216 l.) **et** `team_state` (50 l.). Les deux ne se
font pas ensemble : `match_state` a dix fichiers consommateurs et tient un
`unit: Node` dans ses `Entry` — le problème de `UnitGrid`, un étage au-dessus.
Il a sa carte, la 22.

Celle-ci ne porte que `team_state`, cinq fois plus petit : le galop d'essai que
la carte annonçait.

## Ce qui a rendu l'extraction possible

La carte 10, sans qu'on l'ait cherché. `team_state` manipule des
`BloodBowlData.Player` — tant que le catalogue vivait dans `data/`, hors
architecture, un état extrait vers `core/` l'aurait référencé depuis le noyau.
Le catalogue étant désormais **dans `core/`**, la dépendance est interne.

Il ne restait qu'un verrou : trois `EventBus.emit`.

## La forme retenue

**Un autoload doit être un `Node`.** Un état qui part dans `core/` ne peut donc
plus en être un — il faut quelqu'un pour porter l'instance. Ce patron existe
déjà deux fois dans le projet : `blood_bowl_manager` porte le catalogue
(carte 10), et la liaison GDExtension porte la grille Rust (carte 9). Le noyau
calcule, la coquille émet.

```
app/core/team_composition.gd    75 l. — pur, aucun EventBus, aucun autoload
autoload/team_state.gd          55 l. — appelle, puis émet
```

## Deux corrections qui venaient avec

**Le camelCase.** `selectTeam`, `getSelectedTeam`, `recruitPlayer`,
`firePlayer`, `getPlayerCount`, `expandTeamComposition` étaient les seuls du
projet — faille 7 de l'audit. Cinq fichiers touchés, puisqu'on passait de toute
façon sur les onze sites d'appel.

**Une fuite.** `match_state.gd:100` lisait `TeamState._champions_list.values()`,
un champ privé atteint depuis l'extérieur. Il passe par `get_stars()`.

## Ce que le harnais a attrapé

Mon propre test de caractérisation lisait `_champions_list` — le champ privé que
ce lot supprime, et la fuite même qu'il bouche ailleurs. Le test s'est
interrompu, et les **deux verrous posés carte 9** ont tiré : « n'a exécuté
aucune assertion » et « une erreur moteur a été levée pendant les tests ».
Avant la carte 9, il serait passé au vert en silence.

## Terminé quand

- [x] la composition d'équipe vit dans `core/`, avec six tests de
  caractérisation écrits d'après les onze sites d'appel réels ;
- [x] plus de camelCase, plus d'accès au champ privé ;
- [x] les trois vérifications passent — `check-arch` couvre 3 scripts de `core/` ;
- [x] `make run` : choix d'équipe, recrutement, stars, compétences, arène —
  contrôlé à l'écran.
