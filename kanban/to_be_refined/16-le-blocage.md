# 16 — Le blocage

## Objectif

La seconde famille d'actions, et celle qui exercera le plus l'état d'attente :
un blocage pose jusqu'à trois questions au coach avant d'être résolu.

## Le contenu

- **La force** et son calcul : assistances offensives et défensives, d'où
  découle le nombre de dés (1, 2 ou 3) et **qui les choisit**.
- **Le dé de blocage** — sa propre réserve (carte 13), pas un d6.
- **La poussée** : cases de recul admissibles, poussée en chaîne quand la case
  est occupée, sortie de terrain.
- **Le suivi** : l'attaquant avance ou non, à son choix.
- **L'armure et la blessure** : 2d6 contre AV, puis la table de blessure.
- **Le blitz** : un déplacement qui inclut un blocage, une fois par tour.

## Les états d'attente que ça introduit

| Moment | Qui décide | Ce qu'il choisit |
|---|---|---|
| Dés jetés | l'attaquant, ou le défenseur si les dés lui reviennent | quel résultat appliquer |
| Résultat de poussée | l'attaquant | parmi les cases de recul admissibles |
| Après la poussée | l'attaquant | suivre ou rester |
| Jet raté | le coach actif | relancer ou non |

C'est le premier endroit où **le noyau doit savoir à qui il pose la question**.
La carte 14 ne l'a pas tranché — l'attente y était implicitement celle du coach
actif. Le cas du blocage à un dé où le défenseur choisit le résultat le rend
obligatoire.

## Questions ouvertes

- **Qui répond ?** L'état d'attente doit nommer l'équipe attendue, sinon le
  choix du dé quand il revient au défenseur n'est pas représentable.
- **La poussée en chaîne** est-elle une suite de commandes ou une résolution
  unique ? Elle peut cascader sur plusieurs joueurs, et chaque maillon peut
  ouvrir un choix de direction.
- **La sortie de terrain** (la foule) fait-elle partie de cette carte ? Elle
  n'a pas de jet d'armure et sa table de blessure diffère.
- **L'apothicaire** intercepte la blessure. Hors périmètre, mais le point
  d'accroche doit-il exister dès maintenant, ou la carte 20 le posera-t-elle ?

## Terminé quand

- [ ] un blocage se résout de bout en bout, dés jusqu'à blessure ;
- [ ] les trois choix passent par des états d'attente nommant leur destinataire ;
- [ ] la poussée en chaîne est couverte, cases occupées comprises ;
- [ ] le blitz consomme le déplacement et l'action de blocage ;
- [ ] `make test-behaviour`, `make check-arch`, `make check-integrity` passent.
