# 17 — Le ballon

## Objectif

Sans ballon il n'y a pas de but à marquer, donc pas de récompense pour
l'apprentissage : cette carte est ce qui rend une partie auto-jouée gagnable.

## Le contenu

- **Ramasser** : un jet d'AG modifié par les zones de tackle, échec = rebond.
- **Porter** : le porteur est une donnée de l'état, pas une propriété du joueur.
- **Le rebond** : une case au hasard parmi les huit (d8, réserve dédiée).
- **La passe** : portées, modificateurs, jet de PA, déviation.
- **L'attrape** : jet d'AG, par le destinataire ou par n'importe qui d'autre.
- **La transmission** : sans jet de passe, attrape quand même.
- **La remise en jeu** quand le ballon sort.

## Ce que ça met à l'épreuve

C'est la première règle qui consomme **deux réserves différentes dans la même
résolution** (d6 pour le jet, d8 pour la direction). Le cloisonnement de la
carte 13 s'y vérifie pour de vrai.

## Questions ouvertes

- **L'interception** existe-t-elle dans ce lot ? Elle ajoute un état d'attente
  pour l'équipe adverse en plein milieu de l'action du porteur.
- **Une passe ratée est-elle un revirement ?** Oui dans les règles, mais ça
  dépend de la carte 18.
- **Le rebond en chaîne** : un ballon qui rebondit sur une case occupée rebondit
  encore. Combien de fois avant de s'arrêter ?
- **La récompense d'apprentissage** : le touchdown suffit-il, ou faut-il un
  potentiel de progression du ballon dès maintenant ? Question de la carte 20 du
  volet IA, pas de celle-ci — mais c'est ici que la donnée devient disponible.

## Terminé quand

- [ ] un joueur ramasse, porte, passe, transmet ; un autre attrape ;
- [ ] le rebond et la remise en jeu tirent dans la bonne réserve ;
- [ ] une séquence complète est rejouable à graine égale ;
- [ ] `make test-behaviour`, `make check-arch`, `make check-integrity` passent.
