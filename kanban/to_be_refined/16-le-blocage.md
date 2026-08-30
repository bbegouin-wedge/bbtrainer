# 16 — Le blocage

## Objectif

La seconde famille d'actions, et celle qui exercera le plus l'état d'attente :
un blocage pose jusqu'à trois questions au coach avant d'être résolu.

## Le contenu

- **La force** et son calcul : assistances offensives et défensives, d'où
  découle le nombre de dés (1, 2 ou 3) et **qui les choisit**.
- **La table des symboles du dé de blocage**, sourcée et laissée ici par la
  carte 13 :

  | Face | Résultat |
  |---|---|
  | 1 | Crâne |
  | 2 | Double chute |
  | 3 | Repoussé |
  | 4 | Repoussé |
  | 5 | Trébuchement |
  | 6 | Mis à terre |

  **Le noyau des dés ne connaît que des nombres.** `Dice::roll(Die::Block)` rend
  un entier de 1 à 6 ; la traduction en symbole est une règle du jeu, donc elle
  vit ici. Bénéfice au test : une réserve écrite à la main s'écrit `[1, 1]` et se
  lit « deux crânes ».

  Le dé de blocage a bien sa propre réserve malgré ses six faces : sans elle,
  chaque blocage décalerait la suite des esquives et des jets d'armure.
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

## Ce que la carte 14 lui lègue

**« Qui répond ? » est déjà résolu.** `Pending` porte un champ `coach`, jamais
déduit du tour courant. La carte 14 l'a imposé en sourçant `SIDESTEP` (*« au lieu
que l'entraîneur adverse choisisse où ce joueur est Repoussé… »*) et `TAUNT`
(*« l'entraîneur de ce joueur peut choisir de faire Suivre le joueur adverse »*)
— deux compétences qui **transfèrent la propriété d'une décision**.

**Cette carte supprime l'échafaudage.** `Command::Ask`, `Command::Answer` et
`Question::Confirm` n'existent que pour exercer le mécanisme d'attente en
l'absence de toute règle qui en produise. Les vraies questions du blocage — quel
dé, quelle case de poussée, suivre ou non, relancer — les remplacent.

**Un événement de jet doit identifier chaque dé séparément.** Contrainte tirée de
`PRO` par la carte 14 : *« il peut tenter de relancer **un seul dé** […] dans le
cadre d'un jet de dés multiples »*. On ne peut pas désigner « le deuxième des
trois » si les dés sortent en bloc. C'est ici que ça se paie, puisque le blocage
est le premier jet multiple du jeu.

## Questions ouvertes

- ~~**Qui répond ?**~~ Résolu par la carte 14 : `Pending.coach`.
- **La poussée en chaîne** est-elle une suite de commandes ou une résolution
  unique ? Elle peut cascader sur plusieurs joueurs, et chaque maillon peut
  ouvrir un choix de direction.
- **La sortie de terrain** (la foule) fait-elle partie de cette carte ? Elle
  n'a pas de jet d'armure et sa table de blessure diffère.
- **L'apothicaire** intercepte la blessure. Hors périmètre, mais le point
  d'accroche doit-il exister dès maintenant, ou la carte 20 le posera-t-elle ?
- **Le nombre de dés et qui les choisit** : la table des symboles est sourcée,
  mais pas la règle qui dit combien de dés on jette selon l'écart de force, ni
  celui qui choisit le résultat quand l'avantage est au défenseur.

## Terminé quand

- [ ] un blocage se résout de bout en bout, dés jusqu'à blessure ;
- [ ] les trois choix passent par des états d'attente nommant leur destinataire ;
- [ ] la poussée en chaîne est couverte, cases occupées comprises ;
- [ ] le blitz consomme le déplacement et l'action de blocage ;
- [ ] `make test-behaviour`, `make check-arch`, `make check-integrity` passent.
