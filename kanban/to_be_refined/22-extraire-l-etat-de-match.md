# 22 — Extraire l'état de match

## Objectif

`autoload/match_state.gd` (216 l.) porte **où se trouve chaque joueur pendant un
match** : réserves, terrain, K.O., blessés, plus le banc et les conditions. Ce
qu'une autorité serveur posséderait. Sa place est le noyau.

C'est le dernier script d'`autoload/` qui ne soit pas un simple porteur.

## Pourquoi c'est le lot le plus coûteux du chantier

**Dix fichiers consommateurs** : `arena`, `unit_zone`, `movement_range`,
`roster_drag`, les quatre du dugout, le bandeau de joueurs, la minimap.

**Et le problème de `UnitGrid`, un étage au-dessus** : `Entry` tient un
`unit: Node`, et `get_entry_for_unit(unit: Node)` cherche par ce nœud. Un noyau
ne peut pas garder de nœud. La parade est connue — un identifiant opaque et une
table dans la coquille, comme la carte 9 l'a fait pour la grille — mais elle
porte ici sur un objet bien plus gros.

## Ce que les cartes précédentes ont préparé

- **le patron** : le noyau calcule, la coquille émet et tient les nœuds
  (cartes 9, 10, 11) ;
- **le catalogue est dans `core/`**, donc `Entry` peut référencer
  `BloodBowlData.Player` sans violer les couches (carte 10) ;
- **`TeamState.get_stars()`** remplace l'accès au champ privé que
  `build_from_team_state()` faisait (carte 11).

## La méthode, écrite

Caractériser d'abord, convertir ensuite, et un test d'intégration pour le
câblage que les tests unitaires ne voient pas.

Avec l'avertissement que la carte 9 a payé cher : **écrire les tests d'après les
sites d'appel réels, pas d'après l'usage qu'on imagine.** Ici, ça veut dire
partir des dix fichiers consommateurs.

## Questions ouvertes

- **Un lot ou plusieurs ?** 216 lignes et dix consommateurs, c'est beaucoup pour
  un commit. Le banc (`_staff`) et les localisations pourraient se séparer.
- **`MatchState` reste-t-il un autoload ?** Oui selon le patron — une coquille
  mince qui porte l'instance et émet. Mais ses trois signaux
  (`roster_changed`, `entry_location_changed`, `staff_changed`) sont déclarés
  sur lui : ils resteront côté coquille, le noyau rendant des événements.
- **Le noyau Rust ?** Même réponse que pour le catalogue : pas tant que
  `BloodBowlData` est du GDScript. La question appartient à la carte qui
  décidera du passage du catalogue.

## Terminé quand

- `autoload/` ne contient plus que des porteurs minces ;
- l'état de match vit dans `core/`, avec ses tests ;
- `make run` : le parcours complet, du choix d'équipe au déplacement d'un joueur
  sur le terrain, dugout compris.
