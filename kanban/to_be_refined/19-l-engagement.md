# 19 — L'engagement

## Objectif

Le début de mi-temps : mise en place des deux équipes, coup de pied, table
d'engagement. C'est ce qui manque pour qu'une partie démarre toute seule, sans
qu'un humain place les joueurs.

## Le contenu

- **La mise en place** : onze joueurs maximum, trois sur la ligne de mêlée, deux
  par large couloir au plus.
- **Le coup de pied** : case visée, déviation (d8 + d6).
- **La table d'engagement** : 2d6, avec ses résultats — dont plusieurs
  modifient l'état de façon spectaculaire.
- **La météo**, tirée avant le premier engagement.

## Pourquoi c'est plus lourd qu'il n'y paraît

La mise en place est **onze décisions de placement**, soit une phase entière
avec son propre espace d'actions. Pour l'IA, la carte d'actions spatiale a déjà
prévu un type `PLACER` — c'est ici qu'il sert. La qualité de la mise en place
est une vraie compétence de coach, et un agent qui la subit part perdant.

## Questions ouvertes

- **La mise en place est-elle une suite de commandes** (un placement à la fois,
  cohérent avec le pas atomique de la carte 15) **ou une commande unique**
  portant les onze positions ? Le pas atomique est cohérent, mais la légalité
  d'un placement dépend de l'ensemble final.
- **Les résultats d'engagement les plus perturbants** (invasion du terrain,
  ballon renvoyé, blitz surprise) sont-ils tous du lot, ou en garde-t-on
  quelques-uns pour plus tard ?
- **La météo** modifie des règles écrites dans les cartes 15 à 17. Faut-il un
  point d'accroche plutôt qu'un `if` disséminé ?
- **En variante réduite** (3v3, terrain court — cf. le paramètre décidé pour
  l'IA), que devient la ligne de mêlée ?

## Terminé quand

- [ ] les deux équipes se placent légalement, illégalité refusée ;
- [ ] le coup de pied dévie correctement ;
- [ ] la table d'engagement est appliquée, résultats compris ;
- [ ] une partie démarre sans intervention humaine ;
- [ ] `make test-behaviour`, `make check-arch`, `make check-integrity` passent.
